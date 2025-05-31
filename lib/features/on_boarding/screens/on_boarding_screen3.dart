import 'package:flutter/material.dart';
import 'package:graduation_project11/core/themes/app__theme.dart';
import 'package:graduation_project11/core/utils/shared_keys.dart';
import 'package:graduation_project11/features/auth/sign_in/presentation/screen/sign_in_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnBoardingScreen3 extends StatelessWidget {
  const OnBoardingScreen3({super.key});

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
                    'assets/images/onboarding3.jpg',
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
                              'Redeem Points',
                              style: TextStyle(
                                fontSize: 22 * fontScale,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.light.colorScheme.secondary,
                              ),
                            ),
                            Text(
                              'For Rewards',
                              style: TextStyle(
                                fontSize: 22 * fontScale,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.light.colorScheme.secondary,
                              ),
                            ),
                            SizedBox(height: maxHeight * 0.01),
                            Text(
                              'Collect points from each waste collection and exchange them for cash or vouchers from the stores we have contracted with.',
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
                                      index == 2
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
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
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
                                'PREVIOUS',
                                style: TextStyle(
                                  color: AppTheme.light.colorScheme.primary,
                                  fontSize: 14 * fontScale,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: maxWidth * 0.42,
                            child: ElevatedButton(
                              onPressed: () async {
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setBool(
                                  SharedKeys.onboardingSeen,
                                  true,
                                );

                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SignInScreen(),
                                  ),
                                  (Route<dynamic> route) => false,
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
                                'GET STARTED',
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
