import 'package:flutter/material.dart';
import 'package:graduation_project11/core/themes/app__theme.dart';
import 'package:graduation_project11/core/widgets/custom_appbar.dart';

class RecycleBagScreen extends StatelessWidget {
  const RecycleBagScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Recycle Bag',
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          color: AppTheme.light.colorScheme.secondary,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
