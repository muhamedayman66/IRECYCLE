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
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => DeliveryNotification.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load notifications: ${response.body}');
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
          'Failed to mark notification as read: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error marking notification as read: $e');
    }
  }
}
