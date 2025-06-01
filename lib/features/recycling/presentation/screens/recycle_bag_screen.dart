import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:graduation_project11/core/api/api_constants.dart';
import 'package:graduation_project11/core/themes/app__theme.dart';
import 'package:graduation_project11/core/widgets/custom_appbar.dart';
import 'package:graduation_project11/features/recycling/presentation/screens/place_order_screen.dart';
import 'package:graduation_project11/features/recycling/presentation/screens/scan_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:graduation_project11/core/utils/shared_keys.dart';
import 'package:graduation_project11/features/home/presentation/screen/home_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class RecycleState {
  static bool orderCompleted = false;
}

// إضافة Notification لتحديث الإحصائيات
class UpdateStatsNotification extends Notification {
  final String email;
  UpdateStatsNotification(this.email);
}

class RecycleBagScreen extends StatefulWidget {
  final Map<String, dynamic>? newItem;

  const RecycleBagScreen({Key? key, this.newItem}) : super(key: key);

  static List<Map<String, dynamic>> recycleItems = [];

  static void markOrderAsCompleted() {
    RecycleState.orderCompleted = true;
  }

  @override
  State<RecycleBagScreen> createState() => RecycleBagScreenState();
}

class RecycleBagScreenState extends State<RecycleBagScreen> {
  bool _isLoading = false;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (RecycleState.orderCompleted) {
        RecycleBagScreen.recycleItems.clear();
        updateRecycleBagInPrefs();
        RecycleState.orderCompleted = false;
      }

      if (widget.newItem != null) {
        mergeOrAddItem(widget.newItem!);
        updateRecycleBagInPrefs();
        setState(() {});
      }
    });
  }

  Future<void> _loadUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userEmail = prefs.getString(SharedKeys.userEmail);
    });
  }

  void resetOrder() {
    setState(() {
      RecycleBagScreen.recycleItems.clear();
      updateRecycleBagInPrefs();
    });
  }

  Future<void> updateRecycleBagInPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedItems =
        RecycleBagScreen.recycleItems.map((item) {
          return jsonEncode({
            'item_type': item['item_type'],
            'quantity': item['quantity'],
            'imagePath': item['imagePath'],
          });
        }).toList();
    await prefs.setStringList(SharedKeys.recycleBagItems, encodedItems);
  }

  void mergeOrAddItem(Map<String, dynamic> newItem) {
    bool found = false;
    for (var item in RecycleBagScreen.recycleItems) {
      if (item['item_type'] == newItem['item_type']) {
        item['quantity'] += newItem['quantity'];
        found = true;
        break;
      }
    }
    if (!found) RecycleBagScreen.recycleItems.add(newItem);
  }

  int calculatePoints(String material, int quantity) {
    switch (material.toLowerCase().trim()) {
      case 'glass bottle':
        return quantity * 8; // As per backend: 8 points per glass bottle
      case 'plastic bottle':
        return quantity * 5; // 5 points per plastic bottle
      case 'aluminum can':
        return quantity * 10; // 10 points per aluminum can
      default:
        return 0;
    }
  }

  String getLabel(String material) {
    switch (material.toLowerCase().trim()) {
      case 'glass bottle':
        return 'Glass Bottle';
      case 'plastic bottle':
        return 'Plastic Bottle';
      case 'aluminum can':
        return 'Aluminum Can';
      default:
        return 'Unknown Material';
    }
  }

  String getImagePath(String material) {
    switch (material.toLowerCase().trim()) {
      case 'glass bottle':
        return 'assets/images/glass1.jpg';
      case 'plastic bottle':
        return 'assets/images/plastic1.jpg';
      case 'aluminum can':
        return 'assets/images/cans1.jpg';
      default:
        return 'assets/images/default.jpg';
    }
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> handlePlaceOrder(int totalPoints) async {
    if (_userEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("User is not logged in"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (RecycleBagScreen.recycleItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Recycle bag is empty"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final position = await _getCurrentLocation();
      final items =
          RecycleBagScreen.recycleItems.map((item) {
            return {
              'item_type': getLabel(item['item_type']),
              'quantity': item['quantity'],
            };
          }).toList();

      // Navigate to PlaceOrderScreen with items
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  PlaceOrderScreen(totalPoints: totalPoints, items: items),
        ),
      );

      // Clear bag after navigation (confirmation handled in PlaceOrderScreen)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(SharedKeys.lastEarnedPoints, totalPoints);

      List<String> history =
          prefs.getStringList(SharedKeys.activityHistory) ?? [];
      final newActivity = {
        'type': 'order',
        'points': totalPoints,
        'timestamp': DateTime.now().toIso8601String(),
      };
      history.add(jsonEncode(newActivity));
      await prefs.setStringList(SharedKeys.activityHistory, history);

      // تحديث الإحصائيات باستخدام Notification
      print('إرسال إشعار تحديث الإحصائيات لـ $_userEmail');
      UpdateStatsNotification(_userEmail!).dispatch(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final int deliveryFee = 10;
    final int totalPoints = RecycleBagScreen.recycleItems.fold(
      0,
      (sum, item) => sum + calculatePoints(item['item_type'], item['quantity']),
    );
    final double totalRewards = totalPoints / 20.0; // 20 points = 1 EGP

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: CustomAppBar(
        title: 'Recycle Bag',
        leading: IconButton(
          icon: Icon(
            CupertinoIcons.back,
            color: AppTheme.light.colorScheme.secondary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Flexible(
                  child: ListView.builder(
                    itemCount: RecycleBagScreen.recycleItems.length,
                    itemBuilder: (context, index) {
                      final item = RecycleBagScreen.recycleItems[index];
                      return Dismissible(
                        key: UniqueKey(),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) {
                          setState(() {
                            RecycleBagScreen.recycleItems.removeAt(index);
                            updateRecycleBagInPrefs();
                          });
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.delete,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        child: buildItemCard(item),
                      );
                    },
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        RecycleBagScreen.recycleItems.clear();
                        updateRecycleBagInPrefs();
                      });
                    },
                    icon: Icon(Icons.delete_forever, color: Colors.red),
                    label: Text(
                      "Clear All",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
                Divider(color: AppTheme.light.colorScheme.primary),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      buildSummaryRow("Total Points", "$totalPoints Points"),
                      buildSummaryRow(
                        "Total Rewards",
                        "${totalRewards.toStringAsFixed(2)} EGP",
                      ),
                      buildSummaryRow("Delivery Fee", "$deliveryFee EGP"),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                buildPrivacyText(),
                const SizedBox(height: 30),
                buildButton(
                  text: "Place Order",
                  color:
                      RecycleBagScreen.recycleItems.isEmpty
                          ? Colors.grey
                          : AppTheme.light.colorScheme.primary,
                  textColor: Colors.white,
                  onPressed: () {
                    if (RecycleBagScreen.recycleItems.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Recycle bag is empty"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } else {
                      handlePlaceOrder(totalPoints);
                    }
                  },
                ),
                const SizedBox(height: 10),
                buildButton(
                  text: "Add More",
                  color: AppTheme.light.colorScheme.secondary,
                  textColor: AppTheme.light.colorScheme.primary,
                  border: BorderSide(
                    color: AppTheme.light.colorScheme.primary,
                    width: 2,
                  ),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => ScanScreen()),
                      (route) => false,
                    );
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget buildItemCard(Map<String, dynamic> item) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              getImagePath(item['item_type']),
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['item_type'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Image.asset(
                      'assets/icons/points.jpeg',
                      width: 15,
                      height: 15,
                    ),
                    SizedBox(width: 4),
                    Text(
                      "${calculatePoints(item['item_type'], item['quantity'])} Points",
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap:
                        item['quantity'] >
                                5 // Check if quantity is greater than 5
                            ? () {
                              setState(() {
                                item['quantity'] -= 1;
                                updateRecycleBagInPrefs();
                              });
                            }
                            : null, // If quantity is 5 or less, do nothing (or disable button visually)
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.remove, color: Colors.white, size: 20),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    "${item['quantity']}",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        item['quantity'] += 1;
                        updateRecycleBagInPrefs();
                      });
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.add, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildPrivacyText() {
    return RichText(
      textAlign: TextAlign.start,
      text: TextSpan(
        children: [
          TextSpan(
            text:
                "Your personal data will only be used to process your order. For more details, please review our ",
            style: TextStyle(
              color: AppTheme.light.colorScheme.primary,
              fontSize: 13,
            ),
          ),
          TextSpan(
            text: "Privacy Policy",
            style: TextStyle(
              color: Colors.black,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.light.colorScheme.primary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              color: AppTheme.light.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildButton({
    required String text,
    required Color color,
    required Color textColor,
    BorderSide? border,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 325,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          side: border,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: onPressed,
        child: Text(text, style: TextStyle(fontSize: 18, color: textColor)),
      ),
    );
  }
}
