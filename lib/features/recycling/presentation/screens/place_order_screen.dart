import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:graduation_project11/core/api/api_constants.dart';
import 'package:graduation_project11/core/themes/app__theme.dart';
import 'package:graduation_project11/core/utils/shared_keys.dart';
import 'package:graduation_project11/core/widgets/custom_appbar.dart';
import 'package:graduation_project11/features/recycling/presentation/screens/order_status_screen.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as latLng;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';

class PlaceOrderScreen extends StatefulWidget {
  final int totalPoints;
  final List<Map<String, dynamic>> items; // إضافة قائمة العناصر

  const PlaceOrderScreen({
    super.key,
    required this.totalPoints,
    required this.items, // تمرير العناصر
  });

  @override
  State<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  final logger = Logger();
  String? address = "Loading your saved address...";
  latLng.LatLng? _currentPosition; // Changed to latlong2.LatLng
  bool _isLoading = false;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _getCurrentLocation();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _userEmail = prefs.getString(SharedKeys.userEmail);
        address =
            prefs.getString(SharedKeys.userAddress) ?? "جاري تحميل العنوان...";
      });

      if (_userEmail != null) {
        // محاولة تحميل العنوان المحفوظ أولاً
        final savedAddress = prefs.getString(SharedKeys.userAddress);
        if (savedAddress != null && savedAddress.isNotEmpty) {
          setState(() {
            address = savedAddress;
          });
        }

        // محاولة تحديث العنوان من الملف الشخصي
        await _fetchUserProfile();

        // إذا لم يتم العثور على عنوان، حاول الحصول على الموقع الحالي
        if (address == null ||
            address == "لم يتم العثور على عنوان" ||
            address!.isEmpty) {
          await _getCurrentLocation();
        }

        // تحميل معلومات الطلب المعلق إن وجد
        await _fetchLatestPendingBag();
      } else {
        setState(() {
          address = "يرجى تسجيل الدخول أولاً";
        });
      }
    } catch (e) {
      setState(() {
        address = "حدث خطأ أثناء تحميل البيانات";
      });
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      logger.i('جاري تحميل الملف الشخصي للمستخدم: $_userEmail');

      final response = await http.get(
        Uri.parse(
          '${ApiConstants.getUserProfile}?email=$_userEmail&user_type=regular_user',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      logger.i('حالة الاستجابة: ${response.statusCode}');
      logger.i('محتوى الاستجابة: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();

        // التحقق من البيانات المستلمة
        logger.i('البيانات المستلمة: $data');

        // استخراج معلومات العنوان
        final governorate = data['governorate']?.toString() ?? '';
        final city = data['city']?.toString() ?? '';
        final street = data['street']?.toString() ?? '';
        final building = data['building']?.toString() ?? '';
        final apartment = data['apartment']?.toString() ?? '';

        // تجميع مكونات العنوان المتوفرة فقط
        final List<String> addressParts = [];

        if (street.isNotEmpty) addressParts.add(street);
        if (building.isNotEmpty) addressParts.add('مبنى $building');
        if (apartment.isNotEmpty) addressParts.add('شقة $apartment');
        if (city.isNotEmpty) addressParts.add(city);
        if (governorate.isNotEmpty) addressParts.add(governorate);

        final fullAddress =
            addressParts.isNotEmpty
                ? addressParts.join('، ')
                : "لم يتم العثور على عنوان";

        logger.i('العنوان المجمع: $fullAddress');

        setState(() {
          address = fullAddress;
        });

        // حفظ العنوان في التخزين المحلي
        await prefs.setString(SharedKeys.userAddress, fullAddress);

        // إذا لم يتم العثور على عنوان، حاول الحصول على الموقع الحالي
        if (addressParts.isEmpty) {
          logger.i(
            'لم يتم العثور على عنوان في الملف الشخصي، جاري تحديد الموقع الحالي...',
          );
          await _getCurrentLocation();
        }
      } else {
        logger.e('فشل في تحميل الملف الشخصي: ${response.statusCode}');
        setState(() {
          address = "فشل في تحميل العنوان";
        });

        // في حالة الفشل، حاول الحصول على الموقع الحالي
        await _getCurrentLocation();
      }
    } catch (e) {
      logger.e('خطأ في جلب الملف الشخصي: $e');
      setState(() {
        address = "خطأ في جلب العنوان";
      });

      // في حالة حدوث خطأ، حاول الحصول على الموقع الحالي
      await _getCurrentLocation();
    }
  }

  Future<void> _fetchLatestPendingBag() async {
    try {
      if (_userEmail == null) return;

      final response = await http.get(
        Uri.parse(ApiConstants.recycleBagsPending(_userEmail!)),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          setState(() {
            _currentPosition = latLng.LatLng(
              // Changed to latlong2.LatLng
              double.parse(data[0]['latitude'].toString()),
              double.parse(data[0]['longitude'].toString()),
            );
          });
        }
      }
    } catch (e) {
      logger.e("Error fetching pending bag: $e");
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          address = "خدمات الموقع معطلة";
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            address = "تم رفض إذن الموقع";
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          address = "تم رفض إذن الموقع بشكل دائم";
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
        localeIdentifier: 'ar',
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final components = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
        ].where((component) => component != null && component.isNotEmpty);

        String formattedAddress = components.join('، ');

        setState(() {
          _currentPosition = latLng.LatLng(
            position.latitude,
            position.longitude,
          ); // Changed to latlong2.LatLng
          address = formattedAddress;
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(SharedKeys.userAddress, formattedAddress);
      } else {
        setState(() {
          address = "لم يتم العثور على عنوان";
        });
      }
    } catch (e) {
      setState(() {
        address = "خطأ في تحديد الموقع";
      });
    }
  }

  Future<void> _placeOrder() async {
    if (!mounted) return;

    if (_userEmail == null || _isLoading) {
      _showErrorSnackBar("يرجى تسجيل الدخول أولاً");
      return;
    }

    if (_currentPosition == null) {
      _showErrorSnackBar("يرجى تحديد موقع صالح");
      return;
    }

    if (address == null ||
        address == "لم يتم العثور على عنوان" ||
        address == "فشل في تحميل العنوان" ||
        address == "خطأ في جلب العنوان" ||
        address!.isEmpty) {
      _showErrorSnackBar("يرجى تحديد عنوان صالح");
      return;
    }

    if (widget.items.isEmpty) {
      _showErrorSnackBar("يرجى إضافة عناصر لإعادة التدوير");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      logger.i('جاري إرسال الطلب...');
      logger.i('العنوان: $address');
      logger.i(
        'الموقع: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
      );
      logger.i('العناصر: ${widget.items}');

      final response = await http.post(
        Uri.parse(ApiConstants.placeOrder),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _userEmail,
          'address': address,
          'latitude': _currentPosition!.latitude.toString(),
          'longitude': _currentPosition!.longitude.toString(),
          'items': widget.items,
        }),
      );

      logger.i('حالة الاستجابة: ${response.statusCode}');
      logger.i('محتوى الاستجابة: ${response.body}');

      if (response.statusCode == 201) {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderStatusScreen(userEmail: _userEmail!),
          ),
        );
      } else {
        final responseData = jsonDecode(response.body);
        final error = responseData['error'] ?? "فشل تقديم الطلب";
        logger.e('خطأ من الخادم: $error');
        if (!mounted) return;
        _showErrorSnackBar(error);
      }
    } catch (e) {
      logger.e('خطأ في إرسال الطلب: $e');
      if (!mounted) return;
      _showErrorSnackBar("حدث خطأ أثناء إرسال الطلب");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        logger.e('Could not launch $launchUri');
        if (!mounted) return;
        _showErrorSnackBar('Could not launch phone call');
      }
    } catch (e) {
      logger.e('Error launching phone call: $e');
      if (!mounted) return;
      _showErrorSnackBar('Error launching phone call');
    }
  }

  void _showEditAddressDialog() {
    if (!mounted) return;

    TextEditingController _addressController = TextEditingController(
      text: address,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("تعديل العنوان"),
          content: TextField(
            controller: _addressController,
            decoration: const InputDecoration(hintText: "أدخل العنوان الجديد"),
          ),
          actions: [
            TextButton(
              child: const Text("إلغاء"),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text("حفظ"),
              onPressed: () async {
                String newAddress = _addressController.text;
                if (newAddress.isEmpty) {
                  if (!mounted) return;
                  _showErrorSnackBar("لا يمكن أن يكون العنوان فارغًا.");
                  return;
                }
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setString(SharedKeys.userAddress, newAddress);
                if (!mounted) return;
                setState(() {
                  address = newAddress;
                });
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Changed background color
      appBar: CustomAppBar(
        title: 'Confirm Order Details', // Updated title
        leading: IconButton(
          icon: Icon(
            CupertinoIcons.back,
            color: AppTheme.light.colorScheme.primary, // Adjusted color
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0), // Consistent padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Map Section
                Expanded(
                  flex: 3, // Give map more space
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child:
                        _currentPosition == null
                            ? const Center(child: CircularProgressIndicator())
                            : fm.FlutterMap(
                              options: fm.MapOptions(
                                initialCenter: _currentPosition!,
                                initialZoom: 15.0,
                                interactionOptions: const fm.InteractionOptions(
                                  flags:
                                      fm.InteractiveFlag.all &
                                      ~fm.InteractiveFlag.rotate,
                                ),
                              ),
                              children: [
                                fm.TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName:
                                      'com.irecycle.app', // Replace with your actual package name
                                ),
                                if (_currentPosition != null)
                                  fm.MarkerLayer(
                                    markers: [
                                      fm.Marker(
                                        width: 80.0,
                                        height: 80.0,
                                        point: _currentPosition!,
                                        child: Icon(
                                          Icons.location_pin,
                                          color: Colors.red,
                                          size: 40.0,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                  ),
                ),
                const SizedBox(height: 16),

                // Address Section
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_pin,
                          color: AppTheme.light.colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pickup Address',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.light.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                address ?? 'Loading address...',
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _showEditAddressDialog,
                          child: Text(
                            "Change",
                            style: TextStyle(
                              color: Colors.teal,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Items Summary Section
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Summary',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.light.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Items to Recycle:',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              '${widget.items.length} item(s)',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Points:',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              '${widget.totalPoints} pts',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(), // Pushes button to bottom
                // Confirm Button
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 16.0,
                    top: 16.0,
                  ), // Added top padding too
                  child: ElevatedButton.icon(
                    icon: const Icon(
                      Icons.check_circle_outline,
                      color: Colors.white,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.light.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: _isLoading ? null : _placeOrder,
                    label: Text(
                      "Confirm & Place Order",
                      style: TextStyle(
                        color: Colors.white, // Ensure text is white
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
