import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:graduation_project11/core/api/api_constants.dart';
import 'package:graduation_project11/core/themes/app__theme.dart';
import 'package:graduation_project11/core/widgets/custom_appbar.dart';
import 'package:graduation_project11/core/utils/shared_keys.dart';
import 'package:graduation_project11/features/balance/data/models/balance_model.dart';
import 'package:graduation_project11/features/balance/data/services/balance_service.dart';

class BalanceScreen extends StatefulWidget {
  final String? firstName;
  final String? lastName;

  const BalanceScreen({Key? key, this.firstName, this.lastName})
      : super(key: key);

  @override
  State<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends State<BalanceScreen> {
  final BalanceService _balanceService = BalanceService();

  BalanceModel? _balanceData;
  List<ActivityModel> _activities = [];
  List<ActivityModel> _filteredActivities = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  final List<String> allowedFilters = [
    'All',
    'Last 30 Days',
    'Last 60 Days',
    'Last 90 Days',
  ];
  String selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(SharedKeys.userEmail);
    print('Loading data for email: $email'); // Debug print

    if (email == null) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'User email not found.';
      });
      _showErrorSnackBar(_errorMessage);
      return;
    }

    try {
      final balanceData = await _balanceService.getBalance(email);
      print(
        'Balance data received: ${balanceData.points} points, ${balanceData.rewards} rewards',
      ); // Debug print

      final activities = await _balanceService.getActivities(email);
      print('Activities received: ${activities.length}'); // Debug print

      if (!mounted) return;

      setState(() {
        _balanceData = balanceData;
        _activities = activities;
        _filteredActivities = _applyTimeFilter(selectedFilter);
        _isLoading = false;
      });

      print(
        'State updated - Balance points: ${_balanceData?.points}, rewards: ${_balanceData?.rewards}',
      ); // Debug print
    } catch (e) {
      print('Error loading data: $e'); // Debug print
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
      _showErrorSnackBar(_errorMessage);
    }
  }

  List<ActivityModel> _applyTimeFilter(String filter) {
    final now = DateTime.now();
    return _activities.where((activity) {
      switch (filter) {
        case 'Last 30 Days':
          return activity.date.isAfter(now.subtract(const Duration(days: 30)));
        case 'Last 60 Days':
          return activity.date.isAfter(now.subtract(const Duration(days: 60)));
        case 'Last 90 Days':
          return activity.date.isAfter(now.subtract(const Duration(days: 90)));
        case 'All':
        default:
          return true;
      }
    }).toList();
  }

  void _onFilterChanged(String? value) {
    if (value != null) {
      setState(() {
        selectedFilter = value;
        _filteredActivities = _applyTimeFilter(value);
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final capitalize = (String? s) => (s?.isNotEmpty ?? false)
        ? '${s![0].toUpperCase()}${s.substring(1).toLowerCase()}'
        : '';
    final userFullName =
        '${capitalize(widget.firstName)} ${capitalize(widget.lastName)}';

    return Scaffold(
      backgroundColor: AppTheme.light.colorScheme.secondary,
      appBar: CustomAppBar(title: 'Balance'),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _hasError
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 60),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  AppTheme.light.colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Retry',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 17,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: "$userFullName's\n",
                                    style: TextStyle(
                                      fontSize: 22,
                                      color: AppTheme.light.colorScheme.primary,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Balance',
                                    style: TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.light.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          _buildBalanceCard(),
                          const SizedBox(height: 8),
                          _buildActivityHeader(),
                          const SizedBox(height: 10),
                          Expanded(
                            child: _filteredActivities.isEmpty
                                ? const Center(
                                    child: Text(
                                      "No activities for this period.",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _filteredActivities.length,
                                    itemBuilder: (context, index) {
                                      final item = _filteredActivities[index];
                                      final date = item.date;
                                      final localDate = date.toLocal();
                                      final formatted = DateFormat(
                                        'MMM d yyyy \'at\' h:mm a',
                                      ).format(localDate);

                                      String displayPoints = '';
                                      Color pointsColor;
                                      Widget valueWidget;

                                      if (item.type == 'redeem' &&
                                          item.voucherAmount != null) {
                                        // Handle voucher redemption specifically
                                        displayPoints =
                                            '-${item.voucherAmount!.toStringAsFixed(0)}'; // Show EGP amount
                                        pointsColor = const Color(
                                            0xFFE53935); // Red color for deduction
                                        valueWidget = Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              displayPoints,
                                              style: TextStyle(
                                                color: pointsColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              "EGP", // Label as EGP
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: pointsColor,
                                              ),
                                            ),
                                          ],
                                        );
                                      } else if (item.points > 0) {
                                        displayPoints = '+${item.points}';
                                        pointsColor = const Color(
                                            0xFF328957); // Green color
                                        valueWidget = Row(
                                          children: [
                                            Image.asset(
                                              'assets/icons/points.jpeg',
                                              width: 16,
                                              height: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              displayPoints,
                                              style: TextStyle(
                                                color: pointsColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              "POINTS",
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: pointsColor,
                                              ),
                                            ),
                                          ],
                                        );
                                      } else if (item.points < 0) {
                                        // For other negative point activities (if any)
                                        displayPoints = '${item.points}';
                                        pointsColor = const Color(
                                            0xFFE53935); // Red color
                                        valueWidget = Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Image.asset(
                                              'assets/icons/points.jpeg',
                                              width: 16,
                                              height: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              displayPoints,
                                              style: TextStyle(
                                                color: pointsColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              "POINTS",
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: pointsColor,
                                              ),
                                            ),
                                          ],
                                        );
                                      } else {
                                        // item.points == 0
                                        displayPoints = item.points.toString();
                                        pointsColor = Colors.grey;
                                        valueWidget = Row(
                                          children: [
                                            Image.asset(
                                              'assets/icons/points.jpeg',
                                              width: 16,
                                              height: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              displayPoints,
                                              style: TextStyle(
                                                color: pointsColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              "POINTS",
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: pointsColor,
                                              ),
                                            ),
                                          ],
                                        );
                                      }

                                      return Card(
                                        elevation: 2,
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 6,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item.title,
                                                      style: TextStyle(
                                                        color: AppTheme
                                                            .light
                                                            .colorScheme
                                                            .primary,
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      formatted,
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              valueWidget,
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          const SizedBox(height: 15),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    final points = _balanceData?.points ?? 0;
    final rewards = _balanceData?.rewards ?? 0;

    print(
      'Building balance card - Points: $points, Rewards: $rewards',
    ); // Debug print

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("POINTS", style: _sectionTitleStyle()),
            const SizedBox(height: 10),
            Row(
              children: [
                Image.asset('assets/icons/points.jpeg', width: 16, height: 16),
                const SizedBox(width: 4),
                Text(points.toString(), style: _boldTextStyle()),
                const SizedBox(width: 4),
                const Text("POINTS", style: TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 16),
            Divider(
              height: 1,
              thickness: 1,
              color: AppTheme.light.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text("REWARDS", style: _sectionTitleStyle()),
            const SizedBox(height: 10),
            Row(
              children: [
                Image.asset('assets/icons/rewards.png', width: 16, height: 16),
                const SizedBox(width: 4),
                Text(rewards.toString(), style: _boldTextStyle()),
                const SizedBox(width: 4),
                const Text("EGP", style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.history, color: AppTheme.light.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              "Last Activity",
              style: TextStyle(
                color: AppTheme.light.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        DropdownButton<String>(
          value: selectedFilter,
          items: allowedFilters
              .map((f) => DropdownMenuItem(value: f, child: Text(f)))
              .toList(),
          onChanged: _onFilterChanged,
          style: TextStyle(
            color: AppTheme.light.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
          underline: Container(),
          icon: Icon(
            Icons.filter_list,
            color: AppTheme.light.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  TextStyle _sectionTitleStyle() => TextStyle(
        color: AppTheme.light.colorScheme.primary,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      );

  TextStyle _boldTextStyle() => TextStyle(
        color: AppTheme.light.colorScheme.primary,
        fontSize: 15,
        fontWeight: FontWeight.bold,
      );
}
