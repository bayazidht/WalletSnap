import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:wallet_snap/features/transactions/logic/transaction_provider.dart';
import 'package:wallet_snap/features/categories/logic/category_provider.dart';
import 'package:wallet_snap/features/settings/logic/settings_provider.dart';

import '../../../core/constants/default_category_icons.dart';
import '../data/transaction_model.dart';
import 'scanner_screen.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final TransactionModel? transactionToEdit;

  const AddTransactionScreen({super.key, this.transactionToEdit});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  TransactionType _type = TransactionType.expense;
  double _amount = 0.0;
  String _title = '';
  String? _selectedCategoryId;
  DateTime _date = DateTime.now();
  String _notes = '';

  late TextEditingController _amountController;
  late TextEditingController _titleController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final tx = widget.transactionToEdit;
    _amountController = TextEditingController(
      text: tx?.amount.toStringAsFixed(2) ?? '',
    );
    _titleController = TextEditingController(text: tx?.title ?? '');
    _notesController = TextEditingController(text: tx?.notes ?? '');

    if (tx != null) {
      _type = tx.type;
      _selectedCategoryId = tx.categoryId;
      _date = tx.date;
      _notes = tx.notes;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')),
        );
        return;
      }

      try {
        if (widget.transactionToEdit != null) {
          final updatedTx = widget.transactionToEdit!.copyWith(
            title: _title,
            amount: _amount,
            type: _type,
            categoryId: _selectedCategoryId!,
            notes: _notes,
            date: _date,
          );

          await ref
              .read(transactionProvider.notifier)
              .updateTransaction(updatedTx);
        } else {
          await ref
              .read(transactionProvider.notifier)
              .addTransaction(
                title: _title,
                amount: _amount,
                type: _type,
                categoryId: _selectedCategoryId!,
                date: _date,
                notes: _notes,
              );
        }

        if (mounted) {
          Navigator.pop(context, true);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.transactionToEdit != null
                    ? 'Transaction updated successfully'
                    : 'Transaction saved successfully',
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final currencySymbol = ref.watch(settingsProvider).currencySymbol;

    final categories = ref.watch(categoryProvider);
    final filteredCategories = categories
        .where((c) => c.type.name == _type.name)
        .toList();

    if (_selectedCategoryId == null && filteredCategories.isNotEmpty) {
      _selectedCategoryId = filteredCategories.first.id;
    }

    final isEditing = widget.transactionToEdit != null;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Transaction' : 'Add Transaction',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 10),
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('Expense'),
                    icon: Icon(Icons.upload_rounded),
                  ),
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('Income'),
                    icon: Icon(Icons.download_rounded),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: isEditing
                    ? null
                    : (val) {
                        setState(() {
                          _type = val.first;
                          _selectedCategoryId =
                              null;
                        });
                      },
              ),
              const SizedBox(height: 24),

              _buildInputCard(
                colorScheme,
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          prefixIcon: Text(
                            '$currencySymbol ',
                            style: TextStyle(
                              fontSize: 24,
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 0,
                          ),
                          border: InputBorder.none,
                        ),
                        validator: (val) => (val == null || val.isEmpty)
                            ? 'Enter amount'
                            : null,
                        onSaved: (val) => _amount = double.parse(val!),
                      ),
                    ),
                    _buildScanButton(colorScheme),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _buildInputCard(
                colorScheme,
                label: "Title",
                child: TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: 'Enter a title',
                    border: InputBorder.none,
                  ),
                  onSaved: (val) => _title = val ?? '',
                ),
              ),

              const SizedBox(height: 16),

              _buildInputCard(
                colorScheme,
                label: "Category",
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryId,
                  isExpanded: true,
                  decoration: const InputDecoration(border: InputBorder.none),
                  items: filteredCategories
                      .map(
                        (cat) => DropdownMenuItem(
                          value: cat.id,
                          child: Row(
                            children: [
                              Icon(
                                availableIcons[cat.iconName] ?? Icons.category,
                                size: 22,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Text(cat.name),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedCategoryId = val),
                ),
              ),

              const SizedBox(height: 16),
              _buildDatePicker(colorScheme),

              const SizedBox(height: 16),
              _buildInputCard(
                colorScheme,
                label: "Notes",
                child: TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Add a description...',
                    border: InputBorder.none,
                  ),
                  onSaved: (val) => _notes = val ?? '',
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildSubmitButton(isEditing),
    );
  }

  Widget _buildScanButton(ColorScheme colorScheme) {
    return IconButton.filledTonal(
      onPressed: () => _showScanOptions(context),
      icon: const Icon(Icons.document_scanner_outlined, size: 28),
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  Widget _buildDatePicker(ColorScheme colorScheme) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _date,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (picked != null) setState(() => _date = picked);
      },
      child: _buildInputCard(
        colorScheme,
        label: "Date",
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('EEEE, dd MMM yyyy').format(_date),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(
                Icons.calendar_today_rounded,
                size: 20,
                color: colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(bool isEditing) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: FilledButton(
        onPressed: _submitForm,
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(isEditing ? 'Update Transaction' : 'Save Transaction'),
      ),
    );
  }

  Widget _buildInputCard(
    ColorScheme colorScheme, {
    Widget? child,
    String? label,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null)
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          child ?? const SizedBox.shrink(),
        ],
      ),
    );
  }

  Future<void> _showScanOptions(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScannerScreen()),
    );
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _amountController.text = result['amount'] ?? '';
        _titleController.text = result['title'] ?? '';
        _notesController.text = result['notes'] ?? '';
        if (result['categoryId'] != null) {
          _selectedCategoryId = result['categoryId'];
        }
      });
    }
  }
}
