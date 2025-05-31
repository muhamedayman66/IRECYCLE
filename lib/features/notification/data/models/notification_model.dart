class NotificationModel {
  final String title;
  final String subtitle;
  final String time;

  NotificationModel({
    required this.title,
    required this.subtitle,
    required this.time,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      title: json['title'],
      subtitle: json['body'],
      time: "${(json['id'] * 2) % 60} min ago",
    );
  }
}
