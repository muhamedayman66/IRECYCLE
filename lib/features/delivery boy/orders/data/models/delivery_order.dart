import 'package:logger/logger.dart';

final logger = Logger();

class DeliveryOrder {
  final int id;
  final String? status;
  final int recycleBagId;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String governorate;
  final String address;
  final String location;
  final String latitude;
  final String longitude;
  final DateTime createdAt;
  final DateTime assignedTime;
  final List<RecycleBagItem> items;
  final String? discrepancyReport;
  final Map<String, dynamic>? deliveryBoy;

  DeliveryOrder({
    required this.id,
    this.status,
    required this.recycleBagId,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.governorate,
    required this.address,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.assignedTime,
    required this.items,
    this.discrepancyReport,
    this.deliveryBoy,
  }) {
    // Validate critical fields
    if (id <= 0) {
      throw ArgumentError('Invalid order ID: $id');
    }
    if (recycleBagId <= 0) {
      throw ArgumentError('Invalid recycle bag ID: $recycleBagId');
    }
  }

  factory DeliveryOrder.fromJson(Map<String, dynamic> json) {
    try {
      logger.i('Parsing order data: ${json.toString()}');

      // Extract and validate user details
      final userDetails = json['user_details'] as Map<String, dynamic>? ?? {};

      // Validate assignment ID (this will be the main ID for DeliveryOrder)
      // Try 'assignment_id' first, then fall back to 'id' for compatibility with history endpoint
      dynamic assignmentIdValue = json['assignment_id'] ?? json['id'];
      final assignmentId =
          int.tryParse(assignmentIdValue?.toString() ?? '0') ?? 0;

      if (assignmentId <= 0) {
        throw FormatException(
          'Invalid or missing assignment_id (tried "assignment_id" and "id"): $assignmentIdValue',
        );
      }

      // Validate bag_id
      // Try to get bag_id from top level, then from nested recycle_bag.id
      dynamic bagIdValue = json['bag_id'];
      if (bagIdValue == null) {
        final recycleBagData = json['recycle_bag'] as Map<String, dynamic>?;
        if (recycleBagData != null) {
          bagIdValue = recycleBagData['id'];
        }
      }
      final bagId = int.tryParse(bagIdValue?.toString() ?? '0') ?? 0;

      if (bagId <= 0) {
        throw FormatException(
          'Invalid or missing bag_id (tried "bag_id" and "recycle_bag.id"): $bagIdValue',
        );
      }

      // Parse and validate location data
      String location = 'N/A';
      String latitude = '';
      String longitude = '';

      if (json['latitude'] != null && json['longitude'] != null) {
        final lat = json['latitude'].toString();
        final long = json['longitude'].toString();

        if (lat.isNotEmpty && long.isNotEmpty) {
          try {
            // Validate coordinates
            final latNum = double.parse(lat);
            final longNum = double.parse(long);
            if (latNum >= -90 &&
                latNum <= 90 &&
                longNum >= -180 &&
                longNum <= 180) {
              latitude = lat;
              longitude = long;
              location = '$lat, $long';
            } else {
              logger.w('Invalid coordinates: lat=$lat, long=$long');
            }
          } catch (e) {
            logger.e('Error parsing coordinates: $e');
          }
        }
      }

      // Extract recycle_bag details if present, for other fields like items, user_details etc.
      final recycleBagDetails =
          json['recycle_bag'] as Map<String, dynamic>? ?? {};

      // Parse and validate dates
      // Use top-level created_at and assigned_at if available (from history endpoint)
      // Fallback to recycle_bag.created_at if not (older available_orders structure)
      DateTime createdAt;
      try {
        createdAt = DateTime.parse(
          json['created_at']?.toString() ??
              recycleBagDetails['created_at']?.toString() ??
              DateTime.now().toIso8601String(),
        );
      } catch (e) {
        logger.e(
          'Error parsing created_at date: $e. JSON value: ${json['created_at']}, RecycleBag value: ${recycleBagDetails['created_at']}',
        );
        createdAt = DateTime.now();
      }

      DateTime assignedTime;
      try {
        // 'assigned_at' is usually top-level for assignments.
        // 'assigned_time' was used in an older structure.
        assignedTime = DateTime.parse(
          json['assigned_at']?.toString() ??
              json['assigned_time']?.toString() ??
              createdAt.toIso8601String(),
        );
      } catch (e) {
        logger.e(
          'Error parsing assigned_at/assigned_time date: $e. JSON value: ${json['assigned_at'] ?? json['assigned_time']}',
        );
        assignedTime = createdAt;
      }

      // User details: prefer top-level user_details if present (from available_orders),
      // else from recycle_bag.user_details (from history)
      final Map<String, dynamic> userDetailsToUse =
          json['user_details'] as Map<String, dynamic>? ??
          recycleBagDetails['user_details'] as Map<String, dynamic>? ??
          {};

      // Items: prefer top-level items if present, else from recycle_bag.items
      final itemsList = json['items'] ?? recycleBagDetails['items'];

      // Location fields: prefer top-level, fallback to recycle_bag
      String finalLatitude =
          json['latitude']?.toString() ??
          recycleBagDetails['latitude']?.toString() ??
          '';
      String finalLongitude =
          json['longitude']?.toString() ??
          recycleBagDetails['longitude']?.toString() ??
          '';
      // String finalLocation = 'N/A'; // 'location' is already defined and potentially set above
      if (finalLatitude.isNotEmpty && finalLongitude.isNotEmpty) {
        try {
          final latNum = double.parse(finalLatitude);
          final longNum = double.parse(finalLongitude);
          if (latNum >= -90 &&
              latNum <= 90 &&
              longNum >= -180 &&
              longNum <= 180) {
            location = // Re-assign to the 'location' variable defined earlier
                '$finalLatitude, $finalLongitude';
          } else {
            logger.w(
              'Invalid coordinates: lat=$finalLatitude, long=$finalLongitude',
            );
          }
        } catch (e) {
          logger.e('Error parsing final coordinates: $e');
        }
      }

      final String parsedCustomerEmail =
          userDetailsToUse['email']?.toString() ?? '';
      if (parsedCustomerEmail.isEmpty) {
        logger.w(
          '⚠️ Customer email is missing or empty in user_details for assignment ID: $assignmentId. Contents of user_details: $userDetailsToUse',
        );
      }

      return DeliveryOrder(
        id: assignmentId, // Use assignment_id as the main ID for DeliveryOrder
        status:
            json['status']?.toString() ??
            recycleBagDetails['status']?.toString(), // Prefer top-level status
        recycleBagId: bagId,
        customerName:
            userDetailsToUse['name']?.toString() ??
            ('${userDetailsToUse['first_name']?.toString() ?? ''} ${userDetailsToUse['last_name']?.toString() ?? ''}')
                .trim(),
        customerEmail: parsedCustomerEmail,
        customerPhone:
            userDetailsToUse['phone_number']?.toString() ??
            userDetailsToUse['phone']?.toString() ??
            'N/A',
        governorate:
            json['governorate']?.toString() ?? // Check top-level first
            userDetailsToUse['governorate']
                ?.toString() ?? // Then check consolidated user_details
            'N/A', // Fallback
        address:
            json['address']?.toString() ??
            recycleBagDetails['address']?.toString() ??
            'N/A',
        location:
            location, // This was updated with finalLatitude/finalLongitude
        latitude: finalLatitude,
        longitude: finalLongitude,
        createdAt: createdAt,
        assignedTime: assignedTime,
        items: RecycleBagItem.parseItems(itemsList),
        discrepancyReport: json['discrepancy_report']?.toString(),
        deliveryBoy:
            json['delivery_boy']
                as Map<
                  String,
                  dynamic
                >?, // Top-level delivery_boy for assignment
      );
    } catch (e, stackTrace) {
      logger.e('Error parsing DeliveryOrder: $e');
      logger.e('Stack trace: $stackTrace');
      logger.e('JSON data: ${json.toString()}');
      rethrow;
    }
  }

  // Helper method to normalize governorate names
  static String _normalizeGovernorate(String governorate) {
    governorate = governorate.toLowerCase().trim();
    if (governorate.contains('اسيوط') ||
        governorate.contains('أسيوط') ||
        governorate == 'asyut') {
      return 'Asyut';
    }
    return governorate;
  }

  // Helper method to parse integers safely
  static int _parseInt(String? value, String field) {
    if (value == null) {
      logger.w('⚠️ Warning: $field is null');
      return 0;
    }
    try {
      return int.parse(value);
    } catch (e) {
      logger.w('⚠️ Warning: Failed to parse $field: $value');
      return 0;
    }
  }

  // Helper method to parse dates safely
  static DateTime _parseDateTime(dynamic value, String field) {
    if (value == null) {
      logger.w('⚠️ Warning: $field is null, using current time');
      return DateTime.now();
    }
    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      logger.w('⚠️ Warning: Failed to parse $field: $value');
      return DateTime.now();
    }
  }

  // Helper method to format customer name
  static String _formatCustomerName(Map<String, dynamic> userDetails) {
    final firstName = userDetails['first_name']?.toString() ?? '';
    final lastName = userDetails['last_name']?.toString() ?? '';
    return '$firstName $lastName'.trim();
  }

  // Helper method to parse items
  static List<RecycleBagItem> _parseItems(dynamic items) {
    if (items == null) return [];
    if (items is! List) return [];

    return items.map((item) {
      try {
        return RecycleBagItem.fromJson(item as Map<String, dynamic>);
      } catch (e) {
        logger.w('⚠️ Warning: Failed to parse item: $item');
        return RecycleBagItem(itemType: 'Unknown', quantity: 0, points: 0);
      }
    }).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'recycle_bag_id': recycleBagId,
      'customer_name': customerName,
      'customer_email': customerEmail,
      'customer_phone': customerPhone,
      'governorate': governorate,
      'address': address,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt.toIso8601String(),
      'assigned_time': assignedTime.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'discrepancy_report': discrepancyReport,
      'delivery_boy': deliveryBoy,
    };
  }

  DeliveryOrder copyWith({
    int? id,
    String? status,
    int? recycleBagId,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? governorate,
    String? address,
    String? location,
    String? latitude,
    String? longitude,
    DateTime? createdAt,
    DateTime? assignedTime,
    List<RecycleBagItem>? items,
    String? discrepancyReport,
    Map<String, dynamic>? deliveryBoy,
  }) {
    return DeliveryOrder(
      id: id ?? this.id,
      status: status ?? this.status,
      recycleBagId: recycleBagId ?? this.recycleBagId,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      governorate: governorate ?? this.governorate,
      address: address ?? this.address,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      assignedTime: assignedTime ?? this.assignedTime,
      items: items ?? this.items,
      discrepancyReport: discrepancyReport ?? this.discrepancyReport,
      deliveryBoy: deliveryBoy ?? this.deliveryBoy,
    );
  }

  bool isAssignedTo(String email) {
    return deliveryBoy != null &&
        deliveryBoy!['email']?.toString().toLowerCase() == email.toLowerCase();
  }

  int get totalPoints => items.fold(0, (sum, item) => sum + item.points);

  String get formattedDateTime =>
      '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';

  bool get canBeAccepted => status?.toLowerCase() == 'pending';
  bool get canBeRejected =>
      ['pending', 'accepted', 'in_transit'].contains(status?.toLowerCase());
  bool get canBeCanceled =>
      ['accepted', 'in_transit'].contains(status?.toLowerCase());
  bool get canBeMarkedInTransit => status?.toLowerCase() == 'accepted';
  bool get canBeMarkedDelivered => status?.toLowerCase() == 'in_transit';
  bool get canBeMarkedRejected =>
      ['pending', 'accepted', 'in_transit'].contains(status?.toLowerCase());
}

class RecycleBagItem {
  final String itemType;
  final int quantity;
  final int points;
  final double? weight;
  final String? description;
  final String? imageUrl;
  final DateTime? addedAt;

  RecycleBagItem({
    required this.itemType,
    required this.quantity,
    required this.points,
    this.weight,
    this.description,
    this.imageUrl,
    this.addedAt,
  });

  factory RecycleBagItem.fromJson(Map<String, dynamic> json) {
    try {
      logger.i('Parsing RecycleBagItem: $json');

      final itemType =
          json['item_type']?.toString() ??
          json['type']?.toString() ??
          'Unknown';
      final quantity = int.tryParse(json['quantity']?.toString() ?? '') ?? 0;
      final points = int.tryParse(json['points']?.toString() ?? '') ?? 0;
      final weight = double.tryParse(json['weight']?.toString() ?? '');
      final description = json['description']?.toString();
      final imageUrl = json['image_url']?.toString();
      final addedAt =
          json['added_at'] != null ? DateTime.parse(json['added_at']) : null;

      logger.i(
        'Parsed values - Type: $itemType, Quantity: $quantity, Points: $points',
      );

      return RecycleBagItem(
        itemType: itemType,
        quantity: quantity,
        points: points,
        weight: weight,
        description: description,
        imageUrl: imageUrl,
        addedAt: addedAt,
      );
    } catch (e, stackTrace) {
      logger.e('Error parsing RecycleBagItem: $e');
      logger.e('Stack trace: $stackTrace');
      logger.e('JSON data: ${json.toString()}');
      return RecycleBagItem(itemType: 'Unknown', quantity: 0, points: 0);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'item_type': itemType,
      'quantity': quantity,
      'points': points,
      if (weight != null) 'weight': weight,
      if (description != null) 'description': description,
      if (imageUrl != null) 'image_url': imageUrl,
      if (addedAt != null) 'added_at': addedAt!.toIso8601String(),
    };
  }

  double get totalPoints => points * quantity.toDouble();

  @override
  String toString() {
    return '$quantity x $itemType (${points}pts each)';
  }

  static List<RecycleBagItem> parseItems(dynamic items) {
    if (items == null) return [];
    if (items is! List) return [];

    return items.map((item) {
      try {
        return RecycleBagItem.fromJson(item as Map<String, dynamic>);
      } catch (e) {
        logger.w('⚠️ Warning: Failed to parse item: $item');
        return RecycleBagItem(itemType: 'Unknown', quantity: 0, points: 0);
      }
    }).toList();
  }
}
