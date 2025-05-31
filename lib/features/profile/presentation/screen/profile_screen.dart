import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:graduation_project11/core/api/api_constants.dart';
import 'package:graduation_project11/core/themes/app__theme.dart';
import 'package:graduation_project11/core/widgets/custom_appbar.dart';
import 'package:graduation_project11/features/auth/sign_in/presentation/screen/sign_in_screen.dart';
import 'package:graduation_project11/features/edit_profile/presentation/screens/edit_profile_screen.dart';
import 'package:graduation_project11/features/notification/presentation/screens/notications_screen.dart';
import 'package:graduation_project11/screens/FAQ_screen.dart';
import 'package:graduation_project11/screens/contact_us_screen.dart';
import 'package:graduation_project11/screens/languages_screen.dart';
import 'package:graduation_project11/core/utils/shared_keys.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class ProfileScreen extends StatefulWidget {
  final String email;
  const ProfileScreen({super.key, required this.email});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? firstName;
  String? lastName;
  String? profileImageUrl;
  String? phoneNumber;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? email = prefs.getString(SharedKeys.userEmail);

    if (email == null) {
      Logger().e('No email found in SharedPreferences');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User not logged in')),
        );
      }
      return;
    }

    final url = Uri.parse(
      '${ApiConstants.getUserProfile}?email=$email&user_type=regular_user',
    );

    try {
      final token = await prefs.getString('auth_token');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            firstName = data['first_name'];
            lastName = data['last_name'];
            profileImageUrl = data['profile_image'];
            phoneNumber = data['phone'];
          });
        }
      } else {
        Logger().e(
          'Failed to load user data: ${response.statusCode} - ${response.body}',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load profile: ${response.statusCode}'),
            ),
          );
        }
      }
    } catch (e) {
      Logger().e('Error loading user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error loading profile')));
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SharedKeys.isLoggedIn, false);
    await prefs.remove(SharedKeys.userEmail);
    await prefs.remove('auth_token');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SignInScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    String capitalize(String? s) =>
        (s?.isNotEmpty ?? false)
            ? '${s![0].toUpperCase()}${s.substring(1).toLowerCase()}'
            : '';

    final String displayName =
        firstName != null && lastName != null
            ? '${capitalize(firstName)} ${capitalize(lastName)}'
            : 'Loading...';

    return Scaffold(
      backgroundColor: AppTheme.light.colorScheme.secondary,
      appBar: CustomAppBar(title: 'Profile'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxHeight = constraints.maxHeight;
            final maxWidth = constraints.maxWidth;
            final padding = maxWidth * 0.05;
            final fontScale = maxWidth / 400;

            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: padding,
                  vertical: maxHeight * 0.02,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child:
                              profileImageUrl != null
                                  ? Image.network(
                                    profileImageUrl!,
                                    width: maxWidth * 0.15,
                                    height: maxWidth * 0.15,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              width: maxWidth * 0.15,
                                              height: maxWidth * 0.15,
                                              color: Colors.grey[300],
                                              child: Icon(
                                                Icons.person,
                                                size: maxWidth * 0.08,
                                              ),
                                            ),
                                  )
                                  : Container(
                                    width: maxWidth * 0.15,
                                    height: maxWidth * 0.15,
                                    color: Colors.grey[300],
                                    child: Icon(
                                      Icons.person,
                                      size: maxWidth * 0.08,
                                    ),
                                  ),
                        ),
                        SizedBox(width: maxWidth * 0.03),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: TextStyle(
                                  fontSize: 18 * fontScale,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                phoneNumber ?? 'Loading...',
                                style: TextStyle(
                                  fontSize: 14 * fontScale,
                                  color: Colors.grey[800],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.light.colorScheme.primary,
                            padding: EdgeInsets.symmetric(
                              horizontal: maxWidth * 0.04,
                              vertical: maxHeight * 0.015,
                            ),
                            textStyle: TextStyle(fontSize: 14 * fontScale),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditProfileScreen(),
                              ),
                            );
                          },
                          child: Text(
                            "Edit Profile",
                            style: TextStyle(
                              color: AppTheme.light.colorScheme.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: maxHeight * 0.03),
                    Text(
                      'Settings',
                      style: TextStyle(
                        color: AppTheme.light.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16 * fontScale,
                      ),
                    ),
                    SizedBox(height: maxHeight * 0.01),
                    buildListTile(
                      context,
                      icon: Icons.language,
                      title: "Language",
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LanguagesScreen(),
                            ),
                          ),
                      fontScale: fontScale,
                      tileHeight: maxHeight * 0.07,
                    ),
                    SizedBox(height: maxHeight * 0.01),
                    buildListTile(
                      context,
                      icon: Icons.notifications,
                      title: "Notification",
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      NotificationScreen(email: widget.email),
                            ),
                          ),
                      fontScale: fontScale,
                      tileHeight: maxHeight * 0.07,
                    ),
                    SizedBox(height: maxHeight * 0.02),
                    Text(
                      'About us',
                      style: TextStyle(
                        color: AppTheme.light.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16 * fontScale,
                      ),
                    ),
                    SizedBox(height: maxHeight * 0.01),
                    buildListTile(
                      context,
                      icon: Icons.help,
                      title: "FAQ",
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FaqScreen(),
                            ),
                          ),
                      fontScale: fontScale,
                      tileHeight: maxHeight * 0.07,
                    ),
                    SizedBox(height: maxHeight * 0.01),
                    buildListTile(
                      context,
                      icon: Icons.contact_mail,
                      title: "Contact Us",
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ContactUsScreen(),
                            ),
                          ),
                      fontScale: fontScale,
                      tileHeight: maxHeight * 0.07,
                    ),
                    SizedBox(height: maxHeight * 0.02),
                    Text(
                      'Other',
                      style: TextStyle(
                        color: AppTheme.light.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16 * fontScale,
                      ),
                    ),
                    SizedBox(height: maxHeight * 0.01),
                    buildListTile(
                      context,
                      icon: Icons.share,
                      title: "Share",
                      onTap: () {
                        Share.share(
                          'Check out this amazing app!',
                          subject: 'Look what I made!',
                        );
                      },
                      fontScale: fontScale,
                      tileHeight: maxHeight * 0.07,
                    ),
                    SizedBox(height: maxHeight * 0.01),
                    buildListTile(
                      context,
                      icon: Icons.logout,
                      title: "Logout",
                      onTap: () => _logout(context),
                      fontScale: fontScale,
                      tileHeight: maxHeight * 0.07,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required double fontScale,
    required double tileHeight,
  }) {
    return Card(
      color: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: BorderSide(color: AppTheme.light.colorScheme.primary, width: 1),
      ),
      child: SizedBox(
        height: tileHeight,
        child: ListTile(
          titleAlignment: ListTileTitleAlignment.center,
          tileColor: Colors.transparent,
          leading: Icon(
            icon,
            color: AppTheme.light.colorScheme.primary,
            size: 24 * fontScale,
          ),
          title: Text(
            title,
            style: TextStyle(
              color: AppTheme.light.colorScheme.primary,
              fontSize: 14 * fontScale,
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
