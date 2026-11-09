# FoodBridge – Project Presentation & Practical Lab Defense Guide

Use this guide for your B.Tech final practical evaluation, laboratory project demonstration, and viva voce.

---

## 1. Project Title & Student Introduction

- **Project Title**: FoodBridge – Food Bank Inventory and Donation Tracker
- **Domain**: Mobile Application Development (Flutter, Dart, SQLite, Reactive State Management)
- **Tagline**: *"Rescue Food. Reduce Waste. Feed Lives."*
- **Primary SDG Target**: UN Sustainable Development Goal 2 – Zero Hunger
- **Secondary SDG Target**: UN Sustainable Development Goal 12 – Responsible Consumption and Production (Target 12.3: Food Loss & Waste Reduction)

---

## 2. 10-Slide Presentation Deck Structure

### Slide 1: Title & Team Credentials
- **App Name**: FoodBridge
- **Subtitle**: Automated Community Food Bank Warehousing & Donation Inflow/Outflow Management
- **Target Users**: Non-Governmental Organizations (NGOs), Community Kitchens, Food Rescue Trusts, Orphanages, and Humanitarian Relief Bodies.

### Slide 2: Real-World Motivation & Problem Statement
- **Food Paradox**: Millions of tons of food are thrown away daily from grocery supermarkets, catered events, and agricultural hubs, while millions suffer malnutrition and food insecurity.
- **NGO Pain Points**:
  - Manual ledgers cause stock inaccuracies and duplicate records.
  - Perishable food spoils in warehouses due to lack of early warning expiry tracking.
  - Relief coordinators over-commit food quantities without knowing real-time inventory counts.
  - Cloud-reliant mobile apps fail in rural and field disaster zones due to lack of reliable internet.

### Slide 3: Proposed Solution
- An **offline-first**, mobile-native solution with:
  1. Automated donation logging with dynamic inventory synchronization.
  2. Multi-tier expiry management (Expired, ≤ 7 Days, ≤ 30 Days, Fresh).
  3. Pre-distribution stock sufficiency verification and hard expired-food blocks.
  4. Visual performance analytics (`fl_chart`) calculating Zero Hunger relief efficiency ratios.
  5. Completely local persistence with zero third-party cloud subscription fees.

### Slide 4: Technology Stack
| Layer | Technology | Purpose |
| :--- | :--- | :--- |
| **Framework** | Flutter 3.x | Cross-platform UI toolkit |
| **Language** | Dart 3.x | Object-oriented sound null-safety language |
| **State Management**| Provider + ChangeNotifier | Decoupled reactive state management |
| **Database** | SQLite via `sqflite` | Local embedded ACID database |
| **Preferences** | `shared_preferences` | Theme toggles & alert configurations |
| **Visualization** | `fl_chart` | Interactive charts grounded on SQLite queries |
| **Formatting** | `intl` | Date, countdown, and decimal quantity formatting |
| **Design Standard**| Material 3 | Forest Green palette (`#237A57`), modern card geometry |

### Slide 5: System Architecture
```
┌────────────────────────────────────────────────────────┐
│                      UI Layer                          │
│   Dashboard | Donations | Inventory | Distribution     │
│       Expiry Management | Reports | Settings           │
└───────────────────────────┬────────────────────────────┘
                            │ Watch / Read
                            ▼
┌────────────────────────────────────────────────────────┐
│                   Provider Layer                       │
│  DashboardProvider | InventoryProvider | ThemeProvider │
│      DonationProvider | DistributionProvider           │
└───────────────────────────┬────────────────────────────┘
                            │ Calls Service Methods
                            ▼
┌────────────────────────────────────────────────────────┐
│                   Services Layer                       │
│    DatabaseService (SQLite) | PreferencesService       │
└───────────────────────────┬────────────────────────────┘
                            │ Read / Write
                            ▼
┌────────────────────────────────────────────────────────┐
│                 Local Storage Engine                   │
│   SQLite Database (foodbridge.db) | SharedPreferences  │
└────────────────────────────────────────────────────────┘
```

### Slide 6: Database Schema & Entity Relationships
- **`donations` Table**: `id (PK)`, `donor_name`, `phone_number`, `food_item_name`, `category`, `quantity`, `unit`, `donation_date`, `expiry_date`, `condition`, `description`.
- **`inventory` Table**: `id (PK)`, `food_name`, `category`, `available_quantity`, `unit`, `expiry_date`, `low_stock_threshold`, `last_updated`.
- **`distributions` Table**: `id (PK)`, `recipient_name`, `phone_number`, `food_item_id (FK)`, `food_item_name`, `quantity_distributed`, `unit`, `distribution_date`, `purpose`.

### Slide 7: ACID Transaction Integrity
- **Why Transactions Matter**: When a donation is logged or food is distributed, multiple database tables must be updated simultaneously.
- **Donation Transaction**: Inserts into `donations` and atomically searches `inventory`. If the item exists, it increments quantity and retains the earliest expiry date; if not, it inserts a new inventory record.
- **Distribution Transaction**: Verifies that stock is sufficient and food is not expired, inserts into `distributions`, and decrements `inventory` in an indivisible execution block.

### Slide 8: Multi-Tier Expiry Management
- Food safety is enforced at the design level:
  - 🔴 **Expired Tier**: Immediate red alert; blocked from distribution selector; includes a 1-tap "Dispose Stock" action.
  - 🟠 **Expiring ≤ 7 Days**: Urgent priority; automatically flagged for priority dispatch.
  - 🟡 **Expiring ≤ 30 Days**: Moderate attention; flagged for weekly planning.
  - 🟢 **Fresh (> 30 Days)**: Safe shelf inventory.

### Slide 9: Reports, Analytics & Zero Hunger Impact
- **Zero Hunger Relief Ratio**:
  $$\text{Redistribution Efficiency} = \left(\frac{\text{Total Food Distributed}}{\text{Total Food Received}}\right) \times 100$$
- Visual charts generated from SQLite queries:
  - Monthly inflow vs. outflow multi-bar comparisons.
  - Warehouse inventory breakdown by category (Grains, Vegetables, Dairy, Pulses, Packaged Food).

### Slide 10: Conclusion & Future Scope
- **Conclusion**: FoodBridge replaces error-prone paperwork with an automated, reliable system that saves food, prevents health risks, and speeds up aid delivery.
- **Future Enhancements**:
  - Camera-based barcode and QR code scanner for fast warehouse intake.
  - Integration with volunteer dispatch routes and map geofencing.
  - Multi-node peer-to-peer Wi-Fi Direct sync between mobile devices in disaster zones without cellular internet.

---

## 3. Practical Viva Defense Checklist

During your evaluation, the examiner will likely test:
1. **Adding a Donation**: Enter an item (e.g. 50 kg Rice). Check that warehouse stock increments immediately without closing the app.
2. **Stock Insufficiency Check**: Attempt to distribute 100 kg of an item when only 50 kg is available. Show the validation error.
3. **Expired Food Check**: Go to the distribution form and show that expired items are filtered out or blocked.
4. **Theme Toggling**: Switch to Dark Mode in Settings and explain how `SharedPreferences` persists the choice across restarts.
5. **Resetting Demo Data**: Go to Settings, tap **Reset to Sample Demo Data**, and show the preloaded inventory restoring automatically.

