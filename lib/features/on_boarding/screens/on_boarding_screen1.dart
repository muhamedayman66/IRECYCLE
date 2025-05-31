import 'package:flutter/material.dart';
import 'package:graduation_project11/core/themes/app__theme.dart';
import 'package:graduation_project11/features/on_boarding/screens/on_boarding_screen2.dart';

class OnboardingScreen1 extends StatelessWidget {
  const OnboardingScreen1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.light.colorScheme.primary,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxHeight = constraints.maxHeight;
          final maxWidth = constraints.maxWidth;
          final padding = maxWidth * 0.05;
          final fontScale = maxWidth / 400;

          return Column(
            children: [
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: Image.asset(
                    'assets/images/onboarding1.jpg',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: padding,
                    vertical: maxHeight * 0.02,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: maxHeight * 0.25,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome to',
                              style: TextStyle(
                                fontSize: 22 * fontScale,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.light.colorScheme.secondary,
                              ),
                            ),
                            Text(
                              'iRecycle',
                              style: TextStyle(
                                fontSize: 22 * fontScale,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.light.colorScheme.secondary,
                              ),
                            ),
                            SizedBox(height: maxHeight * 0.01),
                            Text(
                              'Together we create a cleaner and greener environment by managing waste efficiently.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14 * fontScale,
                                color: AppTheme.light.colorScheme.secondary,
                                height: 1.5,
                              ),
                            ),
                            SizedBox(height: maxHeight * 0.02),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                3,
                                (index) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: EdgeInsets.symmetric(
                                    horizontal: maxWidth * 0.015,
                                  ),
                                  width:
                                      index == 0
                                          ? maxWidth * 0.045
                                          : maxWidth * 0.025,
                                  height: maxHeight * 0.008,
                                  decoration: BoxDecoration(
                                    color: AppTheme.light.colorScheme.secondary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: maxWidth * 0.42,
                          ), // Placeholder for PREVIOUS
                          SizedBox(
                            width: maxWidth * 0.42,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder:
                                        (_, __, ___) =>
                                            const OnboardingScreen2(),
                                    transitionsBuilder: (
                                      context,
                                      animation,
                                      _,
                                      child,
                                    ) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      );
                                    },
                                    transitionDuration: const Duration(
                                      milliseconds: 500,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    AppTheme.light.colorScheme.secondary,
                                padding: EdgeInsets.symmetric(
                                  vertical: maxHeight * 0.015,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'NEXT',
                                style: TextStyle(
                                  color: AppTheme.light.colorScheme.primary,
                                  fontSize: 14 * fontScale,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
