import 'package:flutter/material.dart';
import 'package:graduation_project11/core/themes/app__theme.dart';
import 'package:graduation_project11/core/widgets/custom_appbar.dart';

class GlassInfoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: CustomAppBar(
        title: 'Glasses',
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
                    "Glass is 100% recyclable, and reusing it conserves energy while reducing waste. By recycling, you’re directly contributing to a cleaner and greener environment.",
              ),
              _buildSection(
                title: "Transform Waste Into Value:",
                content:
                    "Don’t discard your glass bottles—turn them into points you can use to get valuable rewards. Recycling your bottles has never been more satisfying!",
              ),
              _buildSection(
                title: "Be Part of the Change:",
                content:
                    "Recycling is not just a personal act; it’s a collective mission to create a better future. Every bottle you recycle makes a difference.",
              ),
              _buildSection(
                title: "Inspire Others:",
                content:
                    "Your recycling efforts can inspire those around you to join in. Together, we can amplify the impact and make a lasting change.",
              ),
              _buildSection(
                title: "Get Started Today!",
                content:
                    "It takes just 5 glass bottles to begin. Scan your bottles now, earn points, and unlock fantastic rewards while playing your part in protecting the planet. Let’s work together for a cleaner, more sustainable future!",
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
