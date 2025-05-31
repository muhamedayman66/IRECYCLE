import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/voucher_model.dart';
import '../utils/constants.dart';

class VoucherService {
  static const String _baseUrl = ApiConstants.baseUrl;

  // للمستخدم - إنشاء قسيمة جديدة
  Future<Map<String, dynamic>> generateVoucher(
      String email, double amount) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/generate_qr_code_for_user/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'amount': amount,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body)['error'];
      throw Exception(error ?? 'Failed to generate voucher');
    }
  }

  // للمستخدم - التحقق من حالة القسيمة
  Future<Map<String, dynamic>> checkVoucherStatus(String email) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/check_voucher_status/$email/'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to check voucher status');
    }
  }

  // للمستخدم - استخدام القسيمة
  Future<void> redeemVoucher(String email, int pointsToRedeem) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/use_qr_code/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'points_to_redeem': pointsToRedeem,
      }),
    );

    if (response.statusCode != 200) {
      final error = json.decode(response.body)['error'];
      throw Exception(error ?? 'Failed to redeem voucher');
    }
  }

  // لعمال التوصيل - مسح QR code القسيمة
  Future<VoucherModel> scanVoucherQR(
    String qrCode,
    String deliveryBoyId,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/vouchers/scan'),
      body: json.encode({'qrCode': qrCode, 'deliveryBoyId': deliveryBoyId}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return VoucherModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to scan voucher QR code');
    }
  }

  // للعملاء - الحصول على قائمة القسائم
  Future<List<VoucherModel>> getCustomerVouchers(String customerId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/vouchers/customer/$customerId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      List<dynamic> vouchersJson = json.decode(response.body);
      return vouchersJson.map((json) => VoucherModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to get customer vouchers');
    }
  }

  // للمستخدم - الحصول على معلومات النقاط والمكافآت
  Future<Map<String, dynamic>> getUserBalance(String email) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/user_balance/$email/'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get user balance');
    }
  }

  // للمستخدم - الحصول على سجل القسائم
  Future<List<Map<String, dynamic>>> getVoucherHistory(String email) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/qr_usage_history/$email/'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Failed to get voucher history');
    }
  }
}
