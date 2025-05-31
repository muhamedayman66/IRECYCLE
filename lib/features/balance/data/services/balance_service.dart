import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:graduation_project11/core/api/api_constants.dart';
import 'package:graduation_project11/features/balance/data/models/balance_model.dart';

class BalanceService {
  Future<BalanceModel> getBalance(String email) async {
    try {
      final url = ApiConstants.userBalance(email);
      print('Fetching balance from URL: $url'); // Debug print

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
      );

      print(
        'Balance API Response Status Code: ${response.statusCode}',
      ); // Debug print
      print('Balance API Response Body: ${response.body}'); // Debug print

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('Decoded balance data: $data'); // Debug print
        final balance = BalanceModel.fromJson(data);
        print(
          'Parsed balance model: points=${balance.points}, rewards=${balance.rewards}',
        ); // Debug print
        return balance;
      } else {
        throw Exception(
          'Failed to load balance: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e, stackTrace) {
      print('Error in getBalance: $e'); // Debug print
      print('Stack trace: $stackTrace'); // Debug print
      rethrow;
    }
  }

  Future<List<ActivityModel>> getActivities(String email) async {
    try {
      final url = ApiConstants.activities(email);
      print('Fetching activities from URL: $url'); // Debug print

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
      );

      print(
        'Activities API Response Status Code: ${response.statusCode}',
      ); // Debug print
      print('Activities API Response Body: ${response.body}'); // Debug print

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        print('Decoded activities data: $data'); // Debug print
        final activities =
            data.map((json) => ActivityModel.fromJson(json)).toList();
        print('Parsed ${activities.length} activities'); // Debug print
        return activities;
      } else {
        throw Exception(
          'Failed to load activities: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e, stackTrace) {
      print('Error in getActivities: $e'); // Debug print
      print('Stack trace: $stackTrace'); // Debug print
      rethrow;
    }
  }
}
