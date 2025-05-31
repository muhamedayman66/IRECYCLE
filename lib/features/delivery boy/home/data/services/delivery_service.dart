import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:graduation_project11/core/api/api_constants.dart';
import '../models/delivery_dashboard.dart';

class DeliveryService {
  Future<DeliveryDashboard> getDashboardData(String email) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.deliveryDashboard(email)),
      );

      if (response.statusCode == 200) {
        print('Raw Dashboard Response: ${response.body}'); // Added logging
        final dashboardData = json.decode(response.body);

        // Get available orders count
        final ordersResponse = await http.get(
          Uri.parse(ApiConstants.availableOrders(email)),
        );

        if (ordersResponse.statusCode == 200) {
          final ordersList = json.decode(ordersResponse.body) as List;
          final availableOrdersCount = ordersList.length;

          // Get notifications
          final notificationsResponse = await http.get(
            Uri.parse(ApiConstants.deliveryNotifications(email)),
          );

          if (notificationsResponse.statusCode == 200) {
            final notifications =
                json.decode(notificationsResponse.body) as List;
            final hasUnread = notifications.any(
              (notification) => !(notification['is_read'] as bool),
            );

            // Combine all data
            dashboardData['available_orders'] = availableOrdersCount;
            dashboardData['has_unread_notifications'] = hasUnread;

            return DeliveryDashboard.fromJson(dashboardData);
          }
        }
      }

      throw Exception('Failed to load dashboard data');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
