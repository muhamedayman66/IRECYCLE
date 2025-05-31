// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:graduation_project11/core/api/api_constants.dart';
import 'package:graduation_project11/core/themes/app__theme.dart';
import 'package:graduation_project11/core/widgets/custom_appbar.dart';
import 'package:graduation_project11/features/delivery%20boy/home/presentation/screen/DeliveryHomeScreen.dart';
import 'package:graduation_project11/features/delivery%20boy/orders/data/models/delivery_order.dart';
import 'package:graduation_project11/features/delivery%20boy/orders/data/services/delivery_orders_service.dart';
import 'package:graduation_project11/features/recycling/presentation/widgets/chat_widget.dart';
import 'package:intl/intl.dart'; // Added for date formatting
import 'package:url_launcher/url_launcher.dart';
import 'package:logger/logger.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DeliveryOrdersScreen extends StatefulWidget {
  final String email;

  const DeliveryOrdersScreen({super.key, required this.email});

  // Static methods for status styling, similar to OrderStatusScreen
  static Color getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'in_transit':
        return Colors.indigo; // Matched OrderStatusScreen
      case 'delivered':
      case 'completed': // Added completed for consistency
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
      case 'canceled':
        return Colors.grey; // Matched OrderStatusScreen
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
      case 'completed': // Added completed for consistency
        return Icons.done_all;
      case 'rejected':
        return Icons.cancel;
      case 'cancelled':
      case 'canceled':
        return Icons.block;
      default:
        return Icons.help_outline;
    }
  }

  @override
  _DeliveryOrdersScreenState createState() => _DeliveryOrdersScreenState();
}

class _DeliveryOrdersScreenState extends State<DeliveryOrdersScreen> {
  final DeliveryOrdersService _ordersService = DeliveryOrdersService();
  final logger = Logger();

  final Map<String, int> _statusRank = {
    'in_transit': 1,
    'accepted': 2,
    'pending': 3,
    'delivered': 4,
    'completed': 4,
    'rejected': 5,
    'cancelled': 6,
    'canceled': 6,
    'unknown': 7,
  };

  bool isLoading = true;
  bool isBackgroundLoading = false;
  String? errorMessage;
  List<DeliveryOrder> orders = [];
  Timer? _refreshTimer;
  int? _selectedOrderId;
  bool _isChatOpen = false;

  @override
  void initState() {
    super.initState();
    _loadOrders(showLoadingIndicator: true);
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (mounted) {
        await _loadOrders(showLoadingIndicator: false);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.light.colorScheme.surface,
      appBar: CustomAppBar(title: 'Delivery Orders'), // Updated AppBar title
      body: SafeArea(
        bottom: true, // Ensure bottom padding
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        style: TextStyle(fontSize: 16, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          logger.i('🔄 Retry button pressed');
                          _loadOrders(showLoadingIndicator: true);
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
                : orders.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.light.colorScheme.primary,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No orders available',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Roboto',
                          color: AppTheme.light.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                )
                : LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(
                        bottom: 80,
                      ), // Increased bottom padding for better scrolling
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: orders.length,
                          itemBuilder: (context, index) {
                            final order = orders[index];
                            logger.i(
                              '📱 Building order card for order ${order.id}',
                            );
                            return AnimatedOpacity(
                              // Added AnimatedOpacity for smoother appearance
                              opacity: 1.0,
                              duration: const Duration(milliseconds: 300),
                              child: _buildOrderCard(order),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }

  Future<void> _loadOrders({bool showLoadingIndicator = true}) async {
    if (!mounted) return;

    if (showLoadingIndicator) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    } else {
      isBackgroundLoading = true;
    }

    try {
      logger.i('🔄 Loading orders...');
      List<DeliveryOrder> activeOrders = [];
      try {
        logger.i('🔄 Fetching current active orders for ${widget.email}...');
        activeOrders = await _ordersService.getCurrentOrders(widget.email);
        logger.i('✅ Fetched ${activeOrders.length} active orders.');
      } catch (e) {
        logger.e(
          '❌ Error fetching active orders: $e. Continuing without them.',
        );
      }

      List<DeliveryOrder> availableOrdersList = [];
      final availableOrdersUrl = ApiConstants.availableOrders(widget.email);
      logger.i('📡 Fetching available orders from URL: $availableOrdersUrl');

      final response = await http.get(
        Uri.parse(availableOrdersUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      logger.i('📥 Available orders response status: ${response.statusCode}');
      logger.i('📦 Available orders response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        logger.i('📦 Parsed available orders data length: ${data.length}');
        for (var orderData in data) {
          try {
            availableOrdersList.add(DeliveryOrder.fromJson(orderData));
          } catch (e) {
            logger.e('❌ Error parsing available order: $e');
            logger.e('🔍 Problematic available order data: $orderData');
          }
        }
      } else {
        if (activeOrders.isEmpty) {
          throw Exception(
            'Failed to load available orders: ${response.statusCode}',
          );
        }
      }

      if (mounted) {
        setState(() {
          final Map<int, DeliveryOrder> mergedOrdersMap = {};
          for (var order in activeOrders) {
            mergedOrdersMap[order.id] = order;
          }
          for (var order in availableOrdersList) {
            if (!mergedOrdersMap.containsKey(order.id)) {
              final fetchedStatus = order.status?.toLowerCase() ?? 'unknown';
              if (fetchedStatus != 'delivered' &&
                  fetchedStatus != 'rejected' &&
                  fetchedStatus != 'cancelled' &&
                  fetchedStatus != 'canceled') {
                mergedOrdersMap[order.id] = order;
              } else {
                logger.i(
                  'Skipping available order ${order.id} due to status: $fetchedStatus',
                );
              }
            } else {
              logger.i(
                'Order ${order.id} from available list already present from active list. Keeping active version.',
              );
            }
          }

          orders =
              mergedOrdersMap.values.toList()..sort((a, b) {
                int rankA =
                    _statusRank[a.status?.toLowerCase() ?? 'unknown'] ??
                    _statusRank['unknown']!;
                int rankB =
                    _statusRank[b.status?.toLowerCase() ?? 'unknown'] ??
                    _statusRank['unknown']!;
                if (rankA != rankB) {
                  return rankA.compareTo(rankB);
                }
                return b.createdAt.compareTo(a.createdAt);
              });

          isLoading = false;
          isBackgroundLoading = false;
          errorMessage = null;
        });
      }
      logger.i(
        '✅ Successfully merged and loaded ${orders.length} total orders',
      );
      for (var order in orders) {
        logger.i('''
📦 Order ${order.id}:
   Status: ${order.status}
   Customer: ${order.customerName}
   Location: ${order.location}
   Created: ${order.createdAt}
   Items: ${order.items.length}
''');
      }
    } catch (e) {
      logger.e('❌ Error loading orders: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          isBackgroundLoading = false;
          errorMessage = 'Failed to load orders: $e';
        });
      }
      if (showLoadingIndicator) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage!),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _loadOrders(showLoadingIndicator: true),
            ),
          ),
        );
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
      case 'completed':
        return 'Completed';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
      case 'canceled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.light.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
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

  Widget _buildOrderCard(DeliveryOrder order) {
    logger.i('📦 Building order card for order ${order.id}');

    final String currentOrderStatus = order.status ?? 'Unknown';
    final String statusLabelText = _getStatusLabel(currentOrderStatus);
    final Color statusColorValue = DeliveryOrdersScreen.getStatusColor(
      currentOrderStatus,
    );
    final IconData statusIconData = DeliveryOrdersScreen.getStatusIcon(
      currentOrderStatus,
    );

    final DateFormat dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final String createdAtFormatted =
        order.createdAt != null
            ? dateFormat.format(order.createdAt.toLocal())
            : 'N/A';
    final String assignedAtFormatted =
        order.assignedTime != null
            ? dateFormat.format(order.assignedTime!.toLocal())
            : 'N/A';

    return Column(
      // Wrap cards in a Column
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: statusColorValue.withAlpha(128),
              width: 1.5,
            ),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(statusIconData, color: statusColorValue, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Order #${order.id}',
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
                        statusLabelText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: statusColorValue,
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Order Information
                Text(
                  'Order Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.light.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.access_time,
                  'Created At',
                  createdAtFormatted,
                ),
                // Location Information
                const Divider(height: 24),
                Text(
                  'Location Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.light.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.location_city,
                  'Governorate',
                  order.governorate.isNotEmpty && order.governorate != 'N/A'
                      ? _capitalizeFirstLetter(order.governorate)
                      : 'No governorate provided',
                ),
                if (order.location.isNotEmpty)
                  _buildInfoRow(Icons.location_on, 'Address', order.location),

                // Recycle Bag Contents

                // Recycle Bag Contents
                if (order.items.isNotEmpty) ...[
                  const Divider(height: 24),
                  Text(
                    'Recycle Bag Contents',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.light.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: order.items.length,
                    itemBuilder: (context, index) {
                      final item = order.items[index];
                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: Icon(
                            Icons.recycling,
                            color: AppTheme.light.colorScheme.secondary,
                          ),
                          title: Text(
                            item.itemType,
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text('Points: ${item.points}'),
                          trailing: Text(
                            '${item.quantity} items',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
                // Action Buttons are now part of this card
                const Divider(height: 24),
                _buildActionButtons(order),
              ],
            ),
          ),
        ),
        // Customer Information Card (conditionally displayed below the main card)
        if ([
          'pending',
          'accepted',
          'in_transit',
        ].contains(currentOrderStatus.toLowerCase()))
          Padding(
            padding: const EdgeInsets.fromLTRB(
              12.0,
              0,
              12.0,
              16.0,
            ), // Increased bottom padding
            child: _buildCustomerInfo(order),
          ),
      ],
    );
  }

  Widget _buildActionButtons(DeliveryOrder order) {
    final String orderStatus = order.status?.toLowerCase() ?? 'unknown';
    List<Widget> buttons = [];

    if (orderStatus == 'pending') {
      buttons.addAll([
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _handleAcceptOrder(order),
            icon: const Icon(Icons.check),
            label: const Text('Accept'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _handleRejectOrder(order),
            icon: const Icon(Icons.close),
            label: const Text('Decline'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ]);
    } else if (orderStatus == 'accepted') {
      buttons.addAll([
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _handleStartDelivery(order),
            icon: const Icon(Icons.local_shipping),
            label: const Text('Start Delivery'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ]);
    } else if (orderStatus == 'in_transit') {
      buttons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showDeliveryConfirmation(order),
            icon: const Icon(Icons.check_circle),
            label: const Text('Complete Delivery'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      );
    }

    List<Widget> secondaryActionButtons = [];
    // Cancel button for 'accepted' or 'in_transit'
    if (orderStatus == 'accepted' || orderStatus == 'in_transit') {
      secondaryActionButtons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showCancelConfirmation(order),
            icon: const Icon(Icons.cancel),
            label: const Text('Cancel Order'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      );
    }

    // Reject button ONLY for 'in_transit'
    if (orderStatus == 'in_transit') {
      if (secondaryActionButtons.isNotEmpty) {
        // Add spacing if Cancel button is already there
        secondaryActionButtons.add(const SizedBox(width: 8));
      }
      secondaryActionButtons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showRejectConfirmation(order),
            icon: const Icon(Icons.block),
            label: const Text('Reject Order'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        if (buttons.isNotEmpty) Row(children: buttons),
        if (secondaryActionButtons.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(children: secondaryActionButtons),
        ],
      ],
    );
  }

  Future<void> _handleAcceptOrder(DeliveryOrder order) async {
    try {
      if (widget.email.isEmpty) {
        throw Exception('Delivery boy email is required');
      }

      setState(() => isLoading = true);
      logger.i(
        'Starting to accept order ${order.id} with email ${widget.email}',
      );

      await _ordersService.acceptOrder(order.id, widget.email);
      await _loadOrders(showLoadingIndicator: false);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Order accepted successfully')));
      }
    } catch (e) {
      logger.e('Error accepting order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _handleRejectOrder(DeliveryOrder order) async {
    try {
      setState(() => isLoading = true);

      if (mounted) {
        setState(() {
          orders.removeWhere((o) => o.id == order.id);
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order declined successfully'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      logger.e('Error declining order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _showDeliveryConfirmation(DeliveryOrder order) async {
    if (order.status?.toLowerCase() != 'in_transit') {
      try {
        setState(() => isLoading = true);
        await _ordersService.updateOrderStatus(
          order.id,
          'in_transit',
          email: widget.email,
        );
        if (!mounted) return;
        await _loadOrders(showLoadingIndicator: false);
      } catch (e) {
        logger.e('Error updating to in_transit: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل في تحديث حالة الطلب: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      } finally {
        if (mounted) {
          setState(() => isLoading = false);
        }
      }
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Complete Delivery'),
          content: const Text(
            'Are you sure you want to mark this order as delivered? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop({'confirm': true});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Complete Delivery'),
            ),
          ],
        );
      },
    );

    if (result != null && result['confirm'] == true) {
      try {
        setState(() => isLoading = true);
        await _ordersService.updateOrderStatus(
          order.id,
          'delivered',
          email: widget.email,
          items: order.items,
        );
        if (!mounted) return;
        if (mounted) {
          setState(() {
            orders.removeWhere((o) => o.id == order.id);
            isLoading = false;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إكمال التوصيل بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        logger.e('Error completing delivery: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل في إكمال التوصيل: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => isLoading = false);
        }
      }
    }
  }

  Future<void> _handleStartDelivery(DeliveryOrder order) async {
    try {
      setState(() => isLoading = true);
      final response = await http.post(
        Uri.parse(ApiConstants.startDelivery(order.id)),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'delivery_boy_email': widget.email,
          'status': 'in_transit',
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            final index = orders.indexWhere((o) => o.id == order.id);
            if (index != -1) {
              orders[index] = order.copyWith(status: 'in_transit');
            }
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم بدء التوصيل بنجاح'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() => isLoading = false);
        }
        throw Exception('Failed to start delivery: ${response.body}');
      }
    } catch (e) {
      logger.e('Error starting delivery: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في بدء التوصيل: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _showCancelConfirmation(DeliveryOrder order) async {
    // Check if order is in transit first
    if (order.status?.toLowerCase() == 'in_transit') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'لا يمكن إلغاء الطلب أثناء التوصيل. يرجى إكمال التوصيل أو رفض الطلب.',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Order'),
          content: const Text(
            'Are you sure you want to cancel this order? The order will be returned to pending status.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop({'confirm': true});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Yes, Cancel Order'),
            ),
          ],
        );
      },
    );

    if (result != null && result['confirm'] == true) {
      try {
        setState(() => isLoading = true);
        final int assignmentIdToCancel = order.id;
        logger.i(
          'Attempting to cancel assignment ID: $assignmentIdToCancel for order (bag ID not directly used here, but is order.recycleBagId if needed)',
        );
        await _ordersService.cancelOrder(
          assignmentIdToCancel,
          email: widget.email,
        );
        if (!mounted) return;
        await _loadOrders(showLoadingIndicator: false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إلغاء الطلب وإعادته إلى قائمة الطلبات المعلقة'),
            backgroundColor: Colors.orange,
          ),
        );
      } catch (e) {
        logger.e('Error canceling order: $e');
        if (mounted) {
          String errorMessage = 'فشل في إلغاء الطلب';

          // Check for specific error messages
          if (e.toString().contains('in transit')) {
            errorMessage =
                'لا يمكن إلغاء الطلب أثناء التوصيل. يرجى إكمال التوصيل أو رفض الطلب.';
          } else {
            errorMessage = 'فشل في إلغاء الطلب: ${e.toString()}';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => isLoading = false);
        }
      }
    }
  }

  Future<void> _showRejectConfirmation(DeliveryOrder order) async {
    String reason = '';
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reject Order'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Are you sure you want to reject this order? Please provide a reason:',
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Reason for rejection',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (value) => reason = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (reason.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please provide a reason for rejection'),
                    ),
                  );
                  return;
                }
                Navigator.of(
                  context,
                ).pop({'confirm': true, 'reason': reason.trim()});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reject Order'),
            ),
          ],
        );
      },
    );

    if (result != null && result['confirm'] == true) {
      try {
        setState(() => isLoading = true);
        final response = await http.post(
          Uri.parse(ApiConstants.rejectOrder(order.id)),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode({
            'email': widget.email,
            'reason': result['reason'] ?? 'Rejected by delivery boy',
          }),
        );

        if (response.statusCode != 200) {
          throw Exception('Failed to reject order: ${response.body}');
        }
        if (!mounted) return;
        if (mounted) {
          setState(() {
            orders.removeWhere((o) => o.id == order.id);
            isLoading = false;
          });
        }

        // Show rejection reason with a button to navigate to home screen
        final rejectionReason = result['reason'] ?? 'Rejected by delivery boy';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم رفض الطلب: $rejectionReason'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'الرئيسية',
              textColor: Colors.white,
              onPressed: () {
                // Navigate to home screen when button is pressed
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => DeliveryHomeScreen(email: widget.email),
                  ),
                  (route) => false, // Remove all previous routes
                );
              },
            ),
          ),
        );
      } catch (e) {
        logger.e('Error rejecting order: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل في رفض الطلب: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => isLoading = false);
        }
      }
    }
  }

  void _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('رقم الهاتف غير متوفر')));
      return;
    }

    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('لا يمكن الاتصال بالرقم: $phoneNumber')),
        );
      }
    } catch (e) {
      logger.e('Error making phone call: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء محاولة الاتصال')));
    }
  }

  // Helper method to capitalize the first letter of a string
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  void _openChat(DeliveryOrder order) {
    if (order.customerEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('لا يمكن فتح المحادثة: بريد العميل غير متوفر')),
      );
      return;
    }

    if (!['accepted', 'in_transit'].contains(order.status?.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('لا يمكن فتح المحادثة: حالة الطلب لا تسمح بذلك'),
        ),
      );
      return;
    }

    setState(() {
      _selectedOrderId = order.id;
      _isChatOpen = true;
    });

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Chat with Customer'),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.6,
              child: ChatWidget(
                assignmentId: order.id,
                userEmail: order.customerEmail,
                deliveryBoyEmail: widget.email,
                currentSenderEmail: widget.email,
                currentSenderType: 'delivery_boy',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _isChatOpen = false;
                    _selectedOrderId = null;
                  });
                },
                child: Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildCustomerInfo(DeliveryOrder order) {
    return Card(
      margin: const EdgeInsets.symmetric(
        vertical: 4,
        horizontal: 0,
      ), // Increased vertical margin for better visibility
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: AppTheme.light.colorScheme.primary.withAlpha(80),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Information',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.light.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 25,
                  child: const Icon(Icons.person, size: 25),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (order.customerName.isNotEmpty)
                        Text(
                          order.customerName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (order.customerPhone.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          order.customerPhone,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (order.customerPhone.isNotEmpty)
                      IconButton(
                        onPressed: () => _makePhoneCall(order.customerPhone),
                        icon: Icon(
                          Icons.phone_outlined,
                          color: AppTheme.light.colorScheme.primary,
                          size: 22,
                        ),
                        tooltip: 'Call Customer',
                      ),
                    IconButton(
                      onPressed: () => _openChat(order),
                      icon: Icon(
                        Icons.chat_outlined,
                        color: AppTheme.light.colorScheme.primary,
                        size: 22,
                      ),
                      tooltip: 'Chat with Customer',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DeliveryConfirmationDialog extends StatefulWidget {
  @override
  _DeliveryConfirmationDialogState createState() =>
      _DeliveryConfirmationDialogState();
}

class _DeliveryConfirmationDialogState
    extends State<DeliveryConfirmationDialog> {
  bool isDelivered = true;
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delivery Confirmation'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Order Delivered Successfully'),
            leading: Radio<bool>(
              value: true,
              groupValue: isDelivered,
              onChanged: (value) => setState(() => isDelivered = value!),
            ),
          ),
          ListTile(
            title: const Text('Order Has Issues'),
            leading: Radio<bool>(
              value: false,
              groupValue: isDelivered,
              onChanged: (value) => setState(() => isDelivered = value!),
            ),
          ),
          if (!isDelivered) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for Rejection',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (!isDelivered && _reasonController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please provide a reason for rejection'),
                ),
              );
              return;
            }
            Navigator.pop(context, {
              'isDelivered': isDelivered,
              'reason': isDelivered ? null : _reasonController.text,
            });
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
