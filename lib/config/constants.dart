class AppConstants {
  static const String appName = 'Finora';

  // Database Constants
  static const String dbName = 'expense_tracker.db';
  static const int dbVersion = 5;

  // Database Table Names
  static const String tableTransactions = 'transactions';
  static const String tableCategories = 'categories';
  static const String tableBudgets = 'budgets';
  static const String tableSavingsGoals = 'savings_goals';
  static const String tableNotificationsHistory = 'notifications_history';
  static const String tableSavingsContributions = 'savings_contributions';

  // Shared Preferences Keys
  static const String keyIsFirstLaunch = 'is_first_launch';
  static const String keyThemeMode = 'theme_mode';
  static const String keyPrimaryCurrency = 'primary_currency';
  static const String keyDailyReminderHour = 'daily_reminder_hour';
  static const String keyDailyReminderMinute = 'daily_reminder_minute';
  static const String keyLastDailyReminderFiredDate = 'last_daily_reminder_fired_date';
  static const String keyAppFont = 'app_font';

  // Default Currency
  static const String defaultCurrency = 'USD';
}

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String dashboard = '/dashboard';
  static const String transactions = '/transactions';
  static const String addTransaction = '/add-transaction';
  static const String editTransaction = '/edit-transaction';
  static const String categories = '/categories';
  static const String addCategory = '/add-category';
  static const String budget = '/budget';
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String backupRestore = '/backup-restore';
  static const String export = '/export';
  static const String notifications = '/notifications';
  static const String currencyConverter = '/currency-converter';
}
