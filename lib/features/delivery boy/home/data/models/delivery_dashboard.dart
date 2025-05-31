class DeliveryDashboard {
  final String firstName;
  final String lastName;
  final String workArea;
  final int totalOrders;
  final double averageRating;
  final double totalRewards;
  final int availableOrders;
  final bool hasUnreadNotifications;
  final int totalPoints;
  final int pointsToNextReward;
  final double nextRewardAmount;
  final String? profileImage;

  DeliveryDashboard({
    required this.firstName,
    required this.lastName,
    required this.workArea,
    required this.totalOrders,
    required this.averageRating,
    required this.totalRewards,
    required this.availableOrders,
    required this.hasUnreadNotifications,
    required this.totalPoints,
    required this.pointsToNextReward,
    required this.nextRewardAmount,
    this.profileImage,
  });

  factory DeliveryDashboard.fromJson(Map<String, dynamic> json) {
    return DeliveryDashboard(
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      workArea: json['governorate'] ?? '',
      totalOrders: json['total_orders_delivered'] ?? 0,
      averageRating: (json['average_rating'] ?? 0.0).toDouble(),
      totalRewards: (json['current_balance'] ?? 0.0).toDouble(),
      availableOrders: json['available_orders'] ?? 0,
      hasUnreadNotifications: json['has_unread_notifications'] ?? false,
      totalPoints: json['total_points'] ?? 0,
      pointsToNextReward: json['points_to_next_reward'] ?? 20,
      nextRewardAmount: (json['next_reward_amount'] ?? 1.0).toDouble(),
      profileImage: json['profile_image'],
    );
  }
}
