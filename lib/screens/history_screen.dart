import 'package:flutter/material.dart';
import '../models/transaction_record_model.dart';
import '../services/database_service.dart';
import '../utils/app_colors.dart';
import '../utils/date_formatter.dart';
import '../widgets/empty_state.dart';

/// Screen 8: Transaction History
/// Displays unified audit trails of all inflows (donations) and outflows (distributions).
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseService _dbService = DatabaseService.instance;
  final TextEditingController _searchCtrl = TextEditingController();

  List<TransactionRecordModel> _allTransactions = [];
  bool _isLoading = true;
  String _selectedFilter = 'All'; // 'All', 'Donations', 'Distributions'

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchTransactions() async {
    setState(() => _isLoading = true);
    try {
      final records = await _dbService.getAllTransactions();
      if (mounted) {
        setState(() {
          _allTransactions = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<TransactionRecordModel> get _filteredTransactions {
    final query = _searchCtrl.text.trim().toLowerCase();

    return _allTransactions.where((txn) {
      final matchesFilter = _selectedFilter == 'All' ||
          (_selectedFilter == 'Donations' && txn.isDonation) ||
          (_selectedFilter == 'Distributions' && txn.isDistribution);

      final matchesQuery = query.isEmpty ||
          txn.id.toLowerCase().contains(query) ||
          txn.foodItem.toLowerCase().contains(query) ||
          txn.partyName.toLowerCase().contains(query) ||
          txn.phoneNumber.contains(query);

      return matchesFilter && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final transactions = _filteredTransactions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Records',
            onPressed: _fetchTransactions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search transaction ID, food, or party...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Type Segmented Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildSegmentChip('All Transactions', 'All'),
                const SizedBox(width: 8),
                _buildSegmentChip('Donations (In)', 'Donations'),
                const SizedBox(width: 8),
                _buildSegmentChip('Distributions (Out)', 'Distributions'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Transactions List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : transactions.isEmpty
                    ? EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'No Transactions Found',
                        message: _searchCtrl.text.isNotEmpty
                            ? 'No transactions matched your search query.'
                            : 'No history records logged yet.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final txn = transactions[index];
                          return _buildTransactionCard(txn, isDark);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = value),
      selectedColor: AppColors.secondary,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? AppColors.primary : null,
      ),
    );
  }

  Widget _buildTransactionCard(TransactionRecordModel txn, bool isDark) {
    final isDonation = txn.isDonation;
    final color = isDonation ? AppColors.primary : const Color(0xFF7C3AED);
    final sign = isDonation ? '+' : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2822) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2E3D35) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Transaction ID & Type
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDonation ? Icons.arrow_downward : Icons.arrow_upward,
                      size: 13,
                      color: color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      txn.typeLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'ID: ${txn.id.substring(0, 8).toUpperCase()}',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[400] : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Main: Food Item & Net Quantity Change
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                txn.foodItem,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              Text(
                '$sign${DateFormatter.formatQuantity(txn.quantity)} ${txn.unit}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Party Name & Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${isDonation ? "Donor" : "Recipient"}: ${txn.partyName}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[300] : const Color(0xFF475569),
                ),
              ),
              Text(
                DateFormatter.format(txn.date),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),

          if (txn.details.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              txn.details,
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

