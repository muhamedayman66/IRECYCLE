import 'package:flutter/material.dart';
import 'package:graduation_project11/core/api/api_constants.dart';
import 'package:graduation_project11/core/themes/app__theme.dart';
import 'package:graduation_project11/features/auth/sign_in/presentation/screen/sign_in_screen.dart';
import 'package:graduation_project11/features/auth/sign_up/presentation/screen/sign_up_screen2.dart';
import 'package:graduation_project11/features/auth/sign_up/presentation/widget/arrow_in_circle.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SignUpScreen1 extends StatefulWidget {
  const SignUpScreen1({super.key});

  @override
  State<SignUpScreen1> createState() => _SignUpScreen1State();
}

class _SignUpScreen1State extends State<SignUpScreen1> {
  final _formKey = GlobalKey<FormState>();

  String? userType;
  final TextEditingController genderController = TextEditingController();
  final TextEditingController typeController = TextEditingController();
  final TextEditingController displayTypeController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  bool _hasError = false;
  bool emailValid = false;

  // إضافة TYPE_CHOICES كـ Map للتوافق مع الباك إند
  final Map<String, String> typeChoices = {
    'Customer': 'customer',
    'Delivery Boy': 'delivery_boy',
  };

  Future<bool> emailValidCheck(String email, String userType) async {
    try {
      // التحقق من وجود البريد الإلكتروني في نموذج Register
      final registerResponse = await http.get(
        Uri.parse(ApiConstants.registers),
      );
      if (registerResponse.statusCode == 200) {
        List<dynamic> registers = json.decode(registerResponse.body);
        if (registers.any((user) => user['email'] == email)) {
          return true;
        }
      }

      // التحقق من وجود البريد الإلكتروني في نموذج DeliveryBoy
      if (userType.toLowerCase() == 'delivery_boy') {
        final deliveryBoyResponse = await http.get(
          Uri.parse(ApiConstants.deliveryBoys),
        );
        if (deliveryBoyResponse.statusCode == 200) {
          List<dynamic> deliveryBoys = json.decode(deliveryBoyResponse.body);
          if (deliveryBoys.any((user) => user['email'] == email)) {
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      print('Error checking email: $e');
      return false;
    }
  }

  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _hasError = true;
      });
      return;
    }

    // التحقق من وجود البريد الإلكتروني
    emailValid = await emailValidCheck(
      emailController.text,
      typeController.text,
    );
    if (emailValid) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Email already exists')));
      return;
    }

    // تحديد المسار بناءً على نوع المستخدم
    String endpoint =
        typeController.text == 'customer'
            ? ApiConstants.registerCreate
            : '${ApiConstants.baseUrl}/api/delivery_boys/create/';

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'first_name': firstNameController.text,
          'last_name': lastNameController.text,
          'gender': genderController.text,
          'email': emailController.text,
          'password':
              'password123', // قيمة مؤقتة، يمكن تعديلها في SignUpScreen2
          'birth_date': '2000-01-01', // قيمة مؤقتة
          'phone_number': '0123456789', // قيمة مؤقتة
          'governorate': 'cairo', // قيمة افتراضية، يمكن تعديلها لاحقًا
          'type': typeController.text, // القيمة المخزنة من typeChoices
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => SignUpScreen2(
                  email: emailController.text,
                  userType: typeController.text,
                ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: ${response.body}')),
        );
      }
    } catch (e) {
      print('Error during registration: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred during registration')),
      );
    }
  }

  void _selectGender() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.light.colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              buildOptionItem(
                text: 'Male',
                icon: Icon(
                  Icons.male,
                  color: AppTheme.light.colorScheme.primary,
                ),
                onTap: () {
                  setState(() {
                    genderController.text = 'Male';
                  });
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
              buildOptionItem(
                text: 'Female',
                icon: Icon(
                  Icons.female,
                  color: AppTheme.light.colorScheme.primary,
                ),
                onTap: () {
                  setState(() {
                    genderController.text = 'Female';
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _selectType() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.light.colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
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
                    Icons.person,
                    color: AppTheme.light.colorScheme.primary,
                  ),
                  title: Text(
                    'Customer',
                    style: TextStyle(
                      color: AppTheme.light.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      typeController.text =
                          typeChoices['Customer'] ?? 'customer';
                      displayTypeController.text = 'Customer';
                    });
                    Navigator.pop(context);
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
                    Icons.motorcycle_sharp,
                    color: AppTheme.light.colorScheme.primary,
                  ),
                  title: Text(
                    'Delivery Boy',
                    style: TextStyle(
                      color: AppTheme.light.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      typeController.text =
                          typeChoices['Delivery Boy'] ?? 'delivery_boy';
                      displayTypeController.text = 'Delivery Boy';
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppTheme.light.colorScheme.primary,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Stack(
                    children: [
                      Positioned(
                        top: 20,
                        left: 16,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignInScreen(),
                              ),
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
                        children: [
                          const Spacer(),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Image.asset(
                              'assets/icons/recycle.png',
                              width: 300,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(15),
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
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "SIGN UP",
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.light.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: buildTextField(
                                          label: "First Name",
                                          controller: firstNameController,
                                          hint: 'Enter your first name',
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'This field is required';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: buildTextField(
                                          label: "Last Name",
                                          controller: lastNameController,
                                          hint: 'Enter your last name',
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'This field is required';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  buildTextField(
                                    label: 'Email Address',
                                    controller: emailController,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'This field is required';
                                      }
                                      String emailPattern =
                                          r'^[a-zA-Z0-9._%+-]+@(gmail|yahoo|icloud)\.[a-z]{2,}$';
                                      if (!RegExp(
                                        emailPattern,
                                      ).hasMatch(value)) {
                                        return 'Please enter a valid email';
                                      }
                                      return null;
                                    },
                                    hint: 'Enter your email',
                                  ),
                                  const SizedBox(height: 12),
                                  buildSelectableFormField(
                                    label: 'Gender',
                                    hintText: 'Select your gender',
                                    controller: genderController,
                                    onTap: _selectGender,
                                  ),
                                  const SizedBox(height: 12),
                                  buildSelectableFormField(
                                    label: 'Select Type',
                                    hintText: 'Select your type',
                                    controller: typeController,
                                    onTap: _selectType,
                                  ),
                                  const SizedBox(height: 20),
                                  ArrowInCircle(
                                    progress: 0.25,
                                    progressColor:
                                        _hasError ? Colors.red : Colors.green,
                                    onTap: registerUser,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.light.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 15,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: AppTheme.light.colorScheme.primary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                color: AppTheme.light.colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildSelectableFormField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.light.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller:
              controller == typeController ? displayTypeController : controller,
          readOnly: true,
          onTap: onTap,
          validator:
              (value) =>
                  value == null || value.isEmpty
                      ? 'This field is required'
                      : null,
          style: TextStyle(color: AppTheme.light.colorScheme.primary),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.grey),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 15,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                color: AppTheme.light.colorScheme.primary,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                color: AppTheme.light.colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildOptionItem({
    required String text,
    required Widget icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.light.colorScheme.primary),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: TextStyle(
                color: Colors.green[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            icon,
          ],
        ),
      ),
    );
  }
}
