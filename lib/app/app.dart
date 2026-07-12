import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/savings_goal_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/currency_converter_provider.dart';
import 'routes.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => SavingsGoalProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => CurrencyConverterProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.getThemeWithFont(AppTheme.lightTheme, themeProvider.fontFamily),
            darkTheme: AppTheme.getThemeWithFont(AppTheme.darkTheme, themeProvider.fontFamily),
            themeMode: themeProvider.themeMode,
            initialRoute: AppRoutes.splash,
            routes: AppRouter.routes,
            builder: (context, child) {
              final isDark = themeProvider.themeMode == ThemeMode.system
                  ? MediaQuery.of(context).platformBrightness == Brightness.dark
                  : themeProvider.themeMode == ThemeMode.dark;
              final systemUiOverlayStyle = isDark
                  ? SystemUiOverlayStyle.light.copyWith(
                      statusBarColor: Colors.transparent,
                      statusBarIconBrightness: Brightness.light,
                      statusBarBrightness: Brightness.dark,
                      systemNavigationBarColor: const Color(0xFF200E26),
                      systemNavigationBarIconBrightness: Brightness.light,
                    )
                  : SystemUiOverlayStyle.dark.copyWith(
                      statusBarColor: Colors.transparent,
                      statusBarIconBrightness: Brightness.dark,
                      statusBarBrightness: Brightness.light,
                      systemNavigationBarColor: const Color(0xFF200E26),
                      systemNavigationBarIconBrightness: Brightness.light,
                    );
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: systemUiOverlayStyle,
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
