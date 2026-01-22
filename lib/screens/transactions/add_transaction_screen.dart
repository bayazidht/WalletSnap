import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wallet_snap/models/transaction_model.dart';
import 'package:wallet_snap/models/category_model.dart';
import 'package:wallet_snap/services/recipt_scanner_service.dart';
import 'package:wallet_snap/services/transaction_service.dart';
import 'package:wallet_snap/providers/category_provider.dart';
import 'package:intl/intl.dart';

import '../../data/default_category_icons.dart';
import '../../providers/settings_provider.dart';
import '../receipt_scan/scanner_screen.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? transactionToEdit;

  const AddTransactionScreen({super.key, this.transactionToEdit});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  CategoryType _type = CategoryType.expense;
  double _amount = 0.0;
  String _title = '';
  String? _selectedCategoryId;
  DateTime _date = DateTime.now();
  String _notes = '';

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.transactionToEdit != null) {
      final tx = widget.transactionToEdit!;
      _type = tx.type == TransactionType.income
          ? CategoryType.income
          : CategoryType.expense;
      _amount = tx.amount;
      _title = tx.title;
      _selectedCategoryId = tx.categoryId;
      _date = tx.date;
      _notes = tx.notes;
      _amountController.text = tx.amount.toStringAsFixed(2);
      _titleController.text = tx.title;
      _notesController.text = tx.notes;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _date) {
      setState(() {
        _date = picked;
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null || _selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a category and sign in.'),
          ),
        );
        return;
      }

      final String transactionId = widget.transactionToEdit?.id ?? '';
      final categoryProvider = Provider.of<CategoryProvider>(
        context,
        listen: false,
      );
      final selectedCategoryModel = categoryProvider.getCategoryById(
        _selectedCategoryId!,
      );

      final transactionToSave = TransactionModel(
        id: transactionId,
        title: _title,
        amount: _amount,
        type: _type == CategoryType.income
            ? TransactionType.income
            : TransactionType.expense,
        categoryId: selectedCategoryModel.id,
        date: _date,
        notes: _notes,
      );

      final TransactionService service = TransactionService();

      try {
        if (widget.transactionToEdit != null) {
          await service.updateTransaction(transactionToSave);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Updated successfully!')),
          );
        } else {
          await service.addTransaction(transactionToSave);
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Added successfully!')));
        }
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final currency = Provider.of<SettingsProvider>(context).selectedCurrency;
    final isEditing = widget.transactionToEdit != null;

    final List<CategoryModel> currentCategories = _type == CategoryType.expense
        ? categoryProvider.expenseCategories
        : categoryProvider.incomeCategories;

    if (_selectedCategoryId == null && currentCategories.isNotEmpty) {
      _selectedCategoryId = currentCategories.first.id;
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Transaction' : 'Add Transaction',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 10),

              SegmentedButton<CategoryType>(
                segments: const [
                  ButtonSegment(
                    value: CategoryType.expense,
                    label: Text('Expense'),
                    icon: Icon(Icons.upload_rounded),
                  ),
                  ButtonSegment(
                    value: CategoryType.income,
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
                          _selectedCategoryId = null;
                        });
                      },
                style: SegmentedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _buildInputCard(
                colorScheme,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                          height: 1.2,
                        ),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          isDense: true,
                          prefixIcon: Text(
                            '$currency ',
                            style: TextStyle(
                              fontSize: 24,
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                          border: InputBorder.none,
                        ),
                        validator: (val) => (val == null || val.isEmpty)
                            ? 'Enter amount'
                            : null,
                        onSaved: (val) => _amount = double.parse(val!),
                      ),
                    ),
                    Column(
                      children: [
                        IconButton.filledTonal(
                          onPressed: () {
                            _showScanOptions(context);
                          },
                          icon: const Icon(
                            Icons.document_scanner_outlined,
                            size: 28,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: colorScheme.primaryContainer,
                            foregroundColor: colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Scan",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _buildInputCard(
                colorScheme,
                label: "Title",
                child: TextFormField(
                  controller: _titleController,
                  maxLines: 1,
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
                  borderRadius: BorderRadius.circular(16),
                  items: currentCategories
                      .map(
                        (cat) => DropdownMenuItem(
                          value: cat.id,
                          child: Row(
                            children: [
                              Icon(
                                availableIcons[cat.iconName],
                                size: 22,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                cat.name,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedCategoryId = val),
                  onSaved: (val) => _selectedCategoryId = val,
                ),
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: () => _selectDate(context),
                borderRadius: BorderRadius.circular(20),
                child: _buildInputCard(
                  colorScheme,
                  label: "Date",
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('EEEE, MMM dd, yyyy').format(_date),
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
              ),
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        child: FilledButton(
          onPressed: _submitForm,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            elevation: 2,
          ),
          child: Text(
            isEditing ? 'Update Transaction' : 'Save Transaction',
            style: const TextStyle(fontSize: 16),
          ),
        ),
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
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
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
