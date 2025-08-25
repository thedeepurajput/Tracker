import 'package:flutter/material.dart';
import 'model.dart';
import '../services/category_preferences.dart';
import '../models/custom_category.dart';

class CategoryManagerDialog extends StatefulWidget {
  final bool isExpense;
  final Function(List<String>) onDeletedCategoriesChanged;
  final List<String> deletedCategories;

  const CategoryManagerDialog({
    Key? key,
    required this.isExpense,
    required this.onDeletedCategoriesChanged,
    required this.deletedCategories,
  }) : super(key: key);

  @override
  State<CategoryManagerDialog> createState() => _CategoryManagerDialogState();
}

class _CategoryManagerDialogState extends State<CategoryManagerDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  List<String> _localDeletedCategories = [];
  List<CustomCategory> _customCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _localDeletedCategories = List.from(widget.deletedCategories);
    
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
    
    _loadData();
    _animationController.forward();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load custom categories
      final customData = widget.isExpense 
          ? await CategoryPreferences.getCustomExpenseCategories()
          : await CategoryPreferences.getCustomIncomeCategories();
      
      _customCategories = customData.map((data) => CustomCategory.fromJson(data)).toList();
    } catch (e) {
      print('Error loading categories: $e');
    }
    
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleCategory(String categoryName) {
    setState(() {
      if (_localDeletedCategories.contains(categoryName)) {
        _localDeletedCategories.remove(categoryName);
      } else {
        _localDeletedCategories.add(categoryName);
      }
    });
  }

  void _deleteCustomCategory(int index) {
    setState(() {
      _customCategories.removeAt(index);
    });
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AddCategoryDialog(
        isExpense: widget.isExpense,
        onAdd: (customCategory) {
          setState(() {
            _customCategories.add(customCategory);
          });
        },
      ),
    );
  }

  Widget _buildCategoryTile({
    required String name,
    required String label,
    required IconData icon,
    required Color color,
    required bool isHidden,
    required bool isCustom,
    VoidCallback? onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isHidden ? Colors.grey[100] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHidden ? Colors.grey[300]! : color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: isHidden
            ? null
            : [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _toggleCategory(name),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isHidden ? Colors.grey[400] : color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isHidden ? Colors.grey[600] : color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isHidden ? Colors.grey[500] : Colors.grey[800],
                          decoration: isHidden ? TextDecoration.lineThrough : TextDecoration.none,
                        ),
                      ),
                      if (isCustom)
                        Text(
                          'Custom',
                          style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isCustom && onDelete != null) ...[
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                    tooltip: 'Delete Category',
                  ),
                  const SizedBox(width: 8),
                ],
                Icon(
                  isHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: isHidden ? Colors.grey[500] : color,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveChanges() async {
    try {
      // Save deleted categories
      if (widget.isExpense) {
        await CategoryPreferences.saveDeletedExpenseCategories(_localDeletedCategories);
        await CategoryPreferences.saveCustomExpenseCategories(
          _customCategories.map((cat) => cat.toJson()).toList()
        );
      } else {
        await CategoryPreferences.saveDeletedIncomeCategories(_localDeletedCategories);
        await CategoryPreferences.saveCustomIncomeCategories(
          _customCategories.map((cat) => cat.toJson()).toList()
        );
      }
      
      widget.onDeletedCategoriesChanged(_localDeletedCategories);
      Navigator.of(context).pop();
    } catch (e) {
      print('Error saving categories: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving categories: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.isExpense 
        ? ExpenseCategory.values
        : IncomeCategory.values;

    return Material(
      color: Colors.black54,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  Expanded(
                    child: _buildCategoryList(categories),
                  ),
                  _buildActions(),
                ],
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
          colors: widget.isExpense
              ? [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)]
              : [const Color(0xFF00B894), const Color(0xFF00D2A0)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.category_rounded,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Manage ${widget.isExpense ? 'Expense' : 'Income'} Categories',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(List categories) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Manage Categories:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddCategoryDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add New'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.isExpense 
                      ? const Color(0xFFFF6B6B)
                      : const Color(0xFF00B894),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: categories.length + _customCategories.length,
              itemBuilder: (context, index) {
                if (index < categories.length) {
                  // Default categories
                  final category = categories[index];
                  final categoryName = category.toString().split('.').last;
                  final isHidden = _localDeletedCategories.contains(categoryName);
                  
                  return _buildCategoryTile(
                    name: categoryName,
                    label: category.label,
                    icon: category.icon,
                    color: category.color,
                    isHidden: isHidden,
                    isCustom: false,
                  );
                } else {
                  // Custom categories
                  final customIndex = index - categories.length;
                  final customCategory = _customCategories[customIndex];
                  final isHidden = _localDeletedCategories.contains(customCategory.name);
                  
                  return _buildCategoryTile(
                    name: customCategory.name,
                    label: customCategory.label,
                    icon: customCategory.icon,
                    color: customCategory.color,
                    isHidden: isHidden,
                    isCustom: true,
                    onDelete: () => _deleteCustomCategory(customIndex),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _localDeletedCategories.clear();
                });
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(
                  color: widget.isExpense 
                      ? const Color(0xFFFF6B6B)
                      : const Color(0xFF00B894),
                ),
              ),
              child: Text(
                'Show All',
                style: TextStyle(
                  color: widget.isExpense 
                      ? const Color(0xFFFF6B6B)
                      : const Color(0xFF00B894),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isExpense 
                    ? const Color(0xFFFF6B6B)
                    : const Color(0xFF00B894),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Save Changes',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddCategoryDialog extends StatefulWidget {
  final bool isExpense;
  final Function(CustomCategory) onAdd;

  const AddCategoryDialog({
    Key? key,
    required this.isExpense,
    required this.onAdd,
  }) : super(key: key);

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final _labelController = TextEditingController();
  IconData _selectedIcon = Icons.category;
  Color _selectedColor = const Color(0xFF6C63FF);

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _addCategory() {
    if (_labelController.text.trim().isNotEmpty) {
      final customCategory = CustomCategory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _labelController.text.trim().toLowerCase().replaceAll(' ', '_'),
        label: _labelController.text.trim(),
        icon: _selectedIcon,
        color: _selectedColor,
        isExpense: widget.isExpense,
      );
      
      widget.onAdd(customCategory);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Custom ${widget.isExpense ? 'Expense' : 'Income'} Category',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _labelController,
              decoration: InputDecoration(
                labelText: 'Category Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(_selectedIcon, color: _selectedColor),
              ),
            ),
            const SizedBox(height: 20),
            
            // Icon Selection
            Text(
              'Select Icon:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.isExpense 
                    ? CategoryIcons.expenseIcons.length 
                    : CategoryIcons.incomeIcons.length,
                itemBuilder: (context, index) {
                  final icon = widget.isExpense 
                      ? CategoryIcons.expenseIcons[index]
                      : CategoryIcons.incomeIcons[index];
                  final isSelected = _selectedIcon == icon;
                  
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: Container(
                      width: 50,
                      height: 50,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? _selectedColor.withOpacity(0.1) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: isSelected 
                            ? Border.all(color: _selectedColor, width: 2)
                            : Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected ? _selectedColor : Colors.grey[600],
                        size: 24,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            
            // Color Selection
            Text(
              'Select Color:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CategoryIcons.categoryColors.map((color) {
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected 
                          ? Border.all(color: Colors.grey[800]!, width: 3)
                          : null,
                    ),
                    child: isSelected 
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _addCategory,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isExpense 
                          ? const Color(0xFFFF6B6B)
                          : const Color(0xFF00B894),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Add Category'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
