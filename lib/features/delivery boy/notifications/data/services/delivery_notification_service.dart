import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:graduation_project11/core/api/api_constants.dart';
import '../models/delivery_notification.dart';

class DeliveryNotificationService {
  Future<List<DeliveryNotification>> getNotifications(String email) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.deliveryNotifications(email)),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => DeliveryNotification.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load notifications: ${utf8.decode(response.bodyBytes)}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching notifications: $e');
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.markDeliveryNotificationAsRead(notificationId)),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to mark notification as read: ${utf8.decode(response.bodyBytes)}',
        );
      }
    } catch (e) {
      throw Exception('Error marking notification as read: $e');
    }
  }

  Future<void> clearAllNotifications(String email) async {
    try {
      final response = await http.delete(
        // Changed back to http.delete
        Uri.parse(ApiConstants.clearDeliveryNotifications(email)),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to clear all notifications: ${utf8.decode(response.bodyBytes)}',
        );
      }
    } catch (e) {
      throw Exception('Error clearing all notifications: $e');
    }
  }
}
