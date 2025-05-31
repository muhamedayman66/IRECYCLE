import 'package:flutter/material.dart';

class ArrowInCircle extends StatefulWidget {
  final double progress;
  final VoidCallback onTap;
  const ArrowInCircle(
      {super.key,
      required this.progress,
      required this.onTap,
      required MaterialColor progressColor});

  @override
  State<ArrowInCircle> createState() => _ArrowInCircleState();
}

class _ArrowInCircleState extends State<ArrowInCircle> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: widget.onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 70,
              height: 70,
              child: CircularProgressIndicator(
                value: widget.progress,
                strokeWidth: 3,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
            Icon(Icons.arrow_forward, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }
}
