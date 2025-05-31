import 'package:flutter/material.dart';
import 'package:graduation_project11/core/themes/app__theme.dart';
import 'package:graduation_project11/core/widgets/custom_appbar.dart';

class CansInfoScreen extends StatelessWidget {
  const CansInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: CustomAppBar(
        title: 'Cans',
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_outlined),
          color: AppTheme.light.colorScheme.secondary,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                title: "Why Start Recycling Today?",
                content:
                    "Save Energy and Resources: Recycling aluminum helps conserve energy and reduces the need for raw materials, It’s an impactful way to protect the planet.",
              ),
              _buildSection(
                title: "Turn Trash Into Treasure:",
                content:
                    "Don’t let your empty cans go to waste—turn them into valuable points that can be exchanged for amazing rewards. Recycling has never been so rewarding!",
              ),
              _buildSection(
                title: "Be Part of the Change:",
                content:
                    "Recycling is more than just a personal action; it’s a community effort toward a greener, more sustainable future. Together, we can make a lasting difference.",
              ),
              _buildSection(
                title: "Inspire Others:",
                content:
                    "Lead by example—your efforts can motivate your friends and family to join the movement, creating a bigger impact for the environment.",
              ),
              _buildSection(
                title: "Get Started Today!",
                content:
                    "With just 5 Aluminum Cans, you can begin your recycling journey. Scan your items, earn points, and enjoy exciting rewards while contributing to a cleaner planet. Together, we can make a difference!",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 4),
          Text(content, style: TextStyle(fontSize: 14, color: Colors.black87)),
        ],
      ),
    );
  }
}
