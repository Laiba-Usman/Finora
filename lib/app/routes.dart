import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/transactions/transaction_list_screen.dart';
import '../screens/transactions/add_transaction_screen.dart';
import '../screens/transactions/edit_transaction_screen.dart';
import '../screens/categories/category_list_screen.dart';
import '../screens/categories/add_category_screen.dart';
import '../screens/budget/budget_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/profile_screen.dart';
import '../screens/settings/backup_restore_screen.dart';
import '../screens/export/export_screen.dart';
import '../screens/dashboard/notifications_screen.dart';
import '../screens/currency_converter/currency_converter_screen.dart';

class AppRouter {
  static Map<String, WidgetBuilder> get routes {
    return {
      AppRoutes.splash: (context) => const SplashScreen(),
      AppRoutes.onboarding: (context) => const OnboardingScreen(),
      AppRoutes.login: (context) => const LoginScreen(),
      AppRoutes.signup: (context) => const SignupScreen(),
      AppRoutes.forgotPassword: (context) => const ForgotPasswordScreen(),
      AppRoutes.dashboard: (context) => const DashboardScreen(),
      AppRoutes.transactions: (context) => const TransactionListScreen(),
      AppRoutes.addTransaction: (context) => const AddTransactionScreen(),
      AppRoutes.editTransaction: (context) => const EditTransactionScreen(),
      AppRoutes.categories: (context) => const CategoryListScreen(),
      AppRoutes.addCategory: (context) => const AddCategoryScreen(),
      AppRoutes.budget: (context) => const BudgetScreen(),
      AppRoutes.settings: (context) => const SettingsScreen(),
      AppRoutes.profile: (context) => const ProfileScreen(),
      AppRoutes.backupRestore: (context) => const BackupRestoreScreen(),
      AppRoutes.export: (context) => const ExportScreen(),
      AppRoutes.notifications: (context) => const NotificationsScreen(),
      AppRoutes.currencyConverter: (context) => const CurrencyConverterScreen(),
    };
  }
}
