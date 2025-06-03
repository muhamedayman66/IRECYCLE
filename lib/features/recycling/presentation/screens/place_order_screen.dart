import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:graduation_project11/core/api/api_constants.dart';
import 'package:graduation_project11/core/themes/app__theme.dart';
import 'package:graduation_project11/core/utils/shared_keys.dart';
import 'package:graduation_project11/core/widgets/custom_appbar.dart';
import 'package:graduation_project11/features/recycling/presentation/screens/order_status_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  LatLng? _currentPosition;
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
            _currentPosition = LatLng(
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
          _currentPosition = LatLng(position.latitude, position.longitude);
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
      backgroundColor: AppTheme.light.colorScheme.secondary,
      appBar: CustomAppBar(
        title: 'Place Order',
        leading: IconButton(
          icon: Icon(
            CupertinoIcons.back,
            color: AppTheme.light.colorScheme.secondary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 10),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.light.colorScheme.primary,
                    ),
                  ),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        child: Container(
                          height: 200,
                          color: Colors.grey[300],
                          child:
                              _currentPosition == null
                                  ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                  : GoogleMap(
                                    initialCameraPosition: CameraPosition(
                                      target: _currentPosition!,
                                      zoom: 14,
                                    ),
                                    zoomControlsEnabled: false,
                                    zoomGesturesEnabled: true,
                                    scrollGesturesEnabled: true,
                                    rotateGesturesEnabled: true,
                                    tiltGesturesEnabled: true,
                                    markers: {
                                      Marker(
                                        markerId: const MarkerId(
                                          'current-location',
                                        ),
                                        position: _currentPosition!,
                                      ),
                                    },
                                    gestureRecognizers: {
                                      Factory<PanGestureRecognizer>(
                                        () => PanGestureRecognizer(),
                                      ),
                                      Factory<ScaleGestureRecognizer>(
                                        () => ScaleGestureRecognizer(),
                                      ),
                                      Factory<TapGestureRecognizer>(
                                        () => TapGestureRecognizer(),
                                      ),
                                    },
                                  ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.location_on, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Address',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    address ?? 'No address found',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: _showEditAddressDialog,
                              child: const Text(
                                "Change",
                                style: TextStyle(color: Colors.green),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.light.colorScheme.primary,
                    ),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "🚚 Delivery",
                            style: TextStyle(
                              color: AppTheme.light.colorScheme.primary,
                            ),
                          ),
                          const Text("Arriving in approx. 33 mins"),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 325,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.light.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: _isLoading ? null : _placeOrder,
                    child: Text(
                      "Confirm",
                      style: TextStyle(
                        color: AppTheme.light.colorScheme.secondary,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 80),
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
