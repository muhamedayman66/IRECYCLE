import 'package:flutter/material.dart';
import 'package:graduation_project11/core/themes/app__theme.dart';
import 'package:graduation_project11/core/widgets/custom_appbar.dart';
import 'package:graduation_project11/features/categories/plastic/screens/plastic_info_screen.dart';

import 'package:graduation_project11/features/home/presentation/screen/home_screen.dart';

class PlasticScreen extends StatelessWidget {
  const PlasticScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.light.colorScheme.secondary,
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: "Plastic",
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_outlined),
          color: AppTheme.light.colorScheme.secondary,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Image.asset(
                'assets/images/plastic2.jpg',
                width: double.infinity,
                height: 310,
                fit: BoxFit.contain,
              ),
              Expanded(
                child: Container(
                  padding: EdgeInsets.only(
                    top: 12,
                    left: 16,
                    right: 16,
                    bottom: 30,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.light.colorScheme.secondary,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Step 1
                      Text(
                        "Step 1:  Scan Your Plastic Bottle",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("•  ", style: TextStyle(fontSize: 16)),
                          Expanded(
                            child: Text(
                              "Items Use the app to quickly and easily scan the plastic items you want to recycle. Simply point your camera at the item — it’s that simple!",
                              style: TextStyle(fontSize: 12, height: 1.4),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 8),
                      // Step 2
                      Text(
                        "Step 2: Enter the Quantity",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("•  ", style: TextStyle(fontSize: 16)),
                          Expanded(
                            child: Text(
                              "The minimum quantity accepted is 5 items, but you can recycle larger amounts in multiples of 5 (e.g., 10, 15, 20).",
                              style: TextStyle(fontSize: 12, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("•  ", style: TextStyle(fontSize: 16)),
                          Expanded(
                            child: Text(
                              "The more items you recycle, the more points you’ll earn!",
                              style: TextStyle(fontSize: 12, height: 1.4),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 8),

                      // Step 3
                      Text(
                        "Step 3: Earn Points and Redeem Rewards",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("•  ", style: TextStyle(fontSize: 16)),
                          Expanded(
                            child: Text(
                              "For every 5 items, you’ll earn 25 points.",
                              style: TextStyle(fontSize: 12, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("•  ", style: TextStyle(fontSize: 16)),
                          Expanded(
                            child: Text(
                              "Redeem your points for amazing rewards, such as gift vouchers, exclusive discounts, or even free products from partner stores.",
                              style: TextStyle(fontSize: 12, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                      Spacer(),
                      Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.light.colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 14,
                            ),
                          ),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HomeScreen(),
                              ),
                            );
                          },
                          child: Text(
                            "Go to Homepage",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),

                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 220,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        "Make a Difference: Recycle Your Plastic Today",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.info_outline),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlasticInfoScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
