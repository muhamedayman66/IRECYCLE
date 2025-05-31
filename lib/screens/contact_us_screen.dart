import 'package:flutter/material.dart';
import 'package:graduation_project11/core/themes/app__theme.dart';
import 'package:graduation_project11/core/widgets/custom_appbar.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final String phoneNumber = "19562";

  final String email = "irecycle2025@gmail.com";

  final String address =
      "132 Al-Gomhoria Street, Massachusetts 02156 Asyut, Egypt";
  final String facebookUrl = "https://www.facebook.com/YOUR_PAGE_LINK";

  // Phone
  void _launchPhone() async {
    final Uri uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      print("لا يمكن فتح تطبيق الهاتف");
    }
  }

  // Email
  void _launchEmail() async {
    final Uri uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      print("لا يمكن فتح تطبيق البريد");
    }
  }

  // Facebook
  void _launchFacebook() async {
    final Uri uri = Uri.parse(facebookUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      print("لا يمكن فتح تطبيق الفيسبوك أو المتصفح");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.light.colorScheme.secondary,
      appBar: CustomAppBar(
        title: 'Contact Us',
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_outlined),
          color: AppTheme.light.colorScheme.secondary,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 20, right: 19, top: 100),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.light.colorScheme.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Contact Information",
                style: TextStyle(
                  color: AppTheme.light.colorScheme.secondary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              Text(
                "Feel free to contact us, we're here to help!",
                style: TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),

              // رقم الهاتف
              GestureDetector(
                onTap: _launchPhone,
                child: Column(
                  children: [
                    Icon(
                      Icons.phone,
                      color: AppTheme.light.colorScheme.secondary,
                      size: 30,
                    ),
                    SizedBox(height: 5),
                    Text(
                      phoneNumber,
                      style: TextStyle(
                        color: AppTheme.light.colorScheme.secondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // البريد الإلكتروني
              GestureDetector(
                onTap: _launchEmail,
                child: Column(
                  children: [
                    Icon(
                      Icons.email,
                      color: AppTheme.light.colorScheme.secondary,
                      size: 30,
                    ),
                    SizedBox(height: 5),
                    Text(
                      email,
                      style: TextStyle(
                        color: AppTheme.light.colorScheme.secondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),
              Column(
                children: [
                  Icon(Icons.location_on, color: Colors.white, size: 30),
                  SizedBox(height: 5),
                  Text(
                    address,
                    style: TextStyle(color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
