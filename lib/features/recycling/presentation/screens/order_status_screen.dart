import 'package:flutter/material.dart';
import 'package:graduation_project11/features/recycling/presentation/widgets/chat_widget.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:graduation_project11/core/api/api_constants.dart';
import 'package:graduation_project11/core/themes/app__theme.dart';
import 'package:graduation_project11/core/widgets/custom_appbar.dart';
import 'package:graduation_project11/features/recycling/presentation/screens/rewarding_screen.dart';
import 'package:graduation_project11/core/utils/shared_keys.dart';
import 'package:graduation_project11/features/home/presentation/screen/home_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class UpdateStatsNotification extends Notification {
  final String email;
  UpdateStatsNotification(this.email);
}

class OrderStatusScreen extends StatefulWidget {
  final String userEmail;

  const OrderStatusScreen({Key? key, required this.userEmail})
    : super(key: key);

  @override
  _OrderStatusScreenState createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  bool isLoading = true;
  String? error;
  Map<String, dynamic>? orderData;
  String? _lastStatus;
  // DateTime? _lastUpdateTime; // Not currently used, can be removed if not needed
  Timer? _refreshTimer;
  bool _isChatOpen = false;
  String? _assignmentId;
  int? _numericAssignmentId;
  Set<int> _unreadAssignments = {};
  String? _fetchedUserGovernorate;
  String? _profileUserGovernorate;
  bool _showRejectedFullScreenMessage = false;
  String? _rejectedReasonForFullScreenMessage;

  Future<void> _persistResumeState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SharedKeys.orderStatusResumeEmail, widget.userEmail);
    print(
      "OrderStatusScreen: orderStatusResumeEmail set to ${widget.userEmail}",
    );
  }

  Future<void> _clearResumeState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(SharedKeys.orderStatusResumeEmail);
    print("OrderStatusScreen: orderStatusResumeEmail cleared");
  }

  static Color getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'delivered':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  static IconData getStatusIcon(String? status) {
    if (status == null) return Icons.help_outline;

    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending;
      case 'accepted':
        return Icons.check_circle_outline;
      case 'in_transit':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.done_all;
      case 'rejected':
        return Icons.cancel;
      case 'cancelled':
        return Icons.block;
      default:
        return Icons.help_outline;
    }
  }

  @override
  void initState() {
    super.initState();
    _persistResumeState();
    _loadInitialData();
    _refreshTimer = Timer.periodic(Duration(seconds: 15), (timer) {
      // Reduced refresh interval
      if (mounted && !_isChatOpen) {
        // Don't refresh if chat is open
        _fetchOrderStatus(showLoadingIndicator: false);
        // _loadUnreadAssignments will be called within _fetchOrderStatus
      }
    });
  }

  Future<void> _loadInitialData() async {
    await _fetchOrderStatus(showLoadingIndicator: true);
    await _loadUnreadAssignments();
  }

  Future<void> _loadUnreadAssignments() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> unreadIdsAsString =
        prefs.getStringList(SharedKeys.unreadChatAssignments) ?? [];
    if (mounted) {
      final newUnreadSet =
          unreadIdsAsString
              .map((id) => int.tryParse(id) ?? -1)
              .where((id) => id != -1)
              .toSet();
      if (_unreadAssignments.length != newUnreadSet.length ||
          !_unreadAssignments.containsAll(newUnreadSet)) {
        setState(() {
          _unreadAssignments = newUnreadSet;
        });
      }
    }
    print("OrderStatusScreen: Loaded unread assignments: $_unreadAssignments");
  }

  // _setOrderStatusFlag is removed as its functionality is replaced by _persistResumeState and _clearResumeState

  @override
  void dispose() {
    _refreshTimer?.cancel();
    // No need to clear resume state here, as it should persist if user exits app
    super.dispose();
  }

  Future<String?> _loadUserGovernorate() async {
    final prefs = await SharedPreferences.getInstance();
    final storedGovernorate = prefs.getString(SharedKeys.userGovernorate);
    print(
      'Attempting to load governorate from SharedPreferences with key "${SharedKeys.userGovernorate}": "$storedGovernorate"',
    );
    if (storedGovernorate != null &&
        storedGovernorate.isNotEmpty &&
        storedGovernorate.toLowerCase() != 'null') {
      return storedGovernorate;
    }
    return null;
  }

  // Method _showRejectedMessageAndNavigate is removed as it's replaced by full-screen message

  Future<void> _fetchOrderStatus({bool showLoadingIndicator = true}) async {
    if (!mounted) return;

    await _loadUnreadAssignments(); // Load unread status before fetching order status

    if (showLoadingIndicator) {
      setState(() {
        isLoading = true;
        error = null;
      });
    }
    // For background refresh, we don't set isLoading to true,
    // and we don't clear a pre-existing error unless the fetch is successful.

    try {
      final userEmail = widget.userEmail;
      if (userEmail == null) {
        setState(() {
          error = 'User email not found';
          isLoading = false;
        });
        return;
      }

      final url = ApiConstants.getUserOrderStatus(userEmail);
      print('Order status URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Explicitly decode using UTF-8 to support Arabic characters
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('Received data: $data');

        if (data == null || data.isEmpty) {
          setState(() {
            error = 'No order data available';
            isLoading = false;
          });
          return;
        }

        // Load governorate from SharedPreferences if not in orderData
        final String apiOrderGovernorate =
            data['governorate']?.toString() ?? '';
        String? spGovernorateValue;
        if (apiOrderGovernorate.isEmpty ||
            apiOrderGovernorate.toLowerCase() == 'no governorate provided' ||
            apiOrderGovernorate.toLowerCase() == 'null') {
          spGovernorateValue = await _loadUserGovernorate();
        }

        // Fetch user profile to get governorate from backend
        String? profileGovernorateValue;
        try {
          final profileUri = Uri.parse(ApiConstants.getUserProfile).replace(
            queryParameters: {
              'email': userEmail,
              'user_type': 'regular_user', // Corrected user_type
            },
          );
          print('Fetching user profile from: $profileUri');
          final profileResponse = await http.get(
            profileUri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          );

          if (profileResponse.statusCode == 200) {
            final profileData = json.decode(
              utf8.decode(profileResponse.bodyBytes),
            );
            print('User profile data: $profileData');
            if (profileData != null && profileData['governorate'] != null) {
              profileGovernorateValue = profileData['governorate'].toString();
              if (profileGovernorateValue!.isNotEmpty &&
                  profileGovernorateValue.toLowerCase() != 'null') {
                print(
                  'Fetched governorate from profile: $profileGovernorateValue',
                );
                // Store it in the state variable to be used by _buildOrderDetails
                _profileUserGovernorate = profileGovernorateValue;
              } else {
                profileGovernorateValue =
                    null; // Invalid governorate from profile
              }
            }
          } else {
            print(
              'Failed to fetch user profile: ${profileResponse.statusCode} - ${profileResponse.body}',
            );
          }
        } catch (e) {
          print('Error fetching user profile: $e');
        }

        final String newStatus = (data['status'] ?? '').toLowerCase();
        final String currentStatus = (_lastStatus ?? '').toLowerCase();

        if (_assignmentId == null || newStatus != currentStatus) {
          try {
            final assignmentResponse = await http.get(
              Uri.parse(ApiConstants.getOrderAssignment(data['id'])),
            );
            if (assignmentResponse.statusCode == 200) {
              final assignmentData = json.decode(assignmentResponse.body);
              _assignmentId = assignmentData['id']?.toString();
              _numericAssignmentId = assignmentData['id']; // Store numeric ID
              data['assignment_id'] =
                  _assignmentId; // Keep string for existing logic if any
              print(
                'Found assignment ID: $_assignmentId (Numeric: $_numericAssignmentId)',
              );
              if (_numericAssignmentId != null) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setInt(
                  SharedKeys.lastAssignmentId,
                  _numericAssignmentId!,
                );
                print(
                  'Stored assignment ID in SharedPreferences: $_numericAssignmentId',
                );
              }
            } else {
              print(
                'Failed to get assignment ID: ${assignmentResponse.statusCode}',
              );
              print('Response: ${assignmentResponse.body}');
              if (data['id'] != null && data['id'] is int) {
                _numericAssignmentId = data['id'];
                _assignmentId = _numericAssignmentId.toString();
                data['assignment_id'] = _assignmentId;
                print(
                  'Using order ID as fallback assignment ID: $_assignmentId (Numeric: $_numericAssignmentId)',
                );
                final prefs = await SharedPreferences.getInstance();
                await prefs.setInt(
                  SharedKeys.lastAssignmentId,
                  _numericAssignmentId!,
                );
                print(
                  'Stored order ID as assignment ID in SharedPreferences: $_numericAssignmentId',
                );
              }
            }
          } catch (e) {
            print('Error fetching assignment ID: $e');
            if (data['id'] != null && data['id'] is int) {
              _numericAssignmentId = data['id'];
              _assignmentId = _numericAssignmentId.toString();
              data['assignment_id'] = _assignmentId;
              print(
                'Using order ID as fallback assignment ID after error: $_assignmentId (Numeric: $_numericAssignmentId)',
              );
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setInt(
                  SharedKeys.lastAssignmentId,
                  _numericAssignmentId!,
                );
                print(
                  'Stored order ID as assignment ID in SharedPreferences after error: $_numericAssignmentId',
                );
              } catch (prefsError) {
                print(
                  'Error storing assignment ID in SharedPreferences: $prefsError',
                );
              }
            }
          }
        } else {
          // Ensure _numericAssignmentId is also set if _assignmentId exists from previous fetch
          if (_assignmentId != null && _numericAssignmentId == null) {
            _numericAssignmentId = int.tryParse(_assignmentId!);
          }
          data['assignment_id'] = _assignmentId;
        }

        final Map<String, dynamic>? newDeliveryBoy = data['delivery_boy'];
        if (newDeliveryBoy != null) {
          print('Delivery Boy Data: $newDeliveryBoy');
        }

        setState(() {
          orderData = data;
          // If the API didn't provide a governorate, update _fetchedUserGovernorate
          // with the value from SharedPreferences (which could be null).
          // The _profileUserGovernorate is already set if fetched successfully.
          if (apiOrderGovernorate.isEmpty ||
              apiOrderGovernorate.toLowerCase() == 'no governorate provided' ||
              apiOrderGovernorate.toLowerCase() == 'null') {
            _fetchedUserGovernorate = spGovernorateValue;
          }
          _lastStatus = newStatus;
          isLoading = false;
        });

        if (newStatus == 'delivered' && currentStatus != 'delivered') {
          _clearResumeState(); // Clear resume state as order is complete
          _showDeliveredMessage();
        } else if (newStatus == 'rejected' && currentStatus != 'rejected') {
          _clearResumeState(); // Clear resume state as order is complete (rejected)
          // Instead of SnackBar, trigger the full-screen message
          setState(() {
            _rejectedReasonForFullScreenMessage =
                orderData!['rejection_reason']?.toString();
            _showRejectedFullScreenMessage = true;
            if (showLoadingIndicator) {
              // Only change isLoading if it was a foreground load
              isLoading = false;
            }
          });
        } else {
          // If no major status change caused a specific UI update (like delivered/rejected message),
          // and it was a foreground load, ensure isLoading is false.
          if (showLoadingIndicator && isLoading) {
            setState(() {
              isLoading = false;
            });
          }
        }
      } else {
        // response.statusCode != 200
        if (showLoadingIndicator) {
          setState(() {
            error = 'Failed to fetch order status (${response.statusCode})';
            isLoading = false;
          });
        } else {
          // Log background fetch error, but don't disrupt UI with a full error message
          print('Background fetch order status failed: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error fetching order status: $e');
      if (mounted) {
        if (showLoadingIndicator) {
          setState(() {
            error = 'Error: ${e.toString()}';
            isLoading = false;
          });
        } else {
          // Log background fetch error
          print('Background fetch order status error: $e');
        }
      }
    } finally {
      // Ensure isLoading is false if it was a foreground load and an exception might have been missed
      if (mounted && showLoadingIndicator && isLoading) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  bool _hasDeliveryBoyChanged(
    Map<String, dynamic>? current,
    Map<String, dynamic>? newData,
  ) {
    if (current == null && newData == null) return false;
    if (current == null || newData == null) return true;

    // تحديث المقارنة لتتناسب مع هيكل البيانات الجديد
    return current['phone'] != newData['phone'] ||
        current['name'] != newData['name'] ||
        current['rating'] != newData['rating'];
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      throw 'Could not launch $launchUri';
    }
  }

  void _showCallOptions(String phoneNumber) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.phone),
                title: Text('Call $phoneNumber'),
                onTap: () {
                  Navigator.pop(context);
                  _makePhoneCall(phoneNumber);
                },
              ),
              ListTile(
                leading: Icon(Icons.message),
                title: Text('Open Chat'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _isChatOpen = true;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeliveryBoyInfo(Map<String, dynamic>? deliveryBoy) {
    if (deliveryBoy == null) return const SizedBox();

    // تسجيل البيانات للتحقق
    print('Building Delivery Boy Info with data: $deliveryBoy');

    // استخراج البيانات من التنسيق الجديد
    final String name = deliveryBoy['name'] ?? '';
    final String phone = deliveryBoy['phone'] ?? '';
    final double rating =
        double.tryParse(deliveryBoy['rating']?.toString() ?? '0') ?? 0.0;
    final String deliveryBoyEmail = deliveryBoy['email'] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Delivery Boy Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.light.colorScheme.primary,
                  ),
                ),
                if (rating > 0)
                  Row(
                    children: [
                      Icon(Icons.star, size: 20, color: Colors.amber),
                      SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage:
                      deliveryBoy['image'] != null
                          ? NetworkImage(deliveryBoy['image'])
                          : null,
                  child:
                      deliveryBoy['image'] == null
                          ? const Icon(Icons.person, size: 30)
                          : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (name.isNotEmpty)
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (phone.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          phone,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (phone.isNotEmpty)
                      IconButton(
                        onPressed: () => _showCallOptions(phone),
                        icon: Icon(
                          Icons.phone_outlined,
                          color: AppTheme.light.colorScheme.primary,
                        ),
                      ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isChatOpen = !_isChatOpen;
                        });
                      },
                      icon: Icon(
                        Icons.chat_outlined,
                        color: AppTheme.light.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (_isChatOpen && orderData != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              // معالجة خطأ "not found" عن طريق طباعة معرف الطلب وتأكيد القيمة
              Builder(
                builder: (context) {
                  final assignmentId =
                      int.tryParse(
                        orderData!['assignment_id']?.toString() ??
                            orderData!['id']?.toString() ??
                            '0',
                      ) ??
                      0;
                  print(
                    'Chat using assignment ID: $assignmentId',
                  ); // طباعة معرف الطلب للتصحيح
                  return ChatWidget(
                    assignmentId: assignmentId,
                    userEmail: widget.userEmail, // This is the customer
                    deliveryBoyEmail:
                        deliveryBoyEmail, // This is the delivery boy
                    currentSenderEmail:
                        widget.userEmail, // The customer is sending
                    currentSenderType: 'user', // Type for customer
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetails() {
    if (orderData == null) return SizedBox();

    final status = orderData!['status']?.toString().toLowerCase() ?? 'pending';
    final items = orderData!['items'] as List? ?? [];
    final deliveryBoy = orderData!['delivery_boy'];
    final rejectionReason = orderData!['rejection_reason']?.toString();

    // تحسين معالجة تاريخ الإنشاء
    DateTime? createdAt;
    try {
      if (orderData!['created_at'] != null) {
        createdAt = DateTime.parse(orderData!['created_at'].toString());
      }
    } catch (e) {
      print('Error parsing created_at: $e');
    }

    // تحسين معالجة تاريخ التحديث
    DateTime? lastUpdate;
    try {
      if (orderData!['updated_at'] != null) {
        lastUpdate = DateTime.parse(orderData!['updated_at'].toString());
      }
    } catch (e) {
      print('Error parsing updated_at: $e');
    }

    String governorateToDisplay;

    // Priority:
    // 1. Governorat_profileUserGovernoratee from User Profile API (_profileUserGovernorate)
    // 2. Governorate from Order Status API (orderData!['governorate'])
    // 3. Governorate from SharedPreferences (_fetchedUserGovernorate)

    final String? profileGov = _profileUserGovernorate;
    final String apiOrderGov = orderData!['governorate']?.toString() ?? '';
    final String? spGov = _fetchedUserGovernorate;

    bool isProfileGovValid =
        profileGov != null &&
        profileGov.isNotEmpty &&
        profileGov.toLowerCase() != 'null' &&
        profileGov.toLowerCase() != 'no governorate provided';

    bool isApiOrderGovValid =
        apiOrderGov.isNotEmpty &&
        apiOrderGov.toLowerCase() != 'null' &&
        apiOrderGov.toLowerCase() != 'no governorate provided';

    bool isSpGovValid =
        spGov != null &&
        spGov.isNotEmpty &&
        spGov.toLowerCase() != 'null' &&
        spGov.toLowerCase() != 'no governorate provided';

    if (isProfileGovValid) {
      governorateToDisplay = profileGov;
    } else if (isApiOrderGovValid) {
      governorateToDisplay = apiOrderGov;
    } else if (isSpGovValid) {
      governorateToDisplay = spGov;
    } else {
      governorateToDisplay = 'No governorate provided';
    }

    final String formattedGovernorate =
        governorateToDisplay.toLowerCase() == 'no governorate provided'
            ? 'No governorate provided'
            : '${governorateToDisplay[0].toUpperCase()}${governorateToDisplay.substring(1).toLowerCase()}';
    final latitude = orderData!['latitude']?.toString();
    final longitude = orderData!['longitude']?.toString();

    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        // Order Status Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: getStatusColor(status).withAlpha(128),
              width: 2,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          getStatusIcon(status),
                          color: getStatusColor(status),
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Order #${orderData!['id']}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.light.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Chip(
                      label: Text(
                        _getStatusLabel(status),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: getStatusColor(status),
                    ),
                  ],
                ),
                Divider(height: 24),

                if (status == 'rejected' &&
                    rejectionReason != null &&
                    rejectionReason.isNotEmpty) ...[
                  Text(
                    'Rejection Reason:',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    rejectionReason,
                    style: TextStyle(fontSize: 14, color: Colors.red[700]),
                  ),
                  Divider(height: 24),
                ],

                // Order Information
                Text(
                  'Order Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.light.colorScheme.primary,
                  ),
                ),
                SizedBox(height: 8),
                if (createdAt != null)
                  _buildInfoRow(
                    Icons.access_time,
                    'Created At',
                    '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute}',
                  ),
                if (lastUpdate != null)
                  _buildInfoRow(
                    Icons.update,
                    'Last Update',
                    '${lastUpdate.day}/${lastUpdate.month}/${lastUpdate.year} ${lastUpdate.hour}:${lastUpdate.minute}',
                  ),

                // Location Information
                Divider(height: 24),
                Text(
                  'Location Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.light.colorScheme.primary,
                  ),
                ),
                SizedBox(height: 8),
                _buildInfoRow(
                  Icons.location_city,
                  'Governorate',
                  formattedGovernorate,
                ),
                if (latitude != null && longitude != null)
                  _buildInfoRow(
                    Icons.gps_fixed,
                    'Coordinates',
                    'Lat: $latitude, Long: $longitude',
                  ),

                // Recycle Bag Contents
                Divider(height: 24),
                Text(
                  'Recycle Bag Contents',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.light.colorScheme.primary,
                  ),
                ),
                SizedBox(height: 8),
                if (items.isEmpty)
                  Text(
                    'No items added yet',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final String itemName =
                          item['type']?.toString() ?? 'Unknown Item';
                      final int quantity =
                          int.tryParse(item['quantity']?.toString() ?? '0') ??
                          0;
                      final int points =
                          int.tryParse(item['points']?.toString() ?? '0') ?? 0;

                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: Icon(Icons.recycling),
                          title: Text(itemName),
                          subtitle: Text('Points: $points'),
                          trailing: Text(
                            '$quantity items',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),

        // Delivery Boy Information (if assigned and status is accepted or in_transit)
        if (deliveryBoy != null &&
            [
              'accepted',
              'in_transit',
              'delivered',
              'rejected',
              'cancelled',
              'canceled',
            ].contains(status)) ...[
          SizedBox(height: 16),
          _buildDeliveryBoyInfo(deliveryBoy),
        ],
      ],
    );
  }

  void _showCompletionDialog(bool isDelivered) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isDelivered ? 'Order Delivered!' : 'Order Rejected'),
          content: Text(
            isDelivered
                ? 'Your order has been delivered successfully. Would you like to rate the delivery service?'
                : 'Your order has been rejected. Please check the details or contact support.',
          ),
          actions: [
            if (isDelivered) ...[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showRatingDialog();
                },
                child: Text('Rate Now'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Later'),
              ),
            ] else
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
          ],
        );
      },
    );
  }

  Future<void> _showDeliveredMessage() async {
    if (!mounted) return;
    await _clearResumeState(); // Clear resume state before navigating away

    // Calculate total points from order items
    int totalPoints = 0;
    if (orderData != null && orderData!['items'] != null) {
      final items = orderData!['items'] as List? ?? [];
      for (var item in items) {
        final int points = int.tryParse(item['points']?.toString() ?? '0') ?? 0;
        totalPoints += points;
      }
    }

    // Get assignment ID from order data
    int? assignmentId;
    if (orderData != null) {
      // First try to get it from assignment_id field
      if (orderData!['assignment_id'] != null) {
        assignmentId = int.tryParse(orderData!['assignment_id'].toString());
      }
      // If not found, try to get it from the order id
      else if (orderData!['id'] != null) {
        assignmentId = int.tryParse(orderData!['id'].toString());
      }
    }

    // Store the assignment ID in SharedPreferences
    if (assignmentId != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(SharedKeys.lastAssignmentId, assignmentId);
      print('Stored assignment ID in SharedPreferences: $assignmentId');
    } else {
      print(
        'Warning: No assignment ID available to store in SharedPreferences',
      );
    }

    // Show a dialog informing the user that the order is delivered
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Order Delivered!'),
          content: Text(
            'Your order has been delivered successfully. You will now be redirected to the rewards page.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to the rewarding screen
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder:
                        (context) => RewardingScreen(
                          totalPoints: totalPoints,
                          assignmentId: assignmentId,
                        ),
                  ),
                );
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showRatingDialog() {
    int rating = 0;
    String comment = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Rate Delivery Service'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () {
                          setStateDialog(() {
                            rating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Add a comment (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    onChanged: (value) => comment = value,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (rating > 0) {
                      _submitRating(rating, comment);
                      Navigator.of(context).pop();
                    } else {
                      // إظهار رسالة خطأ إذا لم يتم اختيار تقييم
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please select a rating first')),
                      );
                    }
                  },
                  child: Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Removed _setOrderStatusFlag method

  Future<void> _submitRating(int rating, String comment) async {
    if (orderData == null || orderData!['id'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Order information is missing')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.userRateOrder(orderData!['id'])),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_email': widget.userEmail,
          'stars': rating,
          'comment': comment,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Thank you for your rating!')));

          // تحديث إحصائيات المستخدم بعد التقييم الناجح
          UpdateStatsNotification(widget.userEmail).dispatch(context);
        }
      } else {
        throw Exception('Failed to submit rating');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error submitting rating: $e')));
      }
    }
  }

  String _getStatusLabel(String? status) {
    if (status == null) return 'Unknown';

    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'in_transit':
        return 'In Transit';
      case 'delivered':
        return 'Delivered';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.light.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectedFullScreenWidget() {
    _clearResumeState(); // Clear resume state when this message is shown
    return Scaffold(
      backgroundColor: AppTheme.light.colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.sentiment_dissatisfied_outlined,
                color: Colors.red[700],
                size: 80,
              ),
              const SizedBox(height: 24),
              Text(
                'Better luck next time!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.light.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Unfortunately, your order has been rejected.',
                style: TextStyle(
                  fontSize: 18,
                  color: AppTheme.light.colorScheme.onSurface.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              if (_rejectedReasonForFullScreenMessage != null &&
                  _rejectedReasonForFullScreenMessage!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                  ), // Added padding for longer reasons
                  child: Text(
                    'Rejection Reason: $_rejectedReasonForFullScreenMessage',
                    style: TextStyle(fontSize: 16, color: Colors.red[600]),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.light.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontFamily: 'Roboto',
                  ), // Ensuring consistent font
                ),
                onPressed: () async {
                  await _clearResumeState(); // Clear resume state before going home
                  setState(() {
                    _showRejectedFullScreenMessage = false;
                    // orderData = null; // Reset order data to ensure fresh load if user comes back
                    // _lastStatus = null;
                    // error = null; // Clear any previous errors
                    // isLoading = true; // Show loader for next potential view
                  });
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                    (route) => false,
                  );
                },
                child: const Text(
                  'Back to Home',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showRejectedFullScreenMessage) {
      // _clearResumeState() is now called at the beginning of _buildRejectedFullScreenWidget
      return _buildRejectedFullScreenWidget();
    }

    return WillPopScope(
      onWillPop: () async {
        await _persistResumeState(); // Save email before exiting
        SystemNavigator.pop(); // Exit the app
        return false; // We've handled the pop, do not allow default behavior.
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Order Status',
          actions: [],
          // onBackButtonPressed is removed as WillPopScope handles it
        ),
        body:
            isLoading
                ? Center(child: CircularProgressIndicator())
                : error != null
                ? RefreshIndicator(
                  onRefresh:
                      () => _fetchOrderStatus(showLoadingIndicator: false),
                  child: SingleChildScrollView(
                    // Ensure content is scrollable for RefreshIndicator
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Container(
                      height:
                          MediaQuery.of(context).size.height -
                          (Scaffold.of(context).appBarMaxHeight ??
                              0), // Take full available height
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                            SizedBox(height: 16),
                            Text(
                              error!,
                              style: TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed:
                                  () => _fetchOrderStatus(
                                    showLoadingIndicator: true,
                                  ),
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                : RefreshIndicator(
                  onRefresh:
                      () => _fetchOrderStatus(showLoadingIndicator: false),
                  child: _buildOrderDetails(),
                ),
      ),
    );
  }
}
