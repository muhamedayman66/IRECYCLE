class DeliveryNotification {
  final int id;
  final String message;
  final String createdAt;
  bool isRead;

  DeliveryNotification({
    required this.id,
    required this.message,
    required this.createdAt,
    required this.isRead,
  });

  factory DeliveryNotification.fromJson(Map<String, dynamic> json) {
    return DeliveryNotification(
      id: json['id'],
      message: json['message'],
      createdAt: json['created_at'],
      isRead: json['is_read'],
    );
  }
}
