import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/savings_goal_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import '../../utils/date_formatter.dart';
import '../../utils/extensions.dart';
import '../../utils/currency_formatter.dart';
import '../../models/transaction_model.dart';
import '../../models/category_model.dart';
import '../../models/budget_model.dart';
import '../../models/savings_goal_model.dart';
import '../../models/savings_contribution_model.dart';

import '../settings/profile_screen.dart';
import '../currency_converter/currency_converter_screen.dart';
import '../budget/budget_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0; // 0: Home, 1: Stats, 2: Budget, 3: Profile
  String _statsType = 'expense'; // 'expense' or 'income' for stats toggle

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TransactionProvider>(context, listen: false).loadTransactions();
      Provider.of<CategoryProvider>(context, listen: false).loadCategories();
      Provider.of<SavingsGoalProvider>(context, listen: false).loadGoals();
      Provider.of<NotificationProvider>(context, listen: false).loadNotifications();
      final monthStr = DateFormatter.toYearMonthString(DateTime.now());
      Provider.of<BudgetProvider>(context, listen: false).loadBudgets(monthStr);
    });
  }

  String _formatAmount(double amount) {
    return NumberFormat('#,###').format(amount);
  }

  Widget _buildNotificationBell(BuildContext context, Color color, NotificationProvider provider) {
    final unread = provider.unreadCount;
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.notifications_outlined, size: 28, color: color),
          onPressed: () {
            Navigator.of(context).pushNamed(AppRoutes.notifications);
          },
        ),
        if (unread > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                '$unread',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTopRightActions(BuildContext context, Color color, NotificationProvider provider) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.currency_exchange, size: 26, color: color),
          onPressed: () {
            Navigator.of(context).pushNamed(AppRoutes.currencyConverter);
          },
          tooltip: 'Currency Converter',
        ),
        const SizedBox(width: 4),
        _buildNotificationBell(context, color, provider),
      ],
    );
  }

  void _showAddSavingsGoalDialog(BuildContext context) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    DateTime? selectedDate;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('New Savings Plan', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Goal Name',
                          hintText: 'e.g. New Phone, Vacation',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter a goal name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Target Amount',
                          hintText: '0.00',
                          prefixText: '${Provider.of<ThemeProvider>(context, listen: false).currencySymbol} ',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter a target amount';
                          }
                          final numVal = double.tryParse(val.trim());
                          if (numVal == null || numVal <= 0) {
                            return 'Please enter a valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          selectedDate == null
                              ? 'Target Date (Optional)'
                              : 'Target Date: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}',
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(const Duration(days: 30)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                          );
                          if (date != null) {
                            setState(() {
                              selectedDate = date;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final name = nameController.text.trim();
                      final targetAmount = double.parse(amountController.text.trim());
                      Provider.of<SavingsGoalProvider>(dialogCtx, listen: false)
                          .addGoal(name, targetAmount, selectedDate);
                      Navigator.pop(dialogCtx);
                      ScaffoldMessenger.of(dialogCtx).showSnackBar(
                        const SnackBar(content: Text('Savings Goal created!')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF200E26),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSavingsGoalDetails(BuildContext context, SavingsGoalModel initialGoal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final theme = Theme.of(sheetCtx);
        return Consumer<SavingsGoalProvider>(
          builder: (context, provider, child) {
            // Retrieve latest goal state
            final goalList = provider.goals.where((g) => g.id == initialGoal.id).toList();
            if (goalList.isEmpty) {
              // Goal was deleted, close sheet
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (Navigator.canPop(sheetCtx)) {
                  Navigator.pop(sheetCtx);
                }
              });
              return const SizedBox();
            }
            final goal = goalList.first;
            final progress = (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0);
            final accentColor = const Color(0xFFFFC436); // gold accent

            return Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pull indicator
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            goal.name,
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                              onPressed: () => _showEditSavingsGoalDialog(context, goal),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _confirmDeleteSavingsGoal(context, goal),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Progress Details Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.08)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Savings Progress',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: TextStyle(
                                  color: accentColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          LinearProgressIndicator(
                            value: progress,
                            minHeight: 12,
                            backgroundColor: theme.brightness == Brightness.dark ? const Color(0xFF1E1E2C) : const Color(0xFFF3F4F9),
                            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Saved So Far',
                                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 11),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    goal.currentAmount.formatCurrency(context),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Target Goal',
                                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 11),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    goal.targetAmount.formatCurrency(context),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (goal.targetDate != null) ...[
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Target Date', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(
                                  DateFormat('yyyy-MM-dd').format(goal.targetDate!),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Add Money Button
                    ElevatedButton.icon(
                      onPressed: () => _showAddMoneyToGoalDialog(context, goal),
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        'Add Money',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF200E26),
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Contribution History Title
                    const Text(
                      'Contribution History',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),

                    // Contribution History List
                    FutureBuilder<List<SavingsContributionModel>>(
                      future: provider.getContributionsForGoal(goal.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final contributions = snapshot.data ?? [];
                        if (contributions.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: Text(
                                'No contributions logged yet.',
                                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4), fontSize: 13),
                              ),
                            ),
                          );
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: contributions.length,
                          itemBuilder: (context, index) {
                            final c = contributions[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.05)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.add_circle, color: Colors.green, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Saved Money',
                                        style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '+ ${c.amount.formatCurrency(context)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        DateFormat('MMM d, yyyy h:mm a').format(c.timestamp),
                                        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4), fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditSavingsGoalDialog(BuildContext context, SavingsGoalModel goal) {
    final nameController = TextEditingController(text: goal.name);
    final amountController = TextEditingController(text: goal.targetAmount.toString());
    DateTime? selectedDate = goal.targetDate;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Edit Savings Plan', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Goal Name',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter a goal name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Target Amount',
                          prefixText: '${Provider.of<ThemeProvider>(context, listen: false).currencySymbol} ',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter a target amount';
                          }
                          final numVal = double.tryParse(val.trim());
                          if (numVal == null || numVal <= 0) {
                            return 'Please enter a valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          selectedDate == null
                              ? 'Target Date (Optional)'
                              : 'Target Date: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}',
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate ?? DateTime.now().add(const Duration(days: 30)),
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                          );
                          if (date != null) {
                            setState(() {
                              selectedDate = date;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final name = nameController.text.trim();
                      final targetAmount = double.parse(amountController.text.trim());
                      Provider.of<SavingsGoalProvider>(dialogCtx, listen: false)
                          .updateGoal(goal.id, name, targetAmount, selectedDate);
                      Navigator.pop(dialogCtx);
                      ScaffoldMessenger.of(dialogCtx).showSnackBar(
                        const SnackBar(content: Text('Savings Goal updated!')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF200E26),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteSavingsGoal(BuildContext context, SavingsGoalModel goal) {
    showDialog(
      context: context,
      builder: (confirmCtx) => AlertDialog(
        title: const Text('Delete Savings Goal?'),
        content: Text('Are you sure you want to delete "${goal.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(confirmCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<SavingsGoalProvider>(confirmCtx, listen: false).deleteGoal(goal.id);
              Navigator.pop(confirmCtx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddMoneyToGoalDialog(BuildContext context, SavingsGoalModel goal) {
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Add Savings: ${goal.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Current savings: ${goal.currentAmount.formatCurrencyInt(context)} / ${goal.targetAmount.formatCurrencyInt(context)}',
                  style: const TextStyle(color: Color(0xFF887D8E), fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Amount to Add',
                    hintText: '0.00',
                    prefixText: '${Provider.of<ThemeProvider>(context, listen: false).currencySymbol} ',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter an amount';
                    }
                    final numVal = double.tryParse(val.trim());
                    if (numVal == null || numVal <= 0) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final amount = double.parse(amountController.text.trim());
                  Provider.of<SavingsGoalProvider>(dialogCtx, listen: false)
                      .addMoneyToGoal(goal.id, amount);
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(dialogCtx).showSnackBar(
                    SnackBar(content: Text('Added ${amount.formatCurrencyInt(context)} to ${goal.name}!')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF200E26),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final txProvider = Provider.of<TransactionProvider>(context);
    final catProvider = Provider.of<CategoryProvider>(context);
    final budgetProvider = Provider.of<BudgetProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final savingsGoalProvider = Provider.of<SavingsGoalProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);

    if (txProvider.isLoading || catProvider.isLoading) {
      return const Scaffold(
        body: LoadingIndicator(message: 'Loading financial overview...'),
      );
    }

    // Calculations
    final now = DateTime.now();
    double totalIncomeAllTime = 0;
    double totalExpenseAllTime = 0;
    double monthlyIncome = 0;
    double monthlyExpense = 0;

    for (var tx in txProvider.transactions) {
      final isCurrentMonth = tx.date.year == now.year && tx.date.month == now.month;
      if (tx.type == 'income') {
        totalIncomeAllTime += tx.amount;
        if (isCurrentMonth) {
          monthlyIncome += tx.amount;
        }
      } else {
        totalExpenseAllTime += tx.amount;
        if (isCurrentMonth) {
          monthlyExpense += tx.amount;
        }
      }
    }
    double balance = totalIncomeAllTime - totalExpenseAllTime;

    final displayName = authProvider.isGuest ? 'Albert Flores' : (authProvider.user?.name ?? 'Albert Flores');

    // Tab view routing
    Widget buildBody() {
      switch (_currentIndex) {
        case 0:
          return _buildHomeView(
            context: context,
            theme: theme,
            balance: balance,
            monthlyIncome: monthlyIncome,
            monthlyExpense: monthlyExpense,
            currencySymbol: themeProvider.currencySymbol,
            transactions: txProvider.transactions,
            categories: catProvider.categories,
            displayName: displayName,
            savingsGoalProvider: savingsGoalProvider,
            notificationProvider: notificationProvider,
          );
        case 1:
          return _buildStatsView(
            context: context,
            theme: theme,
            currencySymbol: themeProvider.currencySymbol,
            transactions: txProvider.transactions,
            categories: catProvider.categories,
            notificationProvider: notificationProvider,
          );
        case 2:
          return _buildBudgetView(
            context: context,
            theme: theme,
            currencySymbol: themeProvider.currencySymbol,
            transactions: txProvider.transactions,
            categories: catProvider.categories,
            budgets: budgetProvider.budgets,
            budgetProvider: budgetProvider,
            notificationProvider: notificationProvider,
          );
        case 3:
          return const ProfileScreen();
        default:
          return const SizedBox();
      }
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: buildBody(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.brightness == Brightness.dark ? Colors.black45 : const Color(0x1F000000),
              blurRadius: 16,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          child: BottomAppBar(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            notchMargin: 8,
            color: const Color(0xFF200E26), // Deep Dark Purple
            shape: const CircularNotchedRectangle(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_filled, Icons.home_outlined),
                _buildNavItem(1, Icons.analytics, Icons.analytics_outlined),
                const SizedBox(width: 48), // Spacer for FAB
                _buildNavItem(2, Icons.calendar_month, Icons.calendar_month_outlined),
                _buildNavItem(3, Icons.person, Icons.person_outline),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        height: 64,
        width: 64,
        margin: const EdgeInsets.only(top: 8),
        child: FloatingActionButton(
          elevation: 4,
          shape: const CircleBorder(),
          backgroundColor: const Color(0xFFFFC436), // Vibrant Yellow
          onPressed: () {
            Navigator.of(context).pushNamed(AppRoutes.addTransaction);
          },
          child: const Icon(
            Icons.add,
            color: Color(0xFF200E26),
            size: 32,
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon) {
    final isSelected = _currentIndex == index;
    return IconButton(
      icon: Icon(
        isSelected ? activeIcon : inactiveIcon,
        color: isSelected ? const Color(0xFFFFC436) : const Color(0xFF887D8E),
        size: 28,
      ),
      onPressed: () => setState(() => _currentIndex = index),
    );
  }

  // ── HOME VIEW ───────────────────────────────────────────────────────────
  Widget _buildHomeView({
    required BuildContext context,
    required ThemeData theme,
    required double balance,
    required double monthlyIncome,
    required double monthlyExpense,
    required String currencySymbol,
    required List<TransactionModel> transactions,
    required List<CategoryModel> categories,
    required String displayName,
    required SavingsGoalProvider savingsGoalProvider,
    required NotificationProvider notificationProvider,
  }) {
    final textColor = theme.colorScheme.onSurface;
    final cardColor = theme.colorScheme.surface;
    final progressBg = theme.brightness == Brightness.dark ? const Color(0xFF1E1E2C) : const Color(0xFFF3F4F9);
    final goals = savingsGoalProvider.goals;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF887D8E),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    displayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              _buildTopRightActions(context, textColor, notificationProvider),
            ],
          ),
          const SizedBox(height: 24),

          // Total Balance Card
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2C1438), Color(0xFF4D1B54)],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3D4D1B54),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                )
              ],
            ),
            child: Stack(
              children: [
                // Diagonal background grid/lines
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.05,
                    child: CustomPaint(
                      painter: GridPainter(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Balance',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$currencySymbol ${_formatAmount(balance)}',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 30,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            displayName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pushNamed(AppRoutes.addTransaction);
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFC436), // Accent yellow
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add, color: Color(0xFF200E26), size: 22),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Statistics Side-by-Side Cards
          Row(
            children: [
              // Income Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark ? const Color(0xFF0F2C30) : const Color(0xFFE2F6F5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Income',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF14B8A6),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$currencySymbol ${_formatAmount(monthlyIncome)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF14B8A6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_upward, color: Colors.white, size: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Expense Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark ? const Color(0xFF2C1318) : const Color(0xFFFEEFEE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Expense',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFFEF4444),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$currencySymbol ${_formatAmount(monthlyExpense)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_downward, color: Colors.white, size: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Add Transaction Button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.addTransaction);
            },
            icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 22),
            label: const Text(
              'Add Transaction',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.brightness == Brightness.dark ? theme.colorScheme.primary : const Color(0xFF200E26),
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
          ),
          const SizedBox(height: 20),

          // Monthly Budgets Navigation Card
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.budget);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.account_balance_wallet_outlined, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Configure Monthly Budgets',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Set and edit limits for categories and receive alerts',
                          style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF887D8E)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF887D8E)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Savings Plan / Target Budgets
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My savings plan',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Color(0xFFFFC436), size: 28),
                onPressed: () => _showAddSavingsGoalDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Horizontal Saving Target Cards
          goals.isEmpty
              ? GestureDetector(
                  onTap: () => _showAddSavingsGoalDialog(context),
                  child: Container(
                    height: 110,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.colorScheme.outline.withOpacity(0.08)),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.savings_outlined, color: theme.brightness == Brightness.dark ? theme.colorScheme.primary : const Color(0xFF200E26), size: 28),
                          const SizedBox(height: 8),
                          const Text(
                            'No savings plans yet — tap + to create one',
                            style: TextStyle(color: Color(0xFF887D8E), fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : SizedBox(
                  height: 115,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: goals.length + 1,
                    itemBuilder: (context, index) {
                      if (index == goals.length) {
                        return GestureDetector(
                          onTap: () => _showAddSavingsGoalDialog(context),
                          child: Container(
                            width: 160,
                            margin: const EdgeInsets.only(right: 16, bottom: 4, top: 4),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardColor.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.08)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_circle_outline, color: Color(0xFFFFC436), size: 32),
                                const SizedBox(height: 8),
                                Text(
                                  'Add Goal',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: textColor.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      final goal = goals[index];
                      final accentColors = [
                        const Color(0xFFA855F7), // Purple
                        const Color(0xFF06B6D4), // Cyan
                        const Color(0xFFFFC436), // Gold/Yellow
                        const Color(0xFF10B981), // Green
                        const Color(0xFFEF4444), // Red
                      ];
                      final accentColor = accentColors[index % accentColors.length];
                      return _buildSavingsPlanCard(goal, accentColor, theme, cardColor, progressBg);
                    },
                  ),
                ),
          const SizedBox(height: 24),

          // Recent Transactions Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRoutes.transactions);
                },
                child: const Text('View all', style: TextStyle(color: Color(0xFF887D8E))),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Recent Transactions List
          transactions.isEmpty
              ? const EmptyState(
                  title: 'No transactions yet',
                  description: 'Tap the button below to add your first transaction.',
                  icon: Icons.receipt_long_outlined,
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length > 3 ? 3 : transactions.length,
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    final cat = categories.firstWhere(
                      (c) => c.id == tx.categoryId,
                      orElse: () => CategoryModel(
                        id: 'dummy',
                        name: 'General',
                        icon: 'star',
                        color: '#64748B',
                        type: tx.type,
                      ),
                    );
                    return _buildTransactionTile(tx, cat, currencySymbol, theme, textColor, cardColor);
                  },
                ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSavingsPlanCard(
    SavingsGoalModel goal,
    Color accentColor,
    ThemeData theme,
    Color cardColor,
    Color progressBg,
  ) {
    final progress = (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0);
    return GestureDetector(
      onTap: () => _showSavingsGoalDetails(context, goal),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16, bottom: 4, top: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    goal.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: progressBg,
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  goal.currentAmount.formatCurrencyInt(context),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Text(
                  ' / ${goal.targetAmount.formatCurrencyInt(context)}',
                  style: const TextStyle(color: Color(0xFF887D8E), fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(
    TransactionModel tx,
    CategoryModel category,
    String currencySymbol,
    ThemeData theme,
    Color textColor,
    Color cardColor,
  ) {
    final isExpense = tx.type == 'expense';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: category.color.toColor().withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getCategoryIcon(category.icon),
              color: category.color.toColor(),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.note?.isNotEmpty == true ? tx.note! : category.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category.name,
                  style: const TextStyle(color: Color(0xFF887D8E), fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isExpense ? '-' : '+'} $currencySymbol${_formatAmount(tx.amount)}',
                style: TextStyle(
                  color: isExpense ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormatter.formatDate(tx.date),
                style: const TextStyle(color: Color(0xFF887D8E), fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── STATISTICS VIEW ──────────────────────────────────────────────────────
  Widget _buildStatsView({
    required BuildContext context,
    required ThemeData theme,
    required String currencySymbol,
    required List<TransactionModel> transactions,
    required List<CategoryModel> categories,
    required NotificationProvider notificationProvider,
  }) {
    final textColor = theme.colorScheme.onSurface;
    final cardColor = theme.colorScheme.surface;
    // Filtered transaction list based on toggle
    final filteredTxs = transactions.where((tx) => tx.type == _statsType).toList();
    double totalAmt = filteredTxs.fold(0.0, (sum, item) => sum + item.amount);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Statistics',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              _buildTopRightActions(context, textColor, notificationProvider),
            ],
          ),
          const SizedBox(height: 24),

          // Custom Expense/Income Toggle Card
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark ? const Color(0xFF1E1E2C) : const Color(0xFFEBEAEF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _statsType = 'expense'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _statsType == 'expense'
                            ? (theme.brightness == Brightness.dark ? theme.colorScheme.primary : const Color(0xFF200E26))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Expense',
                          style: TextStyle(
                            color: _statsType == 'expense' ? Colors.white : textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _statsType = 'income'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _statsType == 'income'
                            ? (theme.brightness == Brightness.dark ? theme.colorScheme.primary : const Color(0xFF200E26))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Income',
                          style: TextStyle(
                            color: _statsType == 'income' ? Colors.white : textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Total Expense/Income Number
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _statsType == 'expense' ? 'Total Expenses' : 'Total Income',
                style: const TextStyle(color: Color(0xFF887D8E), fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$currencySymbol ${_formatAmount(totalAmt)}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: theme.colorScheme.outline.withOpacity(0.08)),
                    ),
                    child: Row(
                      children: [
                        Text('Week', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textColor)),
                        Icon(Icons.arrow_drop_down, size: 18, color: textColor),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Weekly Bar Chart using fl_chart
          Container(
            height: 220,
            padding: const EdgeInsets.only(top: 24, bottom: 8, left: 12, right: 12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.08)),
            ),
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                alignment: BarChartAlignment.spaceEvenly,
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        final index = value.toInt() - 1;
                        if (index >= 0 && index < weekdays.length) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              weekdays[index],
                              style: const TextStyle(color: Color(0xFF887D8E), fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _generateWeeklyBarGroups(filteredTxs, theme),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Recent Transactions Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRoutes.transactions);
                },
                child: const Text('View all', style: TextStyle(color: Color(0xFF887D8E))),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Transactions
          filteredTxs.isEmpty
              ? const EmptyState(
                  title: 'No activity in this view',
                  description: 'Your logged transactions will appear here.',
                  icon: Icons.receipt_long_outlined,
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredTxs.length > 3 ? 3 : filteredTxs.length,
                  itemBuilder: (context, index) {
                    final tx = filteredTxs[index];
                    final cat = categories.firstWhere(
                      (c) => c.id == tx.categoryId,
                      orElse: () => CategoryModel(
                        id: 'dummy',
                        name: 'General',
                        icon: 'star',
                        color: '#64748B',
                        type: tx.type,
                      ),
                    );
                    return _buildTransactionTile(tx, cat, currencySymbol, theme, textColor, cardColor);
                  },
                ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Helper to generate weekly bar groups for fl_chart
  List<BarChartGroupData> _generateWeeklyBarGroups(
    List<TransactionModel> filteredTxs,
    ThemeData theme,
  ) {
    // Get start of this week (Monday)
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(monday.year, monday.month, monday.day);

    final Map<int, double> weekdaySums = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
    for (var tx in filteredTxs) {
      final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
      final difference = txDate.difference(startOfWeek).inDays;
      if (difference >= 0 && difference < 7) {
        final weekday = tx.date.weekday;
        weekdaySums[weekday] = (weekdaySums[weekday] ?? 0) + tx.amount;
      }
    }

    double maxVal = 100.0;
    weekdaySums.forEach((key, val) {
      if (val > maxVal) maxVal = val;
    });

    final List<BarChartGroupData> groups = [];
    final barColor = theme.brightness == Brightness.dark ? const Color(0xFF4A2F5B) : const Color(0xFFE5D5EC);

    for (int d = 1; d <= 7; d++) {
      final val = weekdaySums[d] ?? 0.0;
      groups.add(
        BarChartGroupData(
          x: d,
          barRods: [
            BarChartRodData(
              toY: val,
              color: barColor,
              width: 16,
              borderRadius: BorderRadius.circular(6),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxVal * 1.1,
                color: theme.brightness == Brightness.dark ? const Color(0xFF1E1E2C) : const Color(0xFFF3F4F9),
              ),
            ),
          ],
        ),
      );
    }

    return groups;
  }

  // ── BUDGET VIEW ──────────────────────────────────────────────────────────
  Widget _buildBudgetView({
    required BuildContext context,
    required ThemeData theme,
    required String currencySymbol,
    required List<TransactionModel> transactions,
    required List<CategoryModel> categories,
    required List<BudgetModel> budgets,
    required BudgetProvider budgetProvider,
    required NotificationProvider notificationProvider,
  }) {
    final textColor = theme.colorScheme.onSurface;
    final cardColor = theme.colorScheme.surface;

    // Calculate total spend and total budget limits
    double totalBudget = budgets.fold(0.0, (sum, b) => sum + b.amount);
    double totalSpent = 0;
    for (var b in budgets) {
      totalSpent += budgetProvider.getSpentAmount(b, transactions);
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Budget Management',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed(AppRoutes.budget);
                    },
                    child: Icon(Icons.settings_outlined, size: 20, color: textColor.withOpacity(0.6)),
                  ),
                ],
              ),
              _buildTopRightActions(context, textColor, notificationProvider),
            ],
          ),
          const SizedBox(height: 24),

          // Pie/Category Chart using fl_chart
          Container(
            height: 240,
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Inner center text showing remaining balance
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Total Remaining',
                      style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF887D8E)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$currencySymbol ${_formatAmount((totalBudget - totalSpent).clamp(0.0, double.infinity))}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Pie Chart from fl_chart
                SizedBox(
                  width: 210,
                  height: 210,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 75,
                      sections: _generatePieSections(transactions, categories, theme),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Dynamic Category Chips Group
          _buildDynamicCategoryChips(transactions, categories, cardColor, textColor),
          const SizedBox(height: 28),

          // Categories Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Categories',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (dialogCtx) => AddBudgetDialog(
                              currentMonth: DateFormatter.toYearMonthString(DateTime.now()),
                              onSave: () {
                                final monthStr = DateFormatter.toYearMonthString(DateTime.now());
                                Provider.of<BudgetProvider>(context, listen: false).loadBudgets(monthStr);
                              },
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondary,
                          foregroundColor: theme.brightness == Brightness.dark ? Colors.black : const Color(0xFF200E26),
                          minimumSize: const Size(100, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('+ Add Budget', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed(AppRoutes.addCategory);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.brightness == Brightness.dark ? theme.colorScheme.primary : const Color(0xFF200E26),
                          foregroundColor: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
                          minimumSize: const Size(110, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('+ Add Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
          const SizedBox(height: 16),

          // Custom Category Grid List
          budgets.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.colorScheme.outline.withOpacity(0.08)),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Text('No budgets configured for this month.', style: TextStyle(color: Color(0xFF887D8E))),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed(AppRoutes.budget);
                          },
                          child: const Text('Configure Budgets'),
                        ),
                      ],
                    ),
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.35,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: budgets.length,
                  itemBuilder: (context, index) {
                    final budget = budgets[index];
                    final spent = budgetProvider.getSpentAmount(budget, transactions);
                    final remaining = (budget.amount - spent).clamp(0.0, budget.amount);
                    final progress = (spent / budget.amount).clamp(0.0, 1.0);

                    String catName = 'Overall';
                    Color catColor = const Color(0xFF200E26);
                    if (budget.categoryId != null) {
                      final c = categories.firstWhere((element) => element.id == budget.categoryId, 
                        orElse: () => CategoryModel(id: 'dummy', name: 'General', icon: 'star', color: '#200E26', type: 'expense'));
                      catName = c.name;
                      catColor = c.color.toColor();
                    }

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.08)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  catName,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                width: 4,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: catColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Edit Budget Button
                              GestureDetector(
                                onTap: () {
                                  final monthStr = DateFormatter.toYearMonthString(DateTime.now());
                                  showDialog(
                                    context: context,
                                    builder: (dialogCtx) => AddBudgetDialog(
                                      currentMonth: monthStr,
                                      budgetToEdit: budget,
                                      onSave: () {
                                        Provider.of<BudgetProvider>(context, listen: false).loadBudgets(monthStr);
                                      },
                                    ),
                                  );
                                },
                                child: Icon(Icons.edit_outlined, size: 15, color: textColor.withOpacity(0.7)),
                              ),
                              const SizedBox(width: 6),
                              // Delete Budget Button
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (confirmCtx) => AlertDialog(
                                      title: const Text('Delete Budget?'),
                                      content: Text('Are you sure you want to delete the budget for "$catName"?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(confirmCtx),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () async {
                                            final monthStr = DateFormatter.toYearMonthString(DateTime.now());
                                            await budgetProvider.deleteBudget(budget.id, monthStr);
                                            if (confirmCtx.mounted) {
                                              Navigator.pop(confirmCtx);
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: const Icon(Icons.delete_outline, size: 15, color: Colors.red),
                              ),
                            ],
                          ),
                          Text(
                            '${remaining.formatCurrencyInt(context)} Left',
                            style: const TextStyle(color: Color(0xFF887D8E), fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LinearProgressIndicator(
                                value: progress,
                                backgroundColor: theme.brightness == Brightness.dark ? const Color(0xFF1E1E2C) : const Color(0xFFF3F4F9),
                                valueColor: AlwaysStoppedAnimation<Color>(catColor),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              const SizedBox(height: 4),
                              Text('${(progress * 100).toInt()}%', style: const TextStyle(fontSize: 10, color: Color(0xFF887D8E))),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Generates PieChartSectionData dynamically from transactions
  List<PieChartSectionData> _generatePieSections(
    List<TransactionModel> transactions,
    List<CategoryModel> categories,
    ThemeData theme,
  ) {
    final now = DateTime.now();
    final expenses = transactions.where((tx) => 
        tx.type == 'expense' && 
        tx.date.year == now.year && 
        tx.date.month == now.month).toList();

    if (expenses.isEmpty) {
      return [
        PieChartSectionData(
          color: Colors.grey.withOpacity(0.2),
          value: 100,
          title: '0%',
          radius: 22,
          showTitle: false,
        )
      ];
    }

    final Map<String, double> categorySums = {};
    double totalExpense = 0;
    for (var tx in expenses) {
      categorySums[tx.categoryId] = (categorySums[tx.categoryId] ?? 0) + tx.amount;
      totalExpense += tx.amount;
    }

    final List<PieChartSectionData> sections = [];
    categorySums.forEach((categoryId, amount) {
      final cat = categories.firstWhere(
        (c) => c.id == categoryId,
        orElse: () => CategoryModel(id: 'dummy', name: 'Other', icon: 'star', color: '#64748B', type: 'expense'),
      );
      final percentage = totalExpense > 0 ? (amount / totalExpense) * 100 : 0.0;
      
      sections.add(
        PieChartSectionData(
          color: cat.color.toColor(),
          value: amount,
          title: '${percentage.toStringAsFixed(0)}%',
          radius: 22,
          titleStyle: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      );
    });

    return sections;
  }

  // Generates chips with exact Category totals
  Widget _buildDynamicCategoryChips(
    List<TransactionModel> transactions,
    List<CategoryModel> categories,
    Color cardColor,
    Color textColor,
  ) {
    final now = DateTime.now();
    final expenses = transactions.where((tx) => 
        tx.type == 'expense' && 
        tx.date.year == now.year && 
        tx.date.month == now.month).toList();

    if (expenses.isEmpty) {
      return const Center(
        child: Text(
          'No expense data for this month.',
          style: TextStyle(color: Color(0xFF887D8E), fontSize: 12),
        ),
      );
    }

    final Map<String, double> categorySums = {};
    for (var tx in expenses) {
      categorySums[tx.categoryId] = (categorySums[tx.categoryId] ?? 0) + tx.amount;
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: categorySums.keys.map((categoryId) {
        final cat = categories.firstWhere(
          (c) => c.id == categoryId,
          orElse: () => CategoryModel(id: 'dummy', name: 'Other', icon: 'star', color: '#64748B', type: 'expense'),
        );
        final amt = categorySums[categoryId] ?? 0.0;
        return _buildCategoryDotChip('${cat.name}: ${amt.formatCurrencyInt(context)}', cat.color.toColor(), cardColor, textColor);
      }).toList(),
    );
  }

  Widget _buildCategoryDotChip(String label, Color color, Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0x0A000000)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }

  // ── HELPER ICON EXTRACTOR ────────────────────────────────────────────────
  IconData _getCategoryIcon(String name) {
    switch (name) {
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
}

// ── CUSTOM PAINTERS ───────────────────────────────────────────────────────
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    // Simple wavy path
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.5,
      size.width * 0.5,
      size.height * 0.8,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 1.0,
      size.width,
      size.height * 0.6,
    );

    canvas.drawPath(path, paint);

    final path2 = Path();
    path2.moveTo(0, size.height * 0.5);
    path2.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.8,
      size.width * 0.6,
      size.height * 0.4,
    );
    path2.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.2,
      size.width,
      size.height * 0.5,
    );

    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
