// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:graduation_project11/core/themes/app__theme.dart';
import 'package:graduation_project11/core/utils/shared_keys.dart';
import 'package:graduation_project11/features/auth/sign_in/presentation/screen/sign_in_screen.dart';
import 'package:graduation_project11/features/home/presentation/screen/home_screen.dart';
import 'package:graduation_project11/features/on_boarding/screens/on_boarding_screen1.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double opacity = 0.0;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  void _startAnimation() async {
    // Start logo animation
    await Future.delayed(const Duration(seconds: 1));
    if (_mounted) {
      setState(() {
        opacity = 1.0;
      });
    }

    // Navigate after total 3 seconds
    await Future.delayed(const Duration(seconds: 2));
    if (_mounted) {
      await _navigateNext();
    }
  }

  Future<void> _navigateNext() async {
    final prefs = await SharedPreferences.getInstance();

    final bool onboardingSeen =
        prefs.getBool(SharedKeys.onboardingSeen) ?? false;
    final bool isLoggedIn = prefs.getBool(SharedKeys.isLoggedIn) ?? false;

    if (!_mounted) return;

    Widget nextScreen;
    if (!onboardingSeen) {
      nextScreen = const OnboardingScreen1();
    } else if (isLoggedIn) {
      nextScreen = const HomeScreen();
    } else {
      nextScreen = const SignInScreen();
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => nextScreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.light.colorScheme.primary,
      body: Center(
        child: AnimatedOpacity(
          opacity: opacity,
          duration: const Duration(seconds: 2),
          curve: Curves.easeInOut,
          child: Image.asset(
            'assets/icons/recycle.png',
            width: 400,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
