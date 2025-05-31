import 'dart:io';
import 'package:flutter/material.dart';
import 'package:graduation_project11/core/api/api_constants.dart';
import 'package:graduation_project11/features/auth/otp/presentation/screens/otp_screen.dart';
import 'package:graduation_project11/features/auth/sign_in/presentation/screen/sign_in_screen.dart';
import 'package:graduation_project11/core/themes/app__theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignUpScreen4 extends StatefulWidget {
  const SignUpScreen4({super.key, required this.email, required this.userType});

  final String email;
  final String userType;

  @override
  State<SignUpScreen4> createState() => _SignUpScreen4State();
}

class _SignUpScreen4State extends State<SignUpScreen4> {
  final _formKey = GlobalKey<FormState>();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  Color _borderColor = AppTheme.light.colorScheme.primary;

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _borderColor = AppTheme.light.colorScheme.primary;
      });
    }
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.light.colorScheme.primary,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppTheme.light.colorScheme.primary,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.camera_alt,
                            color: AppTheme.light.colorScheme.primary,
                          ),
                          title: Text(
                            'Take a photo',
                            style: TextStyle(
                              color: AppTheme.light.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage(ImageSource.camera);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppTheme.light.colorScheme.primary,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.photo_library,
                            color: AppTheme.light.colorScheme.primary,
                          ),
                          title: Text(
                            'Choose from gallery',
                            style: TextStyle(
                              color: AppTheme.light.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage(ImageSource.gallery);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> uploadImage() async {
    try {
      // تحديد المسار بناءً على نوع المستخدم
      final String endpoint =
          widget.userType == 'customer'
              ? ApiConstants.registers
              : ApiConstants.deliveryBoys;

      final response = await http.get(Uri.parse(endpoint));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final user = data.firstWhere(
          (user) => user['email'] == widget.email,
          orElse: () => null,
        );

        if (user == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('User not found')));
          return;
        }

        final int userId = user['id'];

        // التحقق من اختيار الصورة
        if (_selectedImage == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select an image')),
          );
          setState(() {
            _borderColor = Colors.red;
          });
          return;
        }

        final updateEndpoint =
            widget.userType == 'customer'
                ? ApiConstants.registerUpdate(userId)
                : ApiConstants.deliveryBoyUpdate(userId);

        print(
          'Debug: updateEndpoint for PUT request in SignUpScreen4: $updateEndpoint',
        ); // Diagnostic print

        final request = http.MultipartRequest('PUT', Uri.parse(updateEndpoint));

        request.fields['first_name'] = user['first_name'];
        request.fields['last_name'] = user['last_name'];
        request.fields['gender'] = user['gender'];
        request.fields['governorate'] = user['governorate'];
        request.fields['type'] = user['type'];
        request.fields['birth_date'] = user['birth_date'];
        request.fields['phone_number'] = user['phone_number'];
        request.fields['email'] = user['email'];
        request.fields['password'] = user['password'];
        request.files.add(
          await http.MultipartFile.fromPath('image', _selectedImage!.path),
        );

        // إرسال الطلب
        final streamedResponse = await request.send();
        final responseBody = await streamedResponse.stream.bytesToString();

        if (streamedResponse.statusCode == 200) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => OtpAuthenticationScreen(
                    email: widget.email,
                    source: "signup",
                    userType: widget.userType,
                  ),
            ),
          );
        } else {
          print('Error response: $responseBody');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload image: $responseBody')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch user data')),
        );
      }
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred while uploading image'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.light.colorScheme.primary,
      body: Stack(
        children: [
          Positioned(
            top: 20,
            left: 16,
            child: GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SignInScreen()),
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: AppTheme.light.colorScheme.secondary,
                  size: 24,
                ),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Image.asset('assets/icons/recycle.png', width: 350),
              ),
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.light.colorScheme.secondary,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Text(
                        "SIGN UP",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.light.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _borderColor, width: 2),
                          image:
                              _selectedImage != null
                                  ? DecorationImage(
                                    image: FileImage(_selectedImage!),
                                    fit: BoxFit.cover,
                                  )
                                  : null,
                        ),
                        child:
                            _selectedImage == null
                                ? Center(
                                  child: Icon(
                                    Icons.person_outline,
                                    color: _borderColor,
                                    size: 60,
                                  ),
                                )
                                : null,
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.light.colorScheme.primary,
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        onPressed: _showPickerOptions,
                        child: Text(
                          "Add Picture",
                          style: TextStyle(
                            color: AppTheme.light.colorScheme.secondary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      GestureDetector(
                        onTap: () async {
                          if (_selectedImage == null) {
                            setState(() {
                              _borderColor = Colors.red;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select an image'),
                              ),
                            );
                          } else {
                            await uploadImage();
                          }
                        },
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.light.colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              "Verify",
                              style: TextStyle(
                                color: AppTheme.light.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
