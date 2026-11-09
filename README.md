# FoodBridge – Food Bank Inventory and Donation Tracker

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Provider](https://img.shields.io/badge/State%20Management-Provider%20%26%20ChangeNotifier-237A57)](https://pub.dev/packages/provider)
[![Database](https://img.shields.io/badge/Local%20Database-SQLite%20(sqflite)-4E73DF)](https://pub.dev/packages/sqflite)
[![Design](https://img.shields.io/badge/Design-Material%203-237A57)](https://m3.material.io)
[![UN SDG](https://img.shields.io/badge/UN%20SDG-Goal%202%20(Zero%20Hunger)-E5243B)](https://sdgs.un.org/goals/goal2)

FoodBridge is a production-grade, offline-first mobile application built with **Flutter**, **Dart**, **Provider**, **ChangeNotifier**, and **SQLite (`sqflite`)**. Engineered for non-governmental organizations (NGOs), community food banks, and charitable welfare trusts, FoodBridge automates surplus food donations, maintains accurate warehousing inventory, proactively prevents food spoilage via multi-tier expiry tracking, and streamlines transparent food aid distributions.

---

## Table of Contents

1. [Problem Statement](#1-problem-statement)
2. [Project Objectives](#2-project-objectives)
3. [Sustainable Development Goals (SDG) Alignment](#3-sustainable-development-goals-sdg-alignment)
4. [Key Features & System Capabilities](#4-key-features--system-capabilities)
5. [System Architecture & Design Patterns](#5-system-architecture--design-patterns)
6. [Provider & ChangeNotifier Implementation](#6-provider--changenotifier-implementation)
7. [Database Schema & ACID Transactions](#7-database-schema--acid-transactions)
8. [Folder & Package Structure](#8-folder--package-structure)
9. [Prerequisites & Installation Guide](#9-prerequisites--installation-guide)
10. [How to Run the Application](#10-how-to-run-the-application)
11. [Suggested Screenshot Captures](#11-suggested-screenshot-captures)
12. [Live Project Demonstration Script](#12-live-project-demonstration-script)
13. [GitHub Upload Instructions](#13-github-upload-instructions)
14. [15 Comprehensive Viva Questions & Model Answers](#14-15-comprehensive-viva-questions--model-answers)

---

## 1. Problem Statement

Across urban centers and rural communities, millions of tons of edible food are wasted daily due to logistical inefficiencies, lack of real-time inventory visibility, and uncoordinated donation pipelines. Simultaneously, millions of vulnerable citizens experience severe food insecurity. 

Food banks face severe operational bottlenecks:
- **Lack of Synchronized Inventory**: Manual paper or spreadsheet ledgers fail to link donations to current warehouse quantities.
- **Critical Food Spoilage**: Perishable food often expires silently on warehouse shelves because food banks lack automated expiry countdowns and early warning systems.
- **Stock Depletion & Over-distribution**: Lack of real-time stock validation causes coordinators to commit food quantities that are no longer physically available.
- **Opaque Transaction History**: Difficulty auditing inflow and outflow transactions impairs donor trust and reporting compliance.
- **Internet Dependency**: Many relief operations take place in underserved environments where cloud-reliant applications fail due to spotty connectivity.

---

## 2. Project Objectives

- **Automate Food Donation Intake**: Seamlessly register incoming food donations with donor contact details, food categories, quantities, conditions, and expiry dates.
- **Real-Time Inventory Synchronization**: Increment warehouse stock automatically when donations are received, and decrement stock when food distributions occur, utilizing atomic SQLite database transactions.
- **Zero Wastage via Expiry Management**: Categorize inventory into four actionable tiers (*Expired*, *Expiring ≤ 7 Days*, *Expiring ≤ 30 Days*, and *Fresh*), and enforce strict safety policies preventing expired food distribution.
- **Enforce Stock Validation**: Prevent distribution when requested quantities exceed available physical stock.
- **Visual Analytics & Reporting**: Generate real-time charts (`fl_chart`) illustrating monthly donation vs. distribution trends and food category proportions.
- **Offline-First Security**: Function 100% locally on Android devices without requiring internet access, Firebase, or paid third-party APIs.

---

## 3. Sustainable Development Goals (SDG) Alignment

### Primary Goal: UN SDG 2 – Zero Hunger
> *"End hunger, achieve food security and improved nutrition, and promote sustainable agriculture."*

**Direct Justification**: FoodBridge supports Target 2.1 (universal access to safe, nutritious food) by streamlining donation logistics for charities, community kitchens, and orphanages. By linking surplus food donors with frontline distribution centers, it ensures food reaches hungry families before it spoils.

### Secondary Goal: UN SDG 12 – Responsible Consumption and Production
> *"Ensure sustainable consumption and production patterns."*

**Direct Justification**: FoodBridge directly addresses **Target 12.3**—halving per capita global food waste at retail and consumer levels and reducing food losses along supply chains. Through automatic expiry tracking, visual threshold warnings, and urgency sorting, food banks are empowered to prioritize soon-to-expire goods for immediate dispatch.

---

## 4. Key Features & System Capabilities

### 📱 Screen 1: Splash Screen
- Branded launch screen with custom FoodBridge donation badge.
- Animated fade and scale transitions with official tagline: *"Rescue Food. Reduce Waste. Feed Lives."*
- Auto-initializes local SQLite tables and loads sample demo data on first launch.

### 📊 Screen 2: Executive Operations Dashboard
- **6 Key Performance Indicator (KPI) Cards**:
  1. *Total Food Items* (Active inventory catalog count)
  2. *Available Stock* (Aggregated kilograms across warehouse)
  3. *Total Donations* (All-time recorded inflow)
  4. *Distributed Food* (All-time relief aid delivered)
  5. *Expiring Soon* (Critical items needing immediate dispatch)
  6. *Low Stock Items* (Items requiring replenishment)
- **Interactive Monthly Flow Chart**: Visualizing monthly donations vs distributions over the past 6 months.
- **4 Quick Action Triggers**: Instant navigation to Add Donation, Add Inventory, Distribute Food, and Inventory Registry.
- **Live Feeds**: Displaying recent donation arrivals and distribution dispatches.

### 🤝 Screen 3: Donation Management
- Comprehensive record of incoming food donations.
- Search donations by donor name, food item, or telephone number.
- Horizontal category chips filter (*Rice and Grains, Vegetables, Fruits, Dairy, Packaged Food, Pulses, Other*).
- Date picker filter for specific donation days.
- Full details modal sheet with donor contact info, food condition badge (*Fresh, Good, Needs Attention*), and remarks.
- Edit and delete actions with confirmation dialogs.
- **Automatic Inventory Synchronization**: Inserting, updating, or deleting a donation automatically adjusts inventory stock in a single transaction.

### 📦 Screen 4: Inventory Management
- Real-time warehouse registry with category indicators, current stock, and expiry countdowns.
- Multi-criteria sorting: Name (A–Z), Quantity (High to Low / Low to High), Expiry Date (Earliest / Latest).
- Color-coded stock status chips:
  - 🟢 **Green (Sufficient)**: Quantity > 20 units
  - 🟠 **Orange (Low Stock)**: Quantity ≤ 20 units
  - 🔴 **Red (Critical / Expired)**: Quantity = 0 or item past expiry date.
- Prominent persistent alert banners for expired or low-stock items.

### 🚚 Screen 5: Food Distribution (Relief Dispatch)
- Record food distribution to community centers, government schools, orphanages, and families.
- Dropdown selector displaying only distributable items (non-expired with positive stock).
- Dynamic stock indicator displaying current available quantities.
- Strict validation preventing quantity inputs exceeding physical stock.
- Instant safety block if attempting to dispatch expired food.
- Atomic stock deduction from the inventory registry upon confirmation.

### ⏰ Screen 6: Expiry Management Center
- Dedicated 4-tab tracking center:
  1. **Expired (Critical)**: Items that have passed expiration date with a one-tap "Dispose Stock" safety purge.
  2. **Expiring in ≤ 7 Days**: Urgent priority items recommended for immediate distribution.
  3. **Expiring in 8–30 Days**: Items requiring proactive scheduling.
  4. **Fresh (> 30 Days)**: Safe, stable warehouse inventory.
- Strict food safety policy banner: *"Never distribute food past its expiration date."*

### 📈 Screen 7: Reports & Analytics
- 100% computed from real SQLite records (no mocked or hardcoded graphs).
- **Zero Hunger Relief Ratio**: Distribution efficiency metric calculated as `(Total Food Distributed / Total Food Received) * 100`.
- **Monthly Inflow vs. Outflow Bar Chart**: Real-time multi-rod comparisons with interactive tooltips.
- **Inventory Category Distribution Pie Chart**: Proportional breakdown of food categories with touch interaction.

### 📜 Screen 8: Transaction History (Unified Audit Trail)
- Chronological timeline of all inflows (Donations) and outflows (Distributions).
- Transaction IDs (formatted UUIDs), party names (donor/recipient), quantities, dates, and purpose notes.
- Filter by transaction type: *All*, *Donations (In)*, *Distributions (Out)*.
- Instant search across IDs, party names, and food items.

### ⚙️ Screen 9: Settings & System Maintenance
- Operations Coordinator profile overview.
- Theme Switcher: Seamless toggling between Forest Green Light Theme and Dark Mode (persisted in `SharedPreferences`).
- Notification preference toggles for expiry and low-stock alerts.
- **Reset to Sample Demo Data**: Restores realistic pre-configured records with confirmation dialog.
- **Clear All Database Records**: Safe wiping utility for clean slate testing.
- UN SDG 2 & SDG 12 formal declarations modal dialog.

---

## 5. System Architecture & Design Patterns

FoodBridge adheres to clean architecture principles by maintaining strict separation of concerns across presentation, business logic, and local data persistence.

```
                      ┌───────────────────────────────────────┐
                      │             UI / Screens              │
                      │  (Dashboard, Inventory, Donation...) │
                      └──────────────────┬────────────────────┘
                                         │ Watches / Reads
                                         ▼
                      ┌───────────────────────────────────────┐
                      │    State Management (Providers)      │
                      │   - DashboardProvider                 │
                      │   - InventoryProvider                 │
                      │   - DonationProvider                  │
                      │   - DistributionProvider              │
                      │   - ThemeProvider                     │
                      └──────────────────┬────────────────────┘
                                         │ Calls CRUD / Transactions
                                         ▼
                      ┌───────────────────────────────────────┐
                      │            Services Layer             │
                      │   - DatabaseService (SQLite / FFI)    │
                      │   - PreferencesService (SharedPrefs)  │
                      └──────────────────┬────────────────────┘
                                         │ Reads / Writes
                                         ▼
                      ┌───────────────────────────────────────┐
                      │       Local Data Storage Engine       │
                      │   - SQLite Database (foodbridge.db)   │
                      │   - SharedPreferences Key-Value Store │
                      └───────────────────────────────────────┘
```

---

## 6. Provider & ChangeNotifier Implementation

State management follows the recommended Flutter `Provider` and `ChangeNotifier` pattern:

1. **`ChangeNotifier`**: A class that encapsulates application state and provides change notifications via `notifyListeners()`. When internal state changes (e.g., adding an item, filtering, or calculating metrics), calling `notifyListeners()` informs all dependent widgets to rebuild.
2. **`MultiProvider`**: Configured at the root of the widget tree (`main.dart`), injecting all providers so they are accessible throughout the navigation hierarchy without prop drilling.
3. **`Consumer<T>` and `context.watch<T>()`**: Listens reactively to state updates and repaints only the widgets requiring new data.
4. **`context.read<T>()`**: Dispatches user-driven actions (such as `addDonation` or `recordDistribution`) without triggering unnecessary widget rebuilds.

### Provider Breakdown:
- **`DonationProvider`**: Manages donation records, text search, category filtering, date filtering, and coordinates database writes.
- **`InventoryProvider`**: Manages inventory items, multi-criteria sorting, threshold calculations, and categorized expiry queries (`getExpiredItems`, `getExpiringItems`, etc.).
- **`DistributionProvider`**: Manages food relief transactions and performs pre-submission stock sufficiency checks.
- **`DashboardProvider`**: Computes aggregated KPI summaries, 6-month historical monthly bar metrics, and category distributions for `fl_chart`.
- **`ThemeProvider`**: Manages light and dark theme mode, persisting choices across restarts using `PreferencesService`.

---

## 7. Database Schema & ACID Transactions

FoodBridge utilizes an embedded **SQLite** database (`foodbridge.db`) managed via `sqflite` (with automatic `sqflite_common_ffi` support on desktop platforms).

### Entity Relationship & Tables

```
 ┌─────────────────────────┐           ┌─────────────────────────┐
 │        donations        │           │        inventory        │
 ├─────────────────────────┤           ├─────────────────────────┤
 │ id (TEXT PK)            │           │ id (TEXT PK)            │
 │ donor_name (TEXT)       │           │ food_name (TEXT)        │
 │ phone_number (TEXT)     │           │ category (TEXT)         │
 │ food_item_name (TEXT)   │◀─────────▶│ available_quantity (REAL│
 │ category (TEXT)         │   Sync    │ unit (TEXT)             │
 │ quantity (REAL)         │           │ expiry_date (TEXT)      │
 │ unit (TEXT)             │           │ low_stock_threshold (R) │
 │ donation_date (TEXT)    │           │ last_updated (TEXT)     │
 │ expiry_date (TEXT)      │           └────────────┬────────────┘
 │ condition (TEXT)        │                        │ 1
 │ description (TEXT)      │                        │
 │ created_at (TEXT)       │                        │ has many
 └─────────────────────────┘                        │
                                                    ▼ *
                                       ┌─────────────────────────┐
                                       │      distributions      │
                                       ├─────────────────────────┤
                                       │ id (TEXT PK)            │
                                       │ recipient_name (TEXT)   │
                                       │ phone_number (TEXT)     │
                                       │ food_item_id (TEXT FK)  │
                                       │ food_item_name (TEXT)   │
                                       │ quantity_distributed (R)│
                                       │ unit (TEXT)             │
                                       │ distribution_date (TEXT)│
                                       │ purpose (TEXT)          │
                                       │ created_at (TEXT)       │
                                       └─────────────────────────┘
```

### ACID Transaction Integrity:
```dart
// Atomic Distribution Transaction in DatabaseService:
await db.transaction((txn) async {
  // 1. Fetch current stock
  final item = await txn.query('inventory', where: 'id = ?', whereArgs: [dist.foodItemId]);
  // 2. Validate availability and expiry
  if (item.availableQuantity < dist.quantityDistributed) throw Exception('Insufficient stock');
  if (item.isExpired) throw Exception('Cannot distribute expired food');
  // 3. Insert distribution record
  await txn.insert('distributions', dist.toMap());
  // 4. Atomically decrement stock
  await txn.update('inventory', {'available_quantity': remaining}, where: 'id = ?', whereArgs: [item.id]);
});
```

---

## 8. Folder & Package Structure

```
c:\Users\jagad\Downloads\FLUTTER PROJECT\
├── android/                             # Android native Gradle configuration
│   ├── app/
│   │   ├── src/main/
│   │   │   ├── AndroidManifest.xml      # App label, permissions, lifecycle
│   │   │   └── kotlin/com/example/foodbridge/MainActivity.kt
│   │   └── build.gradle                 # MinSdk 21, TargetSdk 34
│   └── build.gradle
├── lib/
│   ├── main.dart                        # Application entry point & MultiProvider
│   ├── app.dart                         # MaterialApp, Theme configuration & Routing
│   ├── models/                          # Immutable data entities
│   │   ├── donation_model.dart          # Inflow donor records
│   │   ├── inventory_model.dart         # Stock items, expiry & threshold getters
│   │   ├── distribution_model.dart      # Outflow relief distribution records
│   │   └── transaction_record_model.dart# Unified audit trail model
│   ├── providers/                       # State management with ChangeNotifier
│   │   ├── donation_provider.dart       # Donation state, filter & search
│   │   ├── inventory_provider.dart      # Inventory state, sort & category filter
│   │   ├── distribution_provider.dart   # Distribution state & validations
│   │   ├── dashboard_provider.dart      # Real-time metrics & chart calculations
│   │   └── theme_provider.dart          # Dark/Light theme toggle
│   ├── services/                        # Persistence & business transactions
│   │   ├── database_service.dart        # SQLite CRUD, ACID transactions, demo seed
│   │   └── preferences_service.dart     # SharedPreferences wrapper
│   ├── screens/                         # Modern Material 3 screens
│   │   ├── splash_screen.dart           # Screen 1: Branding & splash loading
│   │   ├── main_shell_screen.dart       # 5-tab persistent bottom navigation
│   │   ├── dashboard_screen.dart        # Screen 2: Real-time dashboard & quick actions
│   │   ├── donation_screen.dart         # Screen 3: Donation registry & filters
│   │   ├── add_donation_screen.dart     # Form to record or edit donations
│   │   ├── inventory_screen.dart        # Screen 4: Warehouse stock & status chips
│   │   ├── add_inventory_screen.dart    # Form to add or edit inventory items
│   │   ├── distribution_screen.dart     # Screen 5: Food aid distribution logs
│   │   ├── add_distribution_screen.dart # Form to validate & dispatch food relief
│   │   ├── expiry_screen.dart           # Screen 6: 4-tier expiry tracking center
│   │   ├── reports_screen.dart          # Screen 7: Analytics & fl_chart visualizations
│   │   ├── history_screen.dart          # Screen 8: Unified transaction audit trail
│   │   └── settings_screen.dart         # Screen 9: Settings, reset demo data & SDG info
│   ├── widgets/                         # Reusable UI components
│   │   ├── bottom_navigation.dart       # 5-tab custom navigation bar
│   │   ├── custom_app_bar.dart          # Header with expiry badges & quick shortcuts
│   │   ├── summary_card.dart            # KPI card widget with icons & accents
│   │   ├── food_item_card.dart          # Professional inventory card with badges
│   │   ├── quick_action_button.dart     # Dashboard quick trigger action button
│   │   ├── status_badge.dart            # Semantic status chip (success/warning/danger)
│   │   └── empty_state.dart             # Illustrative empty state view
│   └── utils/                           # Design tokens & helpers
│       ├── app_colors.dart              # Forest Green (#237A57) theme palette
│       ├── app_theme.dart               # Material 3 light & dark theme definitions
│       ├── app_constants.dart           # Categories, units, thresholds, SDG copy
│       └── date_formatter.dart          # Intl date formatting & countdown utilities
├── test/
│   └── widget_test.dart                 # Automated unit and widget tests
├── pubspec.yaml                         # Dependencies and build assets
└── README.md                            # Comprehensive documentation & viva prep
```

---

## 9. Prerequisites & Installation Guide

### Prerequisites
1. **Flutter SDK**: Version `>=3.0.0` ([Install Flutter](https://flutter.dev/docs/get-started/install))
2. **Android Studio** (or VS Code with Flutter Extension)
3. **Android SDK & Device/Emulator**: Android 5.0 (API level 21) or above.

### Installation Steps
1. Open terminal and navigate to the project directory:
   ```bash
   cd "C:\Users\jagad\Downloads\FLUTTER PROJECT"
   ```
2. Fetch project dependencies:
   ```bash
   flutter pub get
   ```
3. Run analyzer to ensure code hygiene:
   ```bash
   flutter analyze
   ```
4. Run automated widget tests:
   ```bash
   flutter test
   ```

---

## 10. How to Run the Application

### Running on an Android Emulator or Physical Device
1. Connect your Android device via USB (with USB Debugging enabled) or start an Android Virtual Device (AVD).
2. Check connected devices:
   ```bash
   flutter devices
   ```
3. Launch the app in debug mode:
   ```bash
   flutter run
   ```
4. To build a standalone release APK:
   ```bash
   flutter build apk --release
   ```
   The generated APK will be located at:
   `build/app/outputs/flutter-apk/app-release.apk`

---

## 11. Suggested Screenshot Captures

When preparing your practical lab report or project presentation, capture these 4 key screens:

1. **Dashboard Screen (Screen 2)**: Demonstrates the Forest Green Material 3 design, 6 real-time KPI cards (*Total Items, Stock kg, Donations, Distributed, Expiring Soon, Low Stock*), monthly flow chart, and quick actions.
2. **Donation Intake with Auto-Sync (Screen 3 & Add Form)**: Demonstrates input validation, category dropdowns, food condition indicators (*Fresh/Good*), and the confirmation message showing automatic inventory increment.
3. **Food Distribution & Validation (Screen 5 & Add Form)**: Demonstrates safety stock validation displaying current stock, blocking quantities exceeding available inventory, and the policy preventing distribution of expired goods.
4. **Expiry Management & Analytics (Screens 6 & 7)**: Highlights the 4-tier expiry urgency tabs (*Expired, ≤ 7 Days, ≤ 30 Days, Fresh*), countdown badges, and the `fl_chart` category pie chart.

---

## 12. Live Project Demonstration Script

Follow this 5-step walkthrough during your practical lab demonstration or viva examination:

- **Step 1: Application Launch & Demo Seeding**
  - Open the app. The branded splash screen appears with the tagline *"Rescue Food. Reduce Waste. Feed Lives."*
  - Point out that on the very first launch, the local SQLite database automatically seeds realistic inventory items (Rice, Wheat Flour, Toor Dal, Oil, Milk, Biscuits, Vegetables).

- **Step 2: Dashboard Overview & KPI Reactivity**
  - Point out the 6 summary cards and explain how each number is calculated reactively via `DashboardProvider`.
  - Highlight the monthly donation vs distribution chart powered by `fl_chart`.

- **Step 3: Recording a Donation & Verifying Automatic Inventory Synchronization**
  - Tap **"Add Donation"**. Fill out the form: Donor: *"City Bakery"*, Item: *"Wheat Flour"*, Category: *"Rice and Grains"*, Quantity: *"50 kg"*, Condition: *"Fresh"*.
  - Tap **Save**. Point out the SnackBar confirming stock synchronization.
  - Navigate to the **Inventory** tab: point out that Wheat Flour has automatically increased from 80 kg to **130 kg**!

- **Step 4: Safe Food Distribution & Stock Validation**
  - Navigate to the **Distribution** tab. Tap **"New Distribution"**.
  - Choose *"Wheat Flour"*. Point out the dynamic banner showing available stock.
  - Enter a quantity higher than available (e.g. 200 kg) and show the instant inline validation: *"Exceeds stock"*.
  - Correct the quantity to *"30 kg"* to *"St. Jude Shelter"*. Tap **Confirm**.
  - Return to Inventory: Wheat Flour has automatically reduced to **100 kg**, and the transaction is logged in **Transaction History**.

- **Step 5: Expiry Tracking & UN SDG Justification**
  - Open **Expiry Management** from the top notification bell. Show the *Expired* tab (containing sample expired bread) and the *Expiring ≤ 7 Days* tab (milk and vegetables).
  - Open **Settings**, toggle **Dark Mode** to demonstrate seamless theming, and tap **"About FoodBridge & SDG Justification"** to explain the direct contribution to **UN SDG 2 (Zero Hunger)** and **SDG 12.3 (Food Waste Reduction)**.

---

## 13. GitHub Upload Instructions

To upload this completed project to your GitHub repository:

```bash
# 1. Initialize git repository (if not already initialized)
git init

# 2. Add all project files
git add .

# 3. Commit the project
git commit -m "feat: complete FoodBridge Food Bank Inventory and Donation Tracker application"

# 4. Set branch to main
git branch -M main

# 5. Link your GitHub remote repository (replace with your repo URL)
git remote add origin https://github.com/YOUR_USERNAME/foodbridge.git

# 6. Push code to GitHub
git push -u origin main
```

---

## 14. 15 Comprehensive Viva Questions & Model Answers

### Q1: What is the primary architecture of FoodBridge and why was it chosen?
**Answer**: FoodBridge follows a clean, three-layer decoupled architecture separating UI Presentation, State Management (Business Logic), and Services/Database Persistence. This architecture promotes the Single Responsibility Principle, enables thorough unit testing, prevents code clutter in `main.dart`, and allows UI components to rebuild reactively without coupled dependencies.

### Q2: How do Provider and ChangeNotifier work together in Flutter?
**Answer**: `ChangeNotifier` is an observable class in Flutter that maintains application state and broadcasts updates via `notifyListeners()`. `Provider` is a dependency injection and state-listening wrapper that provides instances of `ChangeNotifier` to widgets via the `BuildContext`. When state changes and `notifyListeners()` is called, all widgets wrapped in `Consumer` or using `context.watch()` automatically re-render with the latest data.

### Q3: Why is MultiProvider placed at the root of the application?
**Answer**: Placing `MultiProvider` at the root above `MaterialApp` ensures all providers (`DonationProvider`, `InventoryProvider`, `DistributionProvider`, `DashboardProvider`, `ThemeProvider`) are available across all routes and screens. It eliminates prop drilling and ensures that navigating between tabs or modal sheets maintains continuous access to shared reactive state.

### Q4: How is inventory automatically updated when a donation is recorded?
**Answer**: Inside `DatabaseService.recordDonationWithInventorySync()`, an atomic SQLite transaction performs two operations: it inserts the donation into the `donations` table, and queries the `inventory` table for an existing item with matching name, category, and unit. If found, it increments `available_quantity` and adjusts the expiry date; if not found, it creates a new inventory record. Once the transaction completes, `InventoryProvider.loadInventory()` and `DashboardProvider.refreshDashboard()` are called to update all screens.

### Q5: What is an ACID transaction and why is it essential in food distribution?
**Answer**: ACID stands for Atomicity, Consistency, Isolation, and Durability. In food distribution, deducting stock and inserting a distribution record must happen as a single atomic unit. If stock deduction fails, the distribution record must not be saved; if the system crashes midway, changes are rolled back. This prevents phantom stock and inventory discrepancy.

### Q6: How does FoodBridge prevent the distribution of expired food?
**Answer**: FoodBridge implements a two-tier safety validation. First, the distribution screen's food dropdown queries `InventoryProvider.getDistributableItems()`, which filters out any item where `isExpired` is true. Second, at the database service level inside `recordDistributionTransaction()`, an explicit validation checks `if (item.isExpired) throw Exception(...)`, ensuring safety even if bypassed in the UI.

### Q7: What validation prevents over-distribution of stock?
**Answer**: In `AddDistributionScreen`, the quantity form field validates that `quantity <= _selectedItem.availableQuantity`. Furthermore, the transaction in `DatabaseService` checks `availableQuantity < distribution.quantityDistributed` and throws an error if stock is insufficient, preventing negative inventory.

### Q8: How does the application support offline operation?
**Answer**: FoodBridge uses an embedded SQLite database (`sqflite`) for all operational records and `SharedPreferences` for user preferences. All queries, transactions, calculations, and chart analytics execute locally on the device with zero cloud or API dependency.

### Q9: How are the charts in the Analytics screen generated?
**Answer**: The charts are generated using the `fl_chart` library. Rather than using mocked data, `DashboardProvider` iterates over the actual `donations`, `distributions`, and `inventory` SQLite tables. It aggregates monthly totals for the past 6 months to feed `BarChartData` and groups warehouse stock by category to feed `PieChartData`.

### Q10: How does dark mode persistence work in FoodBridge?
**Answer**: The user's theme selection is managed by `ThemeProvider`, which reads and writes a boolean flag (`is_dark_mode`) to disk via `SharedPreferences`. When the toggle is tapped in Settings, `PreferencesService` saves the boolean and `ThemeProvider` calls `notifyListeners()`, causing `MaterialApp` to switch between `AppTheme.lightTheme` and `AppTheme.darkTheme` instantly and persist across app reboots.

### Q11: Explain the difference between `context.read()`, `context.watch()`, and `Consumer`.
**Answer**: 
- `context.watch<T>()`: Subscribes the enclosing widget to changes in `T`; whenever `notifyListeners()` is called, the widget rebuilds.
- `context.read<T>()`: Retrieves `T` once without listening; used in callbacks (like button `onPressed`) to invoke methods without causing rebuilds.
- `Consumer<T>`: A widget that wraps only the specific portion of the widget tree that needs to rebuild, optimizing performance by avoiding full-screen repaints.

### Q12: How are expiry countdown days calculated?
**Answer**: In `InventoryModel.daysUntilExpiry`, the current calendar date (with time normalized to midnight) is compared to the item's `expiryDate`: `expiry.difference(today).inDays`. A negative number indicates an expired item, 0–7 indicates expiring soon, 8–30 indicates expiring within the month, and >30 indicates fresh stock.

### Q13: How does FoodBridge align with UN Sustainable Development Goal 2 (Zero Hunger)?
**Answer**: FoodBridge supports UN SDG 2 (Zero Hunger) by improving donation logistics, preventing food spoilage through multi-tier expiry tracking, and connecting donors with orphanages and community kitchens. It also supports SDG 12.3 by reducing retail and consumer food waste.

### Q14: What is the purpose of `sqflite_common_ffi` in the project?
**Answer**: `sqflite` runs natively on Android and iOS using platform channels. `sqflite_common_ffi` allows the same SQLite database code to run seamlessly on desktop platforms (Windows, Linux, macOS) during development, automated testing, or desktop debugging by utilizing SQLite's C-library FFI bindings.

### Q15: How can a coordinator reset demo data for demonstration purposes?
**Answer**: In the Settings screen, the coordinator can tap "Reset to Sample Demo Data". This invokes `DatabaseService.instance.resetToDemoData()`, which clears existing SQLite tables and re-seeds realistic inventory, donation, and distribution records, followed by a full state refresh across all active providers.

