import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/inventory_model.dart';
import '../models/distribution_model.dart';
import '../providers/inventory_provider.dart';
import '../providers/distribution_provider.dart';
import '../providers/dashboard_provider.dart';
import '../utils/app_colors.dart';
import '../utils/date_formatter.dart';

/// Screen for Recording Food Aid Distribution to Beneficiary Organizations or Families.
class AddDistributionScreen extends StatefulWidget {
  const AddDistributionScreen({super.key});

  @override
  State<AddDistributionScreen> createState() => _AddDistributionScreenState();
}

class _AddDistributionScreenState extends State<AddDistributionScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _recipientCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _quantityCtrl = TextEditingController();
  final TextEditingController _purposeCtrl = TextEditingController();

  InventoryModel? _selectedItem;
  DateTime _distributionDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _recipientCtrl.dispose();
    _phoneCtrl.dispose();
    _quantityCtrl.dispose();
    _purposeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _distributionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _distributionDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an eligible food item from available stock.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final quantity = double.parse(_quantityCtrl.text.trim());

    // Final safety validation
    if (_selectedItem!.isExpired) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Safety alert: "${_selectedItem!.foodName}" has expired and cannot be distributed!'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (quantity > _selectedItem!.availableQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Insufficient stock! Maximum available: ${_selectedItem!.availableQuantity} ${_selectedItem!.unit}',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final newDistribution = DistributionModel(
        id: const Uuid().v4(),
        recipientName: _recipientCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim(),
        foodItemId: _selectedItem!.id,
        foodItemName: _selectedItem!.foodName,
        quantityDistributed: quantity,
        unit: _selectedItem!.unit,
        distributionDate: _distributionDate,
        purpose: _purposeCtrl.text.trim(),
      );

      final distProvider = context.read<DistributionProvider>();
      final invProvider = context.read<InventoryProvider>();
      final dashProvider = context.read<DashboardProvider>();

      await distProvider.addDistribution(newDistribution);
      await invProvider.loadInventory();
      await dashProvider.refreshDashboard();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Distribution recorded! ${DateFormatter.formatQuantity(quantity)} ${_selectedItem!.unit} '
              'of ${_selectedItem!.foodName} deducted from inventory.',
            ),
            backgroundColor: const Color(0xFF7C3AED),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final invProvider = context.watch<InventoryProvider>();
    // Filter only eligible items (not expired and quantity > 0)
    final distributableItems = invProvider.getDistributableItems();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Food Distribution'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Safety Warning Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: Color(0xFF7C3AED), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Food Safety Policy: Expired inventory items are strictly blocked from distribution.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5B21B6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Section 1: Beneficiary Details
              const Text(
                'Recipient / Beneficiary Organization',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _recipientCtrl,
                decoration: const InputDecoration(
                  labelText: 'Recipient / Organization Name *',
                  hintText: 'e.g. Community Welfare Center, Sneha Orphanage',
                  prefixIcon: Icon(Icons.domain_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Recipient name cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Contact Phone Number *',
                  hintText: 'e.g. +91 94401 22334',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Phone number cannot be empty';
                  }
                  if (val.trim().length < 7) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Section 2: Food Selection & Stock Deduction
              const Text(
                'Food Item & Quantity',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),

              if (distributableItems.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'No food items currently available for distribution. '
                    'All items are either out of stock or expired.',
                    style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600),
                  ),
                )
              else
                DropdownButtonFormField<InventoryModel>(
                  value: _selectedItem,
                  decoration: const InputDecoration(
                    labelText: 'Select Food Item from Stock *',
                    prefixIcon: Icon(Icons.fastfood_outlined),
                  ),
                  items: distributableItems.map((item) {
                    return DropdownMenuItem(
                      value: item,
                      child: Text(
                        '${item.foodName} (${DateFormatter.formatQuantity(item.availableQuantity)} ${item.unit} available)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (item) {
                    setState(() {
                      _selectedItem = item;
                      _quantityCtrl.clear();
                    });
                  },
                  validator: (val) => val == null ? 'Please select a food item' : null,
                ),
              const SizedBox(height: 14),

              // Live Stock Info Banner
              if (_selectedItem != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Available Stock: ${DateFormatter.formatQuantity(_selectedItem!.availableQuantity)} ${_selectedItem!.unit}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Exp: ${DateFormatter.format(_selectedItem!.expiryDate)}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),

              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _quantityCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Quantity to Distribute *',
                        hintText: 'e.g. 25',
                        prefixIcon: const Icon(Icons.scale_outlined),
                        suffixText: _selectedItem?.unit ?? '',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Enter quantity';
                        }
                        final num = double.tryParse(val.trim());
                        if (num == null || num <= 0) {
                          return 'Quantity must be > 0';
                        }
                        if (_selectedItem != null && num > _selectedItem!.availableQuantity) {
                          return 'Exceeds stock (${_selectedItem!.availableQuantity} ${_selectedItem!.unit})';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Distribution Date *',
                    prefixIcon: Icon(Icons.event_outlined),
                  ),
                  child: Text(
                    DateFormatter.format(_distributionDate),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _purposeCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Purpose / Relief Program *',
                  hintText: 'e.g. Mid-day meals, Disaster relief, Orphanage weekend meal support',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please provide distribution purpose or beneficiary details';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
                  onPressed: _isSaving || distributableItems.isEmpty ? null : _submit,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(_isSaving ? 'Recording Distribution...' : 'Confirm Distribution & Deduct Stock'),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

