import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<NotificationProvider>(context);
    final notifications = provider.notifications;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notifications.any((n) => !n.isRead))
            TextButton.icon(
              onPressed: () async {
                await provider.markAllAsRead();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All notifications marked as read')),
                  );
                }
              },
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('Mark all read'),
              style: TextButton.styleFrom(
                foregroundColor: theme.brightness == Brightness.dark
                    ? theme.colorScheme.primary
                    : const Color(0xFF200E26),
              ),
            ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? _buildEmptyState(theme)
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    return _buildNotificationCard(context, notif, provider, theme);
                  },
                ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Icon(
              Icons.notifications_none_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No notifications yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We will notify you here when budget limits are reached or logging reminders fire.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    NotificationModel notif,
    NotificationProvider provider,
    ThemeData theme,
  ) {
    final textColor = theme.colorScheme.onSurface;
    final cardColor = theme.colorScheme.surface;
    final formattedTime = DateFormat('MMM d, h:mm a').format(notif.timestamp);

    return InkWell(
      onTap: () {
        if (!notif.isRead) {
          provider.markAsRead(notif.id);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notif.isRead ? cardColor : cardColor.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notif.isRead
                ? theme.colorScheme.outline.withOpacity(0.08)
                : theme.colorScheme.primary.withOpacity(0.2),
            width: notif.isRead ? 1 : 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: notif.title.contains('🚨') || notif.title.contains('Budget Exceeded')
                    ? const Color(0xFFFEEFEE) // Red for budget alert
                    : notif.title.contains('📝') || notif.title.contains('Reminder')
                        ? const Color(0xFFE2F6F5) // Blue for reminder
                        : theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                notif.title.contains('🚨') || notif.title.contains('Budget Exceeded')
                    ? Icons.error_outline
                    : notif.title.contains('📝') || notif.title.contains('Reminder')
                        ? Icons.edit_note
                        : Icons.notifications_active_outlined,
                color: notif.title.contains('🚨') || notif.title.contains('Budget Exceeded')
                    ? const Color(0xFFEF4444)
                    : notif.title.contains('📝') || notif.title.contains('Reminder')
                        ? const Color(0xFF14B8A6)
                        : theme.colorScheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: TextStyle(
                            fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                            fontSize: 14,
                            color: textColor,
                          ),
                        ),
                      ),
                      if (!notif.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notif.body,
                    style: TextStyle(
                      fontSize: 13,
                      color: textColor.withOpacity(0.7),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formattedTime,
                    style: TextStyle(
                      fontSize: 11,
                      color: textColor.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
