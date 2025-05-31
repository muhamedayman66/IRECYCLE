import 'package:flutter/material.dart';
import 'package:graduation_project11/features/delivery%20boy/home/presentation/screen/DeliveryHomeScreen.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:graduation_project11/core/themes/app__theme.dart';
import 'package:graduation_project11/core/widgets/custom_appbar.dart';
import 'package:graduation_project11/features/home/presentation/screen/home_screen.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:graduation_project11/core/utils/shared_keys.dart';

class DeliveryQrCodeScreen extends StatefulWidget {
  final String code;
  final double amount;
  final DateTime expiryDate;

  const DeliveryQrCodeScreen({
    super.key,
    required this.code,
    required this.amount,
    required this.expiryDate,
  });

  @override
  State<DeliveryQrCodeScreen> createState() => _DeliveryQrCodeScreenState();
}

class _DeliveryQrCodeScreenState extends State<DeliveryQrCodeScreen> {
  bool _showQrCode = true;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userEmail = prefs.getString(SharedKeys.userEmail);
    });
  }

  void _toggleView() {
    setState(() {
      _showQrCode = !_showQrCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = widget.expiryDate.isBefore(DateTime.now());
    final remainingTime = widget.expiryDate.difference(DateTime.now());

    return WillPopScope(
      onWillPop: () async {
        if (_userEmail != null) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => DeliveryHomeScreen(email: _userEmail!)),
            (route) => false,
          );
        }
        return false;
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Delivery Voucher',
          leading: const SizedBox.shrink(),
        ),
        body: Container(
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
                            "${widget.amount.toStringAsFixed(2)} EGP",
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
                                .format(widget.expiryDate),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isExpired ? Colors.red : Colors.black,
                            ),
                          ),
                          if (!isExpired) ...[
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

                  // QR Code Card
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
                                data: widget.code,
                                version: QrVersions.auto,
                                size: 200.0,
                                backgroundColor: Colors.white,
                              ),
                            )
                          else
                            Container(
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
                        label: 'Copy',
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
                          Share.share(
                            "Here is your delivery voucher code: ${widget.code}\n"
                            "Amount: ${widget.amount.toStringAsFixed(2)} EGP\n"
                            "Valid until: ${DateFormat('MMM dd, yyyy HH:mm').format(widget.expiryDate)}",
                          );
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
                        if (_userEmail != null) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DeliveryHomeScreen(email: _userEmail!),
                            ),
                          );
                        }
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
                        backgroundColor: const Color(0xFF2E8B57),
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
