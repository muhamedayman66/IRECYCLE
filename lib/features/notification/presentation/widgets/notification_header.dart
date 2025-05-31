import 'package:flutter/material.dart';

class NotificationHeader extends StatelessWidget {
  final bool hasNotifications;
  final VoidCallback onClear;

  const NotificationHeader({
    super.key,
    required this.hasNotifications,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              "Recent",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 5),
            if (hasNotifications)
              Icon(Icons.circle, size: 8, color: Colors.red),
          ],
        ),
        GestureDetector(
          onTap: onClear,
          child: Text("Clear All", style: TextStyle(color: Colors.blue)),
        ),
      ],
    );
  }
}
