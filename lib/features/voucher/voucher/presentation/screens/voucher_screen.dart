import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:graduation_project11/core/api/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Added for date formatting
import 'qr_code_screen.dart';
import 'package:graduation_project11/core/themes/app__theme.dart';
import 'package:graduation_project11/core/widgets/custom_appbar.dart';
import 'package:graduation_project11/core/utils/shared_keys.dart';

class VoucherScreen extends StatefulWidget {
  const VoucherScreen({super.key});

  @override
  _VoucherScreenState createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen> {
  final TextEditingController _amountController = TextEditingController();
  bool _isLoading = true; // Changed initial state to true
  bool _isRequestInProgress = false;
  int _rewardBalance = 0;
  String? _userEmail;
  // int _maxAllowedAmount = 0; // This seems to be same as _rewardBalance
  bool _hasActiveVoucher = false;
  String? _activeVoucherQrCodeUrl;
  double? _activeVoucherAmount;
  DateTime? _activeVoucherExpiryDate;
  String? _activeVoucherCode; // To store the voucher code if available

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString(SharedKeys.userEmail);

    if (email == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please log in first")));
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _userEmail = email;
      _isLoading = true; // Set loading true at the start of data fetching
    });

    try {
      // Check voucher status
      print('Fetching voucher status for $email');
      final voucherResponse = await http.get(
        Uri.parse(ApiConstants.checkVoucherStatus(email)),
        headers: {'Content-Type': 'application/json'},
      );

      print(
        'Voucher Response: ${voucherResponse.statusCode} - ${voucherResponse.body}',
      );
      if (voucherResponse.statusCode == 200) {
        final voucherData = json.decode(voucherResponse.body);
        print('Voucher Data: $voucherData');
        if (voucherData['has_active_voucher'] == true &&
            voucherData['active_voucher'] != null) {
          final activeVoucher = voucherData['active_voucher'];
          String? rawQrCodeUrl = activeVoucher['qr_code_url'] as String?;
          String? expiryDateString = activeVoucher['expires_at'] as String?;

          setState(() {
            _hasActiveVoucher = true;
            _activeVoucherAmount =
                double.tryParse(activeVoucher['amount'].toString());
            _activeVoucherCode = activeVoucher['code']
                as String?; // Assuming 'code' is part of active_voucher

            if (rawQrCodeUrl != null && rawQrCodeUrl.isNotEmpty) {
              if (rawQrCodeUrl.startsWith('http')) {
                _activeVoucherQrCodeUrl = rawQrCodeUrl;
              } else {
                _activeVoucherQrCodeUrl = ApiConstants.baseUrl +
                    (rawQrCodeUrl.startsWith('/')
                        ? rawQrCodeUrl
                        : '/$rawQrCodeUrl');
              }
            } else {
              _activeVoucherQrCodeUrl = null;
            }

            if (expiryDateString != null) {
              _activeVoucherExpiryDate = DateTime.tryParse(expiryDateString);
            } else {
              _activeVoucherExpiryDate = null;
            }
          });
        } else {
          setState(() {
            _hasActiveVoucher = false;
            _activeVoucherQrCodeUrl = null;
            _activeVoucherAmount = null;
            _activeVoucherExpiryDate = null;
            _activeVoucherCode = null;
          });
          print('No active voucher: ${voucherData['message']}');
        }
      } else {
        setState(() {
          _hasActiveVoucher = false;
        });
        print(
          // Changed from throw to print to allow balance loading
          'Failed to load voucher status: ${voucherResponse.statusCode} - ${voucherResponse.body}',
        );
      }

      // Load balance
      print('Fetching balance for $email');
      final balanceResponse = await http.get(
        Uri.parse(ApiConstants.userBalance(email)),
        headers: {'Content-Type': 'application/json'},
      );

      print(
        'Balance Response: ${balanceResponse.statusCode} - ${balanceResponse.body}',
      );
      if (balanceResponse.statusCode == 200) {
        final balanceData = json.decode(balanceResponse.body);
        print('Balance Data: $balanceData');
        final int points = balanceData['points'] ?? 0;
        final int rewards = balanceData['rewards'] ?? 0;

        await prefs.setInt('${email}_points', points);
        await prefs.setInt(SharedKeys.balanceKey(email), rewards);

        setState(() {
          _rewardBalance = rewards >= 0 ? rewards : 0;
          // _maxAllowedAmount = rewards >= 0 ? rewards : 0;
        });
      } else {
        throw Exception(
          'Failed to load balance: ${balanceResponse.statusCode} - ${balanceResponse.body}',
        );
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(
            content: Text(
                "Error loading data: ${e.toString().replaceAll('Exception: ', '')}")));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _generateVoucher() async {
    if (_isRequestInProgress) {
      print('Request blocked: Previous request still in progress');
      return;
    }

    setState(() {
      _isRequestInProgress = true;
      _isLoading = true;
    });

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    http.Response? qrResponse;

    try {
      if (_hasActiveVoucher) {
        // Check if there's already an active voucher
        throw Exception(
            'You have an active voucher that needs to be used or expire before generating a new one');
      }

      final String amountText = _amountController.text.trim();
      final int? amount = int.tryParse(amountText);

      if (amountText.isEmpty || amount == null || amount < 10) {
        throw Exception("Please enter an amount of at least 10 EGP");
      }

      if (amount > _rewardBalance) {
        throw Exception("The maximum allowed amount is $_rewardBalance EGP");
      }

      if (_userEmail == null || _userEmail!.isEmpty) {
        throw Exception("Please log in first");
      }

      final requestBody = {'email': _userEmail, 'amount': amount};
      print(
        'Sending request to generate QR: $requestBody at: ${DateTime.now().toUtc()}',
      );

      qrResponse = await http
          .post(
        Uri.parse(ApiConstants.generateQr), // User's endpoint
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      )
          .timeout(
        const Duration(seconds: 20), // Increased timeout
        onTimeout: () {
          throw Exception('Request timed out. Please try again.');
        },
      );

      print(
        'QR Response received at: ${DateTime.now().toUtc()} - Status: ${qrResponse.statusCode} - Body: ${qrResponse.body}',
      );

      if (qrResponse.statusCode == 200) {
        final responseData = json.decode(qrResponse.body);
        // Assuming responseData contains 'voucher' map with 'code', 'amount', 'expires_at', 'qr_code_url'
        final voucher = responseData['voucher'];
        final String newVoucherCode = voucher['code'];
        final double newVoucherAmount =
            double.parse(voucher['amount'].toString());
        final DateTime newVoucherExpiry = DateTime.parse(voucher['expires_at']);
        String? newQrCodeUrl = voucher['qr_code_url'];

        if (newQrCodeUrl != null && newQrCodeUrl.isNotEmpty) {
          if (!newQrCodeUrl.startsWith('http')) {
            newQrCodeUrl = ApiConstants.baseUrl +
                (newQrCodeUrl.startsWith('/')
                    ? newQrCodeUrl
                    : '/$newQrCodeUrl');
          }
        }

        // Update balance using remaining_rewards from API response
        final int newRewards = responseData['remaining_rewards'] ??
            _rewardBalance; // Use remaining_rewards
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(SharedKeys.balanceKey(_userEmail!),
            newRewards); // Persist new balance

        setState(() {
          // Update UI state
          _rewardBalance = newRewards;
          // _hasActiveVoucher will be true upon navigating to QrCodeScreen and returning,
          // or on next _loadUserData call.
          // For immediate UI update if staying on this screen (though we navigate away):
          // _hasActiveVoucher = true;
          // _activeVoucherCode = newVoucherCode;
          // _activeVoucherAmount = newVoucherAmount;
          // _activeVoucherExpiryDate = newVoucherExpiry;
          // _activeVoucherQrCodeUrl = newQrCodeUrl;
        });

        // Navigate to QrCodeScreen
        Navigator.pushReplacement(
          // Using pushReplacement as in delivery_voucher_screen
          context,
          MaterialPageRoute(
            builder: (context) => QrCodeScreen(
              // Pass data similar to DeliveryQrCodeScreen
              code: newVoucherCode, // Pass the code
              amount:
                  newVoucherAmount.toString(), // QrCodeScreen expects String
              userEmail: _userEmail!,
              qrCodeUrl: newQrCodeUrl, // Pass the direct QR URL
              voucherExpiryDate: newVoucherExpiry, // Pass DateTime object
            ),
          ),
        );
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Voucher generated successfully')),
        );
      } else {
        final errorData = json.decode(qrResponse.body);
        throw Exception(errorData['error'] ?? 'Failed to generate voucher');
      }
    } catch (e) {
      print(
        'Error generating voucher at: ${DateTime.now().toUtc()} - Error: $e',
      );
      scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRequestInProgress = false;
        });
      }
      print('Finished voucher generation at: ${DateTime.now().toUtc()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Voucher', // Kept original title
        leading: IconButton(
          // Kept original back button
          icon: const Icon(Icons.arrow_back_ios_new_outlined),
          color: AppTheme.light.colorScheme.secondary,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_hasActiveVoucher) ...[
                    Card(
                      elevation: 4,
                      color: theme.primaryColor, // Using theme.primaryColor
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              'Active Voucher Found', // Changed text
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (_activeVoucherAmount != null)
                              Text(
                                'Amount: ${_activeVoucherAmount!.toStringAsFixed(2)} EGP',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                            if (_activeVoucherCode != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Code: ${_activeVoucherCode!}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                            ],
                            const SizedBox(height: 8),
                            if (_activeVoucherExpiryDate != null)
                              Text(
                                'Expires on: ${DateFormat('MMM dd, yyyy hh:mm a').format(_activeVoucherExpiryDate!)}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            const SizedBox(height: 16),
                            if (_activeVoucherQrCodeUrl != null &&
                                _activeVoucherQrCodeUrl!.isNotEmpty)
                              Image.network(
                                _activeVoucherQrCodeUrl!,
                                height: 150, // Adjusted size
                                width: 150, // Adjusted size
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  print('Error loading QR code image: $error');
                                  return const Text(
                                    'Error loading QR code image.',
                                    style: TextStyle(color: Colors.white),
                                  );
                                },
                                loadingBuilder: (BuildContext context,
                                    Widget child,
                                    ImageChunkEvent? loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
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
                                    fontStyle: FontStyle.italic),
                              ),
                            const SizedBox(height: 16),
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
                          borderRadius: BorderRadius.circular(
                              15), // Added for consistency
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.light.colorScheme.primary,
                              AppTheme.light.colorScheme.primary
                                  .withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              'Current Reward Balance', // Changed text
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_rewardBalance.toStringAsFixed(0)} EGP', // User balance is int
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
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Enter Amount (EGP)',
                        hintText: 'Min 10 EGP, Max $_rewardBalance EGP',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.attach_money),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Generate Button
                    ElevatedButton(
                      onPressed: _isRequestInProgress ? null : _generateVoucher,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            AppTheme.light.colorScheme.primary, // Added style
                        foregroundColor: Colors.white, // Added style
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        disabledBackgroundColor:
                            AppTheme.light.colorScheme.primary.withOpacity(0.7),
                      ),
                      child: _isRequestInProgress
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Generate Voucher', // Changed text
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
