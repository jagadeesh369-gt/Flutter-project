import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/donation_model.dart';
import '../providers/donation_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/dashboard_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/date_formatter.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_badge.dart';
import 'add_donation_screen.dart';

/// Screen 3: Donation Management
/// Displays donation records with search, category filtering, date filtering,
/// details viewer dialog, and edit/delete actions.
class DonationScreen extends StatefulWidget {
  const DonationScreen({super.key});

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showDeleteConfirmation(BuildContext context, DonationModel donation) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Donation Record?'),
        content: Text(
          'Are you sure you want to delete the donation from "${donation.donorName}" '
          'for ${DateFormatter.formatQuantity(donation.quantity)} ${donation.unit} of ${donation.foodItemName}?\n\n'
          'Note: Associated inventory quantity will be deducted accordingly.',
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
              await context.read<DonationProvider>().deleteDonation(donation);
              if (mounted) {
                await context.read<InventoryProvider>().loadInventory();
                await context.read<DashboardProvider>().refreshDashboard();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Donation deleted and inventory updated successfully.'),
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

  void _showDonationDetails(BuildContext context, DonationModel donation) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2822) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    donation.foodItemName,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ),
                StatusBadge(
                  label: donation.condition,
                  type: donation.condition == 'Fresh'
                      ? BadgeType.success
                      : donation.condition == 'Good'
                          ? BadgeType.info
                          : BadgeType.warning,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              donation.category,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            _buildDetailRow(Icons.person_outline, 'Donor Name', donation.donorName),
            _buildDetailRow(Icons.phone_outlined, 'Phone Number',
                donation.phoneNumber.isNotEmpty ? donation.phoneNumber : 'Not provided'),
            _buildDetailRow(Icons.scale_outlined, 'Quantity Donated',
                '${DateFormatter.formatQuantity(donation.quantity)} ${donation.unit}'),
            _buildDetailRow(Icons.event_available_outlined, 'Donation Date',
                DateFormatter.format(donation.donationDate)),
            _buildDetailRow(Icons.event_busy_outlined, 'Expiry Date',
                DateFormatter.format(donation.expiryDate)),
            _buildDetailRow(Icons.notes_outlined, 'Notes / Description',
                donation.description.isNotEmpty ? donation.description : 'No notes recorded'),

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddDonationScreen(existingDonation: donation),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit Donation'),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Close'),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Donation Management',
        subtitle: 'Food Inflow & Donor Records',
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Donation'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddDonationScreen()),
          );
        },
      ),
      body: Consumer<DonationProvider>(
        builder: (context, provider, child) {
          final donations = provider.filteredDonations;

          return Column(
            children: [
              // Search & Filter Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (val) => provider.setSearchQuery(val),
                        decoration: InputDecoration(
                          hintText: 'Search donor, food or phone...',
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
                    // Date Filter Icon
                    IconButton(
                      icon: Icon(
                        Icons.calendar_month_outlined,
                        color: provider.filterDate != null ? AppColors.primary : null,
                      ),
                      tooltip: 'Filter by Date',
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: provider.filterDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          provider.setDateFilter(picked);
                        }
                      },
                    ),
                    if (provider.filterDate != null ||
                        provider.selectedCategory != null ||
                        provider.searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.filter_alt_off_outlined, color: AppColors.danger),
                        tooltip: 'Clear Filters',
                        onPressed: () {
                          _searchCtrl.clear();
                          provider.clearFilters();
                        },
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
                    _buildFilterChip('All', provider.selectedCategory == null || provider.selectedCategory == 'All', () {
                      provider.setCategoryFilter('All');
                    }),
                    ...AppConstants.foodCategories.map((cat) {
                      final isSelected = provider.selectedCategory == cat;
                      return _buildFilterChip(cat, isSelected, () {
                        provider.setCategoryFilter(isSelected ? null : cat);
                      });
                    }),
                  ],
                ),
              ),

              if (provider.filterDate != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        'Filtered Date: ${DateFormatter.format(provider.filterDate)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => provider.setDateFilter(null),
                        child: const Icon(Icons.close, size: 16, color: AppColors.danger),
                      ),
                    ],
                  ),
                ),

              // Donation Cards List
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : donations.isEmpty
                        ? EmptyState(
                            icon: Icons.volunteer_activism_outlined,
                            title: 'No Donations Found',
                            message: provider.searchQuery.isNotEmpty || provider.selectedCategory != null
                                ? 'No donation records match the selected filters.'
                                : 'No food donations have been registered yet.',
                            buttonText: 'Add First Donation',
                            onButtonPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AddDonationScreen()),
                              );
                            },
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                            itemCount: donations.length,
                            itemBuilder: (context, index) {
                              final item = donations[index];
                              return _buildDonationCard(context, item, isDark);
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
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

  Widget _buildDonationCard(BuildContext context, DonationModel item, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2822) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2E3D35) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDonationDetails(context, item),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top: Donor Name & Condition Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.person, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.donorName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(
                      label: item.condition,
                      type: item.condition == 'Fresh'
                          ? BadgeType.success
                          : item.condition == 'Good'
                              ? BadgeType.info
                              : BadgeType.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Middle: Food Item & Quantity
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.foodItemName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.category,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '+${DateFormatter.formatQuantity(item.quantity)} ${item.unit}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark ? const Color(0xFF2E3D35) : const Color(0xFFF1F5F9),
                ),
                const SizedBox(height: 10),

                // Bottom: Dates & Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.event_outlined, size: 14, color: isDark ? Colors.grey[400] : const Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(
                          'Donated: ${DateFormatter.format(item.donationDate)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: 'Edit Donation',
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddDonationScreen(existingDonation: item),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          tooltip: 'Delete Donation',
                          color: AppColors.danger,
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _showDeleteConfirmation(context, item),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

