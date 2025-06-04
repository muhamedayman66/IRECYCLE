import 'package:flutter/material.dart';
import 'package:graduation_project11/core/themes/app__theme.dart';
import 'package:graduation_project11/features/notification/data/models/notification_model.dart';

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;

  const NotificationTile({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.light.colorScheme.primary,
        child: Icon(Icons.notifications, color: Colors.white),
      ),
      title: Text(
        notification.title,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(notification.subtitle),
      trailing: Text(notification.time, style: TextStyle(color: Colors.grey)),
    );
  }
}
