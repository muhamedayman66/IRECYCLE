// ignore_for_file: deprecated_member_use

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:graduation_project11/core/themes/app__theme.dart';
import 'package:graduation_project11/features/delivery%20boy/balance/presentation/screens/delivery_balance_screen.dart';
import 'package:graduation_project11/features/delivery%20boy/navigation%20bar/custom_delivery_bottomnavigationbar.dart';
import 'package:graduation_project11/features/delivery%20boy/notifications/presentation/screen/DeliveryNotificationsScreen.dart.dart';
import 'package:graduation_project11/features/delivery%20boy/orders/presentation/screen/DeliveryOrdersScreen.dart';
import 'package:graduation_project11/features/delivery%20boy/profile/presentation/screen/DeliveryProfileScreen.dart.dart';
import 'package:graduation_project11/features/delivery%20boy/voucher/presentation/screen/delivery_voucher_screen.dart';
import 'package:graduation_project11/features/stores/screen/stores_screen.dart';
import '../../data/models/delivery_dashboard.dart';
import '../../data/services/delivery_service.dart';

class DeliveryHomeScreen extends StatefulWidget {
  final String email;

  const DeliveryHomeScreen({super.key, required this.email});

  @override
  _DeliveryHomeScreenState createState() => _DeliveryHomeScreenState();
}

class _DeliveryHomeScreenState extends State<DeliveryHomeScreen> {
  int _currentIndex = 0;
  String? _email;

  @override
  void initState() {
    super.initState();
    print('DeliveryHomeScreen initialized with email: ${widget.email}');
    _email = widget.email;
  }

  List<Widget> _buildScreens() {
    print('Building screens with email: $_email');
    if (_email == null) {
      print('Email is null, showing loading screens');
      return [
        const Center(child: CircularProgressIndicator()),
        const Center(child: CircularProgressIndicator()),
        const Center(child: CircularProgressIndicator()),
        const Center(child: CircularProgressIndicator()),
        const Center(child: CircularProgressIndicator()),
      ];
    }

    print('Creating screens with email: $_email');
    return [
      DeliveryHomeScreenContent(
        email: _email!,
        onUserDataLoaded: (fName, lName, workArea) {
          // Mock callback for future use
        },
      ),
      DeliveryBalanceScreen(email: _email!),
      const StoresScreen(),
      DeliveryProfileScreen(email: _email!),
      DeliveryOrdersScreen(email: _email!),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.light.colorScheme.secondary,
      body: SafeArea(
        bottom: true,
        child: Stack(
          children: [
            _buildScreens()[_currentIndex],
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: DeliveryBottomNavBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DeliveryHomeScreenContent extends StatefulWidget {
  final String email;
  final Function(String?, String?, String?) onUserDataLoaded;

  const DeliveryHomeScreenContent({
    super.key,
    required this.email,
    required this.onUserDataLoaded,
  });

  @override
  State<DeliveryHomeScreenContent> createState() =>
      _DeliveryHomeScreenContentState();
}

class _DeliveryHomeScreenContentState extends State<DeliveryHomeScreenContent> {
  final DeliveryService _deliveryService = DeliveryService();
  DeliveryDashboard? _dashboardData;
  bool _isLoading = true;
  String? _error;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    loadDashboardData();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> loadDashboardData() async {
    if (_isDisposed) return;

    try {
      if (!mounted) return;

      setState(() {
        _isLoading = true;
        _error = null;
      });

      final data = await _deliveryService.getDashboardData(widget.email);

      if (_isDisposed || !mounted) return;

      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });

      widget.onUserDataLoaded(data.firstName, data.lastName, data.workArea);
    } catch (e) {
      if (_isDisposed || !mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.light.colorScheme.secondary,
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error loading data: $_error',
                        textAlign: TextAlign.center,
                      ),
                      ElevatedButton(
                        onPressed: loadDashboardData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
                : LayoutBuilder(
                  builder: (context, constraints) {
                    final maxHeight = constraints.maxHeight;
                    final maxWidth = constraints.maxWidth;
                    final padding = maxWidth * 0.04;
                    final fontScale = maxWidth / 400;

                    return Column(
                      children: [
                        _buildHeader(
                          context,
                          maxWidth,
                          maxHeight,
                          padding,
                          fontScale,
                        ),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: loadDashboardData,
                            child: ListView(
                              padding: EdgeInsets.only(bottom: maxHeight * 0.1),
                              children: [
                                SizedBox(height: maxHeight * 0.015),
                                _buildPointsCard(
                                  context,
                                  maxWidth,
                                  maxHeight,
                                  padding,
                                  fontScale,
                                ),
                                SizedBox(height: maxHeight * 0.015),
                                _buildQuickStats(
                                  context,
                                  maxWidth,
                                  maxHeight,
                                  padding,
                                  fontScale,
                                ),
                                SizedBox(height: maxHeight * 0.015),
                                _buildTipCard(
                                  context,
                                  maxWidth,
                                  maxHeight,
                                  padding,
                                  fontScale,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    double maxWidth,
    double maxHeight,
    double padding,
    double fontScale,
  ) {
    return Container(
      width: double.infinity,
      color: AppTheme.light.colorScheme.primary,
      padding: EdgeInsets.symmetric(
        vertical: maxHeight * 0.01,
        horizontal: padding,
      ),
      child: _buildTopBar(context, maxWidth, maxHeight, padding, fontScale),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    double maxWidth,
    double maxHeight,
    double padding,
    double fontScale,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(maxWidth * 0.03),
          margin: EdgeInsets.symmetric(vertical: maxHeight * 0.01),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Governorate',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14 * fontScale,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    Text(
                      capitalize(_dashboardData?.workArea),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18 * fontScale,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: maxHeight * 0.015),
        Row(
          children: [
            _buildUserInfo(maxWidth, maxHeight, fontScale),
            const Spacer(),
            Stack(
              children: [
                IconButton(
                  iconSize: 24 * fontScale,
                  padding: EdgeInsets.zero,
                  color: Colors.white,
                  onPressed: () {
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => DeliveryNotificationsScreen(
                                email: widget.email,
                              ),
                        ),
                      ).then((_) {
                        setState(() {
                          // Mock reset
                        });
                      });
                    }
                  },
                  icon: const Icon(Icons.notifications_none_outlined),
                ),
                if (_dashboardData?.hasUnreadNotifications ?? false)
                  Positioned(
                    right: maxWidth * 0.005,
                    top: maxWidth * 0.005,
                    child: Container(
                      width: 12 * fontScale,
                      height: 12 * fontScale,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserInfo(double maxWidth, double maxHeight, double fontScale) {
    String capitalize(String? s) =>
        (s?.isNotEmpty ?? false)
            ? '${s![0].toUpperCase()}${s.substring(1).toLowerCase()}'
            : 'Not Set';
    final String displayName =
        _dashboardData?.firstName != null && _dashboardData?.lastName != null
            ? '${capitalize(_dashboardData?.firstName)} ${capitalize(_dashboardData?.lastName)}'
            : 'User';

    return Row(
      children: [
        CircleAvatar(
          radius: maxWidth * 0.08,
          backgroundImage:
              _dashboardData?.profileImage != null
                  ? NetworkImage(_dashboardData!.profileImage!)
                  : null,
          backgroundColor: Colors.grey[200],
          child:
              _dashboardData?.profileImage == null
                  ? Icon(
                    Icons.person,
                    size: maxWidth * 0.08,
                    color: Colors.grey[600],
                  )
                  : null,
        ),
        SizedBox(width: maxWidth * 0.03),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HELLO,',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16 * fontScale,
                fontFamily: 'Roboto',
              ),
            ),
            Text(
              displayName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20 * fontScale,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
              ),
            ),
            SizedBox(height: maxHeight * 0.005),
          ],
        ),
      ],
    );
  }

  Widget _buildPointsCard(
    BuildContext context,
    double maxWidth,
    double maxHeight,
    double padding,
    double fontScale,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: padding),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: AppTheme.light.colorScheme.primary.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              flex: 7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(maxWidth * 0.015),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.light.colorScheme.primary.withOpacity(
                            0.1,
                          ),
                        ),
                        child: Icon(
                          Icons.stars,
                          color: AppTheme.light.colorScheme.primary,
                          size: 20 * fontScale,
                        ),
                      ),
                      SizedBox(width: maxWidth * 0.015),
                      Text(
                        "Your Points",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 17 * fontScale,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: maxHeight * 0.008),
                  Padding(
                    padding: EdgeInsets.only(left: maxWidth * 0.02),
                    child: Row(
                      children: [
                        Text(
                          "${_dashboardData?.totalPoints ?? 0}",
                          style: TextStyle(
                            color: AppTheme.light.colorScheme.primary,
                            fontSize: 26 * fontScale,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Roboto',
                          ),
                        ),
                        SizedBox(width: maxWidth * 0.015),
                        Text(
                          "POINTS",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14 * fontScale,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Roboto',
                          ),
                        ),
                        if (_dashboardData?.pointsToNextReward != null) ...[],
                      ],
                    ),
                  ),
                  SizedBox(height: maxHeight * 0.02),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(maxWidth * 0.01),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.light.colorScheme.primary.withOpacity(
                            0.1,
                          ),
                        ),
                        child: Icon(
                          Icons.monetization_on_outlined,
                          color: AppTheme.light.colorScheme.primary,
                          size: 14 * fontScale,
                        ),
                      ),
                      SizedBox(width: maxWidth * 0.01),
                      Text(
                        "Total Rewards",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11 * fontScale,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: maxHeight * 0.004),
                  Padding(
                    padding: EdgeInsets.only(left: maxWidth * 0.02),
                    child: Row(
                      children: [
                        Text(
                          "${((_dashboardData?.totalPoints ?? 0) / 20.0).toStringAsFixed(2)}",
                          style: TextStyle(
                            color: AppTheme.light.colorScheme.primary,
                            fontSize: 16 * fontScale,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Roboto',
                          ),
                        ),
                        SizedBox(width: maxWidth * 0.01),
                        Text(
                          "EGP",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11 * fontScale,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DeliveryVoucherScreen(),
                    ),
                  ).then((_) {
                    // This block executes when DeliveryVoucherScreen is popped.
                    if (mounted) {
                      // Check if the widget is still in the tree
                      loadDashboardData();
                    }
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.light.colorScheme.primary.withOpacity(0.09),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: EdgeInsets.symmetric(vertical: 25, horizontal: 5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.card_giftcard,
                        color: AppTheme.light.colorScheme.primary,
                        size: 45 * fontScale,
                      ),
                      SizedBox(height: maxHeight * 0.004),
                      Text(
                        "Voucher",
                        style: TextStyle(
                          fontSize: 12 * fontScale,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.light.colorScheme.primary,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(
    BuildContext context,
    double maxWidth,
    double maxHeight,
    double padding,
    double fontScale,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatCard(
            maxWidth,
            maxHeight,
            fontScale,
            "Orders Completed",
            "${_dashboardData?.totalOrders ?? 0}",
            Icons.check_circle,
            AppTheme.light.colorScheme.primary,
          ),
          _buildStatCard(
            maxWidth,
            maxHeight,
            fontScale,
            "Average Rating",
            "${_dashboardData?.averageRating?.toStringAsFixed(1) ?? 'N/A'}",
            Icons.star,
            AppTheme.light.colorScheme.primary,
          ),
          _buildStatCard(
            maxWidth,
            maxHeight,
            fontScale,
            "Available Orders",
            "${_dashboardData?.availableOrders ?? 0}",
            Icons.delivery_dining,
            AppTheme.light.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    double maxWidth,
    double maxHeight,
    double fontScale,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: maxWidth * 0.28,
      padding: EdgeInsets.all(maxWidth * 0.03),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(maxWidth * 0.02),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20 * fontScale, color: color),
          ),
          SizedBox(height: maxHeight * 0.01),
          Text(
            value,
            style: TextStyle(
              fontSize: 16 * fontScale,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Roboto',
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12 * fontScale,
              color: color,
              fontFamily: 'Roboto',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(
    BuildContext context,
    double maxWidth,
    double maxHeight,
    double padding,
    double fontScale,
  ) {
    final tips = [
      "Check order details carefully before accepting.",
      "Keep your work area updated for better order assignments.",
      "Maintain good communication with customers.",
      "Verify items accurately to avoid discrepancies.",
      "Aim for high ratings to earn more rewards.",
    ];
    final randomTip = tips[Random().nextInt(tips.length)];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: padding),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.light.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(maxWidth * 0.02),
            decoration: BoxDecoration(
              color: AppTheme.light.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lightbulb_outline,
              color: AppTheme.light.colorScheme.primary,
              size: 24 * fontScale,
            ),
          ),
          SizedBox(width: maxWidth * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Tip of the Day",
                  style: TextStyle(
                    color: AppTheme.light.colorScheme.primary,
                    fontSize: 14 * fontScale,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
                  ),
                ),
                SizedBox(height: maxHeight * 0.005),
                Text(
                  randomTip,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12 * fontScale,
                    fontFamily: 'Roboto',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String capitalize(String? s) =>
      (s?.isNotEmpty ?? false)
          ? '${s![0].toUpperCase()}${s.substring(1).toLowerCase()}'
          : 'Not Set';
}
