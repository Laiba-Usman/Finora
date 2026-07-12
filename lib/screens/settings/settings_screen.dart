import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/savings_goal_provider.dart';
import '../../providers/notification_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Theme Toggles
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Dark Mode'),
            trailing: Switch(
              value: themeProvider.isDarkMode,
              onChanged: (isDark) {
                themeProvider.toggleTheme(isDark);
              },
            ),
          ),
          const Divider(),
          // Currency Picker
          ListTile(
            leading: const Icon(Icons.monetization_on),
            title: const Text('Primary Currency'),
            subtitle: Text('Current: ${themeProvider.currency}'),
            trailing: DropdownButton<String>(
              value: themeProvider.currency,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'USD', child: Text('USD (\$)')),
                DropdownMenuItem(value: 'EUR', child: Text('EUR (€)')),
                DropdownMenuItem(value: 'GBP', child: Text('GBP (£)')),
                DropdownMenuItem(value: 'JPY', child: Text('JPY (¥)')),
                DropdownMenuItem(value: 'INR', child: Text('INR (₹)')),
                DropdownMenuItem(value: 'PKR', child: Text('PKR (₨)')),
              ],
              onChanged: (newVal) async {
                if (newVal != null) {
                  await themeProvider.updateCurrency(newVal);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Currency updated to $newVal')),
                    );
                  }
                }
              },
            ),
          ),
          const Divider(),
          // Profile settings
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('User Profile'),
            subtitle: const Text('View and update your profile details'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.profile);
            },
          ),
          const Divider(),
          // Cloud Sync Backup settings
          ListTile(
            leading: const Icon(Icons.cloud_sync),
            title: const Text('Cloud Backup & Restore'),
            subtitle: const Text('Sync your records securely to the cloud'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.backupRestore);
            },
          ),
          const Divider(),
          // Export Screen
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Export Reports'),
            subtitle: const Text('Save your statements as CSV or PDF'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.export);
            },
          ),
          const Divider(),
          // App Font Screen
          ListTile(
            leading: const Icon(Icons.font_download_outlined),
            title: const Text('App Font'),
            subtitle: Text('Current: ${themeProvider.fontFamily}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showFontSelectionDialog(context, themeProvider);
            },
          ),
          const Divider(),
          // About Section
          const AboutListTile(
            icon: Icon(Icons.info),
            applicationName: AppConstants.appName,
            applicationVersion: '1.0.0',
            applicationLegalese: '© 2026 Smart Expense Tracker Project',
            aboutBoxChildren: [
              SizedBox(height: 12),
              Text('Smart Expense Tracker is a Flutter Academic project featuring clean architecture and modern UX patterns.'),
            ],
          ),
          const Divider(),
          // Logout Button
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: OutlinedButton(
              onPressed: () async {
                // Clear all in-memory Provider state before sign out
                Provider.of<TransactionProvider>(context, listen: false).clearData();
                Provider.of<CategoryProvider>(context, listen: false).clearData();
                Provider.of<BudgetProvider>(context, listen: false).clearData();
                Provider.of<SavingsGoalProvider>(context, listen: false).clearData();
                Provider.of<NotificationProvider>(context, listen: false).clearData();

                await authProvider.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.login,
                    (route) => false,
                  );
                }
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }

  void _showFontSelectionDialog(BuildContext context, ThemeProvider themeProvider) {
    final fonts = ['Default', 'Roboto', 'Poppins', 'Montserrat', 'Lato'];
    showDialog(
      context: context,
      builder: (dialogCtx) {
        final theme = Theme.of(dialogCtx);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Select App Font', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: fonts.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final font = fonts[index];
                final isSelected = themeProvider.fontFamily == font;
                
                // Get custom text style for preview
                TextStyle fontStyle = const TextStyle(fontSize: 14);
                if (font != 'Default') {
                  try {
                    fontStyle = GoogleFonts.getFont(font, fontSize: 14);
                  } catch (_) {}
                }
                
                return ListTile(
                  title: Text(font, style: isSelected ? const TextStyle(fontWeight: FontWeight.bold) : null),
                  subtitle: Text(
                    'The quick brown fox jumps over the lazy dog',
                    style: fontStyle.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  ),
                  trailing: isSelected ? Icon(Icons.check_circle, color: theme.colorScheme.primary) : null,
                  onTap: () {
                    themeProvider.updateFontFamily(font);
                    Navigator.pop(dialogCtx);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Close', style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }
}
