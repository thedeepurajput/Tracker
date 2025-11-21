import 'package:flutter/material.dart';
import '../services/DatabaseHelper.dart';
import 'model.dart';

class AddTransaction extends StatefulWidget {
  final DateTime selectedDate;
  final void Function(ExpenseItem) onAdd;

  const AddTransaction({
    Key? key,
    required this.selectedDate,
    required this.onAdd,
  }) : super(key: key);

  @override
  State<AddTransaction> createState() => _AddTransactionState();
}

class _AddTransactionState extends State<AddTransaction>
    with SingleTickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  bool _isExpense = true;
  ExpenseCategory _selectedExpenseCategory = ExpenseCategory.food;
  IncomeCategory _selectedIncomeCategory = IncomeCategory.salary;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.upi;
  late DateTime _selectedDate;
  bool _isRecurring = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  bool get _canSave {
    return _titleController.text.trim().isNotEmpty &&
        _amountController.text.isNotEmpty &&
        double.tryParse(_amountController.text) != null &&
        double.parse(_amountController.text) > 0;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: Theme.of(ctx).colorScheme.copyWith(
                  primary: _isExpense
                      ? const Color(0xFFFF6B6B)
                      : const Color(0xFF00B894),
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveTransaction() async {
    if (!_canSave) return;
    final amount = double.parse(_amountController.text);

    final item = ExpenseItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      amount: _isExpense ? amount : -amount,
      category: _isExpense ? _selectedExpenseCategory : ExpenseCategory.other,
      date: _selectedDate,
      paymentMethod: _selectedPaymentMethod,
      isRecurring: _isRecurring,
      description: '',
      customCategoryId: null,
    );

    try {
      await ExpenseDatabase.instance.insertTransaction(item);
      widget.onAdd(item);
      await _animationController.reverse();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Error adding ${_isExpense ? 'expense' : 'income'}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Center(
              child: Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    _buildToggle(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: _buildForm(),
                      ),
                    ),
                    _buildActions(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 8, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isExpense
              ? [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)]
              : [const Color(0xFF00B894), const Color(0xFF00D2A0)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Icon(_isExpense ? Icons.remove : Icons.add,
              color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Add ${_isExpense ? 'Expense' : 'Income'}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () async {
              await _animationController.reverse();
              if (mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isExpense = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isExpense ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.trending_down,
                        color: _isExpense ? Colors.red : Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Expense',
                      style: TextStyle(
                        color: _isExpense ? Colors.red : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isExpense = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isExpense ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.trending_up,
                        color: !_isExpense ? Colors.green : Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Income',
                      style: TextStyle(
                        color: !_isExpense ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(
          _titleController,
          label: _isExpense ? 'Expense Title' : 'Income Source',
          hint: _isExpense ? 'e.g. Lunch' : 'e.g. Salary',
          icon: _isExpense
              ? Icons.shopping_bag_outlined
              : Icons.account_balance_wallet_outlined,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          _amountController,
          label: 'Amount',
          hint: '0.00',
          icon: _isExpense ? Icons.currency_rupee : Icons.currency_rupee,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          prefix: '₹ ',
        ),
        const SizedBox(height: 20),
        _isExpense
            ? _buildExpenseCategoryDropdown()
            : _buildIncomeCategoryDropdown(),
        const SizedBox(height: 20),
        _buildPaymentMethodDropdown(),
        const SizedBox(height: 20),
        _buildDatePicker(),
        const SizedBox(height: 20),
        _buildRecurringSwitch(),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController c, {
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? prefix,
  }) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefix,
        prefixIcon: Icon(icon,
            color:
                _isExpense ? const Color(0xFFFF6B6B) : const Color(0xFF00B894)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildExpenseCategoryDropdown() {
    return DropdownButtonFormField<ExpenseCategory>(
      value: _selectedExpenseCategory,
      decoration: InputDecoration(
        labelText: 'Category',
        prefixIcon: Icon(Icons.category_outlined,
            color: const Color(0xFFFF6B6B)),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
      items: ExpenseCategory.values
          .map((cat) => DropdownMenuItem<ExpenseCategory>(
                value: cat,
                child: Row(
                  children: [
                    Icon(cat.icon, color: cat.color),
                    const SizedBox(width: 8),
                    Text(cat.label),
                  ],
                ),
              ))
          .toList(),
      onChanged: (val) {
        if (val != null) {
          setState(() => _selectedExpenseCategory = val);
        }
      },
    );
  }

  Widget _buildIncomeCategoryDropdown() {
    return DropdownButtonFormField<IncomeCategory>(
      value: _selectedIncomeCategory,
      decoration: InputDecoration(
        labelText: 'Income Category',
        prefixIcon: Icon(Icons.currency_rupee,
            color: const Color(0xFF00B894)),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
      items: IncomeCategory.values
          .map((cat) => DropdownMenuItem<IncomeCategory>(
                value: cat,
                child: Row(
                  children: [
                    Icon(cat.icon, color: cat.color),
                    const SizedBox(width: 8),
                    Text(cat.label),
                  ],
                ),
              ))
          .toList(),
      onChanged: (val) {
        if (val != null) {
          setState(() => _selectedIncomeCategory = val);
        }
      },
    );
  }

  Widget _buildPaymentMethodDropdown() {
    return DropdownButtonFormField<PaymentMethod>(
      value: _selectedPaymentMethod,
      decoration: InputDecoration(
        labelText: 'Payment Method',
        prefixIcon: Icon(
          Icons.payment_outlined,
          color: _isExpense ? const Color(0xFFFF6B6B) : const Color(0xFF00B894),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: PaymentMethod.values
          .map((m) => DropdownMenuItem(
                value: m,
                child: Row(
                  children: [
                    Icon(
                      m.icon,
                      color: _isExpense
                          ? const Color(0xFFFF6B6B)
                          : const Color(0xFF00B894),
                    ),
                    SizedBox(width: 8),
                    Text(m.label),
                  ],
                ),
              ))
          .toList(),
      onChanged: (val) {
        if (val != null) setState(() => _selectedPaymentMethod = val);
      },
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: _pickDate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date',
          prefixIcon: Icon(
            Icons.calendar_today_outlined,
            color:
                _isExpense ? const Color(0xFFFF6B6B) : const Color(0xFF00B894),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text('${_selectedDate.toLocal()}'.split(' ')[0]),
      ),
    );
  }

  Widget _buildRecurringSwitch() {
    return SwitchListTile(
      title: Text('Recurring ${_isExpense ? 'Expense' : 'Income'}'),
      value: _isRecurring,
      onChanged: (v) => setState(() => _isRecurring = v),
      activeColor:
          _isExpense ? const Color(0xFFFF6B6B) : const Color(0xFF00B894),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                await _animationController.reverse();
                if (mounted) Navigator.of(context).pop();
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: _isExpense
                      ? const Color(0xFFFF6B6B)
                      : const Color(0xFF00B894),
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: _isExpense
                      ? const Color(0xFFFF6B6B)
                      : const Color(0xFF00B894),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _canSave ? _saveTransaction : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _canSave
                    ? (_isExpense
                        ? const Color(0xFFFF6B6B)
                        : const Color(0xFF00B894))
                    : Colors.grey,
              ),
              child: Text('Add ${_isExpense ? 'Expense' : 'Income'}'),
            ),
          ),
        ],
      ),
    );
  }
}
