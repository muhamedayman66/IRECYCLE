import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:graduation_project11/core/api/api_constants.dart';
import '../models/delivery_order.dart';
import 'package:logger/logger.dart';
import 'package:flutter/material.dart';

class DeliveryOrdersService {
  final http.Client _client;
  final logger = Logger();

  DeliveryOrdersService({http.Client? client})
      : _client = client ?? http.Client();

  Future<List<DeliveryOrder>> getAvailableOrders(String email) async {
    try {
      logger.i('🔍 Fetching available orders for email: $email');
      final url = ApiConstants.availableOrders(email);
      logger.i('📡 Request URL: $url');

      final response = await _client.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          logger.e('⚠️ Request timed out');
          throw Exception('Request timed out');
        },
      );

      logger.i('📥 Response status code: ${response.statusCode}');
      logger.i('📥 Response headers: ${response.headers}');
      logger.i('📥 Raw response body: ${response.body}');

      if (response.statusCode != 200) {
        logger.e('❌ API error: ${response.statusCode}');
        logger.e('❌ Error body: ${response.body}');
        throw Exception('Failed to fetch orders (HTTP ${response.statusCode})');
      }

      final List<dynamic> ordersJson = json.decode(response.body);
      logger.i('📦 Decoded JSON length: ${ordersJson.length}');

      if (ordersJson.isEmpty) {
        logger.i('⚠️ No available orders found');
        return [];
      }

      final orders = <DeliveryOrder>[];

      for (var json in ordersJson) {
        logger.i('🔄 Processing order JSON: $json');
        try {
          final recycleBag = json['recycle_bag'] as Map<String, dynamic>? ?? {};
          logger.i('📦 Recycle bag data: $recycleBag');

          final userDetails =
              recycleBag['user_details'] as Map<String, dynamic>? ?? {};
          logger.i('👤 User details: $userDetails');

          final order = DeliveryOrder.fromJson(json);
          logger.i('✅ Successfully parsed order: ${order.id}');
          logger.i(
            '📝 Order full details:'
            '\n- ID: ${order.id}'
            '\n- Status: ${order.status}'
            '\n- RecycleBagId: ${order.recycleBagId}'
            '\n- Customer: ${order.customerName}'
            '\n- Phone: ${order.customerPhone}'
            '\n- Governorate: ${order.governorate}'
            '\n- Address: ${order.address}'
            '\n- Created: ${order.createdAt}'
            '\n- Assigned: ${order.assignedTime}'
            '\n- Items Count: ${order.items.length}'
            '\n- Delivery Boy: ${order.deliveryBoy}',
          );

          // تحسين التحقق من حالة الطلب
          final isPending = order.status?.toLowerCase() == 'pending';

          // تحسين التحقق من تعيين الطلب
          final isNotAssigned = order.deliveryBoy == null ||
              order.deliveryBoy!.isEmpty ||
              order.deliveryBoy!['email'] == null ||
              order.deliveryBoy!['email'].toString().trim().isEmpty;

          // تحسين التحقق من المحافظة
          final orderGovernorate = order.governorate.toLowerCase().trim();
          final isInSameGovernorate = orderGovernorate == 'asyut' ||
              orderGovernorate == 'أسيوط' ||
              orderGovernorate.contains('اسيوط');

          logger.i(
            '🔍 Order ${order.id} validation:'
            '\n- isPending: $isPending'
            '\n- isNotAssigned: $isNotAssigned'
            '\n- isInSameGovernorate: $isInSameGovernorate'
            '\n- orderGovernorate: $orderGovernorate'
            '\n- deliveryBoy: ${order.deliveryBoy}',
          );

          // تعديل شروط إضافة الطلب
          final shouldAdd = (isPending && isInSameGovernorate) ||
              (order.isAssignedTo(email) &&
                  [
                    'accepted',
                    'in_transit',
                  ].contains(order.status?.toLowerCase()));

          if (shouldAdd) {
            logger.i('✅ Adding order ${order.id} to available orders list');
            orders.add(order);
          } else {
            logger.i(
              '❌ Skipping order ${order.id}:'
              '\n- Not pending: ${!isPending}'
              '\n- Wrong governorate: ${!isInSameGovernorate}'
              '\n- Not assigned to me: ${!order.isAssignedTo(email)}'
              '\n- Current governorate: $orderGovernorate'
              '\n- Current status: ${order.status}',
            );
          }
        } catch (e, stackTrace) {
          logger.e('❌ Error parsing order: $e');
          logger.e('Stack trace: $stackTrace');
          logger.e('Problematic JSON: $json');
          continue;
        }
      }

      // Sort orders by creation time (newest first)
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      logger.i('📊 Final available orders count: ${orders.length}');
      if (orders.isEmpty) {
        logger.i('⚠️ No orders passed validation');
      } else {
        logger.i('✅ Found ${orders.length} valid orders');
        for (var order in orders) {
          logger.i(
            '📦 Order ${order.id}:'
            '\n- Status: ${order.status}'
            '\n- Governorate: ${order.governorate}'
            '\n- Delivery Boy: ${order.deliveryBoy}',
          );
        }
      }
      return orders;
    } catch (e, stackTrace) {
      logger.e('❌ Error in getAvailableOrders: $e');
      logger.e('Stack trace: $stackTrace');
      throw Exception('Failed to fetch available orders: $e');
    }
  }

  Future<bool> hasActiveOrder(String email) async {
    try {
      logger.i('🔍 Checking for active orders for email: $email');
      final response = await _client.get(
        Uri.parse(ApiConstants.deliveryHistory(email)),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> ordersJson = json.decode(response.body);
        final hasActive = ordersJson.any((json) {
          final order = DeliveryOrder.fromJson(json);
          final status = order.status?.toLowerCase();
          final isAssignedToMe = order.isAssignedTo(email);
          final isActive = ['accepted', 'in_transit'].contains(status);

          logger.i(
            '📋 Order ${order.id} check:' +
                '\n- Status: $status' +
                '\n- Assigned to me: $isAssignedToMe' +
                '\n- Is active: $isActive',
          );

          return isAssignedToMe && isActive;
        });

        logger.i(hasActive ? '⚠️ Found active order' : '✅ No active orders');
        return hasActive;
      }

      logger.e('❌ Failed to check active orders: ${response.statusCode}');
      return false;
    } catch (e) {
      logger.e('❌ Error checking active orders: $e');
      return false;
    }
  }

  Future<bool> acceptOrder(int assignmentId, String email) async {
    // Renamed orderId to assignmentId
    try {
      // Optional: Consider re-adding hasActiveOrder check if business logic requires it strictly here.
      // if (await hasActiveOrder(email)) {
      //   throw Exception('You already have an active order. Complete it first.');
      // }

      logger.i(
        'Attempting to accept assignment $assignmentId for delivery boy $email',
      );

      // The backend `place_order` now ensures a pending DeliveryAssignment exists.
      // `get_available_orders` returns this assignment_id as `DeliveryOrder.id`.
      // So, we directly use this assignmentId to call the accept endpoint.

      final acceptUrl = ApiConstants.acceptOrder(
        assignmentId,
      ); // Uses /api/assignments/<assignment_id>/accept/
      logger.i('Accept order URL: $acceptUrl');

      final response = await _client.post(
        Uri.parse(acceptUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email,
        }), // Backend accept_order view expects 'email'
      );

      logger.i('Accept order request body: ${json.encode({'email': email})}');
      logger.i('Accept order response status: ${response.statusCode}');
      logger.i('Accept order response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to accept order: ${response.body}');
      }

      logger.i('Assignment $assignmentId accepted successfully by $email');
      return true;
    } catch (e) {
      logger.e('Error accepting order for assignment $assignmentId: $e');
      // Consider re-throwing a more specific error or the original error
      throw Exception('Error accepting order: $e');
    }
  }

  Future<bool> rejectOrder(
    int orderId, {
    String? reason,
    required String email,
  }) async {
    try {
      // First create an assignment if it doesn't exist
      final createAssignmentResponse = await _client.post(
        Uri.parse(ApiConstants.createAssignment()),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'recycle_bag_id': orderId,
          'delivery_boy_email': email,
        }),
      );

      logger.i(
        'Create assignment response: ${createAssignmentResponse.statusCode}, Body: ${createAssignmentResponse.body}',
      );

      if (createAssignmentResponse.statusCode != 201 &&
          createAssignmentResponse.statusCode != 200) {
        logger.e(
          'Failed to create assignment: ${createAssignmentResponse.statusCode}, Body: ${createAssignmentResponse.body}',
        );
        throw Exception('Failed to create assignment');
      }

      final assignmentData = json.decode(createAssignmentResponse.body);
      final assignmentId = assignmentData['id'];

      logger.i('Created assignment with ID: $assignmentId');

      // Reject the assignment
      final response = await _client.post(
        Uri.parse(ApiConstants.rejectOrder(assignmentId)),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'reason': reason, 'delivery_boy_email': email}),
      );

      if (response.statusCode != 200) {
        logger.e(
          'Failed to reject assignment: ${response.statusCode}, Body: ${response.body}',
        );
        throw Exception('Failed to reject order');
      }

      logger.i(
        'Order $orderId (Assignment $assignmentId) rejected successfully',
      );
      return true;
    } catch (e) {
      logger.e('Error rejecting order: $e');
      throw Exception('Error: $e');
    }
  }

  Future<bool> updateOrderStatus(
    int orderId,
    String status, {
    required String email,
    String? discrepancyReport,
    List<RecycleBagItem> items = const [],
  }) async {
    try {
      logger.i('🔄 Updating order $orderId status to $status');

      if (status.toLowerCase() == 'accepted') {
        final hasActive = await hasActiveOrder(email);
        if (hasActive) {
          throw Exception(
            'You already have an active order. Complete it first.',
          );
        }
      }

      // التحقق من وجود العناصر عند تحديث الحالة إلى delivered
      if (status.toLowerCase() == 'delivered' && items.isEmpty) {
        logger.e('❌ Cannot complete order: No items found');
        throw Exception('Cannot complete order: No items found');
      }

      // التحقق من أن الطلب في حالة in_transit قبل إكماله
      if (status.toLowerCase() == 'delivered') {
        final order = await _getCurrentOrder(orderId, email: email);
        if (order.status?.toLowerCase() != 'in_transit') {
          throw Exception(
            'Order must be in transit before completing delivery',
          );
        }
      }

      String endpoint;
      Map<String, dynamic> body = {
        'delivery_boy_email': email,
        'status': status.toLowerCase(),
      };

      // تحديث طريقة إرسال العناصر لتتوافق مع النموذج الجديد
      if (items.isNotEmpty) {
        body['items'] = items
            .map(
              (item) => {
                'type': item.itemType,
                'quantity': item.quantity,
                'points': item.points,
                if (item.weight != null) 'weight': item.weight,
                if (item.description != null) 'description': item.description,
                if (item.imageUrl != null) 'image_url': item.imageUrl,
                if (item.addedAt != null)
                  'added_at': item.addedAt!.toIso8601String(),
              },
            )
            .toList();
        logger.i('📦 Items to be updated: ${body['items']}');
      }

      switch (status.toLowerCase()) {
        case 'accepted':
          endpoint = ApiConstants.acceptOrder(orderId);
          break;
        case 'in_transit':
          endpoint = ApiConstants.verifyOrder(orderId);
          break;
        case 'delivered':
          endpoint = ApiConstants.completeOrder(orderId);
          body['update_points'] = true;
          body['update_rewards'] = true;
          break;
        case 'rejected':
          endpoint = ApiConstants.rejectOrder(orderId);
          if (discrepancyReport != null) {
            body['reason'] = discrepancyReport;
          }
          break;
        case 'canceled':
          endpoint = ApiConstants.cancelOrder(orderId);
          body = {
            'delivery_boy_email': email,
            'cancel_reason': 'Canceled by delivery boy',
            'status': 'canceled',
            'return_to_pending': true,
          };
          break;
        default:
          throw Exception('Invalid status: $status');
      }

      logger.i('📤 Sending request to: $endpoint');
      logger.i('📤 Request body: $body');

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(body),
      );

      logger.i(
        '📥 Update status response: HTTP ${response.statusCode}, Body: ${response.body}',
      );

      if (response.statusCode != 200) {
        final errorBody = response.body;
        logger.e('❌ API error response: $errorBody');
        throw Exception(
          'Failed to update order status to $status (HTTP ${response.statusCode}): $errorBody',
        );
      }

      logger.i('✅ Order $orderId status updated to $status successfully');
      return true;
    } catch (e) {
      logger.e('❌ Error updating order status: $e');
      throw Exception('Error updating order status: $e');
    }
  }

  Future<void> _updatePointsAndRewards(int orderId, String email) async {
    // هذه الدالة لم تعد مطلوبة لأن تحديث النقاط والمكافآت يتم تلقائياً في الخادم
    logger.i('✅ Points and rewards are updated automatically by the server');
  }

  Future<DeliveryOrder> _getCurrentOrder(
    int orderId, {
    required String email,
  }) async {
    try {
      logger.i('Fetching order details for order $orderId');

      // أولاً، نحاول العثور على الطلب في التاريخ
      final historyResponse = await http.get(
        Uri.parse(ApiConstants.deliveryHistory(email)),
        headers: {'Content-Type': 'application/json'},
      );

      logger.i('History response: ${historyResponse.statusCode}');

      if (historyResponse.statusCode == 200) {
        final List<dynamic> orders = json.decode(historyResponse.body);
        final order = orders.firstWhere(
          (o) => o['id'] == orderId,
          orElse: () => null,
        );

        if (order != null) {
          logger.i('Found order in history: $order');
          return DeliveryOrder.fromJson(order);
        }
      }

      // إذا لم نجد في التاريخ، نبحث في الطلبات المتاحة
      logger.i('Order not found in history, checking available orders...');
      final availableResponse = await http.get(
        Uri.parse(ApiConstants.availableOrders(email)),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      logger.i('Available orders response: ${availableResponse.statusCode}');

      if (availableResponse.statusCode == 200) {
        final List<dynamic> orders = json.decode(availableResponse.body);
        final order = orders.firstWhere(
          (o) => o['id'] == orderId,
          orElse: () => null,
        );

        if (order != null) {
          logger.i('Found order in available orders: $order');
          return DeliveryOrder.fromJson(order);
        }
      }

      // إذا لم نجد الطلب في أي من القائمتين
      logger.e('Order $orderId not found in any list');
      throw Exception('Order not found in available orders or history');
    } catch (e) {
      logger.e('Error getting order $orderId: $e');
      throw Exception('Error getting order details: $e');
    }
  }

  bool _isValidStatusTransition(String currentStatus, String newStatus) {
    final validTransitions = {
      'pending': <String>{'accepted', 'rejected', 'canceled'},
      'accepted': <String>{'in_transit', 'rejected', 'canceled'},
      'in_transit': <String>{'delivered', 'rejected', 'canceled'},
      'delivered': <String>{},
      'rejected': <String>{},
      'canceled': <String>{},
    };

    currentStatus = currentStatus.toLowerCase();
    newStatus = newStatus.toLowerCase();

    logger.i('🔄 Checking status transition: $currentStatus -> $newStatus');
    final isValid =
        validTransitions[currentStatus]?.contains(newStatus) ?? false;
    logger.i(isValid ? '✅ Valid transition' : '❌ Invalid transition');

    return isValid;
  }

  Future<void> cancelOrder(int orderId, {required String email}) async {
    try {
      // تحقق من الإيميل
      if (email == null || email.isEmpty) {
        logger.e('❌ Delivery boy email is empty or null');
        throw Exception('Delivery boy email cannot be empty');
      }

      // جيب تفاصيل الطلب الحالي
      final order = await _getCurrentOrder(orderId, email: email);

      // تحقق من حالة الطلب - لا يمكن إلغاء الطلبات التي في حالة in_transit
      if (order.status?.toLowerCase() == 'in_transit') {
        logger.e(
          '❌ Order ${order.id} cannot be cancelled (status: in_transit)',
        );
        throw Exception(
            'Order cannot be cancelled when in transit. Please complete the delivery or reject the order.');
      }

      if (!order.canBeCanceled) {
        logger.e(
          '❌ Order ${order.id} cannot be cancelled (status: ${order.status})',
        );
        throw Exception('Order cannot be cancelled in current status');
      }

      // First create an assignment if it doesn't exist
      final createAssignmentResponse = await _client.post(
        Uri.parse(ApiConstants.createAssignment()),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'recycle_bag_id': orderId,
          'delivery_boy_email': email,
        }),
      );

      logger.i(
        'Create assignment response: ${createAssignmentResponse.statusCode}, Body: ${createAssignmentResponse.body}',
      );

      if (createAssignmentResponse.statusCode != 201 &&
          createAssignmentResponse.statusCode != 200) {
        logger.e(
          'Failed to create assignment: ${createAssignmentResponse.statusCode}, Body: ${createAssignmentResponse.body}',
        );
        throw Exception('Failed to create assignment');
      }

      final assignmentData = json.decode(createAssignmentResponse.body);
      final assignmentId = assignmentData['id'];

      logger.i('Created assignment with ID: $assignmentId');

      // طباعة الـ body قبل الإرسال للتأكد
      final requestBody = {
        'email':
            email, // تغيير من 'delivery_boy_email' إلى 'email' لتتوافق مع ما يتوقعه الخادم
        'return_to_pending': true,
        'reason': 'Cancelled by delivery boy',
        'status': 'pending',
      };
      logger.i('📤 Cancel request body: $requestBody');

      // Cancel the assignment
      final response = await _client.post(
        Uri.parse(ApiConstants.cancelOrder(assignmentId)),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode != 200) {
        logger.e(
          'Failed to cancel assignment: ${response.statusCode}, Body: ${response.body}',
        );
        throw Exception('Failed to cancel order: ${response.body}');
      }

      logger.i(
        'Order $orderId (Assignment $assignmentId) cancelled successfully',
      );
    } catch (e) {
      logger.e('Error cancelling order: $e');
      throw Exception('Error: $e');
    }
  }

  Future<List<DeliveryOrder>> getCurrentOrders(String email) async {
    try {
      logger.i('Fetching current orders for email: $email');
      final url = ApiConstants.deliveryHistory(email);
      logger.i('Request URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      logger.i('Response status code: ${response.statusCode}');
      logger.i('Raw response body: ${response.body}');
      logger.i('Response headers: ${response.headers}');
      logger.i('Response content type: ${response.headers['content-type']}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          logger.i('Response body is empty');
          return [];
        }

        final List<dynamic> ordersJson = json.decode(response.body);
        logger.i(
          'Successfully decoded JSON. Array length: ${ordersJson.length}',
        );
        logger.i('Raw decoded JSON: $ordersJson');

        final orders = ordersJson.map((json) {
          logger.i('Processing order: $json');
          return DeliveryOrder.fromJson(json);
        }).where((order) {
          // Check if order is active and assigned to this delivery boy
          final isActive = [
            'accepted',
            'in_transit',
          ].contains(order.status?.toLowerCase());
          final isAssignedToMe = order.isAssignedTo(email);

          logger.i(
            'Order ${order.id} - Status: ${order.status}, isActive: $isActive, isAssignedToMe: $isAssignedToMe',
          );

          return isActive && isAssignedToMe;
        }).toList();

        // Sort by most recent first
        orders.sort((a, b) => b.assignedTime.compareTo(a.assignedTime));

        logger.i('Filtered to ${orders.length} active orders for $email');
        return orders;
      }

      logger.e('Failed to load current orders: ${response.statusCode}');
      throw Exception('Failed to load current orders: ${response.statusCode}');
    } catch (e) {
      logger.e('Error fetching current orders: $e');
      throw Exception('Error: $e');
    }
  }

  Widget _buildActionButtons(DeliveryOrder order) {
    final status = order.status?.toLowerCase() ?? 'unknown';
    final buttonStyle = ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );

    // For pending orders - show Accept/Reject
    if (status == 'pending') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _handleAcceptOrder(order),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Accept'),
              style: buttonStyle.copyWith(
                backgroundColor: MaterialStateProperty.all(Colors.green),
                foregroundColor: MaterialStateProperty.all(Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _handleRejectOrder(order),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Reject'),
              style: buttonStyle.copyWith(
                backgroundColor: MaterialStateProperty.all(Colors.red),
                foregroundColor: MaterialStateProperty.all(Colors.white),
              ),
            ),
          ),
        ],
      );
    }

    // For accepted orders - show Start Delivery/Cancel/Reject
    if (status == 'accepted') {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleStartDelivery(order),
                  icon: const Icon(Icons.local_shipping),
                  label: const Text('Start Delivery'),
                  style: buttonStyle.copyWith(
                    backgroundColor: MaterialStateProperty.all(Colors.green),
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showCancelConfirmation(order),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel Order'),
                  style: buttonStyle.copyWith(
                    backgroundColor: MaterialStateProperty.all(Colors.orange),
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showRejectConfirmation(order),
                  icon: const Icon(Icons.block),
                  label: const Text('Reject Order'),
                  style: buttonStyle.copyWith(
                    backgroundColor: MaterialStateProperty.all(Colors.red),
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // For in_transit orders - show Complete/Cancel/Reject
    if (status == 'in_transit') {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showDeliveryConfirmation(order),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Complete Delivery'),
                  style: buttonStyle.copyWith(
                    backgroundColor: MaterialStateProperty.all(Colors.green),
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showCancelConfirmation(order),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel Order'),
                  style: buttonStyle.copyWith(
                    backgroundColor: MaterialStateProperty.all(Colors.orange),
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showRejectConfirmation(order),
                  icon: const Icon(Icons.block),
                  label: const Text('Reject Order'),
                  style: buttonStyle.copyWith(
                    backgroundColor: MaterialStateProperty.all(Colors.red),
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Container(); // No buttons for other statuses
  }

  Future<void> _handleAcceptOrder(DeliveryOrder order) async {
    try {
      await acceptOrder(order.id, order.deliveryBoy!['email']);
      logger.i('✅ Order ${order.id} accepted successfully');
    } catch (e) {
      logger.e('❌ Error accepting order: $e');
      throw Exception('Failed to accept order: $e');
    }
  }

  Future<void> _handleStartDelivery(DeliveryOrder order) async {
    try {
      await updateOrderStatus(
        order.id,
        'in_transit',
        email: order.deliveryBoy!['email'],
      );
      logger.i('✅ Order ${order.id} status updated to in_transit');
    } catch (e) {
      logger.e('❌ Error starting delivery: $e');
      throw Exception('Failed to start delivery: $e');
    }
  }

  Future<void> _handleRejectOrder(DeliveryOrder order, {String? reason}) async {
    try {
      await rejectOrder(
        order.id,
        reason: reason,
        email: order.deliveryBoy!['email'],
      );
      logger.i('✅ Order ${order.id} rejected successfully');
    } catch (e) {
      logger.e('❌ Error rejecting order: $e');
      throw Exception('Failed to reject order: $e');
    }
  }

  void _showCancelConfirmation(DeliveryOrder order) {
    // تنفيذ عملية الإلغاء
    try {
      cancelOrder(order.id, email: order.deliveryBoy!['email']);
      logger.i('✅ Order ${order.id} cancelled successfully');
    } catch (e) {
      logger.e('❌ Error cancelling order: $e');
      throw Exception('Failed to cancel order: $e');
    }
  }

  void _showRejectConfirmation(DeliveryOrder order) {
    // تنفيذ عملية الرفض
    try {
      _handleRejectOrder(order, reason: 'Rejected by delivery boy');
    } catch (e) {
      logger.e('❌ Error rejecting order: $e');
      throw Exception('Failed to reject order: $e');
    }
  }

  void _showDeliveryConfirmation(DeliveryOrder order) {
    // تنفيذ عملية إكمال التوصيل
    try {
      updateOrderStatus(
        order.id,
        'delivered',
        email: order.deliveryBoy!['email'],
      );
      logger.i('✅ Order ${order.id} completed successfully');
    } catch (e) {
      logger.e('❌ Error completing delivery: $e');
      throw Exception('Failed to complete delivery: $e');
    }
  }

  Widget buildOrderCard(DeliveryOrder order) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getStatusColor(order.status).withAlpha(128),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _getStatusIcon(order.status),
                      color: _getStatusColor(order.status),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Order #${order.id}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ],
                ),
                Chip(
                  label: Text(
                    order.status ?? 'Unknown',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: _getStatusColor(order.status),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.location_city,
              'Area',
              order.governorate ?? 'Not specified',
            ),
            _buildInfoRow(
              Icons.access_time,
              'Created',
              _formatDateTime(order.createdAt),
            ),
            if (order.items.isNotEmpty) ...[
              const Divider(height: 24),
              const Text(
                'Items:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                ),
              ),
              const SizedBox(height: 8),
              ...order.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.itemType,
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Qty: ${item.quantity} (${item.points} pts)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const Divider(height: 24),
            _buildActionButtons(order),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'Roboto',
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
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

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase() ?? 'unknown') {
      case 'pending':
        return Icons.pending;
      case 'accepted':
        return Icons.check_circle_outline;
      case 'in_transit':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.done_all;
      case 'rejected':
      case 'canceled':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase() ?? 'unknown') {
      case 'pending':
        return Colors.grey;
      case 'accepted':
        return Colors.lightGreen;
      case 'in_transit':
        return Colors.green;
      case 'delivered':
        return Colors.teal;
      case 'rejected':
      case 'canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final dt = dateTime.toLocal();
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
