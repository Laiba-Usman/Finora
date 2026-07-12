import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/category_model.dart';
import '../../providers/category_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../utils/validators.dart';
import '../../utils/extensions.dart';

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String _categoryType = 'expense';
  String _selectedColor = '#EF4444'; // Default Red
  String _selectedIcon = 'star'; // Default Star
  CategoryModel? _categoryToEdit;
  bool _initialized = false;

  final List<String> _colors = [
    '#EF4444', // Red
    '#3B82F6', // Blue
    '#10B981', // Green
    '#EC4899', // Pink
    '#8B5CF6', // Purple
    '#F59E0B', // Amber
    '#06B6D4', // Cyan
    '#64748B', // Slate
  ];

  final List<String> _icons = [
    'star',
    'work',
    'home',
    'health_and_safety',
    'school',
    'flight',
    'directions_car',
    'restaurant',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is CategoryModel) {
        _categoryToEdit = args;
        _nameController.text = args.name;
        _categoryType = args.type;
        _selectedColor = args.color;
        _selectedIcon = args.icon;
      }
      _initialized = true;
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'star':
        return Icons.star;
      case 'work':
        return Icons.work;
      case 'home':
        return Icons.home;
      case 'health_and_safety':
        return Icons.health_and_safety;
      case 'school':
        return Icons.school;
      case 'flight':
        return Icons.flight;
      case 'directions_car':
        return Icons.directions_car;
      case 'restaurant':
        return Icons.restaurant;
      default:
        return Icons.category;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (_formKey.currentState!.validate()) {
      try {
        final catProvider = Provider.of<CategoryProvider>(context, listen: false);
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        
        final newCategory = CategoryModel(
          id: _categoryToEdit != null ? _categoryToEdit!.id : const Uuid().v4(),
          name: _nameController.text.trim(),
          icon: _selectedIcon,
          color: _selectedColor,
          type: _categoryType,
          isCustom: true,
        );

        final userId = authProvider.user?.uid;
        
        if (_categoryToEdit != null) {
          await catProvider.updateCategory(newCategory, userId: userId);
        } else {
          await catProvider.addCategory(newCategory, userId: userId);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _categoryToEdit != null 
                    ? 'Category updated successfully!' 
                    : 'Custom category added successfully!'
              ),
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving category: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = _categoryToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Category' : 'New Category'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type Toggle
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Expense')),
                      selected: _categoryType == 'expense',
                      onSelected: (selected) {
                        if (selected) setState(() => _categoryType = 'expense');
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Income')),
                      selected: _categoryType == 'income',
                      onSelected: (selected) {
                        if (selected) setState(() => _categoryType = 'income');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Name textfield
              CustomTextField(
                controller: _nameController,
                labelText: 'Category Name',
                hintText: 'e.g. Subscriptions, Gifts',
                prefixIcon: Icons.edit_outlined,
                validator: Validators.validateName,
              ),
              const SizedBox(height: 24),
              // Color Picker Label
              Text(
                'Select Accent Color',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              // Color List
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _colors.length,
                  itemBuilder: (context, index) {
                    final colorHex = _colors[index];
                    final color = colorHex.toColor();
                    final isSelected = _selectedColor == colorHex;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = colorHex),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6.0),
                        width: 44,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: theme.colorScheme.onBackground, width: 3)
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              // Icon Picker Label
              Text(
                'Select Icon',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              // Icon Grid/List
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _icons.length,
                  itemBuilder: (context, index) {
                    final iconName = _icons[index];
                    final iconData = _getIconData(iconName);
                    final isSelected = _selectedIcon == iconName;
                    final activeColor = _selectedColor.toColor();

                    return GestureDetector(
                      onTap: () => setState(() => _selectedIcon = iconName),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6.0),
                        width: 50,
                        decoration: BoxDecoration(
                          color: isSelected ? activeColor.withOpacity(0.2) : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? activeColor : theme.colorScheme.onSurface.withOpacity(0.1),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          iconData,
                          color: isSelected ? activeColor : theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 48),
              CustomButton(
                text: isEditing ? 'Update Category' : 'Save Category',
                onPressed: _saveCategory,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
