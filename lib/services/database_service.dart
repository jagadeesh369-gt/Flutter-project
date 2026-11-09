import 'dart:io' if (dart.library.html) 'dart:html' as universal_io;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import '../models/donation_model.dart';
import '../models/inventory_model.dart';
import '../models/distribution_model.dart';
import '../models/transaction_record_model.dart';

/// Database management service handling SQLite database initialization for Android/Desktop,
/// with an automatic reactive fallback store for Web (Render / Browser) deployments.
class DatabaseService {
  static const String _dbName = 'foodbridge.db';
  static const int _dbVersion = 1;

  static DatabaseService? _instance;
  static Database? _database;
  final Uuid _uuid = const Uuid();

  // In-memory web fallback store
  final List<DonationModel> _webDonations = [];
  final List<InventoryModel> _webInventory = [];
  final List<DistributionModel> _webDistributions = [];
  bool _webInitialized = false;

  DatabaseService._();

  static DatabaseService get instance {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database?> _initDatabase() async {
    if (kIsWeb) return null;

    try {
      if (!kIsWeb) {
        // Desktop platform check
        final isDesktop = defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS;

        if (isDesktop) {
          sqfliteFfiInit();
          databaseFactory = databaseFactoryFfi;
        }
      }

      final dbPath = await getDatabasesPath();
      final fullPath = p.join(dbPath, _dbName);

      return await openDatabase(
        fullPath,
        version: _dbVersion,
        onCreate: _onCreate,
      );
    } catch (e) {
      debugPrint('SQLite initialization warning: $e. Falling back to web store.');
      return null;
    }
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
    if (kIsWeb) {
      final list = List<DonationModel>.from(_webDonations);
      list.sort((a, b) => b.donationDate.compareTo(a.donationDate));
      return list;
    }

    try {
      final db = await database;
      if (db == null) return List.from(_webDonations);
      final List<Map<String, dynamic>> maps = await db.query(
        'donations',
        orderBy: 'donation_date DESC, created_at DESC',
      );
      return maps.map((m) => DonationModel.fromMap(m)).toList();
    } catch (_) {
      return List.from(_webDonations);
    }
  }

  /// Inserts a donation and automatically updates or creates the inventory item
  /// inside a single ACID SQLite transaction (or web state).
  Future<void> recordDonationWithInventorySync(DonationModel donation) async {
    if (kIsWeb) {
      _webDonations.insert(0, donation);
      final existingIndex = _webInventory.indexWhere(
        (i) =>
            i.foodName.trim().toLowerCase() == donation.foodItemName.trim().toLowerCase() &&
            i.category == donation.category &&
            i.unit == donation.unit,
      );

      if (existingIndex >= 0) {
        final existing = _webInventory[existingIndex];
        final effectiveExpiry = donation.expiryDate.isBefore(existing.expiryDate)
            ? donation.expiryDate
            : existing.expiryDate;
        _webInventory[existingIndex] = existing.copyWith(
          availableQuantity: existing.availableQuantity + donation.quantity,
          expiryDate: effectiveExpiry,
          lastUpdated: DateTime.now(),
        );
      } else {
        _webInventory.add(InventoryModel(
          id: _uuid.v4(),
          foodName: donation.foodItemName.trim(),
          category: donation.category,
          availableQuantity: donation.quantity,
          unit: donation.unit,
          expiryDate: donation.expiryDate,
          lastUpdated: DateTime.now(),
        ));
      }
      return;
    }

    try {
      final db = await database;
      if (db == null) return;
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
          final existing = InventoryModel.fromMap(existingItems.first);
          final newQuantity = existing.availableQuantity + donation.quantity;
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
    } catch (e) {
      debugPrint('Error recording donation in DB: $e');
    }
  }

  Future<void> updateDonationWithInventorySync(
    DonationModel updatedDonation,
    DonationModel oldDonation,
  ) async {
    if (kIsWeb) {
      final idx = _webDonations.indexWhere((d) => d.id == updatedDonation.id);
      if (idx >= 0) _webDonations[idx] = updatedDonation;

      final diff = updatedDonation.quantity - oldDonation.quantity;
      if (diff != 0) {
        final invIdx = _webInventory.indexWhere(
          (i) =>
              i.foodName.trim().toLowerCase() == oldDonation.foodItemName.trim().toLowerCase() &&
              i.category == oldDonation.category &&
              i.unit == oldDonation.unit,
        );
        if (invIdx >= 0) {
          final existing = _webInventory[invIdx];
          _webInventory[invIdx] = existing.copyWith(
            availableQuantity: (existing.availableQuantity + diff).clamp(0.0, 999999.0),
            lastUpdated: DateTime.now(),
          );
        }
      }
      return;
    }

    try {
      final db = await database;
      if (db == null) return;
      await db.transaction((txn) async {
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
    } catch (e) {
      debugPrint('Error updating donation in DB: $e');
    }
  }

  Future<void> deleteDonationWithInventorySync(DonationModel donation) async {
    if (kIsWeb) {
      _webDonations.removeWhere((d) => d.id == donation.id);
      final invIdx = _webInventory.indexWhere(
        (i) =>
            i.foodName.trim().toLowerCase() == donation.foodItemName.trim().toLowerCase() &&
            i.category == donation.category &&
            i.unit == donation.unit,
      );
      if (invIdx >= 0) {
        final existing = _webInventory[invIdx];
        _webInventory[invIdx] = existing.copyWith(
          availableQuantity: (existing.availableQuantity - donation.quantity).clamp(0.0, 999999.0),
          lastUpdated: DateTime.now(),
        );
      }
      return;
    }

    try {
      final db = await database;
      if (db == null) return;
      await db.transaction((txn) async {
        await txn.delete('donations', where: 'id = ?', whereArgs: [donation.id]);

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
    } catch (e) {
      debugPrint('Error deleting donation in DB: $e');
    }
  }

  // ==========================================
  // INVENTORY OPERATIONS
  // ==========================================

  Future<List<InventoryModel>> getAllInventory() async {
    if (kIsWeb) {
      return List.from(_webInventory);
    }

    try {
      final db = await database;
      if (db == null) return List.from(_webInventory);
      final List<Map<String, dynamic>> maps = await db.query(
        'inventory',
        orderBy: 'food_name ASC',
      );
      return maps.map((m) => InventoryModel.fromMap(m)).toList();
    } catch (_) {
      return List.from(_webInventory);
    }
  }

  Future<InventoryModel?> getInventoryItemById(String id) async {
    if (kIsWeb) {
      final matches = _webInventory.where((i) => i.id == id);
      return matches.isNotEmpty ? matches.first : null;
    }

    try {
      final db = await database;
      if (db == null) {
        final matches = _webInventory.where((i) => i.id == id);
        return matches.isNotEmpty ? matches.first : null;
      }
      final List<Map<String, dynamic>> maps = await db.query(
        'inventory',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return InventoryModel.fromMap(maps.first);
    } catch (_) {
      final matches = _webInventory.where((i) => i.id == id);
      return matches.isNotEmpty ? matches.first : null;
    }
  }

  Future<void> insertInventoryItem(InventoryModel item) async {
    if (kIsWeb) {
      final idx = _webInventory.indexWhere((i) => i.id == item.id);
      if (idx >= 0) {
        _webInventory[idx] = item;
      } else {
        _webInventory.insert(0, item);
      }
      return;
    }

    try {
      final db = await database;
      if (db == null) return;
      await db.insert('inventory', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint('Error inserting inventory item: $e');
    }
  }

  Future<void> updateInventoryItem(InventoryModel item) async {
    if (kIsWeb) {
      final idx = _webInventory.indexWhere((i) => i.id == item.id);
      if (idx >= 0) _webInventory[idx] = item;
      return;
    }

    try {
      final db = await database;
      if (db == null) return;
      await db.update('inventory', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
    } catch (e) {
      debugPrint('Error updating inventory item: $e');
    }
  }

  Future<void> deleteInventoryItem(String id) async {
    if (kIsWeb) {
      _webInventory.removeWhere((i) => i.id == id);
      return;
    }

    try {
      final db = await database;
      if (db == null) return;
      await db.delete('inventory', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      debugPrint('Error deleting inventory item: $e');
    }
  }

  // ==========================================
  // DISTRIBUTION OPERATIONS
  // ==========================================

  Future<List<DistributionModel>> getAllDistributions() async {
    if (kIsWeb) {
      final list = List<DistributionModel>.from(_webDistributions);
      list.sort((a, b) => b.distributionDate.compareTo(a.distributionDate));
      return list;
    }

    try {
      final db = await database;
      if (db == null) return List.from(_webDistributions);
      final List<Map<String, dynamic>> maps = await db.query(
        'distributions',
        orderBy: 'distribution_date DESC, created_at DESC',
      );
      return maps.map((m) => DistributionModel.fromMap(m)).toList();
    } catch (_) {
      return List.from(_webDistributions);
    }
  }

  Future<void> recordDistributionTransaction(DistributionModel distribution) async {
    if (kIsWeb) {
      final itemIdx = _webInventory.indexWhere((i) => i.id == distribution.foodItemId);
      if (itemIdx < 0) {
        throw Exception('The selected food item does not exist in inventory.');
      }
      final item = _webInventory[itemIdx];
      if (item.isExpired) {
        throw Exception('Safety restriction: Cannot distribute expired food (${item.foodName}).');
      }
      if (item.availableQuantity < distribution.quantityDistributed) {
        throw Exception(
          'Insufficient stock for "${item.foodName}". '
          'Requested: ${distribution.quantityDistributed} ${item.unit}, '
          'Available: ${item.availableQuantity} ${item.unit}.',
        );
      }

      _webDistributions.insert(0, distribution);
      _webInventory[itemIdx] = item.copyWith(
        availableQuantity: item.availableQuantity - distribution.quantityDistributed,
        lastUpdated: DateTime.now(),
      );
      return;
    }

    final db = await database;
    if (db == null) return;
    await db.transaction((txn) async {
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

      if (item.isExpired) {
        throw Exception('Safety restriction: Cannot distribute expired food (${item.foodName}).');
      }

      if (item.availableQuantity < distribution.quantityDistributed) {
        throw Exception(
          'Insufficient stock for "${item.foodName}". '
          'Requested: ${distribution.quantityDistributed} ${item.unit}, '
          'Available: ${item.availableQuantity} ${item.unit}.',
        );
      }

      await txn.insert('distributions', distribution.toMap());

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

    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

  // ==========================================
  // DEMO DATA PRELOADING & RESET
  // ==========================================

  Future<bool> isDatabaseEmpty() async {
    if (kIsWeb) {
      return !_webInitialized && _webInventory.isEmpty;
    }

    try {
      final db = await database;
      if (db == null) return _webInventory.isEmpty;
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM inventory'),
      );
      return (count ?? 0) == 0;
    } catch (_) {
      return _webInventory.isEmpty;
    }
  }

  Future<void> preloadDemoData() async {
    final now = DateTime.now();

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
        expiryDate: now.add(const Duration(days: 25)),
        lastUpdated: now,
      ),
      InventoryModel(
        id: 'inv-6',
        foodName: 'Fresh Vegetables Basket',
        category: 'Vegetables',
        availableQuantity: 35.0,
        unit: 'kg',
        expiryDate: now.add(const Duration(days: 4)),
        lastUpdated: now,
      ),
      InventoryModel(
        id: 'inv-7',
        foodName: 'Pasteurized Milk Packets',
        category: 'Dairy Products',
        availableQuantity: 15.0,
        unit: 'litres',
        expiryDate: now.add(const Duration(days: 2)),
        lastUpdated: now,
      ),
      InventoryModel(
        id: 'inv-8',
        foodName: 'Fresh Apples & Oranges',
        category: 'Fruits',
        availableQuantity: 18.0,
        unit: 'kg',
        expiryDate: now.add(const Duration(days: 6)),
        lastUpdated: now,
      ),
      InventoryModel(
        id: 'inv-9',
        foodName: 'Artisan Bread Loaves',
        category: 'Packaged Food',
        availableQuantity: 10.0,
        unit: 'packets',
        expiryDate: now.subtract(const Duration(days: 2)),
        lastUpdated: now,
      ),
    ];

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

    if (kIsWeb) {
      _webInventory.clear();
      _webInventory.addAll(sampleInventory);
      _webDonations.clear();
      _webDonations.addAll(sampleDonations);
      _webDistributions.clear();
      _webDistributions.addAll(sampleDistributions);
      _webInitialized = true;
      return;
    }

    try {
      final db = await database;
      if (db == null) {
        _webInventory.addAll(sampleInventory);
        _webDonations.addAll(sampleDonations);
        _webDistributions.addAll(sampleDistributions);
        return;
      }
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
    } catch (e) {
      debugPrint('Error preloading demo data in DB: $e');
      _webInventory.addAll(sampleInventory);
      _webDonations.addAll(sampleDonations);
      _webDistributions.addAll(sampleDistributions);
    }
  }

  Future<void> clearAllData() async {
    if (kIsWeb) {
      _webInventory.clear();
      _webDonations.clear();
      _webDistributions.clear();
      return;
    }

    try {
      final db = await database;
      if (db == null) {
        _webInventory.clear();
        _webDonations.clear();
        _webDistributions.clear();
        return;
      }
      await db.transaction((txn) async {
        await txn.delete('distributions');
        await txn.delete('donations');
        await txn.delete('inventory');
      });
    } catch (e) {
      debugPrint('Error clearing data in DB: $e');
    }
  }

  Future<void> resetToDemoData() async {
    await clearAllData();
    await preloadDemoData();
  }
}
