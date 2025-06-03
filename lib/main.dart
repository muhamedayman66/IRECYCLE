import 'package:flutter/material.dart';
import 'package:graduation_project11/screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'package:graduation_project11/core/routes/pages.dart';
import 'package:graduation_project11/core/themes/app__theme.dart';
import 'package:graduation_project11/core/providers/auth_provider.dart';
import 'package:graduation_project11/features/home/presentation/screen/home_screen.dart';
import 'package:graduation_project11/features/delivery%20boy/home/presentation/screen/DeliveryHomeScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:graduation_project11/core/utils/shared_keys.dart';
import 'package:graduation_project11/features/recycling/presentation/screens/order_status_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authProvider = AuthProvider();
  await authProvider.ensureInitialized(); // Ensure AuthProvider is initialized

  final prefs = await SharedPreferences.getInstance();
  final String? resumeEmail = prefs.getString(
    SharedKeys.orderStatusResumeEmail,
  );

  Widget initialScreenWidget;

  if (resumeEmail != null &&
      resumeEmail.isNotEmpty &&
      authProvider.isLoggedIn && // Check current auth state
      authProvider.userType == 'regular_user' &&
      authProvider.email == resumeEmail) {
    // If resume conditions are met (user is logged in as the same regular user)
    initialScreenWidget = OrderStatusScreen(userEmail: resumeEmail);
  } else {
    // If resume conditions are not met (e.g. different user, logged out, or no resumeEmail)
    if (resumeEmail != null && resumeEmail.isNotEmpty) {
      // If there was a resumeEmail but conditions failed, clear the stale flag
      await prefs.remove(SharedKeys.orderStatusResumeEmail);
      print("main.dart: Cleared stale orderStatusResumeEmail for $resumeEmail");
    }
    initialScreenWidget = const AuthWrapper();
  }

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider.value(value: authProvider)],
      child: MyApp(initialScreen: initialScreenWidget),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Widget initialScreen;
  const MyApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: MaterialApp(
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        home: initialScreen,
        onGenerateRoute: AppRoute.generate,
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // AuthProvider calls _loadAuthState in its constructor.
        // Consumer rebuilds when notifyListeners is called after _loadAuthState completes.

        // If email is null, it implies _loadAuthState hasn't completed OR user is logged out.
        // SplashScreen handles its own navigation logic based on SharedPreferences.
        // This also covers the case where AuthProvider is still loading.
        if (authProvider.email == null && !authProvider.isLoggedIn) {
          return const SplashScreen();
        }

        // If after loading, user is still not logged in.
        if (!authProvider.isLoggedIn) {
          return const SplashScreen(); // SplashScreen will navigate to SignIn or Onboarding
        }

        // User is logged in, direct based on type
        if (authProvider.userType == 'delivery_boy') {
          return DeliveryHomeScreen(email: authProvider.email!);
        } else if (authProvider.userType == 'regular_user') {
          // If OrderStatusScreen resume was handled in main, we wouldn't reach here with resumeEmail.
          // So, go to HomeScreen.
          return const HomeScreen();
        }

        // Fallback for unknown userType or unexpected state
        print(
          'AuthWrapper: Fallback. UserType: ${authProvider.userType}, LoggedIn: ${authProvider.isLoggedIn}. Defaulting to SplashScreen.',
        );
        return const SplashScreen();
      },
    );
  }
}
