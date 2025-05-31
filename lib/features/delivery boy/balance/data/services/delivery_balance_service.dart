import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:graduation_project11/core/api/api_constants.dart';

class DeliveryBalanceService {
  Future<Map<String, dynamic>> getBalanceData(String email) async {
    try {
      print('Fetching balance data for email: $email'); // Debug print
      final uri = Uri.parse(ApiConstants.deliveryDashboard(email));
      print('Request URI: $uri'); // Debug print

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      print('API Response Status Code: ${response.statusCode}'); // Debug print
      print('API Response Body: ${response.body}'); // Debug print

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Convert activities to the correct format
        final activities =
            (data['recent_activities'] as List?)?.map((activity) {
                  return {
                    'type': 'delivery',
                    'description': 'Order #${activity['order_id']} delivered',
                    'points_earned': activity['points_earned'],
                    'date': activity['date'],
                  };
                }).toList() ??
                [];

        return {
          'points': data['total_points'] ?? 0,
          'rewards': (data['current_balance'] ?? 0.0).toDouble(),
          'activities': activities,
          'first_name': data['first_name'] ?? '',
          'last_name': data['last_name'] ?? '',
          'next_reward_amount': (data['next_reward_amount'] ?? 0.0).toDouble(),
        };
      } else if (response.statusCode == 404) {
        throw Exception(
          'Delivery Boy not found. Please check your email address.',
        );
      } else {
        throw Exception(
          'Failed to load balance data. Status code: ${response.statusCode}, Body: ${response.body}',
        );
      }
    } catch (e) {
      print('Error in getBalanceData: $e'); // Debug print
      if (e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Network is unreachable')) {
        throw Exception(
          'Network error. Please check your internet connection.',
        );
      }
      throw Exception('Failed to load balance data: $e');
    }
  }

  Future<void> redeemPoints(String email, int points) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/delivery/redeem_points/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'points': points}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to redeem points: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error redeeming points: $e');
    }
  }
}
