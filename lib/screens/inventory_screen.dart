import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/inventory_model.dart';
import '../providers/inventory_provider.dart';
import '../providers/dashboard_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/food_item_card.dart';
import 'add_inventory_screen.dart';
import 'expiry_screen.dart';

/// Screen 4: Inventory Management
/// Real-time inventory list with search, category filtering, multi-criteria sorting,
/// low-stock & expiry alert banners, and CRUD operations.
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showDeleteConfirmation(BuildContext context, InventoryModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Inventory Item?'),
        content: Text(
          'Are you sure you want to delete "${item.foodName}" (${item.category})?\n\n'
          'This will permanently remove the item from available stock tracking.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<InventoryProvider>().deleteFoodItem(item.id);
              if (mounted) {
                await context.read<DashboardProvider>().refreshDashboard();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"${item.foodName}" deleted from inventory.'),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSortSheet(BuildContext context, InventoryProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2822) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sort Inventory By',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            _buildSortOption(ctx, provider, 'Name (A to Z)', 'name_asc'),
            _buildSortOption(ctx, provider, 'Quantity (High to Low)', 'qty_desc'),
            _buildSortOption(ctx, provider, 'Quantity (Low to High)', 'qty_asc'),
            _buildSortOption(ctx, provider, 'Expiry Date (Earliest First)', 'exp_asc'),
            _buildSortOption(ctx, provider, 'Expiry Date (Latest First)', 'exp_desc'),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(
    BuildContext ctx,
    InventoryProvider provider,
    String label,
    String sortKey,
  ) {
    final isSelected = provider.sortBy == sortKey;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppColors.primary : null,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
      onTap: () {
        provider.setSortBy(sortKey);
        Navigator.pop(ctx);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Inventory Stock',
        subtitle: 'Food Bank Warehousing',
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Food Item'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddInventoryScreen()),
          );
        },
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, child) {
          final items = provider.filteredItems;
          final lowStockCount = provider.getLowStockItems().length;
          final expiredCount = provider.getExpiredItems().length;

          return Column(
            children: [
              // Search & Sort Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (val) => provider.setSearchQuery(val),
                        decoration: InputDecoration(
                          hintText: 'Search food item or category...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    provider.setSearchQuery('');
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.swap_vert_rounded),
                      tooltip: 'Sort Items',
                      onPressed: () => _showSortSheet(context, provider),
                    ),
                  ],
                ),
              ),

              // Category Filter Chips
              SizedBox(
                height: 46,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  children: [
                    _buildCategoryChip('All', provider.selectedCategory == null || provider.selectedCategory == 'All', () {
                      provider.setCategoryFilter('All');
                    }),
                    ...AppConstants.foodCategories.map((cat) {
                      final isSelected = provider.selectedCategory == cat;
                      return _buildCategoryChip(cat, isSelected, () {
                        provider.setCategoryFilter(isSelected ? null : cat);
                      });
                    }),
                  ],
                ),
              ),

              // Warning Banners (Low Stock / Expired)
              if (expiredCount > 0 || lowStockCount > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                  child: Row(
                    children: [
                      if (expiredCount > 0)
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ExpiryScreen(initialTab: 0)),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.danger),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '$expiredCount Expired Item${expiredCount > 1 ? 's' : ''}',
                                      style: const TextStyle(
                                        color: AppColors.danger,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (expiredCount > 0 && lowStockCount > 0)
                        const SizedBox(width: 8),
                      if (lowStockCount > 0)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.priority_high_rounded, size: 16, color: AppColors.warning),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '$lowStockCount Low Stock Item${lowStockCount > 1 ? 's' : ''}',
                                    style: const TextStyle(
                                      color: AppColors.warning,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

              // Inventory Items List
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : items.isEmpty
                        ? EmptyState(
                            icon: Icons.inventory_2_outlined,
                            title: 'No Items Found',
                            message: provider.searchQuery.isNotEmpty || provider.selectedCategory != null
                                ? 'No inventory items match your current filters.'
                                : 'No food items in the inventory. Add an item or record donations.',
                            buttonText: 'Add Food Item',
                            onButtonPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AddInventoryScreen()),
                              );
                            },
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return FoodItemCard(
                                item: item,
                                onEdit: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddInventoryScreen(existingItem: item),
                                    ),
                                  );
                                },
                                onDelete: () => _showDeleteConfirmation(context, item),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.secondary,
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppColors.primary : null,
        ),
      ),
    );
  }
}

