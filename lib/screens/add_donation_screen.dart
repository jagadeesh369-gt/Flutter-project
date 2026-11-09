import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/donation_model.dart';
import '../providers/donation_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/dashboard_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/date_formatter.dart';

/// Screen for Recording a New Food Donation or Editing an Existing Record.
class AddDonationScreen extends StatefulWidget {
  final DonationModel? existingDonation;

  const AddDonationScreen({super.key, this.existingDonation});

  @override
  State<AddDonationScreen> createState() => _AddDonationScreenState();
}

class _AddDonationScreenState extends State<AddDonationScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _donorNameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _foodItemCtrl;
  late TextEditingController _quantityCtrl;
  late TextEditingController _descriptionCtrl;

  late String _selectedCategory;
  late String _selectedUnit;
  late String _selectedCondition;
  late DateTime _donationDate;
  late DateTime _expiryDate;

  bool _isSaving = false;

  bool get _isEditMode => widget.existingDonation != null;

  @override
  void initState() {
    super.initState();
    final d = widget.existingDonation;

    _donorNameCtrl = TextEditingController(text: d?.donorName ?? '');
    _phoneCtrl = TextEditingController(text: d?.phoneNumber ?? '');
    _foodItemCtrl = TextEditingController(text: d?.foodItemName ?? '');
    _quantityCtrl = TextEditingController(text: d != null ? DateFormatter.formatQuantity(d.quantity) : '');
    _descriptionCtrl = TextEditingController(text: d?.description ?? '');

    _selectedCategory = d?.category ?? AppConstants.foodCategories.first;
    _selectedUnit = d?.unit ?? AppConstants.measurementUnits.first;
    _selectedCondition = d?.condition ?? AppConstants.foodConditions.first;
    _donationDate = d?.donationDate ?? DateTime.now();
    _expiryDate = d?.expiryDate ?? DateTime.now().add(const Duration(days: 30));
  }

  @override
  void dispose() {
    _donorNameCtrl.dispose();
    _phoneCtrl.dispose();
    _foodItemCtrl.dispose();
    _quantityCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isDonationDate}) async {
    final initial = isDonationDate ? _donationDate : _expiryDate;
    final first = isDonationDate ? DateTime(2020) : _donationDate;
    final last = DateTime(2035);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : initial,
      firstDate: first,
      lastDate: last,
    );

    if (picked != null) {
      setState(() {
        if (isDonationDate) {
          _donationDate = picked;
          if (_expiryDate.isBefore(_donationDate)) {
            _expiryDate = _donationDate.add(const Duration(days: 7));
          }
        } else {
          _expiryDate = picked;
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_expiryDate.isBefore(_donationDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Validation Error: Expiry date cannot be earlier than donation date.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final quantity = double.parse(_quantityCtrl.text.trim());
      final donationProvider = context.read<DonationProvider>();
      final inventoryProvider = context.read<InventoryProvider>();
      final dashboardProvider = context.read<DashboardProvider>();

      if (_isEditMode) {
        final updated = widget.existingDonation!.copyWith(
          donorName: _donorNameCtrl.text.trim(),
          phoneNumber: _phoneCtrl.text.trim(),
          foodItemName: _foodItemCtrl.text.trim(),
          category: _selectedCategory,
          quantity: quantity,
          unit: _selectedUnit,
          donationDate: _donationDate,
          expiryDate: _expiryDate,
          condition: _selectedCondition,
          description: _descriptionCtrl.text.trim(),
        );

        await donationProvider.updateDonation(updated, widget.existingDonation!);
      } else {
        final newDonation = DonationModel(
          id: const Uuid().v4(),
          donorName: _donorNameCtrl.text.trim(),
          phoneNumber: _phoneCtrl.text.trim(),
          foodItemName: _foodItemCtrl.text.trim(),
          category: _selectedCategory,
          quantity: quantity,
          unit: _selectedUnit,
          donationDate: _donationDate,
          expiryDate: _expiryDate,
          condition: _selectedCondition,
          description: _descriptionCtrl.text.trim(),
        );

        await donationProvider.addDonation(newDonation);
      }

      await inventoryProvider.loadInventory();
      await dashboardProvider.refreshDashboard();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? 'Donation updated and inventory synchronized.'
                  : 'Donation saved! Inventory stock automatically updated.',
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
            content: Text('Error saving donation: $e'),
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
        title: Text(_isEditMode ? 'Edit Donation' : 'Record New Donation'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section 1: Donor Information
              const Text(
                'Donor Information',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _donorNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Donor Name *',
                  hintText: 'e.g. Green Future NGO or John Doe',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Donor name cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  hintText: 'e.g. +91 98765 43210',
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

              // Section 2: Food Item Details
              const Text(
                'Food Item Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _foodItemCtrl,
                decoration: const InputDecoration(
                  labelText: 'Food Item Name *',
                  hintText: 'e.g. Basmati Rice, Fresh Apples',
                  prefixIcon: Icon(Icons.fastfood_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Food item name cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Food Category *',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: AppConstants.foodCategories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _quantityCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Quantity *',
                        hintText: 'e.g. 50',
                        prefixIcon: Icon(Icons.scale_outlined),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Enter quantity';
                        }
                        final num = double.tryParse(val.trim());
                        if (num == null || num <= 0) {
                          return 'Quantity must be > 0';
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
              const SizedBox(height: 24),

              // Section 3: Dates & Condition
              const Text(
                'Dates & Condition',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(isDonationDate: true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Donation Date *',
                          prefixIcon: Icon(Icons.event_available_outlined),
                        ),
                        child: Text(
                          DateFormatter.format(_donationDate),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(isDonationDate: false),
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
                  ),
                ],
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                value: _selectedCondition,
                decoration: const InputDecoration(
                  labelText: 'Food Condition *',
                  prefixIcon: Icon(Icons.health_and_safety_outlined),
                ),
                items: AppConstants.foodConditions.map((cond) {
                  return DropdownMenuItem(value: cond, child: Text(cond));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCondition = val);
                },
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _descriptionCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description / Remarks (Optional)',
                  hintText: 'e.g. Donated directly from morning packaging run.',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _submitForm,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    _isSaving
                        ? 'Saving...'
                        : (_isEditMode ? 'Update Donation' : 'Save Donation & Update Inventory'),
                  ),
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

