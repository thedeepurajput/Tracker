import 'package:flutter/material.dart';
import '../services/DatabaseHelper.dart';
import 'model.dart';
import 'category_manager.dart';
import '../services/category_preferences.dart';
import '../models/custom_category.dart';

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
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  late DateTime _selectedDate;
  bool _isRecurring = false;
  
  // Track selected custom categories
  CustomCategory? _selectedCustomExpenseCategory;
  CustomCategory? _selectedCustomIncomeCategory;
  
  // Track deleted categories
  List<String> _deletedExpenseCategories = [];
  List<String> _deletedIncomeCategories = [];
  
  // Track custom categories
  List<CustomCategory> _customExpenseCategories = [];
  List<CustomCategory> _customIncomeCategories = [];

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
    _loadCategoryPreferences();
    _animationController.forward();
  }

  Future<void> _loadCategoryPreferences() async {
    try {
      final deletedExpense = await CategoryPreferences.getDeletedExpenseCategories();
      final deletedIncome = await CategoryPreferences.getDeletedIncomeCategories();
      
      final customExpenseData = await CategoryPreferences.getCustomExpenseCategories();
      final customIncomeData = await CategoryPreferences.getCustomIncomeCategories();
      
      setState(() {
        _deletedExpenseCategories = deletedExpense;
        _deletedIncomeCategories = deletedIncome;
        _customExpenseCategories = customExpenseData.map((data) => CustomCategory.fromJson(data)).toList();
        _customIncomeCategories = customIncomeData.map((data) => CustomCategory.fromJson(data)).toList();
      });
    } catch (e) {
      print('Error loading category preferences: $e');
    }
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
    
    // Determine the category and custom category ID
    ExpenseCategory category;
    String? customCategoryId;
    
    if (_isExpense) {
      if (_selectedCustomExpenseCategory != null) {
        category = ExpenseCategory.other; // Use 'other' as fallback for custom categories
        customCategoryId = _selectedCustomExpenseCategory!.id;
      } else {
        category = _selectedExpenseCategory;
      }
    } else {
      // For income, we'll use ExpenseCategory.other and rely on the amount sign
      if (_selectedCustomIncomeCategory != null) {
        category = ExpenseCategory.other;
        customCategoryId = _selectedCustomIncomeCategory!.id;
      } else {
        category = ExpenseCategory.other; // Income always uses 'other' category
      }
    }
    
    final item = ExpenseItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      amount: _isExpense ? amount : -amount,
      category: category,
      date: _selectedDate,
      paymentMethod: _selectedPaymentMethod,
      isRecurring: _isRecurring, 
      description: '',
      customCategoryId: customCategoryId,
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
          content: Text('Error adding ${_isExpense ? 'expense' : 'income'}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCategoryManager(bool isExpense) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return CategoryManagerDialog(
          isExpense: isExpense,
          deletedCategories: isExpense ? _deletedExpenseCategories : _deletedIncomeCategories,
          onDeletedCategoriesChanged: (deletedCategories) {
            setState(() {
              if (isExpense) {
                _deletedExpenseCategories = deletedCategories;
              } else {
                _deletedIncomeCategories = deletedCategories;
              }
            });
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    ).then((_) {
      // Reload categories when dialog closes
      _loadCategoryPreferences();
    });
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
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
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
          Icon(_isExpense ? Icons.remove : Icons.add, color: Colors.white, size: 24),
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
                    Icon(Icons.trending_down, color: _isExpense ? Colors.red : Colors.grey),
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
                    Icon(Icons.trending_up, color: !_isExpense ? Colors.green : Colors.grey),
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
          icon: _isExpense ? Icons.shopping_bag_outlined : Icons.account_balance_wallet_outlined,
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
        _isExpense ? _buildExpenseCategoryDropdown() : _buildIncomeCategoryDropdown(),
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
        prefixIcon: Icon(icon, color: _isExpense ? const Color(0xFFFF6B6B) : const Color(0xFF00B894)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildExpenseCategoryDropdown() {
    // Filter out deleted categories
    final availableDefaultCategories = ExpenseCategory.values
        .where((cat) => !_deletedExpenseCategories.contains(cat.toString().split('.').last))
        .toList();
    
    // Get available custom categories
    final availableCustomCategories = _customExpenseCategories
        .where((cat) => !_deletedExpenseCategories.contains(cat.name))
        .toList();
    
    // Ensure we have a valid selection
    if (_selectedCustomExpenseCategory != null) {
      // If custom category is selected, make sure it's still available
      if (!availableCustomCategories.contains(_selectedCustomExpenseCategory)) {
        _selectedCustomExpenseCategory = null;
        if (availableDefaultCategories.isNotEmpty) {
          _selectedExpenseCategory = availableDefaultCategories.first;
        }
      }
    } else {
      // If default category is selected, make sure it's still available
      if (!availableDefaultCategories.contains(_selectedExpenseCategory)) {
        if (availableDefaultCategories.isNotEmpty) {
          _selectedExpenseCategory = availableDefaultCategories.first;
        } else if (availableCustomCategories.isNotEmpty) {
          _selectedCustomExpenseCategory = availableCustomCategories.first;
        }
      }
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedCustomExpenseCategory?.id ?? _selectedExpenseCategory.toString(),
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined, color: const Color(0xFFFF6B6B)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: () {
                  // Combine all categories for sorting
                  final allCategories = <Map<String, dynamic>>[];
                  
                  // Add default categories
                  for (final cat in availableDefaultCategories) {
                    allCategories.add({
                      'type': 'default',
                      'value': cat.toString(),
                      'label': cat.label,
                      'icon': cat.icon,
                      'color': cat.color,
                    });
                  }
                  
                  // Add custom categories
                  for (final cat in availableCustomCategories) {
                    allCategories.add({
                      'type': 'custom',
                      'value': cat.id,
                      'label': cat.label,
                      'icon': cat.icon,
                      'color': cat.color,
                    });
                  }
                  
                  // Sort alphabetically by label
                  allCategories.sort((a, b) => (a['label'] as String).compareTo(b['label'] as String));
                  
                  // Convert to dropdown items
                  return allCategories.map((catData) => DropdownMenuItem<String>(
                    value: catData['value'] as String,
                    child: Row(
                      children: [
                        Icon(catData['icon'] as IconData, color: catData['color'] as Color),
                        const SizedBox(width: 8),
                        Text(catData['label'] as String),
                      ],
                    ),
                  )).toList();
                }(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      // Check if it's a custom category
                      final customCat = availableCustomCategories.firstWhere(
                        (cat) => cat.id == val,
                        orElse: () => CustomCategory(id: '', name: '', label: '', icon: Icons.category, color: Colors.grey, isExpense: true),
                      );
                      
                      if (customCat.id.isNotEmpty) {
                        _selectedCustomExpenseCategory = customCat;
                      } else {
                        _selectedCustomExpenseCategory = null;
                        _selectedExpenseCategory = ExpenseCategory.values.firstWhere(
                          (cat) => cat.toString() == val,
                          orElse: () => ExpenseCategory.food,
                        );
                      }
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: () => _showCategoryManager(true),
                icon: const Icon(Icons.settings_outlined),
                color: const Color(0xFFFF6B6B),
                tooltip: 'Manage Categories',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIncomeCategoryDropdown() {
    // Filter out deleted categories  
    final availableDefaultCategories = IncomeCategory.values
        .where((cat) => !_deletedIncomeCategories.contains(cat.toString().split('.').last))
        .toList();
    
    // Get available custom categories
    final availableCustomCategories = _customIncomeCategories
        .where((cat) => !_deletedIncomeCategories.contains(cat.name))
        .toList();
    
    // Ensure we have a valid selection
    if (_selectedCustomIncomeCategory != null) {
      // If custom category is selected, make sure it's still available
      if (!availableCustomCategories.contains(_selectedCustomIncomeCategory)) {
        _selectedCustomIncomeCategory = null;
        if (availableDefaultCategories.isNotEmpty) {
          _selectedIncomeCategory = availableDefaultCategories.first;
        }
      }
    } else {
      // If default category is selected, make sure it's still available
      if (!availableDefaultCategories.contains(_selectedIncomeCategory)) {
        if (availableDefaultCategories.isNotEmpty) {
          _selectedIncomeCategory = availableDefaultCategories.first;
        } else if (availableCustomCategories.isNotEmpty) {
          _selectedCustomIncomeCategory = availableCustomCategories.first;
        }
      }
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedCustomIncomeCategory?.id ?? _selectedIncomeCategory.toString(),
                decoration: InputDecoration(
                  labelText: 'Income Category',
                  prefixIcon: Icon(Icons.currency_rupee, color: const Color(0xFF00B894)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: () {
                  // Combine all categories for sorting
                  final allCategories = <Map<String, dynamic>>[];
                  
                  // Add default categories
                  for (final cat in availableDefaultCategories) {
                    allCategories.add({
                      'type': 'default',
                      'value': cat.toString(),
                      'label': cat.label,
                      'icon': cat.icon,
                      'color': cat.color,
                    });
                  }
                  
                  // Add custom categories
                  for (final cat in availableCustomCategories) {
                    allCategories.add({
                      'type': 'custom',
                      'value': cat.id,
                      'label': cat.label,
                      'icon': cat.icon,
                      'color': cat.color,
                    });
                  }
                  
                  // Sort alphabetically by label
                  allCategories.sort((a, b) => (a['label'] as String).compareTo(b['label'] as String));
                  
                  // Convert to dropdown items
                  return allCategories.map((catData) => DropdownMenuItem<String>(
                    value: catData['value'] as String,
                    child: Row(
                      children: [
                        Icon(catData['icon'] as IconData, color: catData['color'] as Color),
                        const SizedBox(width: 8),
                        Text(catData['label'] as String),
                      ],
                    ),
                  )).toList();
                }(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      // Check if it's a custom category
                      final customCat = availableCustomCategories.firstWhere(
                        (cat) => cat.id == val,
                        orElse: () => CustomCategory(id: '', name: '', label: '', icon: Icons.category, color: Colors.grey, isExpense: false),
                      );
                      
                      if (customCat.id.isNotEmpty) {
                        _selectedCustomIncomeCategory = customCat;
                      } else {
                        _selectedCustomIncomeCategory = null;
                        _selectedIncomeCategory = IncomeCategory.values.firstWhere(
                          (cat) => cat.toString() == val,
                          orElse: () => IncomeCategory.salary,
                        );
                      }
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF00B894).withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: () => _showCategoryManager(false),
                icon: const Icon(Icons.settings_outlined),
                color: const Color(0xFF00B894),
                tooltip: 'Manage Categories',
              ),
            ),
          ],
        ),
      ],
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
              color: _isExpense ? const Color(0xFFFF6B6B) : const Color(0xFF00B894),
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
            color: _isExpense ? const Color(0xFFFF6B6B) : const Color(0xFF00B894),
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
      activeColor: _isExpense ? const Color(0xFFFF6B6B) : const Color(0xFF00B894),
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
                  color: _isExpense ? const Color(0xFFFF6B6B) : const Color(0xFF00B894),
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: _isExpense ? const Color(0xFFFF6B6B) : const Color(0xFF00B894),
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
                backgroundColor:
                _canSave ? (_isExpense ? const Color(0xFFFF6B6B) : const Color(0xFF00B894)) : Colors.grey,
              ),
              child: Text('Add ${_isExpense ? 'Expense' : 'Income'}'),
            ),
          ),
        ],
      ),
    );
  }
}