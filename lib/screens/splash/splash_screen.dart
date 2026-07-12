import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Artificial delay to show beautiful logo/animation
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final isFirstLaunch = prefs.getBool(AppConstants.keyIsFirstLaunch) ?? true;

    if (isFirstLaunch) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Wait until AuthProvider status is no longer loading or initial
    if (authProvider.status == AuthStatus.initial || authProvider.status == AuthStatus.loading) {
      final completer = Completer<void>();
      void listener() {
        if (authProvider.status != AuthStatus.initial && authProvider.status != AuthStatus.loading) {
          authProvider.removeListener(listener);
          if (!completer.isCompleted) {
            completer.complete();
          }
        }
      }
      authProvider.addListener(listener);
      // Wait for completion with a max 5-second timeout as a fallback
      await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
        authProvider.removeListener(listener);
      }).catchError((_) {});
    }

    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Placeholder / Graphic icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                AppConstants.appName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Track wisely, spend smart.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
