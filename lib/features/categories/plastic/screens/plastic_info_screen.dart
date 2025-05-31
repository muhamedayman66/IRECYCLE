import 'package:flutter/material.dart';
import 'package:graduation_project11/core/themes/app__theme.dart';
import 'package:graduation_project11/core/widgets/custom_appbar.dart';

class PlasticInfoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: CustomAppBar(
        title: 'Plastic',
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
                    "Protect the Planet: Plastic waste is one of the greatest environmental challenges of our time. By recycling, you’re helping to reduce pollution and make the Earth cleaner and greener.",
              ),
              _buildSection(
                title: "Turn Trash Into Treasure:",
                content:
                    "Don’t throw away plastic—turn it into valuable points that can be redeemed for things you love. Recycling is rewarding in every way!",
              ),
              _buildSection(
                title: "Be Part of the Change:",
                content:
                    "Recycling is more than an individual effort; it’s a movement toward a sustainable future. Join the collective mission to make a lasting difference.",
              ),
              _buildSection(
                title: "Inspire Others:",
                content:
                    "Your actions can inspire your friends and family to join the cause, amplifying the impact and creating a bigger wave of positive change.",
              ),
              _buildSection(
                title: "Get Started Today!",
                content:
                    "With just 5 plastic items, you can begin your recycling journey. Scan your items, earn points, and enjoy exciting rewards while contributing to a cleaner planet. Together, we can make a difference!",
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
