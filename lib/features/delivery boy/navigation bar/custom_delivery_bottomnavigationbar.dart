import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:graduation_project11/core/themes/app__theme.dart';
import 'package:graduation_project11/features/delivery%20boy/orders/presentation/screen/DeliveryOrdersScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:graduation_project11/core/utils/shared_keys.dart';
import 'package:logger/logger.dart';

class DeliveryBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const DeliveryBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.light.colorScheme;
    final size = MediaQuery.of(context).size;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          height: size.height * 0.1,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: Size(double.infinity, size.height * 0.1),
                painter: CurvedNavBarPainter(theme.primary),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                    icon: Icons.home,
                    label: 'Home',
                    index: 0,
                    theme: theme,
                    size: size,
                  ),
                  _buildNavItem(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Balance',
                    index: 1,
                    theme: theme,
                    size: size,
                  ),
                  SizedBox(width: size.width * 0.18),
                  _buildNavItem(
                    icon: Icons.store_outlined,
                    label: 'Stores',
                    index: 2,
                    theme: theme,
                    size: size,
                  ),
                  _buildNavItem(
                    icon: Icons.person_outline,
                    label: 'Profile',
                    index: 3,
                    theme: theme,
                    size: size,
                  ),
                ],
              ),
              Positioned(
                top: -size.height * 0.03,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    onTap(4);
                  },
                  child: Container(
                    width: size.width * 0.2,
                    height: size.width * 0.2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [theme.primary, theme.primary.withOpacity(0.8)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primary.withOpacity(0.4),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.list_alt,
                          color: theme.onPrimary,
                          size: size.width * 0.09,
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Orders',
                            style: TextStyle(
                              color: theme.onPrimary,
                              fontSize: size.width * 0.035,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required ColorScheme theme,
    required Size size,
  }) {
    final bool isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: size.width * 0.18,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color:
                  isSelected
                      ? theme.onPrimary
                      : theme.onPrimary.withOpacity(0.5),
              size: size.width * 0.06,
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                color:
                    isSelected
                        ? theme.onPrimary
                        : theme.onPrimary.withOpacity(0.5),
                fontSize: size.width * 0.028,
                fontWeight: FontWeight.w600,
                fontFamily: 'Roboto',
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

class CurvedNavBarPainter extends CustomPainter {
  final Color color;

  CurvedNavBarPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    final path = Path();
    final double curveRadius = size.height * 0.2;
    final double centerX = size.width / 2;
    final double curveWidth = curveRadius * 2 + 20;

    path.moveTo(0, 0);
    path.lineTo(centerX - curveWidth / 2 - 10, 0);
    path.quadraticBezierTo(
      centerX - curveWidth / 2,
      0,
      centerX - curveRadius,
      curveRadius,
    );
    path.arcToPoint(
      Offset(centerX + curveRadius, curveRadius),
      radius: Radius.circular(curveRadius),
      clockwise: false,
    );
    path.quadraticBezierTo(
      centerX + curveWidth / 2,
      0,
      centerX + curveWidth / 2 + 10,
      0,
    );
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
