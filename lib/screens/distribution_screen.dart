import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/distribution_model.dart';
import '../providers/distribution_provider.dart';
import '../utils/app_colors.dart';
import '../utils/date_formatter.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/empty_state.dart';
import 'add_distribution_screen.dart';

/// Screen 5: Food Distribution
/// Displays the record of all food aid distributions with search and details.
class DistributionScreen extends StatefulWidget {
  const DistributionScreen({super.key});

  @override
  State<DistributionScreen> createState() => _DistributionScreenState();
}

class _DistributionScreenState extends State<DistributionScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showDistributionDetails(BuildContext context, DistributionModel dist) {
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
                    dist.recipientName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 14, color: Color(0xFF7C3AED)),
                      SizedBox(width: 4),
                      Text(
                        'Distributed',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            _buildDetailRow(Icons.fastfood_outlined, 'Food Item', dist.foodItemName),
            _buildDetailRow(Icons.scale_outlined, 'Quantity Delivered',
                '${DateFormatter.formatQuantity(dist.quantityDistributed)} ${dist.unit}'),
            _buildDetailRow(Icons.phone_outlined, 'Contact Phone',
                dist.phoneNumber.isNotEmpty ? dist.phoneNumber : 'Not provided'),
            _buildDetailRow(Icons.event_outlined, 'Distribution Date',
                DateFormatter.format(dist.distributionDate)),
            _buildDetailRow(Icons.flag_outlined, 'Purpose / Beneficiaries',
                dist.purpose.isNotEmpty ? dist.purpose : 'Relief food distribution'),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
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
          Icon(icon, size: 18, color: const Color(0xFF7C3AED)),
          const SizedBox(width: 12),
          SizedBox(
            width: 130,
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
        title: 'Food Distribution',
        subtitle: 'Relief Outflow & Beneficiaries',
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.outbox_rounded),
        label: const Text('New Distribution'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddDistributionScreen()),
          );
        },
      ),
      body: Consumer<DistributionProvider>(
        builder: (context, provider, child) {
          final distributions = provider.filteredDistributions;

          return Column(
            children: [
              // Search Input
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => provider.setSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: 'Search recipient, food item or purpose...',
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),

              // Distribution Records List
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : distributions.isEmpty
                        ? EmptyState(
                            icon: Icons.local_shipping_outlined,
                            title: 'No Distributions Recorded',
                            message: provider.searchQuery.isNotEmpty
                                ? 'No distribution records match your search criteria.'
                                : 'No food distributions recorded yet. Dispatch relief food to beneficiaries.',
                            buttonText: 'Distribute Food',
                            onButtonPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AddDistributionScreen()),
                              );
                            },
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                            itemCount: distributions.length,
                            itemBuilder: (context, index) {
                              final item = distributions[index];
                              return _buildDistributionCard(context, item, isDark);
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDistributionCard(BuildContext context, DistributionModel item, bool isDark) {
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
          onTap: () => _showDistributionDetails(context, item),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top: Recipient & Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.domain, size: 16, color: Color(0xFF7C3AED)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.recipientName,
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
                    Text(
                      DateFormatter.format(item.distributionDate),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Middle: Food item & quantity distributed
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.foodItemName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '-${DateFormatter.formatQuantity(item.quantityDistributed)} ${item.unit}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Bottom: Purpose summary
                if (item.purpose.isNotEmpty)
                  Text(
                    'Purpose: ${item.purpose}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

