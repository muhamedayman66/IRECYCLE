import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for input formatters
import 'package:graduation_project11/core/api/api_constants.dart';
import 'package:graduation_project11/core/themes/app__theme.dart';
import 'package:graduation_project11/core/utils/shared_keys.dart';
import 'package:graduation_project11/core/widgets/custom_appbar.dart';
import 'package:graduation_project11/features/delivery%20boy/home/presentation/screen/DeliveryHomeScreen.dart';
import 'package:graduation_project11/features/delivery%20boy/voucher/presentation/screen/delivery_qr_code_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class DeliveryVoucherScreen extends StatefulWidget {
  const DeliveryVoucherScreen({Key? key}) : super(key: key);

  @override
  State<DeliveryVoucherScreen> createState() => _DeliveryVoucherScreenState();
}

class _DeliveryVoucherScreenState extends State<DeliveryVoucherScreen> {
  final TextEditingController _amountController = TextEditingController();
  bool _isLoading = true;
  bool _isRequestInProgress = false;
  String? _userEmail;
  double _balance = 0.0;
  Map<String, dynamic>? _activeVoucher;
  bool _hasActiveQRCode = false;
  String? _qrCodeUrl;
  DateTime? _qrCodeExpiry;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString(SharedKeys.userEmail);

    if (email == null) {
      // ScaffoldMessenger.of(
      //   context,
      // ).showSnackBar(const SnackBar(content: Text("Please log in first")));
      return;
    }

    setState(() {
      _userEmail = email;
      _isLoading = true;
    });

    try {
      // Load balance first
      final balanceResponse = await http.get(
        Uri.parse(ApiConstants.deliveryDashboard(email)),
        headers: {'Content-Type': 'application/json'},
      );

      if (balanceResponse.statusCode == 200) {
        final data = json.decode(balanceResponse.body);
        setState(() {
          _balance = data['current_balance'].toDouble();
          if (data['active_voucher'] != null) {
            _activeVoucher = data['active_voucher'];
          }
        });
      }

      // Check for active QR code
      print('Checking for active QR code for email: $email');
      final qrResponse = await http.get(
        Uri.parse(ApiConstants.checkDeliveryVoucherStatus(email)),
        headers: {'Content-Type': 'application/json'},
      );

      print('QR Status Response Code: ${qrResponse.statusCode}');
      print('QR Status Response Body: ${qrResponse.body}');

      if (qrResponse.statusCode == 200) {
        final data = json.decode(qrResponse.body);
        print('Decoded QR Status Data: $data');
        setState(() {
          _hasActiveQRCode = data['has_active_voucher'] ?? false;
          print('_hasActiveQRCode set to: $_hasActiveQRCode');
          if (_hasActiveQRCode && data['active_voucher'] != null) {
            final activeVoucherData =
                data['active_voucher'] as Map<String, dynamic>;
            String? rawQrCodeUrl = activeVoucherData['qr_code_url'] as String?;
            String? expiryDateString =
                activeVoucherData['expires_at'] as String?;

            if (rawQrCodeUrl != null && rawQrCodeUrl.isNotEmpty) {
              if (rawQrCodeUrl.startsWith('http')) {
                _qrCodeUrl = rawQrCodeUrl;
              } else {
                _qrCodeUrl =
                    ApiConstants.baseUrl +
                    (rawQrCodeUrl.startsWith('/')
                        ? rawQrCodeUrl
                        : '/$rawQrCodeUrl');
              }
            } else {
              _qrCodeUrl = null;
            }

            if (expiryDateString != null) {
              _qrCodeExpiry = DateTime.parse(expiryDateString);
            } else {
              _qrCodeExpiry = null;
            }

            print('Raw QR Code URL from API: $rawQrCodeUrl');
            print('Processed _qrCodeUrl set to: $_qrCodeUrl');
            print('Expiry Date String from API: $expiryDateString');
            print('_qrCodeExpiry set to: $_qrCodeExpiry');
          } else {
            _qrCodeUrl = null;
            _qrCodeExpiry = null;
            print(
              'No active QR code found in API response or active_voucher data missing.',
            );
          }
        });
      } else {
        print('Failed to fetch QR status: ${qrResponse.statusCode}');
      }
    } catch (e) {
      print('Error loading user data or QR status: $e');
      // ScaffoldMessenger.of(
      //   context,
      // ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generateVoucher() async {
    if (_isRequestInProgress) {
      print('Request already in progress, returning...');
      return;
    }

    setState(() {
      _isRequestInProgress = true;
      _isLoading = true;
    });

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    http.Response? voucherResponse;

    try {
      if (_hasActiveQRCode) {
        throw Exception(
          'You have an active QR code that needs to be used or expire before generating a new voucher',
        );
      }

      if (_activeVoucher != null) {
        throw Exception(
          'You have an active voucher that needs to be used or expire before generating a new one',
        );
      }

      final String amountText = _amountController.text.trim();
      print('Amount text entered: $amountText');

      final double? amount = double.tryParse(amountText);
      print('Parsed amount: $amount');

      if (amountText.isEmpty || amount == null) {
        throw Exception('Please enter an amount.');
      }
      if (amount < 10) {
        throw Exception('Minimum voucher amount is 10 EGP.');
      }

      if (amount > _balance) {
        throw Exception(
          'The amount exceeds your current balance of ${_balance.toStringAsFixed(2)} EGP.',
        );
      }

      voucherResponse = await http.post(
        Uri.parse(ApiConstants.generateDeliveryBoyVoucher(_userEmail!)),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'amount': amount}),
      );

      print('Response status: ${voucherResponse.statusCode}');
      print('Response body: ${voucherResponse.body}');

      if (voucherResponse.statusCode == 200) {
        final responseData = json.decode(voucherResponse.body);
        final voucher = responseData['voucher'];
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => DeliveryQrCodeScreen(
                  code: voucher['code'],
                  amount: double.parse(voucher['amount'].toString()),
                  expiryDate: DateTime.parse(voucher['expires_at']),
                ),
          ),
        );
        // scaffoldMessenger.showSnackBar(
        //   const SnackBar(content: Text('Voucher generated successfully')),
        // );
      } else {
        final errorData = json.decode(voucherResponse.body);
        throw Exception(errorData['error'] ?? 'Failed to generate voucher');
      }
    } catch (e) {
      print('Error generating voucher: $e');
      // scaffoldMessenger.showSnackBar(
      //   SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      // );
    } finally {
      if (mounted) {
        setState(() {
          _isRequestInProgress = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const CustomAppBar(title: 'Voucher Generation'),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_hasActiveQRCode) ...[
                      Card(
                        elevation: 4,
                        color: theme.primaryColor,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text(
                                'Active QR Code Found',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'You have an active QR code that needs to be used or expire before generating a new voucher.',
                                style: const TextStyle(color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                              if (_qrCodeExpiry != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Expires on: ${DateFormat('MMM dd, yyyy hh:mm a').format(_qrCodeExpiry!)}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                              const SizedBox(height: 16),
                              if (_qrCodeUrl != null && _qrCodeUrl!.isNotEmpty)
                                Image.network(
                                  _qrCodeUrl!,
                                  height: 200,
                                  width: 200,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    print(
                                      'Error loading QR code image: $error',
                                    );
                                    return const Text(
                                      'Error loading QR code image.',
                                      style: TextStyle(color: Colors.white),
                                    );
                                  },
                                  loadingBuilder: (
                                    BuildContext context,
                                    Widget child,
                                    ImageChunkEvent? loadingProgress,
                                  ) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value:
                                            loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                                : null,
                                      ),
                                    );
                                  },
                                )
                              else
                                const Text(
                                  'QR code image not available.',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ] else if (_activeVoucher != null) ...[
                      Card(
                        elevation: 4,
                        color: theme.primaryColor,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text(
                                'Active Voucher Found',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'You have an active voucher (${_activeVoucher!['code']}) worth ${_activeVoucher!['amount']} EGP that needs to be used or expire before generating a new one.',
                                style: const TextStyle(color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Expires on: ${DateFormat('MMM dd, yyyy hh:mm a').format(DateTime.parse(_activeVoucher!['expires_at']))}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      // Balance Card
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.light.colorScheme.primary,
                                AppTheme.light.colorScheme.primary.withOpacity(
                                  0.8,
                                ),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text(
                                'Current Balance',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_balance.toStringAsFixed(2)} EGP',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Amount Input
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ], // Added
                        decoration: InputDecoration(
                          labelText: 'Enter Amount (EGP)',
                          hintText: 'Min 10 EGP', // Added hint
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.attach_money),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Generate Button
                      ElevatedButton(
                        onPressed: _generateVoucher,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Generate Voucher',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
