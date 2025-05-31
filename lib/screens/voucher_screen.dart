import 'package:flutter/material.dart';
import '../core/services/voucher_service.dart';
import 'package:qr_flutter/qr_flutter.dart';

class VoucherScreen extends StatefulWidget {
  final String email;

  const VoucherScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<VoucherScreen> createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen> {
  final VoucherService _voucherService = VoucherService();
  final TextEditingController _pointsController = TextEditingController();
  Map<String, dynamic> _userBalance = {'points': 0, 'rewards': 0};
  Map<String, dynamic>? _activeVoucher;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final balance = await _voucherService.getUserBalance(widget.email);
      final voucherStatus =
          await _voucherService.checkVoucherStatus(widget.email);

      setState(() {
        _userBalance = balance;
        if (voucherStatus['has_active_voucher'] == true) {
          _activeVoucher = {
            'qr_code_url': voucherStatus['qr_code_url'],
            'amount': voucherStatus['voucher_amount'],
            'expiry': voucherStatus['voucher_expiry'],
          };
        } else {
          _activeVoucher = null;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateVoucher() async {
    if (_pointsController.text.isEmpty) return;

    final points = int.tryParse(_pointsController.text);
    if (points == null || points <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid number of points')),
      );
      return;
    }

    if (points > _userBalance['points']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient points')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final amount = points / 20; // 20 نقطة = 1 جنيه
      final result =
          await _voucherService.generateVoucher(widget.email, amount);
      _pointsController.clear();
      await _loadUserData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voucher generated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating voucher: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Vouchers'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text(
                            'Points',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_userBalance['points']}',
                            style: const TextStyle(fontSize: 24),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text(
                            'Rewards',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_userBalance['rewards']} EGP',
                            style: const TextStyle(fontSize: 24),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_activeVoucher == null) ...[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _pointsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Enter Points to Redeem',
                              border: OutlineInputBorder(),
                              helperText: '20 points = 1 EGP',
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _generateVoucher,
                          child: const Text('Generate'),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_activeVoucher!['qr_code_url'] != null)
                            QrImageView(
                              data: _activeVoucher!['qr_code_url'],
                              size: 200,
                            ),
                          const SizedBox(height: 16),
                          Text(
                            'Active Voucher: ${_activeVoucher!['amount']} EGP',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Expires: ${_activeVoucher!['expiry']}',
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  @override
  void dispose() {
    _pointsController.dispose();
    super.dispose();
  }
}
