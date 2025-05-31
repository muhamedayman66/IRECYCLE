import 'package:flutter/material.dart';
import 'package:graduation_project11/core/themes/app__theme.dart';
import 'package:graduation_project11/core/widgets/custom_appbar.dart';
import 'package:graduation_project11/features/auth/sign_in/presentation/screen/sign_in_screen.dart';
import 'package:graduation_project11/features/delivery%20boy/edit_profile/presentation/screens/DeliveryEditProfileScreen.dart.dart';
import 'package:graduation_project11/features/delivery%20boy/notifications/presentation/screen/DeliveryNotificationsScreen.dart.dart';
import 'package:graduation_project11/features/delivery%20boy/profile/data/services/profile_service.dart';
import 'package:graduation_project11/screens/FAQ_screen.dart';
import 'package:graduation_project11/screens/contact_us_screen.dart';
import 'package:graduation_project11/screens/languages_screen.dart';
import 'package:share_plus/share_plus.dart';

class DeliveryProfileScreen extends StatefulWidget {
  final String? email;
  const DeliveryProfileScreen({super.key, this.email});

  @override
  State<DeliveryProfileScreen> createState() => _DeliveryProfileScreenState();
}

class _DeliveryProfileScreenState extends State<DeliveryProfileScreen> {
  String? firstName;
  String? lastName;
  String? phoneNumber;
  String? workArea;
  String? profileImageUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    if (widget.email == null) return;

    try {
      setState(() => isLoading = true);
      final profileData = await DeliveryProfileService.getProfile(
        widget.email!,
      );

      setState(() {
        firstName = profileData['first_name'];
        lastName = profileData['last_name'];
        phoneNumber = profileData['phone'];
        workArea = profileData['governorate'];
        profileImageUrl = profileData['profile_image'];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
      }
    }
  }

  void _logout(BuildContext context) {
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
            : 'User';

    return Scaffold(
      backgroundColor: AppTheme.light.colorScheme.secondary,
      appBar: CustomAppBar(title: 'Profile'),
      body: SafeArea(
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
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
                                Container(
                                  width: maxWidth * 0.15,
                                  height: maxWidth * 0.15,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(50),
                                    image:
                                        profileImageUrl != null
                                            ? DecorationImage(
                                              image: NetworkImage(
                                                profileImageUrl!,
                                              ),
                                              fit: BoxFit.cover,
                                            )
                                            : null,
                                  ),
                                  child:
                                      profileImageUrl == null
                                          ? Icon(
                                            Icons.person,
                                            size: maxWidth * 0.08,
                                          )
                                          : null,
                                ),
                                SizedBox(width: maxWidth * 0.03),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        phoneNumber ?? 'Not set',
                                        style: TextStyle(
                                          fontSize: 14 * fontScale,
                                          color: Colors.grey[800],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Governorate: ${capitalize(workArea)}',
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
                                    backgroundColor:
                                        AppTheme.light.colorScheme.primary,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: maxWidth * 0.04,
                                      vertical: maxHeight * 0.015,
                                    ),
                                    textStyle: TextStyle(
                                      fontSize: 14 * fontScale,
                                    ),
                                  ),
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                DeliveryEditProfileScreen(
                                                  email: widget.email,
                                                ),
                                      ),
                                    );
                                    _loadProfileData(); // Reload profile after editing
                                  },
                                  child: Text(
                                    "Edit Profile",
                                    style: TextStyle(
                                      color:
                                          AppTheme.light.colorScheme.secondary,
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
                                      builder:
                                          (context) => const LanguagesScreen(),
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
                                              DeliveryNotificationsScreen(
                                                email: widget.email,
                                              ),
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
                                      builder:
                                          (context) => const ContactUsScreen(),
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
