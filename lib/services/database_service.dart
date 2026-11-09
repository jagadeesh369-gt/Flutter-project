import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import '../models/donation_model.dart';
import '../models/inventory_model.dart';
import '../models/distribution_model.dart';
import '../models/transaction_record_model.dart';

/// Database management service handling SQLite database initialization,
/// migrations, atomic transactions, and sample demo data preloading.
class DatabaseService {
  static const String _dbName = 'foodbridge.db';
  static const int _dbVersion = 1;

  static DatabaseService? _instance;
  static Database? _database;
  final Uuid _uuid = const Uuid();

  DatabaseService._();

  static DatabaseService get instance {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // If running on desktop platform (Windows, Linux, macOS), initialize FFI
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final fullPath = p.join(dbPath, _dbName);

    return await openDatabase(
      fullPath,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create Donations Table
    await db.execute('''
      CREATE TABLE donations (
        id TEXT PRIMARY KEY,
        donor_name TEXT NOT NULL,
        phone_number TEXT,
        food_item_name TEXT NOT NULL,
        category TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        donation_date TEXT NOT NULL,
        expiry_date TEXT NOT NULL,
        condition TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Create Inventory Table
    await db.execute('''
      CREATE TABLE inventory (
        id TEXT PRIMARY KEY,
        food_name TEXT NOT NULL,
        category TEXT NOT NULL,
        available_quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        expiry_date TEXT NOT NULL,
        low_stock_threshold REAL DEFAULT 20.0,
        last_updated TEXT NOT NULL
      )
    ''');

    // Create Distributions Table
    await db.execute('''
      CREATE TABLE distributions (
        id TEXT PRIMARY KEY,
        recipient_name TEXT NOT NULL,
        phone_number TEXT,
        food_item_id TEXT NOT NULL,
        food_item_name TEXT NOT NULL,
        quantity_distributed REAL NOT NULL,
        unit TEXT NOT NULL,
        distribution_date TEXT NOT NULL,
        purpose TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (food_item_id) REFERENCES inventory (id) ON DELETE CASCADE
      )
    ''');
  }

  // ==========================================
  // DONATION OPERATIONS
  // ==========================================

  Future<List<DonationModel>> getAllDonations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'donations',
      orderBy: 'donation_date DESC, created_at DESC',
    );
    return maps.map((m) => DonationModel.fromMap(m)).toList();
  }

  /// Inserts a donation and automatically updates or creates the inventory item
  /// inside a single ACID SQLite transaction.
  Future<void> recordDonationWithInventorySync(DonationModel donation) async {
    final db = await database;
    await db.transaction((txn) async {
      // 1. Insert donation record
      await txn.insert('donations', donation.toMap());

      // 2. Check if identical item (same name, category, unit) exists in inventory
      final List<Map<String, dynamic>> existingItems = await txn.query(
        'inventory',
        where: 'LOWER(food_name) = ? AND category = ? AND unit = ?',
        whereArgs: [donation.foodItemName.trim().toLowerCase(), donation.category, donation.unit],
      );

      if (existingItems.isNotEmpty) {
        // Update existing item
        final existing = InventoryModel.fromMap(existingItems.first);
        final newQuantity = existing.availableQuantity + donation.quantity;

        // Keep earlier expiry date if new donation expires sooner
        final effectiveExpiry = donation.expiryDate.isBefore(existing.expiryDate)
            ? donation.expiryDate
            : existing.expiryDate;

        await txn.update(
          'inventory',
          {
            'available_quantity': newQuantity,
            'expiry_date': effectiveExpiry.toIso8601String(),
            'last_updated': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [existing.id],
        );
      } else {
        // Create new inventory entry
        final newInventoryItem = InventoryModel(
          id: _uuid.v4(),
          foodName: donation.foodItemName.trim(),
          category: donation.category,
          availableQuantity: donation.quantity,
          unit: donation.unit,
          expiryDate: donation.expiryDate,
          lastUpdated: DateTime.now(),
        );

        await txn.insert('inventory', newInventoryItem.toMap());
      }
    });
  }

  /// Updates a donation record and synchronizes the inventory quantity difference.
  Future<void> updateDonationWithInventorySync(
    DonationModel updatedDonation,
    DonationModel oldDonation,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      // Update donation record
      await txn.update(
        'donations',
        updatedDonation.toMap(),
        where: 'id = ?',
        whereArgs: [updatedDonation.id],
      );

      final diff = updatedDonation.quantity - oldDonation.quantity;
      if (diff != 0) {
        final List<Map<String, dynamic>> items = await txn.query(
          'inventory',
          where: 'LOWER(food_name) = ? AND category = ? AND unit = ?',
          whereArgs: [
            oldDonation.foodItemName.trim().toLowerCase(),
            oldDonation.category,
            oldDonation.unit,
          ],
        );

        if (items.isNotEmpty) {
          final existing = InventoryModel.fromMap(items.first);
          final updatedQty = (existing.availableQuantity + diff).clamp(0.0, 999999.0);
          await txn.update(
            'inventory',
            {
              'available_quantity': updatedQty,
              'last_updated': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [existing.id],
          );
        }
      }
    });
  }

  /// Deletes a donation and adjusts inventory stock accordingly.
  Future<void> deleteDonationWithInventorySync(DonationModel donation) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'donations',
        where: 'id = ?',
        whereArgs: [donation.id],
      );

      final List<Map<String, dynamic>> items = await txn.query(
        'inventory',
        where: 'LOWER(food_name) = ? AND category = ? AND unit = ?',
        whereArgs: [
          donation.foodItemName.trim().toLowerCase(),
          donation.category,
          donation.unit,
        ],
      );

      if (items.isNotEmpty) {
        final existing = InventoryModel.fromMap(items.first);
        final newQty = (existing.availableQuantity - donation.quantity).clamp(0.0, 999999.0);
        await txn.update(
          'inventory',
          {
            'available_quantity': newQty,
            'last_updated': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [existing.id],
        );
      }
    });
  }

  // ==========================================
  // INVENTORY OPERATIONS
  // ==========================================

  Future<List<InventoryModel>> getAllInventory() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'inventory',
      orderBy: 'food_name ASC',
    );
    return maps.map((m) => InventoryModel.fromMap(m)).toList();
  }

  Future<InventoryModel?> getInventoryItemById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'inventory',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return InventoryModel.fromMap(maps.first);
  }

  Future<void> insertInventoryItem(InventoryModel item) async {
    final db = await database;
    await db.insert(
      'inventory',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateInventoryItem(InventoryModel item) async {
    final db = await database;
    await db.update(
      'inventory',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteInventoryItem(String id) async {
    final db = await database;
    await db.delete(
      'inventory',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==========================================
  // DISTRIBUTION OPERATIONS
  // ==========================================

  Future<List<DistributionModel>> getAllDistributions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'distributions',
      orderBy: 'distribution_date DESC, created_at DESC',
    );
    return maps.map((m) => DistributionModel.fromMap(m)).toList();
  }

  /// Atomically validates stock sufficiency and expiry date, inserts distribution record,
  /// and deducts distributed quantity from inventory.
  Future<void> recordDistributionTransaction(DistributionModel distribution) async {
    final db = await database;
    await db.transaction((txn) async {
      // 1. Fetch current inventory row
      final List<Map<String, dynamic>> items = await txn.query(
        'inventory',
        where: 'id = ?',
        whereArgs: [distribution.foodItemId],
        limit: 1,
      );

      if (items.isEmpty) {
        throw Exception('The selected food item does not exist in inventory.');
      }

      final item = InventoryModel.fromMap(items.first);

      // 2. Validate expiry
      if (item.isExpired) {
        throw Exception('Safety restriction: Cannot distribute expired food (${item.foodName}).');
      }

      // 3. Validate sufficient stock
      if (item.availableQuantity < distribution.quantityDistributed) {
        throw Exception(
          'Insufficient stock for "${item.foodName}". '
          'Requested: ${distribution.quantityDistributed} ${item.unit}, '
          'Available: ${item.availableQuantity} ${item.unit}.',
        );
      }

      // 4. Record distribution
      await txn.insert('distributions', distribution.toMap());

      // 5. Deduct from inventory
      final remaining = item.availableQuantity - distribution.quantityDistributed;
      await txn.update(
        'inventory',
        {
          'available_quantity': remaining,
          'last_updated': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [item.id],
      );
    });
  }

  // ==========================================
  // UNIFIED TRANSACTIONS
  // ==========================================

  Future<List<TransactionRecordModel>> getAllTransactions() async {
    final donations = await getAllDonations();
    final distributions = await getAllDistributions();

    final List<TransactionRecordModel> transactions = [];

    for (final d in donations) {
      transactions.add(TransactionRecordModel(
        id: d.id,
        type: TransactionType.donation,
        foodItem: d.foodItemName,
        quantity: d.quantity,
        unit: d.unit,
        date: d.donationDate,
        partyName: d.donorName,
        phoneNumber: d.phoneNumber,
        details: 'Condition: ${d.condition}${d.description.isNotEmpty ? " • ${d.description}" : ""}',
        category: d.category,
      ));
    }

    for (final dist in distributions) {
      transactions.add(TransactionRecordModel(
        id: dist.id,
        type: TransactionType.distribution,
        foodItem: dist.foodItemName,
        quantity: dist.quantityDistributed,
        unit: dist.unit,
        date: dist.distributionDate,
        partyName: dist.recipientName,
        phoneNumber: dist.phoneNumber,
        details: dist.purpose.isNotEmpty ? dist.purpose : 'Food Relief Distribution',
      ));
    }

    // Sort descending by date
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

  // ==========================================
  // DEMO DATA PRELOADING & RESET
  // ==========================================

  Future<bool> isDatabaseEmpty() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM inventory'),
    );
    return (count ?? 0) == 0;
  }

  Future<void> preloadDemoData() async {
    final db = await database;
    final now = DateTime.now();

    // Sample Inventory Items across multiple categories, quantities, and realistic expiries
    final List<InventoryModel> sampleInventory = [
      InventoryModel(
        id: 'inv-1',
        foodName: 'Rice',
        category: 'Rice and Grains',
        availableQuantity: 150.0,
        unit: 'kg',
        expiryDate: now.add(const Duration(days: 120)),
        lastUpdated: now,
      ),
      InventoryModel(
        id: 'inv-2',
        foodName: 'Wheat Flour',
        category: 'Rice and Grains',
        availableQuantity: 80.0,
        unit: 'kg',
        expiryDate: now.add(const Duration(days: 90)),
        lastUpdated: now,
      ),
      InventoryModel(
        id: 'inv-3',
        foodName: 'Toor Dal',
        category: 'Pulses',
        availableQuantity: 45.0,
        unit: 'kg',
        expiryDate: now.add(const Duration(days: 180)),
        lastUpdated: now,
      ),
      InventoryModel(
        id: 'inv-4',
        foodName: 'Sunflower Cooking Oil',
        category: 'Packaged Food',
        availableQuantity: 30.0,
        unit: 'litres',
        expiryDate: now.add(const Duration(days: 60)),
        lastUpdated: now,
      ),
      InventoryModel(
        id: 'inv-5',
        foodName: 'Glucose Biscuits',
        category: 'Packaged Food',
        availableQuantity: 120.0,
        unit: 'packets',
        expiryDate: now.add(const Duration(days: 25)), // Expiring within 30 days
        lastUpdated: now,
      ),
      InventoryModel(
        id: 'inv-6',
        foodName: 'Fresh Vegetables Basket',
        category: 'Vegetables',
        availableQuantity: 35.0,
        unit: 'kg',
        expiryDate: now.add(const Duration(days: 4)), // Expiring soon (<7 days)
        lastUpdated: now,
      ),
      InventoryModel(
        id: 'inv-7',
        foodName: 'Pasteurized Milk Packets',
        category: 'Dairy Products',
        availableQuantity: 15.0, // Low stock (<= 20)
        unit: 'litres',
        expiryDate: now.add(const Duration(days: 2)), // Expiring soon
        lastUpdated: now,
      ),
      InventoryModel(
        id: 'inv-8',
        foodName: 'Fresh Apples & Oranges',
        category: 'Fruits',
        availableQuantity: 18.0, // Low stock
        unit: 'kg',
        expiryDate: now.add(const Duration(days: 6)), // Expiring soon
        lastUpdated: now,
      ),
      InventoryModel(
        id: 'inv-9',
        foodName: 'Artisan Bread Loaves',
        category: 'Packaged Food',
        availableQuantity: 10.0,
        unit: 'packets',
        expiryDate: now.subtract(const Duration(days: 2)), // Expired item for demonstration
        lastUpdated: now,
      ),
    ];

    // Sample Donations
    final List<DonationModel> sampleDonations = [
      DonationModel(
        id: 'don-1',
        donorName: 'Green Future NGO',
        phoneNumber: '+91 98765 43210',
        foodItemName: 'Rice',
        category: 'Rice and Grains',
        quantity: 175.0,
        unit: 'kg',
        donationDate: now.subtract(const Duration(days: 10)),
        expiryDate: now.add(const Duration(days: 120)),
        condition: 'Fresh',
        description: 'Bulk grain donation from harvest drive',
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      DonationModel(
        id: 'don-2',
        donorName: 'Local Supermarket',
        phoneNumber: '+91 91234 56789',
        foodItemName: 'Glucose Biscuits',
        category: 'Packaged Food',
        quantity: 140.0,
        unit: 'packets',
        donationDate: now.subtract(const Duration(days: 7)),
        expiryDate: now.add(const Duration(days: 25)),
        condition: 'Good',
        description: 'Excess surplus boxed inventory',
        createdAt: now.subtract(const Duration(days: 7)),
      ),
      DonationModel(
        id: 'don-3',
        donorName: 'Community Volunteers',
        phoneNumber: '+91 99887 76655',
        foodItemName: 'Fresh Vegetables Basket',
        category: 'Vegetables',
        quantity: 45.0,
        unit: 'kg',
        donationDate: now.subtract(const Duration(days: 3)),
        expiryDate: now.add(const Duration(days: 4)),
        condition: 'Fresh',
        description: 'Organic local farm surplus',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      DonationModel(
        id: 'don-4',
        donorName: 'Individual Donors (Priya Sharma)',
        phoneNumber: '+91 90123 45678',
        foodItemName: 'Sunflower Cooking Oil',
        category: 'Packaged Food',
        quantity: 30.0,
        unit: 'litres',
        donationDate: now.subtract(const Duration(days: 2)),
        expiryDate: now.add(const Duration(days: 60)),
        condition: 'Fresh',
        description: 'Birthday celebration food drive contribution',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      DonationModel(
        id: 'don-5',
        donorName: 'City Dairy Cooperative',
        phoneNumber: '+91 94567 89012',
        foodItemName: 'Pasteurized Milk Packets',
        category: 'Dairy Products',
        quantity: 25.0,
        unit: 'litres',
        donationDate: now.subtract(const Duration(days: 1)),
        expiryDate: now.add(const Duration(days: 2)),
        condition: 'Fresh',
        description: 'Chilled early morning delivery',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];

    // Sample Distributions
    final List<DistributionModel> sampleDistributions = [
      DistributionModel(
        id: 'dist-1',
        recipientName: 'Community Welfare Center',
        phoneNumber: '+91 98451 11223',
        foodItemId: 'inv-1',
        foodItemName: 'Rice',
        quantityDistributed: 25.0,
        unit: 'kg',
        distributionDate: now.subtract(const Duration(days: 5)),
        purpose: 'Weekly community kitchen lunch program',
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      DistributionModel(
        id: 'dist-2',
        recipientName: 'Local Orphanage (Sneha Nilayam)',
        phoneNumber: '+91 94401 22334',
        foodItemId: 'inv-5',
        foodItemName: 'Glucose Biscuits',
        quantityDistributed: 20.0,
        unit: 'packets',
        distributionDate: now.subtract(const Duration(days: 4)),
        purpose: 'Evening snacks for 40 resident children',
        createdAt: now.subtract(const Duration(days: 4)),
      ),
      DistributionModel(
        id: 'dist-3',
        recipientName: 'Government School Mid-day Meal',
        phoneNumber: '+91 93901 33445',
        foodItemId: 'inv-6',
        foodItemName: 'Fresh Vegetables Basket',
        quantityDistributed: 10.0,
        unit: 'kg',
        distributionDate: now.subtract(const Duration(days: 2)),
        purpose: 'Nutritious lunch supplements for primary students',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      DistributionModel(
        id: 'dist-4',
        recipientName: 'Needy Families Support Group',
        phoneNumber: '+91 91001 44556',
        foodItemId: 'inv-7',
        foodItemName: 'Pasteurized Milk Packets',
        quantityDistributed: 10.0,
        unit: 'litres',
        distributionDate: now.subtract(const Duration(days: 1)),
        purpose: 'Infant and elderly dietary relief pack',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];

    await db.transaction((txn) async {
      for (final item in sampleInventory) {
        await txn.insert('inventory', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final don in sampleDonations) {
        await txn.insert('donations', don.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final dist in sampleDistributions) {
        await txn.insert('distributions', dist.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('distributions');
      await txn.delete('donations');
      await txn.delete('inventory');
    });
  }

  Future<void> resetToDemoData() async {
    await clearAllData();
    await preloadDemoData();
  }
}

