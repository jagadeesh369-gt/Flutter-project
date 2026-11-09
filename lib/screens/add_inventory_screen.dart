import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/inventory_model.dart';
import '../providers/inventory_provider.dart';
import '../providers/dashboard_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/date_formatter.dart';

/// Screen for Adding or Editing an Item directly in the Inventory.
class AddInventoryScreen extends StatefulWidget {
  final InventoryModel? existingItem;

  const AddInventoryScreen({super.key, this.existingItem});

  @override
  State<AddInventoryScreen> createState() => _AddInventoryScreenState();
}

class _AddInventoryScreenState extends State<AddInventoryScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _quantityCtrl;
  late TextEditingController _thresholdCtrl;

  late String _selectedCategory;
  late String _selectedUnit;
  late DateTime _expiryDate;

  bool _isSaving = false;
  bool get _isEditMode => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;

    _nameCtrl = TextEditingController(text: item?.foodName ?? '');
    _quantityCtrl = TextEditingController(
      text: item != null ? DateFormatter.formatQuantity(item.availableQuantity) : '',
    );
    _thresholdCtrl = TextEditingController(
      text: item != null
          ? DateFormatter.formatQuantity(item.lowStockThreshold)
          : AppConstants.lowStockThreshold.toInt().toString(),
    );

    _selectedCategory = item?.category ?? AppConstants.foodCategories.first;
    _selectedUnit = item?.unit ?? AppConstants.measurementUnits.first;
    _expiryDate = item?.expiryDate ?? DateTime.now().add(const Duration(days: 60));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _quantityCtrl.dispose();
    _thresholdCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final quantity = double.parse(_quantityCtrl.text.trim());
      final threshold = double.tryParse(_thresholdCtrl.text.trim()) ?? AppConstants.lowStockThreshold;

      final inventoryProvider = context.read<InventoryProvider>();
      final dashboardProvider = context.read<DashboardProvider>();

      if (_isEditMode) {
        final updated = widget.existingItem!.copyWith(
          foodName: _nameCtrl.text.trim(),
          category: _selectedCategory,
          availableQuantity: quantity,
          unit: _selectedUnit,
          expiryDate: _expiryDate,
          lowStockThreshold: threshold,
          lastUpdated: DateTime.now(),
        );

        await inventoryProvider.updateFoodItem(updated);
      } else {
        final newItem = InventoryModel(
          id: const Uuid().v4(),
          foodName: _nameCtrl.text.trim(),
          category: _selectedCategory,
          availableQuantity: quantity,
          unit: _selectedUnit,
          expiryDate: _expiryDate,
          lowStockThreshold: threshold,
          lastUpdated: DateTime.now(),
        );

        await inventoryProvider.addFoodItem(newItem);
      }

      await dashboardProvider.refreshDashboard();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode ? 'Food item updated successfully.' : 'Food item added to inventory.',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save food item: $e'),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Food Item' : 'Add Food Item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Food Item Name *',
                  hintText: 'e.g. Basmati Rice, Toor Dal',
                  prefixIcon: Icon(Icons.fastfood_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter food item name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: AppConstants.foodCategories.map((c) {
                  return DropdownMenuItem(value: c, child: Text(c));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _quantityCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Available Quantity *',
                        prefixIcon: Icon(Icons.scale_outlined),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Enter quantity';
                        }
                        final num = double.tryParse(val.trim());
                        if (num == null || num < 0) {
                          return 'Quantity must be >= 0';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unit *',
                      ),
                      items: AppConstants.measurementUnits.map((u) {
                        return DropdownMenuItem(value: u, child: Text(u));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedUnit = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: _pickExpiryDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Expiry Date *',
                    prefixIcon: Icon(Icons.event_busy_outlined),
                  ),
                  child: Text(
                    DateFormatter.format(_expiryDate),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _thresholdCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Low Stock Alert Threshold',
                  hintText: 'e.g. 20',
                  suffixText: _selectedUnit,
                  prefixIcon: const Icon(Icons.warning_amber_outlined),
                ),
                validator: (val) {
                  if (val != null && val.isNotEmpty) {
                    final num = double.tryParse(val.trim());
                    if (num == null || num <= 0) {
                      return 'Enter a positive threshold';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _submit,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(_isSaving
                      ? 'Saving...'
                      : (_isEditMode ? 'Update Item' : 'Add to Inventory')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

