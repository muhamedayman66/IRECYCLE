import 'package:flutter/material.dart';
import 'package:graduation_project11/core/themes/app__theme.dart';
import 'package:graduation_project11/core/widgets/custom_appbar.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../data/models/delivery_notification.dart';
import '../../data/services/delivery_notification_service.dart';

class DeliveryNotificationsScreen extends StatefulWidget {
  final String? email;
  const DeliveryNotificationsScreen({super.key, this.email});

  @override
  _DeliveryNotificationsScreenState createState() =>
      _DeliveryNotificationsScreenState();
}

class _DeliveryNotificationsScreenState
    extends State<DeliveryNotificationsScreen> {
  final DeliveryNotificationService _notificationService =
      DeliveryNotificationService();
  List<DeliveryNotification> notifications = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (widget.email == null) {
      setState(() {
        error = 'Email is required';
        isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final fetchedNotifications = await _notificationService.getNotifications(
        widget.email!,
      );

      if (mounted) {
        setState(() {
          notifications = fetchedNotifications;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoading = false;
        });
      }
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      setState(() {
        final index = notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          notifications[index].isRead = true;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error marking notification as read: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.light.colorScheme.secondary,
      appBar: CustomAppBar(
        title: 'Notifications',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: SafeArea(child: _buildContent()),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(child: Text(error!));
    }

    if (notifications.isEmpty) {
      return const Center(
        child: Text(
          'No notifications available',
          style: TextStyle(fontSize: 16, fontFamily: 'Roboto'),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationCard(notification);
      },
    );
  }

  Widget _buildNotificationCard(DeliveryNotification notification) {
    final DateTime notificationTime = DateTime.parse(notification.createdAt);
    final String timeAgo = timeago.format(notificationTime);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: notification.isRead ? Colors.white : Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(
          Icons.notifications,
          color: notification.isRead
              ? Colors.grey
              : AppTheme.light.colorScheme.primary,
        ),
        title: Text(
          notification.message,
          style: TextStyle(
            fontWeight:
                notification.isRead ? FontWeight.normal : FontWeight.bold,
            fontFamily: 'Roboto',
            color: AppTheme.light.colorScheme.primary,
          ),
        ),
        subtitle: Text(
          timeAgo,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontFamily: 'Roboto',
          ),
        ),
        trailing: !notification.isRead
            ? IconButton(
                icon: Icon(
                  Icons.mark_email_read,
                  color: AppTheme.light.colorScheme.primary,
                ),
                onPressed: () => _markAsRead(notification.id),
              )
            : null,
      ),
    );
  }
}
