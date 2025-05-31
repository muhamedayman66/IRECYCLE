import 'package:flutter/material.dart';
import 'package:graduation_project11/core/themes/app__theme.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: AppTheme.light.colorScheme.primary,
      elevation: 0,
      flexibleSpace: Padding(
        padding: const EdgeInsets.only(bottom: 15), // التحكم في النزول لتحت
        child: Stack(
          children: [
            // Title in bottom center
            Align(
              alignment: Alignment.bottomCenter,
              child: Text(
                title,
                style: TextStyle(
                  color: AppTheme.light.colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
            ),

            // Leading widget in bottom left (بنفس المستوى)
            if (leading != null)
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 5,
                    top: 20,
                  ), // نزّل السهم شوية
                  child: leading!,
                ),
              ),

            // Actions in bottom right
            if (actions != null)
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 5, top: 20),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: actions!,
                  ),
                ),
              ),
          ],
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70);
}
