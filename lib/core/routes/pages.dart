import 'package:flutter/material.dart';
import 'package:graduation_project11/core/routes/routes_name.dart';
import 'package:graduation_project11/features/auth/sign_in/presentation/screen/sign_in_screen.dart';
import 'package:graduation_project11/features/auth/sign_up/presentation/screen/sign_up_screen1.dart';
import 'package:graduation_project11/features/balance/presentation/screens/balance_screen.dart';
import 'package:graduation_project11/features/profile/presentation/screen/profile_screen.dart';
import 'package:graduation_project11/features/stores/screen/stores_screen.dart';
import 'package:graduation_project11/features/home/presentation/screen/home_screen.dart';
import 'package:graduation_project11/features/on_boarding/screens/on_boarding_screen1.dart';
import 'package:graduation_project11/screens/splash_screen.dart';

class AppRoute {
  static Route<dynamic> generate(RouteSettings? settings) {
    switch (settings?.name) {
      case RoutesName.splash:
        return MaterialPageRoute(builder: (_) => SplashScreen());

      case RoutesName.onboardingScreen1:
        return MaterialPageRoute(builder: (_) => OnboardingScreen1());

      case RoutesName.signIn:
        return MaterialPageRoute(builder: (_) => SignInScreen());

      case RoutesName.signUp:
        return MaterialPageRoute(builder: (_) => SignUpScreen1());

      case RoutesName.home:
        return MaterialPageRoute(builder: (_) => HomeScreen());

      case RoutesName.balance:
        return MaterialPageRoute(builder: (_) => BalanceScreen());

      case RoutesName.stores:
        return MaterialPageRoute(builder: (_) => StoresScreen());

      case RoutesName.profile:
        return MaterialPageRoute(
          builder: (_) => ProfileScreen(email: settings?.arguments as String),
        );

      default:
        return MaterialPageRoute(
          builder:
              (_) => Scaffold(body: Center(child: Text('Route not found!'))),
        );
    }
  }
}
