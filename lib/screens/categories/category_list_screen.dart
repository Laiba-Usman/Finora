import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../providers/category_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/extensions.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  String _activeTab = 'expense'; // 'expense' or 'income'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryProvider>(context, listen: false).loadCategories();
    });
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'movie':
        return Icons.movie;
      case 'receipt_long':
        return Icons.receipt_long;
      case 'payments':
        return Icons.payments;
      case 'laptop':
        return Icons.laptop;
      case 'trending_up':
        return Icons.trending_up;
      case 'add_card':
        return Icons.add_card;
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
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catProvider = Provider.of<CategoryProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final filteredCategories = _activeTab == 'expense'
        ? catProvider.expenseCategories
        : catProvider.incomeCategories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
      ),
      body: Column(
        children: [
          // Tab switcher
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Expense')),
                    selected: _activeTab == 'expense',
                    onSelected: (selected) {
                      if (selected) setState(() => _activeTab = 'expense');
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Income')),
                    selected: _activeTab == 'income',
                    onSelected: (selected) {
                      if (selected) setState(() => _activeTab = 'income');
                    },
                  ),
                ),
              ],
            ),
          ),
          // Categories list
          Expanded(
            child: catProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredCategories.isEmpty
                    ? const Center(child: Text('No categories configured.'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: filteredCategories.length,
                        itemBuilder: (context, index) {
                          final cat = filteredCategories[index];
                          final catColor = cat.color.toColor();
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6.0),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: catColor.withOpacity(0.15),
                                child: Icon(
                                  _getIconData(cat.icon),
                                  color: catColor,
                                ),
                              ),
                              title: Text(
                                cat.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                cat.isCustom ? 'Custom' : 'System Default',
                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                              ),
                              trailing: cat.isCustom
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                          onPressed: () {
                                            Navigator.of(context).pushNamed(
                                              AppRoutes.addCategory,
                                              arguments: cat,
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                                          onPressed: () async {
                                            final userId = authProvider.user?.uid;
                                            await catProvider.deleteCategory(cat.id, userId: userId);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Category deleted')),
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pushNamed(AppRoutes.addCategory);
        },
        tooltip: 'Add Custom Category',
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
    );
  }
}
