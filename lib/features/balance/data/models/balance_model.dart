class BalanceModel {
  final int points;
  final int rewards;
  final int? lastEarned;
  final List<ActivityModel> activities;

  BalanceModel({
    required this.points,
    required this.rewards,
    this.lastEarned,
    required this.activities,
  });

  factory BalanceModel.fromJson(Map<String, dynamic> json) {
    List<ActivityModel> activities = [];
    if (json['activities'] != null) {
      activities = (json['activities'] as List)
          .map((activity) => ActivityModel.fromJson(activity))
          .toList();
    }

    return BalanceModel(
      points: json['points'] ?? 0,
      rewards: json['rewards'] ?? 0,
      lastEarned: json['last_activity']?['points'],
      activities: activities,
    );
  }
}

class ActivityModel {
  final String id;
  final String title;
  final int points;
  final String type;
  final DateTime date;
  final int rewards;
  final double? voucherAmount; // Added for redeemed EGP value

  ActivityModel({
    required this.id,
    required this.title,
    required this.points,
    required this.type,
    required this.date,
    this.rewards = 0,
    this.voucherAmount, // Added
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    double? parsedVoucherAmount;
    if (json['voucher_amount'] != null) {
      if (json['voucher_amount'] is String) {
        parsedVoucherAmount = double.tryParse(json['voucher_amount']);
      } else if (json['voucher_amount'] is num) {
        parsedVoucherAmount = (json['voucher_amount'] as num).toDouble();
      }
    }

    return ActivityModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Unknown Activity',
      points: json['points'] ?? 0,
      type: json['type']?.toString() ?? 'unknown',
      date: DateTime.parse(json['date']),
      rewards: json['rewards'] ?? 0,
      voucherAmount: parsedVoucherAmount, // Added
    );
  }
}
