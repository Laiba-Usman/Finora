import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login failed: ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<void> _loginAsGuest() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signInAnonymously();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Guest Login failed: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signInWithGoogle();
      // Only navigate if sign-in succeeded (user didn't cancel)
      if (mounted && authProvider.isAuthenticated) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Login failed: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Icon(
                  Icons.account_balance_wallet,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome Back!',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onBackground,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Log in to track your budget effortlessly.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onBackground.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                CustomTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  hintText: 'yourname@example.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _passwordController,
                  labelText: 'Password',
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  validator: Validators.validatePassword,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRoutes.forgotPassword);
                    },
                    child: const Text('Forgot Password?'),
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Log In',
                  isLoading: authProvider.status == AuthStatus.loading,
                  onPressed: _login,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: authProvider.status == AuthStatus.loading ? null : _loginWithGoogle,
                  icon: const Icon(Icons.g_mobiledata, size: 24),
                  label: const Text('Sign in with Google'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: authProvider.status == AuthStatus.loading ? null : _loginAsGuest,
                  child: const Text('Continue as Guest'),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: TextStyle(color: theme.colorScheme.onBackground.withOpacity(0.7)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed(AppRoutes.signup);
                      },
                      child: const Text('Sign Up'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
