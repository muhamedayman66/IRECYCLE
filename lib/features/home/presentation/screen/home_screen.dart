// ignore_for_file: library_private_types_in_public_api, deprecated_member_use, use_build_context_synchronously

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:graduation_project11/core/api/api_constants.dart';
import 'package:graduation_project11/core/themes/app__theme.dart';
import 'package:graduation_project11/core/widgets/custom_bottomnavigationbar.dart';
import 'package:graduation_project11/features/balance/presentation/screens/balance_screen.dart';
import 'package:graduation_project11/features/categories/cans/screens/cans_screen.dart';
import 'package:graduation_project11/features/categories/glass/screens/glass_screen.dart';
import 'package:graduation_project11/features/categories/plastic/screens/plastic_screen.dart';
import 'package:graduation_project11/features/notification/presentation/screens/notications_screen.dart';
import 'package:graduation_project11/features/profile/presentation/screen/profile_screen.dart';
import 'package:graduation_project11/features/recycling/presentation/screens/scan_screen.dart';
import 'package:graduation_project11/features/stores/screen/stores_screen.dart';
import 'package:graduation_project11/features/recycling/presentation/screens/recycle_bag_screen.dart';
import 'package:graduation_project11/core/utils/shared_keys.dart';
import 'package:graduation_project11/features/voucher/voucher/presentation/screens/voucher_screen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:logger/logger.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String? _firstName;
  String? _lastName;
  String? _email;

  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _email = prefs.getString(SharedKeys.userEmail);
    });
  }

  List<Widget> _buildScreens() {
    if (_email == null) {
      return [
        const Center(child: CircularProgressIndicator()),
        const Center(child: CircularProgressIndicator()),
        const Center(child: CircularProgressIndicator()),
        const Center(child: CircularProgressIndicator()),
        const Center(child: CircularProgressIndicator()),
      ];
    }

    return [
      HomeScreenContent(
        email: _email!,
        onUserDataLoaded: (fName, lName, imgUrl) {
          setState(() {
            _firstName = fName;
            _lastName = lName;
          });
        },
      ),
      BalanceScreen(firstName: _firstName, lastName: _lastName),
      StoresScreen(), // Fixed: Replaced SizedBox with StoresScreen
      ProfileScreen(email: _email!), // Fixed: Correct index for ProfileScreen
      const ScanScreen(), // Added ScanScreen for the scan button
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: true,
        child: Stack(
          children: [
            _buildScreens()[_currentIndex],
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: BottomNavBar(
                currentIndex: _currentIndex,
                onTap: (index) async {
                  if (index != _currentIndex && index != 0) {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool(SharedKeys.lastTransactionShown, true);
                    Logger().i(
                      'Marked lastTransaction as shown due to navigation',
                    );
                  }
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

class HomeScreenContent extends StatefulWidget {
  final String email;
  final Function(String?, String?, String?) onUserDataLoaded;

  const HomeScreenContent({
    super.key,
    required this.email,
    required this.onUserDataLoaded,
  });

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  int? rewards = 0;
  int? points = 0;
  int? itemsRecycled = 0;
  double? co2Saved = 0.0;
  bool hasItemsInBag = false;
  bool hasUnreadNotifications = false;
  String? firstName;
  String? lastName;
  String? profileImageUrl;
  String? userAddress;
  int? lastEarnedPoints;

  late final GetNotificationsUseCase _getNotificationsUseCase;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadRewardAndPoints(),
      _loadTotalRecycledItems(),
      _checkRecycleBag(),
      _loadUserData(),
      _loadUserAddress(),
      _setUserAddressFromLocation(),
      _checkUnreadNotifications(),
    ]);
  }

  Future<void> _updateStats() async {
    print('تحديث الإحصائيات...');
    await Future.wait([_loadRewardAndPoints(), _loadTotalRecycledItems()]);
    print(
      'تم تحديث الإحصائيات - النقاط: $points، المكافآت: $rewards، العناصر المعاد تدويرها: $itemsRecycled، CO2: $co2Saved',
    );
  }

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _loadUserData() async {
    final String apiUrl =
        '${ApiConstants.getUserProfile}?email=${widget.email}&user_type=regular_user';
    try {
      final token = await _getAuthToken();
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            firstName = data['first_name'];
            lastName = data['last_name'];
            profileImageUrl = data['profile_image'];
          });
        }
        widget.onUserDataLoaded(firstName, lastName, profileImageUrl);
      } else {
        Logger().e('Failed to load user data: ${response.body}');
      }
    } catch (e) {
      Logger().e('Error loading user data: $e');
    }
  }

  Future<void> _loadRewardAndPoints() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      print('Loading rewards and points for user: ${widget.email}');
      final token = await _getAuthToken();
      final response = await http.get(
        Uri.parse(ApiConstants.userBalance(widget.email)),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      print('Balance API response status: ${response.statusCode}');
      print('Balance API response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final int points = data['points'] ?? 0;
        final int rewards = data['rewards'] ?? 0;
        final lastActivity = data['last_activity'];
        print(
          'Parsed data: points=$points, rewards=$rewards, lastActivity=$lastActivity',
        );

        if (lastActivity != null && lastActivity['type'] == 'delivered') {
          lastEarnedPoints = lastActivity['points'];
          print('Last earned points: $lastEarnedPoints');
        }

        await prefs.setInt(SharedKeys.pointsKey(widget.email), points);
        await prefs.setInt(SharedKeys.balanceKey(widget.email), rewards);
        print('Saved to SharedPreferences: points=$points, rewards=$rewards');

        if (mounted) {
          setState(() {
            this.points = points;
            this.rewards = rewards;
            if (lastEarnedPoints != null) {
              this.lastEarnedPoints = lastEarnedPoints;
            }
          });
          print(
            'Updated state: points=${this.points}, rewards=${this.rewards}, lastEarnedPoints=${this.lastEarnedPoints}',
          );
        }

        await prefs.remove('${widget.email}_lastEarnedPoints');
        await prefs.remove(SharedKeys.lastTransactionKey(widget.email));
        await prefs.remove(SharedKeys.lastTransactionShown);
        print('Removed temporary SharedPreferences keys');
      } else {
        print('Failed to load balance: ${response.body}');
        final cachedPoints =
            prefs.getInt(SharedKeys.pointsKey(widget.email)) ?? 0;
        final cachedRewards =
            prefs.getInt(SharedKeys.balanceKey(widget.email)) ?? 0;
        print(
          'Using cached values: points=$cachedPoints, rewards=$cachedRewards',
        );

        if (mounted) {
          setState(() {
            this.points = cachedPoints;
            this.rewards = cachedRewards;
          });
          print(
            'Updated state with cached values: points=${this.points}, rewards=${this.rewards}',
          );
        }
      }
    } catch (e, stackTrace) {
      print('Error loading rewards and points: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> _loadTotalRecycledItems() async {
    try {
      print(
        'Loading total recycled items for email: ${widget.email}',
      ); // Debug print
      final response = await http.get(
        Uri.parse(ApiConstants.totalRecycledItems(widget.email)),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
        },
      );

      print(
        'Total recycled items response status: ${response.statusCode}',
      ); // Debug print
      print(
        'Total recycled items response body: ${response.body}',
      ); // Debug print

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final totalItems = data['total_items'] ?? 0;
        final co2Saved =
            double.tryParse(data['co2_saved']?.toString() ?? '0.0') ?? 0.0;

        // Cache the values
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(
          SharedKeys.itemsRecycledKey(widget.email),
          totalItems,
        );
        await prefs.setDouble(SharedKeys.co2SavedKey(widget.email), co2Saved);

        if (mounted) {
          setState(() {
            itemsRecycled = totalItems;
            this.co2Saved = co2Saved;
          });
          print(
            'Updated stats - Items: $itemsRecycled, CO2: ${this.co2Saved}',
          ); // Debug print
        }
      } else {
        print(
          'Failed to load total recycled items: ${response.statusCode} - ${response.body}',
        ); // Debug print

        // Load cached values
        final prefs = await SharedPreferences.getInstance();
        final cachedItems =
            prefs.getInt(SharedKeys.itemsRecycledKey(widget.email)) ?? 0;
        final cachedCo2 =
            prefs.getDouble(SharedKeys.co2SavedKey(widget.email)) ?? 0.0;

        if (mounted) {
          setState(() {
            itemsRecycled = cachedItems;
            this.co2Saved = cachedCo2;
          });
          print(
            'Using cached values - Items: $itemsRecycled, CO2: ${this.co2Saved}',
          ); // Debug print
        }
      }
    } catch (e, stackTrace) {
      print('Error loading total recycled items: $e'); // Debug print
      print('Stack trace: $stackTrace'); // Debug print

      // Load cached values in case of error
      final prefs = await SharedPreferences.getInstance();
      final cachedItems =
          prefs.getInt(SharedKeys.itemsRecycledKey(widget.email)) ?? 0;
      final cachedCo2 =
          prefs.getDouble(SharedKeys.co2SavedKey(widget.email)) ?? 0.0;

      if (mounted) {
        setState(() {
          itemsRecycled = cachedItems;
          this.co2Saved = cachedCo2;
        });
        print(
          'Using cached values after error - Items: $itemsRecycled, CO2: ${this.co2Saved}',
        ); // Debug print
      }
    }
  }

  Future<void> _checkRecycleBag() async {
    try {
      final token = await _getAuthToken();
      final response = await http.get(
        Uri.parse(ApiConstants.recycleBagsPending(widget.email)),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> bags = json.decode(response.body);
        if (mounted) {
          setState(() {
            hasItemsInBag = bags.isNotEmpty;
          });
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(SharedKeys.showRecycleBagDot, hasItemsInBag);
      } else {
        Logger().e('Failed to check recycle bag: ${response.body}');
      }
    } catch (e) {
      Logger().e('Error checking recycle bag: $e');
    }
  }

  Future<void> _loadUserAddress() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        userAddress = prefs.getString(SharedKeys.userAddress);
      });
    }
  }

  Future<void> _setUserAddressFromLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (placemarks.isNotEmpty) {
      final address = placemarks.first;
      final fullAddress =
          '${address.street}, ${address.subLocality}, ${address.locality}';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(SharedKeys.userAddress, fullAddress);
      if (mounted) {
        setState(() {
          userAddress = fullAddress;
        });
      }
    }
  }

  Future<void> _checkUnreadNotifications() async {
    try {
      final token = await _getAuthToken();
      final response = await http.get(
        Uri.parse(ApiConstants.notifications(widget.email)),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> notifications = json.decode(response.body);
        if (mounted) {
          setState(() {
            hasUnreadNotifications = notifications.any(
              (notification) => !notification['is_read'],
            );
          });
        }
      } else {
        Logger().e('Failed to check notifications: ${response.body}');
      }
    } catch (e) {
      Logger().e('Error checking unread notifications: $e');
    }
  }

  void _showCustomAddressDialog(BuildContext context) {
    String? tempAddress = userAddress;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Address',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder:
          (context, animation, secondaryAnimation) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: AppTheme.light.colorScheme.secondary,
            title: Text(
              'Change Delivery Address',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.light.colorScheme.primary,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: userAddress,
                  onChanged: (value) {
                    tempAddress = value;
                  },
                  decoration: InputDecoration(
                    labelText: 'Enter your address',
                    labelStyle: TextStyle(
                      color: AppTheme.light.colorScheme.primary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (tempAddress != null && tempAddress!.isNotEmpty) {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString(
                        SharedKeys.userAddress,
                        tempAddress!,
                      );
                      if (mounted) {
                        setState(() {
                          userAddress = tempAddress;
                        });
                      }
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.light.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 20,
                    ),
                  ),
                  child: const Text(
                    "Save",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<UpdateStatsNotification>(
      onNotification: (notification) {
        if (notification.email == widget.email) {
          print('تم استلام إشعار تحديث الإحصائيات لـ ${notification.email}');
          _updateStats();
          return true;
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTheme.light.colorScheme.secondary,
        body: SafeArea(
          child: LayoutBuilder(
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
                      onRefresh: _updateStats,
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
                          _buildCategoriesSection(
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
                          _buildEcoTipCard(
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
        GestureDetector(
          onTap: () => _showCustomAddressDialog(context),
          child: Container(
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
                        'Receiving From',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14 * fontScale,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      Text(
                        userAddress ?? 'Select your address',
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
                Icon(
                  Icons.edit_location_alt,
                  color: Colors.white,
                  size: 20 * fontScale,
                ),
              ],
            ),
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
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool(SharedKeys.lastTransactionShown, true);
                    Logger().i(
                      'Marked lastTransaction as shown due to navigation to Notifications',
                    );
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  NotificationScreen(email: widget.email),
                        ),
                      ).then((_) {
                        _checkRecycleBag();
                        _checkUnreadNotifications();
                      });
                    }
                  },
                  icon: const Icon(Icons.notifications_none_outlined),
                ),
                if (hasUnreadNotifications)
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
            SizedBox(width: maxWidth * 0.03),
            Stack(
              children: [
                IconButton(
                  iconSize: 24 * fontScale,
                  padding: EdgeInsets.zero,
                  color: Colors.white,
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool(SharedKeys.lastTransactionShown, true);
                    Logger().i(
                      'Marked lastTransaction as shown due to navigation to RecycleBag',
                    );
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RecycleBagScreen(),
                        ),
                      ).then((_) {
                        _checkRecycleBag();
                      });
                    }
                  },
                  icon: const Icon(Icons.shopping_cart_outlined),
                ),
                if (hasItemsInBag)
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
            : '';
    final String displayName =
        firstName != null && lastName != null
            ? '${capitalize(firstName)} ${capitalize(lastName)}'
            : 'Loading...';

    return Row(
      children: [
        CircleAvatar(
          radius: maxWidth * 0.08,
          backgroundImage:
              profileImageUrl != null ? NetworkImage(profileImageUrl!) : null,
          backgroundColor: Colors.grey[200],
          child:
              profileImageUrl == null
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.light.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Points Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (lastEarnedPoints != null && lastEarnedPoints! > 0) ...[
                SizedBox(width: 8),
                Text(
                  "+$lastEarnedPoints",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 14 * fontScale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 12),
          // Rewards + Voucher Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Rewards Info
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(maxWidth * 0.02),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.light.colorScheme.primary,
                    ),
                    child: Icon(
                      Icons.monetization_on,
                      color: Colors.white,
                      size: 24 * fontScale,
                    ),
                  ),
                  SizedBox(width: maxWidth * 0.03),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Available Rewards",
                        style: TextStyle(
                          color: AppTheme.light.colorScheme.primary,
                          fontSize: 14 * fontScale,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      Text(
                        "$rewards EGP",
                        style: TextStyle(
                          color: AppTheme.light.colorScheme.primary,
                          fontSize: 20 * fontScale,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Voucher Button
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => VoucherScreen()),
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(
                    color: AppTheme.light.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.card_giftcard, color: Colors.white),
                      SizedBox(width: maxWidth * 0.02),
                      Text(
                        "Voucher",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15 * fontScale,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(
    BuildContext context,
    double maxWidth,
    double maxHeight,
    double padding,
    double fontScale,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Categories',
            style: TextStyle(
              fontSize: 20 * fontScale,
              fontWeight: MultiWeight.bold.value,
              color: AppTheme.light.colorScheme.primary,
              fontFamily: 'Roboto',
            ),
          ),
          SizedBox(height: maxHeight * 0.01),
          SizedBox(
            height: maxHeight * 0.18,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryCard(
                  context,
                  maxWidth,
                  maxHeight,
                  fontScale,
                  'Glass',
                  'assets/images/glass1.jpg',
                  AppTheme.light.colorScheme.primary,
                  () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool(SharedKeys.lastTransactionShown, true);
                    Logger().i(
                      'Marked lastTransaction as shown due to navigation to Glass',
                    );
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => GlassScreen()),
                      );
                    }
                  },
                ),
                SizedBox(width: maxWidth * 0.03),
                _buildCategoryCard(
                  context,
                  maxWidth,
                  maxHeight,
                  fontScale,
                  'Plastic',
                  'assets/images/plastic1.jpg',
                  AppTheme.light.colorScheme.primary,
                  () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool(SharedKeys.lastTransactionShown, true);
                    Logger().i(
                      'Marked lastTransaction as shown due to navigation to Plastic',
                    );
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlasticScreen(),
                        ),
                      );
                    }
                  },
                ),
                SizedBox(width: maxWidth * 0.03),
                _buildCategoryCard(
                  context,
                  maxWidth,
                  maxHeight,
                  fontScale,
                  'Cans',
                  'assets/images/cans1.jpg',
                  AppTheme.light.colorScheme.primary,
                  () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool(SharedKeys.lastTransactionShown, true);
                    Logger().i(
                      'Marked lastTransaction as shown due to navigation to Cans',
                    );
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CansScreen()),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    double maxWidth,
    double maxHeight,
    double fontScale,
    String title,
    String imagePath,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: maxWidth * 0.35,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                imagePath,
                width: maxWidth * 0.35,
                height: maxHeight * 0.18,
                fit: BoxFit.cover,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: color.withOpacity(0.3),
              ),
            ),
            Positioned(
              bottom: maxHeight * 0.01,
              left: maxWidth * 0.02,
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18 * fontScale,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
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
            "Items Recycled",
            "${itemsRecycled ?? 0}",
            Icons.recycling,
            AppTheme.light.colorScheme.primary,
          ),
          _buildStatCard(
            maxWidth,
            maxHeight,
            fontScale,
            "CO₂ Saved",
            "${co2Saved?.toStringAsFixed(2) ?? '0.00'} kg",
            Icons.cloud,
            AppTheme.light.colorScheme.primary,
          ),
          _buildStatCard(
            maxWidth,
            maxHeight,
            fontScale,
            "Points Earned",
            "${points ?? 0}",
            Icons.star,
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

  Widget _buildEcoTipCard(
    BuildContext context,
    double maxWidth,
    double maxHeight,
    double padding,
    double fontScale,
  ) {
    final tips = [
      "Use reusable bags to reduce plastic waste.",
      "Sort your recyclables to make processing easier.",
      "Choose products with minimal packaging.",
      "Compost organic waste to enrich soil.",
      "Recycle glass bottles to save energy.",
    ];
    final randomTip = tips[Random().nextInt(tips.length)];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: padding),
      padding: EdgeInsets.symmetric(
        horizontal: maxWidth * 0.05,
        vertical: maxHeight * 0.02,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 24 * fontScale,
            color: AppTheme.light.colorScheme.primary,
          ),
          SizedBox(width: maxWidth * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Eco Tip of the Day",
                  style: TextStyle(
                    fontSize: 16 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.light.colorScheme.primary,
                    fontFamily: 'Roboto',
                  ),
                ),
                SizedBox(height: maxHeight * 0.005),
                Text(
                  randomTip,
                  style: TextStyle(
                    fontSize: 14 * fontScale,
                    color: AppTheme.light.colorScheme.primary,
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
}

enum MultiWeight { bold }

extension MultiWeightExtension on MultiWeight {
  FontWeight get value {
    switch (this) {
      case MultiWeight.bold:
        return FontWeight.w700;
    }
  }
}
