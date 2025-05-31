// ignore_for_file: deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:graduation_project11/core/themes/app__theme.dart';
import 'package:graduation_project11/core/widgets/custom_appbar.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  _FAQScreenState createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FaqScreen> {
  List<bool> _isExpanded = [];
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> filteredFaqs = [];

  final List<Map<String, dynamic>> faqs = [
    {
      "question": "How can I recycle using the app?",
      "answer": [
        "• Open the app and select the type of material you want to recycle (plastic, glass, cans).",
        "• Use the camera to scan the item and enter the quantity.",
        "• Submit the recycling request, and points will be added to your account once the process is complete.",
      ],
    },
    {
      "question": "How do I redeem points for rewards?",
      "answer": [
        "• Go to the 'Balance' page in the app.",
        "• Select 'Redeem Points' and browse the available rewards.",
        "• Choose your reward, and a voucher will be issued that you can use at partner stores.",
      ],
    },
    {
      "question": "Which stores accept my rewards?",
      "answer": [
        "• You can use your points in restaurants, supermarkets, cafés, pharmacies, and dessert shops that are part of our network.",
      ],
    },
    {
      "question": "Is there a minimum amount required for recycling?",
      "answer": [
        "• Yes, the minimum amount is 5 items per type. You can recycle in multiples of 5 (e.g., 10, 15, 20...).",
      ],
    },
    {
      "question": "Can I track my points and rewards?",
      "answer": [
        "• Yes! You can check your balance and rewards anytime in the 'Balance' section of the app.",
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _isExpanded = List.generate(faqs.length, (index) => false);
    filteredFaqs = List.from(faqs); // عرض كل الأسئلة في البداية
    searchController.addListener(_filterFAQs); // تشغيل البحث عند الكتابة
  }

  void _filterFAQs() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredFaqs =
          faqs.where((faq) {
            return faq["question"].toLowerCase().contains(query);
          }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'FAQ',
        leading: IconButton(
          icon: Icon(
            CupertinoIcons.back,
            color: AppTheme.light.colorScheme.secondary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // شريط البحث
            TextField(
              controller: searchController, // ✅ ربط البحث
              decoration: InputDecoration(
                hintText: 'Search for help',
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            SizedBox(height: 20),
            // قائمة الأسئلة بعد الفلترة
            Expanded(
              child: ListView.builder(
                itemCount: filteredFaqs.length,
                itemBuilder: (context, index) {
                  return _buildFAQItem(
                    index: index,
                    question: filteredFaqs[index]["question"]!,
                    answers: filteredFaqs[index]["answer"] as List<String>,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem({
    required int index,
    required String question,
    required List<String> answers,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.light.colorScheme.secondary,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.light.colorScheme.primary,
          ),
        ),
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded[index] = expanded;
          });
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        iconColor: AppTheme.light.colorScheme.primary,
        collapsedIconColor: AppTheme.light.colorScheme.primary,
        children: [
          Divider(color: AppTheme.light.colorScheme.primary, thickness: 1),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  answers
                      .map(
                        (answer) => Text(
                          answer,
                          style: TextStyle(fontSize: 14, height: 1.5),
                        ),
                      )
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
