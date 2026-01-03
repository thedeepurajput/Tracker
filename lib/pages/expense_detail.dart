import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/DatabaseHelper.dart';
import 'model.dart';

class ExpenseDetailsBottomSheet extends StatefulWidget {
  final ExpenseItem expense;
  final Function(ExpenseItem) onUpdate;
  final VoidCallback onDelete;

  const ExpenseDetailsBottomSheet({
    super.key,
    required this.expense,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<ExpenseDetailsBottomSheet> createState() => _ExpenseDetailsBottomSheetState();
}

class _ExpenseDetailsBottomSheetState extends State<ExpenseDetailsBottomSheet> {
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late ExpenseCategory _selectedCategory;
  late PaymentMethod _selectedPaymentMethod;
  late DateTime _selectedDate;
  late bool _isRecurring;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.expense.title);
    _amountController = TextEditingController(text: widget.expense.amount.abs().toStringAsFixed(0));
    _selectedCategory = widget.expense.category;
    _selectedPaymentMethod = widget.expense.paymentMethod;
    _selectedDate = widget.expense.date;
    _isRecurring = widget.expense.isRecurring;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveChanges() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null) return;

    final updatedExpense = ExpenseItem(
      id: widget.expense.id,
      title: _titleController.text.trim(),
      amount: widget.expense.isExpense ? -amount.abs() : amount.abs(),
      category: _selectedCategory,
      date: _selectedDate,
      paymentMethod: _selectedPaymentMethod,
      isRecurring: _isRecurring,
    );

    await ExpenseDatabase.instance.updateExpense(updatedExpense);
    widget.onUpdate(updatedExpense);

    setState(() => _isEditing = false);
    if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Transaction updated successfully"))
      );
    }
  }

  Future<void> _deleteExpense() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Transaction"),
        content: const Text("Are you sure you want to delete this?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Delete", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ExpenseDatabase.instance.deleteExpense(widget.expense.id);
      if (mounted) Navigator.pop(context);
      widget.onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = widget.expense.isIncome;
    final color = isIncome ? const Color(0xFF00B894) : const Color(0xFFFF6B6B);

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    _isEditing ? 'Edit Transaction' : 'Details',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
                ),
                Row(
                  children: [
                    if (!_isEditing) ...[
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, color: Colors.blue),
                        onPressed: () => setState(() => _isEditing = true),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_rounded, color: Colors.red),
                        onPressed: _deleteExpense,
                      ),
                    ] else ...[
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => setState(() => _isEditing = false),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check_rounded, color: Colors.green),
                        onPressed: _saveChanges,
                      ),
                    ]
                  ],
                )
              ],
            ),
          ),

          const Divider(height: 1),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  if (!_isEditing) ...[
                    const SizedBox(height: 10),
                    Text(
                      '₹${widget.expense.amount.abs().toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: color),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isIncome ? 'Income' : 'Expense',
                        style: TextStyle(color: color, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],

                  if (_isEditing) ...[
                    TextField(
                      controller: _titleController,
                      style: theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        prefixIcon: const Icon(Icons.title),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _amountController,
                      style: theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        // Yahan change kiya hai: Icons.attach_money -> Icons.currency_rupee
                        prefixIcon: const Icon(Icons.currency_rupee),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),

                    if (widget.expense.isExpense)
                      DropdownButtonFormField<ExpenseCategory>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: ExpenseCategory.values.map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat.label),
                        )).toList(),
                        onChanged: (val) => setState(() => _selectedCategory = val!),
                      ),
                    if (widget.expense.isExpense) const SizedBox(height: 16),

                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Date',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          DateFormat('dd/MM/yyyy').format(_selectedDate),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<PaymentMethod>(
                      value: _selectedPaymentMethod,
                      decoration: InputDecoration(
                        labelText: 'Payment Method',
                        prefixIcon: const Icon(Icons.payment),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: PaymentMethod.values.map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(m.label),
                      )).toList(),
                      onChanged: (val) => setState(() => _selectedPaymentMethod = val!),
                    ),
                    const SizedBox(height: 16),

                    SwitchListTile(
                      title: const Text('Recurring Transaction'),
                      value: _isRecurring,
                      activeColor: theme.colorScheme.primary,
                      onChanged: (val) => setState(() => _isRecurring = val),
                    ),

                  ] else ...[
                    _buildDetailRow(theme, Icons.description_outlined, "Title", widget.expense.title),
                    _buildDetailRow(theme, Icons.category_outlined, "Category", widget.expense.category.label),
                    _buildDetailRow(theme, Icons.calendar_today_outlined, "Date", DateFormat('dd MMMM yyyy').format(widget.expense.date)),
                    _buildDetailRow(theme, Icons.payment_outlined, "Method", widget.expense.paymentMethod.label),
                    if (widget.expense.isRecurring)
                      _buildDetailRow(theme, Icons.repeat, "Recurring", "Yes"),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  label,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500)
              ),
              const SizedBox(height: 2),
              Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 16)
              ),
            ],
          )
        ],
      ),
    );
  }
}