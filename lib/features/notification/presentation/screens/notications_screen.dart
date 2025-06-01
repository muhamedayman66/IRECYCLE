// ignore_for_file: library_private_types_in_public_api, avoid_print
import 'package:flutter/material.dart';
import 'package:graduation_project11/core/api/api_constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:timeago/timeago.dart' as timeago;
import 'package:graduation_project11/core/themes/app__theme.dart';
import 'package:graduation_project11/core/widgets/custom_appbar.dart';

// Model
class NotificationModel {
  final int id;
  final String message;
  final String createdAt;
  bool isRead; // عدّلنا isRead لتكون mutable

  NotificationModel({
    required this.id,
    required this.message,
    required this.createdAt,
    required this.isRead,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      message: json['message'],
      createdAt: json['created_at'],
      isRead: json['is_read'],
    );
  }
}

// Repository
class NotificationRepository {
  final String baseUrl = ApiConstants.baseUrl;

  Future<List<NotificationModel>> fetchNotifications(String email) async {
    final response = await http.get(
      Uri.parse(ApiConstants.notifications(email)),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => NotificationModel.fromJson(json)).toList();
    } else {
      throw Exception(
        'Failed to load notifications: ${utf8.decode(response.bodyBytes)}',
      );
    }
  }

  Future<void> markAsRead(int notificationId) async {
    final url = Uri.parse(ApiConstants.markNotificationAsRead(notificationId));
    print('Mark as read URL: $url'); // Log the URL
    final response = await http.post(url);
    print(
      'Response: ${response.statusCode} - ${response.body}',
    ); // Log the response

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to mark notification as read: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<void> clearAllNotifications(String email) async {
    final response = await http.delete(
      Uri.parse(ApiConstants.clearNotifications('$email')),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to clear notifications: ${response.body}');
    }
  }
}

// Use Cases
class GetNotificationsUseCase {
  final NotificationRepository repository;

  GetNotificationsUseCase(this.repository);

  Future<List<NotificationModel>> execute(String email) async {
    return await repository.fetchNotifications(email);
  }
}

class MarkNotificationAsReadUseCase {
  final NotificationRepository repository;

  MarkNotificationAsReadUseCase(this.repository);

  Future<void> execute(int notificationId) async {
    return await repository.markAsRead(notificationId);
  }
}

class ClearNotificationsUseCase {
  final NotificationRepository repository;

  ClearNotificationsUseCase(this.repository);

  Future<void> execute(String email) async {
    return await repository.clearAllNotifications(email);
  }
}

// Widgets
class NotificationHeader extends StatelessWidget {
  final bool hasNotifications;
  final VoidCallback onClear;

  const NotificationHeader({
    super.key,
    required this.hasNotifications,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Notifications',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        if (hasNotifications)
          TextButton(
            onPressed: onClear,
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
      ],
    );
  }
}

class NotificationTile extends StatefulWidget {
  final NotificationModel notification;
  final Function(int, bool) onMarkAsRead; // دالة لتحديث الحالة محليًا

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onMarkAsRead,
  });

  @override
  _NotificationTileState createState() => _NotificationTileState();
}

class _NotificationTileState extends State<NotificationTile> {
  late bool isRead;
  final MarkNotificationAsReadUseCase _markNotificationAsReadUseCase =
      MarkNotificationAsReadUseCase(NotificationRepository());

  @override
  void initState() {
    super.initState();
    isRead = widget.notification.isRead;
  }

  Future<void> markAsRead() async {
    // تحديث الحالة محليًا أولاً
    setState(() {
      isRead = true;
    });
    widget.onMarkAsRead(widget.notification.id, true);

    try {
      // إرسال طلب للـ backend
      await _markNotificationAsReadUseCase.execute(widget.notification.id);
    } catch (e) {
      // في حالة الفشل، نرجّع التغيير المحلي (rollback)
      setState(() {
        isRead = false;
      });
      widget.onMarkAsRead(widget.notification.id, false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking notification as read: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateTime notificationTime = DateTime.parse(
      widget.notification.createdAt,
    );
    final String timeAgo = timeago.format(notificationTime);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(
          Icons.notifications,
          color: isRead ? Colors.grey : Colors.green,
        ),
        title: Text(
          widget.notification.message,
          softWrap: true, // Ensure text wraps
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Text(timeAgo),
        trailing:
            isRead
                ? null
                : TextButton(
                  onPressed: markAsRead,
                  child: const Text('Mark as Read'),
                ),
      ),
    );
  }
}

// Main Screen
class NotificationScreen extends StatefulWidget {
  final String email;

  const NotificationScreen({super.key, required this.email});

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<NotificationModel> notifications = [];
  late final GetNotificationsUseCase _getNotificationsUseCase;
  late final ClearNotificationsUseCase _clearNotificationsUseCase;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _getNotificationsUseCase = GetNotificationsUseCase(
      NotificationRepository(),
    );
    _clearNotificationsUseCase = ClearNotificationsUseCase(
      NotificationRepository(),
    );
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    setState(() {
      isLoading = true;
    });
    try {
      List<NotificationModel> fetchedNotifications =
          await _getNotificationsUseCase.execute(widget.email);
      setState(() {
        notifications = fetchedNotifications;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching notifications: $e')),
      );
    }
  }

  Future<void> clearNotifications() async {
    try {
      await _clearNotificationsUseCase.execute(widget.email);
      setState(() {
        notifications.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications cleared')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error clearing notifications: $e')),
      );
    }
  }

  void updateNotificationReadStatus(int notificationId, bool isRead) {
    setState(() {
      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        notifications[index].isRead = isRead;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Notifications",
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined),
          color: AppTheme.light.colorScheme.secondary,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: fetchNotifications,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NotificationHeader(
                hasNotifications: notifications.isNotEmpty,
                onClear: clearNotifications,
              ),
              const SizedBox(height: 10),
              Expanded(
                child:
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _buildNotificationList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationList() {
    if (notifications.isEmpty) {
      return const Center(child: Text("No notifications available"));
    }

    return ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        return NotificationTile(
          notification: notifications[index],
          onMarkAsRead: updateNotificationReadStatus,
        );
      },
    );
  }
}
