import 'package:flutter/material.dart';
import 'package:graduation_project11/core/api/api_constants.dart';
import 'package:graduation_project11/core/utils/shared_keys.dart';
import 'package:graduation_project11/features/home/presentation/screen/home_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:graduation_project11/core/themes/app__theme.dart';
import 'package:graduation_project11/core/widgets/custom_appbar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // Added for date formatting

class QrCodeScreen extends StatefulWidget {
  final String
      code; // Changed from qrCodeUrl, this will be the voucher code itself
  final String amount;
  final String userEmail;
  final String?
      qrCodeUrl; // This is the URL to the QR image if backend provides it, otherwise we generate from 'code'
  final DateTime? voucherExpiryDate; // Changed from String? voucherExpiry

  const QrCodeScreen({
    Key? key,
    required this.code,
    required this.amount,
    required this.userEmail,
    this.qrCodeUrl,
    this.voucherExpiryDate,
  }) : super(key: key);

  @override
  State<QrCodeScreen> createState() => _QrCodeScreenState();
}

class _QrCodeScreenState extends State<QrCodeScreen> {
  bool _showQrCode = true; // To toggle between QR and code string
  // String? _effectiveQrData; // Data to be encoded in QR
  // bool isLoading = true; // Removed, as data is passed directly

  @override
  void initState() {
    super.initState();
    // _initializeQrData(); // No need to load, data is passed
  }

  // void _initializeQrData() {
  //   // If qrCodeUrl is provided and valid, it might mean the backend stores the QR image.
  //   // However, for consistency with DeliveryQrCodeScreen, we'll primarily use widget.code
  //   // to generate the QR on the fly. The qrCodeUrl prop might be for displaying an image if needed.
  //   _effectiveQrData = widget.code; // Always use the voucher code for QR generation
  //   setState(() {
  //     isLoading = false;
  //   });
  // }

  void _toggleView() {
    setState(() {
      _showQrCode = !_showQrCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = widget.voucherExpiryDate != null &&
        widget.voucherExpiryDate!.isBefore(DateTime.now());
    final remainingTime = widget.voucherExpiryDate?.difference(DateTime.now());

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
        return false;
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Voucher', // Kept original title
          leading:
              const SizedBox.shrink(), // Consistent with delivery QR screen
        ),
        body: Container(
          // Added gradient background like delivery QR screen
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                AppTheme.light.colorScheme.primary.withOpacity(0.1),
              ],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Amount Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.light.colorScheme.primary,
                            AppTheme.light.colorScheme.primary.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Voucher Amount",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${widget.amount} EGP", // Amount is already string
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Expiry Info
                  if (widget.voucherExpiryDate != null)
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(
                              isExpired ? Icons.timer_off : Icons.timer,
                              size: 24,
                              color: isExpired ? Colors.red : Colors.green,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isExpired ? "Expired" : "Valid until",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('MMM dd, yyyy HH:mm')
                                  .format(widget.voucherExpiryDate!),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isExpired ? Colors.red : Colors.black,
                              ),
                            ),
                            if (!isExpired && remainingTime != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                "Expires in: ${remainingTime.inHours}h ${remainingTime.inMinutes.remainder(60)}m",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // QR Code / Voucher Code Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _showQrCode ? "QR Code" : "Voucher Code",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.light.colorScheme.primary,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  _showQrCode ? Icons.numbers : Icons.qr_code,
                                  color: AppTheme.light.colorScheme.primary,
                                ),
                                onPressed: _toggleView,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (_showQrCode)
                            Container(
                              // Styling for QR code container
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: QrImageView(
                                data:
                                    widget.code, // Use the voucher code for QR
                                version: QrVersions.auto,
                                size: 200.0,
                                backgroundColor: Colors.white,
                              ),
                            )
                          else
                            Container(
                              // Styling for voucher code text
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: SelectableText(
                                widget.code,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ActionButton(
                        icon: Icons.copy,
                        label: 'Copy Code',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: widget.code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text("Voucher code copied to clipboard!"),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 20),
                      _ActionButton(
                        icon: Icons.share,
                        label: 'Share',
                        onPressed: () {
                          String shareText =
                              "Here is your voucher code: ${widget.code}\n"
                              "Amount: ${widget.amount} EGP";
                          if (widget.voucherExpiryDate != null) {
                            shareText +=
                                "\nValid until: ${DateFormat('MMM dd, yyyy HH:mm').format(widget.voucherExpiryDate!)}";
                          }
                          Share.share(shareText);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Home Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HomeScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.home, color: Colors.white),
                      label: const Text(
                        "Go to Home Page",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF2E8B57), // Same as delivery
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// _ActionButton widget (copied from DeliveryQrCodeScreen for consistency)
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppTheme.light.colorScheme.primary,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: AppTheme.light.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.light.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
