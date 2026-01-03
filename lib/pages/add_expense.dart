import 'package:flutter/material.dart';
import '../services/DatabaseHelper.dart';
import 'model.dart';

class AddTransaction extends StatefulWidget {
  final DateTime selectedDate;
  final void Function(ExpenseItem) onAdd;

  const AddTransaction({
    super.key,
    required this.selectedDate,
    required this.onAdd,
  });

  @override
  State<AddTransaction> createState() => _AddTransactionState();
}

class _AddTransactionState extends State<AddTransaction> with SingleTickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  bool _isExpense = true;
  ExpenseCategory _selectedExpenseCategory = ExpenseCategory.food;
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

    _amountController.addListener(() {
      setState(() {});
    });

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));

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
              primary: _isExpense ? const Color(0xFFFF6B6B) : const Color(0xFF00B894),
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
      amount: _isExpense ? -amount : amount,
      category: _isExpense ? _selectedExpenseCategory : ExpenseCategory.other,
      date: _selectedDate,
      paymentMethod: _selectedPaymentMethod,
      isRecurring: _isRecurring,
    );

    try {
      await ExpenseDatabase.instance.insertTransaction(item);
      widget.onAdd(item);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _isExpense ? const Color(0xFFFF6B6B) : const Color(0xFF00B894);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // --- HEADER WITH BACK ARROW ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                // 1. Back Arrow Button
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_rounded, size: 24, color: Colors.black54),
                  ),
                ),

                const SizedBox(width: 16),

                // 2. Title
                Expanded(
                  child: Text(
                    _isExpense ? 'New Expense' : 'New Income',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: activeColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                // 3. Switch
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: !_isExpense,
                    onChanged: (value) => setState(() => _isExpense = !value),
                    activeColor: const Color(0xFF00B894),
                    activeTrackColor: const Color(0xFF00B894).withOpacity(0.3),
                    inactiveThumbColor: const Color(0xFFFF6B6B),
                    inactiveTrackColor: const Color(0xFFFF6B6B).withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              children: [
                const SizedBox(height: 50),

                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        // Amount Input Row
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '\u20B9',
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w900,
                                    color: activeColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IntrinsicWidth(
                                  child: TextField(
                                    controller: _amountController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    style: TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.w900,
                                      color: activeColor,
                                    ),
                                    cursorColor: activeColor,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText: '0',
                                      hintStyle: TextStyle(color: Colors.black12),
                                      contentPadding: EdgeInsets.zero,
                                      isDense: true,
                                    ),
                                    autofocus: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Quick Amount Chips
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 10,
                            alignment: WrapAlignment.center,
                            children: [50, 100, 500, 2000].map((amount) {
                              return InkWell(
                                onTap: () {
                                  final current = double.tryParse(_amountController.text) ?? 0;
                                  setState(() {
                                    _amountController.text = (current + amount).toStringAsFixed(0);
                                  });
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: activeColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: activeColor.withOpacity(0.2)),
                                  ),
                                  child: Text(
                                    '+\u20B9$amount',
                                    style: TextStyle(color: activeColor, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Title Field
                        TextField(
                          controller: _titleController,
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                          decoration: InputDecoration(
                            labelText: 'Title',
                            hintText: 'What is this for?',
                            prefixIcon: Icon(Icons.edit_note_rounded, color: activeColor),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: activeColor, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        const SizedBox(height: 20),

                        // Category Dropdown
                        if (_isExpense)
                          DropdownButtonFormField<ExpenseCategory>(
                            value: _selectedExpenseCategory,
                            decoration: InputDecoration(
                              labelText: 'Category',
                              prefixIcon: Icon(Icons.category_rounded, color: activeColor),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            items: ExpenseCategory.values.map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Row(
                                children: [
                                  Icon(cat.icon, color: cat.color, size: 20),
                                  const SizedBox(width: 10),
                                  Text(cat.label),
                                ],
                              ),
                            )).toList(),
                            onChanged: (val) => setState(() => _selectedExpenseCategory = val!),
                          ),

                        if (_isExpense) const SizedBox(height: 20),

                        // Date & Payment Row
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: _pickDate,
                                borderRadius: BorderRadius.circular(16),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Date',
                                    prefixIcon: Icon(Icons.calendar_today_rounded, color: activeColor),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                  child: Text(
                                    "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<PaymentMethod>(
                                value: _selectedPaymentMethod,
                                decoration: InputDecoration(
                                  labelText: 'Method',
                                  prefixIcon: Icon(Icons.payment_rounded, color: activeColor),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                                isExpanded: true,
                                items: PaymentMethod.values.map((m) => DropdownMenuItem(
                                  value: m,
                                  child: Text(m.label, overflow: TextOverflow.ellipsis),
                                )).toList(),
                                onChanged: (val) => setState(() => _selectedPaymentMethod = val!),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Recurring Switch
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.grey.shade50,
                          ),
                          child: SwitchListTile(
                            title: const Text('Recurring', style: TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: const Text('Repeats monthly', style: TextStyle(fontSize: 12)),
                            value: _isRecurring,
                            onChanged: (val) => setState(() => _isRecurring = val),
                            activeColor: activeColor,
                            secondary: Icon(Icons.repeat_rounded, color: _isRecurring ? activeColor : Colors.grey),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Save Button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _saveTransaction,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [activeColor, activeColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_rounded, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Text(
                        'Add Transaction',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}