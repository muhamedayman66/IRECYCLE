// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:graduation_project11/core/themes/app__theme.dart';
import 'package:graduation_project11/core/widgets/custom_appbar.dart';

class LanguagesScreen extends StatefulWidget {
  const LanguagesScreen({super.key});

  @override
  _LanguageSelectionScreenState createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguagesScreen> {
  String selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Languages',
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_outlined,
            color: AppTheme.light.colorScheme.secondary,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // شريط البحث
            TextField(
              decoration: InputDecoration(
                hintText: 'search for help',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            SizedBox(height: 20),
            // قائمة اللغات
            Container(
              alignment: Alignment.center,
              height: 55,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: AppTheme.light.colorScheme.primary),
              ),
              child: _buildLanguageTile('English', '🇬🇧'),
            ),
            SizedBox(height: 10),
            Container(
              alignment: Alignment.center,
              height: 55,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: AppTheme.light.colorScheme.primary),
              ),
              child: _buildLanguageTile('Arabic', '🇪🇬'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageTile(String language, String flag) {
    return ListTile(
      leading: Text(flag, style: TextStyle(fontSize: 20)),
      title: Text(language, style: TextStyle(fontWeight: FontWeight.w500)),
      trailing:
          selectedLanguage == language
              ? Icon(Icons.check, color: Colors.green)
              : null,
      onTap: () {},
    );
  }
}
