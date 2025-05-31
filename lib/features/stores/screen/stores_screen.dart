import 'package:flutter/material.dart';
import 'package:graduation_project11/core/themes/app__theme.dart';
import 'package:graduation_project11/core/widgets/custom_appbar.dart';
import 'package:graduation_project11/features/stores/screen/cafes_screen.dart';
import 'package:graduation_project11/features/stores/screen/dessert_shop_screen.dart';
import 'package:graduation_project11/features/stores/screen/hypermarkets_screen.dart';
import 'package:graduation_project11/features/stores/screen/pharmacies_screen.dart';
import 'package:graduation_project11/features/stores/screen/restaurant_screen.dart';
import 'package:graduation_project11/features/stores/widgets/category_card.dart';

class StoresScreen extends StatefulWidget {
  const StoresScreen({
    super.key,
  });

  @override
  State<StoresScreen> createState() => _StoresScreenState();
}

class _StoresScreenState extends State<StoresScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.light.colorScheme.secondary,
      appBar: CustomAppBar(title: 'Stores'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxHeight = constraints.maxHeight;
            final maxWidth = constraints.maxWidth;
            final padding = maxWidth * 0.05;

            return SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: maxHeight * 0.03,
                  ), // Adjusted spacing from top
                  Center(
                    child: Container(
                      width: maxWidth *
                          0.9, // Constrain container width for better layout
                      padding: EdgeInsets.all(padding),
                      decoration: BoxDecoration(
                        color: AppTheme.light.colorScheme.secondary,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: CategoryCard(
                                  title: 'Hypermarkets',
                                  imagePath: 'assets/images/hypermarkets.jpg',
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          HypermarketsScreen(),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: maxWidth * 0.02),
                              Expanded(
                                child: CategoryCard(
                                  title: 'Cafes',
                                  imagePath: 'assets/images/cafes.jpg',
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CafesScreen(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: maxHeight * 0.015),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: CategoryCard(
                                  title: 'Restaurants',
                                  imagePath: 'assets/images/restaurants.jpg',
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RestaurantScreen(),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: maxWidth * 0.02),
                              Expanded(
                                child: CategoryCard(
                                  title: 'Dessert shops',
                                  imagePath: 'assets/images/desserts.jpg',
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DessertShopsScreen(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: maxHeight * 0.015),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: CategoryCard(
                                  title: 'Pharmacies',
                                  imagePath: 'assets/images/pharmacies.jpg',
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PharmaciesScreen(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: maxHeight * 0.03,
                  ), // Extra padding at the bottom
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
