import 'package:logger/logger.dart';

class RecycleBagItem {
  static final logger = Logger();
  final String type;
  final int quantity;
  final int points;
  final double? weight;
  final String? description;
  final String? imageUrl;
  final DateTime? addedAt;

  RecycleBagItem({
    required this.type,
    required this.quantity,
    required this.points,
    this.weight,
    this.description,
    this.imageUrl,
    this.addedAt,
  });

  factory RecycleBagItem.fromJson(Map<String, dynamic> json) {
    try {
      final type = json['type']?.toString() ?? json['item_type']?.toString();
      if (type == null) {
        logger.w('Type is missing in JSON: $json');
        throw FormatException('Type is required');
      }

      final quantityStr = json['quantity']?.toString();
      final quantity = int.tryParse(quantityStr ?? '');
      if (quantity == null) {
        logger.w('Invalid quantity in JSON: $json');
        throw FormatException('Invalid quantity: $quantityStr');
      }

      final pointsStr = json['points']?.toString();
      final points = int.tryParse(pointsStr ?? '');
      if (points == null) {
        logger.w('Invalid points in JSON: $json');
        throw FormatException('Invalid points: $pointsStr');
      }

      return RecycleBagItem(
        type: type,
        quantity: quantity,
        points: points,
        weight: double.tryParse(json['weight']?.toString() ?? ''),
        description: json['description']?.toString(),
        imageUrl: json['image_url']?.toString(),
        addedAt: json['added_at'] != null ? DateTime.parse(json['added_at']) : null,
      );
    } catch (e) {
      logger.e('Error parsing RecycleBagItem: $e', error: e);
      return RecycleBagItem(
        type: 'Unknown',
        quantity: 0,
        points: 0,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
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
    final buffer = StringBuffer();
    buffer.write('$quantity × $type (${points}pts each)');
    
    if (weight != null) {
      buffer.write(' - ${weight!.toStringAsFixed(2)}kg');
    }
    if (description != null && description!.isNotEmpty) {
      buffer.write(' - $description');
    }
    if (addedAt != null) {
      buffer.write(' - Added: ${addedAt!.toLocal()}');
    }
    
    return buffer.toString();
  }

  static List<RecycleBagItem> parseItems(dynamic items) {
    if (items == null) return [];
    if (items is! List) {
      logger.w('Items is not a List: $items');
      return [];
    }

    return items.map((item) {
      try {
        if (item is! Map<String, dynamic>) {
          logger.w('Item is not a Map: $item');
          throw FormatException('Invalid item format');
        }
        return RecycleBagItem.fromJson(item);
      } catch (e) {
        logger.e('Failed to parse item: $item', error: e);
        return RecycleBagItem(
          type: 'Unknown',
          quantity: 0,
          points: 0,
        );
      }
    }).toList();
  }
} 