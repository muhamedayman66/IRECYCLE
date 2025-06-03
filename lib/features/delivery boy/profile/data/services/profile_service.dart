import 'dart:convert';
import 'dart:io';
import 'package:graduation_project11/core/api/api_constants.dart';
import 'package:http/http.dart' as http;

class DeliveryProfileService {
  static Future<Map<String, dynamic>> getProfile(String email) async {
    try {
      final queryParameters = {
        'email': email,
        'user_type': 'delivery_boy'
      };
      
      final uri = Uri.parse(ApiConstants.getUserProfile)
          .replace(queryParameters: queryParameters);

      print('Requesting profile from: $uri'); // Debug log

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      print('Response status: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to load profile: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error in getProfile: $e'); // Debug log
      throw Exception('Error getting profile: $e');
    }
  }

  static Future<bool> updateProfile({
    required String email,
    required String firstName,
    required String lastName,
    required String gender,
    required String dob,
    required String governorate,
    required String phone,
    File? profileImage,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/update_profile/'),
      );

      // Add text fields
      request.fields.addAll({
        'email': email,
        'user_type': 'delivery_boy',
        'first_name': firstName,
        'last_name': lastName,
        'gender': gender,
        'dob': dob,
        'governorate': governorate,
        'phone': phone,
      });

      // Add profile image if provided
      if (profileImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('profile_image', profileImage.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print(
        'Update profile response: ${response.statusCode} - ${response.body}',
      ); // Debug log

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['message'] == 'Profile updated successfully';
      } else {
        throw Exception(
          'Failed to update profile: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error updating profile: $e'); // Debug log
      throw Exception('Error updating profile: $e');
    }
  }
}
