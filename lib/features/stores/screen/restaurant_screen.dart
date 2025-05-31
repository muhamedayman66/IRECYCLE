import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:graduation_project11/core/api/api_constants.dart';
import 'package:graduation_project11/core/themes/app__theme.dart';
import 'package:graduation_project11/core/widgets/custom_appbar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

class RestaurantScreen extends StatefulWidget {
  const RestaurantScreen({super.key});

  @override
  _RestaurantScreenState createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends State<RestaurantScreen> {
  List<Map<String, dynamic>> allStores = [];
  List<Map<String, dynamic>> filteredStores = [];
  bool isLoading = true;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    fetchStores();
  }

  Future<void> fetchStores() async {
    try {
      final response = await http.get(Uri.parse(ApiConstants.stores));

      if (response.statusCode == 200) {
        List<dynamic> storesData = jsonDecode(response.body);
        List<Map<String, dynamic>> restaurants = [];
        for (var store in storesData) {
          if (store['category']?.toLowerCase() == 'restaurants') {
            String imagePath = "assets/images/restaurants.jpg"; // Default image
            switch (store['name'].toLowerCase()) {
              case 'buffalo burger':
                imagePath = "assets/images/buffaloburgerRS.jpg";
                break;
              case 'heart attack':
                imagePath = "assets/images/heartattackRS.jpg";
                break;
              case 'bazooka':
                imagePath = "assets/images/bazookaRS.jpg"; // Adjust if needed
                break;
            }
            restaurants.add({
              "name": store['name'],
              "branches": store['branches'] ?? [],
              "image": imagePath,
            });
          }
        }

        setState(() {
          allStores = restaurants;
          filteredStores = restaurants;
          isLoading = false;
        });

        if (restaurants.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No restaurants available at the moment'),
              ),
            );
          }
        }
      } else {
        throw Exception(
          'Failed to fetch store data: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  void _filterSearch(String query) {
    setState(() {
      searchQuery = query;
      filteredStores =
          allStores
              .where(
                (store) =>
                    store["name"].toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
    });
  }

  Future<void> _showBranchesOnGoogleMaps(
    BuildContext context,
    Map<String, dynamic> store,
  ) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw "Location service is disabled";
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever ||
            permission == LocationPermission.denied) {
          throw "Location permission denied";
        }
      }

      List<dynamic> branches = store['branches'];
      if (branches.isEmpty) {
        throw "No branches available for this store";
      }

      String waypoints = branches
          .map((branch) => "${branch['latitude']},${branch['longitude']}")
          .join("|");
      String url =
          "https://www.google.com/maps/dir/?api=1&destination=${branches[0]['latitude']},${branches[0]['longitude']}&waypoints=$waypoints";

      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        throw "Cannot open the map";
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: CustomAppBar(
        title: 'Restaurants',
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: TextField(
                      onChanged: _filterSearch,
                      decoration: InputDecoration(
                        hintText: "Search...",
                        prefixIcon: const Icon(Icons.search),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: AppTheme.light.colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: AppTheme.light.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child:
                        filteredStores.isEmpty
                            ? const Center(child: Text('No results found'))
                            : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                vertical: 7,
                                horizontal: 8,
                              ),
                              itemCount: filteredStores.length,
                              itemBuilder: (context, index) {
                                var store = filteredStores[index];
                                return Container(
                                  width: double.infinity,
                                  height: 120,
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: AppTheme.light.colorScheme.primary,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: SizedBox(
                                                width: 70,
                                                height: 55,
                                                child: Image.asset(
                                                  store["image"],
                                                  fit: BoxFit.fill,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    store["name"],
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15,
                                                      color:
                                                          AppTheme
                                                              .light
                                                              .colorScheme
                                                              .primary,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    "Fried Chicken, Burgers, Sandwiches",
                                                    style: TextStyle(
                                                      color: Colors.grey[700],
                                                      fontSize: 12.5,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              _showBranchesOnGoogleMaps(
                                                context,
                                                store,
                                              );
                                            },
                                            icon: Icon(
                                              Icons.location_on,
                                              size: 15,
                                              color:
                                                  AppTheme
                                                      .light
                                                      .colorScheme
                                                      .secondary,
                                            ),
                                            label: Text(
                                              "Location",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color:
                                                    AppTheme
                                                        .light
                                                        .colorScheme
                                                        .secondary,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              fixedSize: const Size(120, 10),
                                              backgroundColor:
                                                  AppTheme
                                                      .light
                                                      .colorScheme
                                                      .primary,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              elevation: 1,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
    );
  }
}
