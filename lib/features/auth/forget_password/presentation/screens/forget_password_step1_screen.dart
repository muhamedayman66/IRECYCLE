import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:graduation_project11/core/api/api_constants.dart';
import 'package:graduation_project11/core/themes/app__theme.dart';
import 'package:graduation_project11/features/auth/otp/presentation/screens/otp_screen.dart';
import 'package:graduation_project11/features/auth/sign_in/presentation/screen/sign_in_screen.dart';
import 'package:http/http.dart' as http;

class ForgetPasswordStep1Screen extends StatefulWidget {
  const ForgetPasswordStep1Screen({super.key});

  @override
  State<ForgetPasswordStep1Screen> createState() =>
      _ForgetPasswordStep1ScreenState();
}

class _ForgetPasswordStep1ScreenState extends State<ForgetPasswordStep1Screen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _userTypeController = TextEditingController();
  final TextEditingController _displayUserTypeController = TextEditingController();
  String? _selectedUserType;

  // إضافة TYPE_CHOICES كـ Map للتوافق مع الباك إند
  final Map<String, String> typeChoices = {
    'Customer': 'regular_user',
    'Delivery Boy': 'delivery_boy',
  };

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
                      _userTypeController.text = typeChoices['Customer'] ?? 'regular_user';
                      _displayUserTypeController.text = 'Customer';
                      _selectedUserType = typeChoices['Customer'];
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
                      _userTypeController.text = typeChoices['Delivery Boy'] ?? 'delivery_boy';
                      _displayUserTypeController.text = 'Delivery Boy';
                      _selectedUserType = typeChoices['Delivery Boy'];
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
          controller: controller == _userTypeController ? _displayUserTypeController : controller,
          readOnly: true,
          onTap: onTap,
          validator: (value) => value == null || value.isEmpty ? 'This field is required' : null,
          style: TextStyle(
            color: AppTheme.light.colorScheme.primary,
          ),
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

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedUserType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please select user type',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      try {
        // تحديد الـ endpoint بناءً على نوع المستخدم
        final String apiUrl =
            _selectedUserType == 'regular_user'
                ? ApiConstants.registers
                : ApiConstants.deliveryBoys;

        // إرسال طلب GET للتحقق من الإيميل
        final response = await http.get(Uri.parse(apiUrl));

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);

          // البحث عن المستخدم بالإيميل
          final user = data.firstWhere(
            (user) => user['email'] == _emailController.text,
            orElse: () => null,
          );

          if (user != null) {
            // إذا تم العثور على الإيميل، الانتقال إلى صفحة OTP
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => OtpAuthenticationScreen(
                      email: _emailController.text,
                      source: "forget_password",
                      userType: _selectedUserType!, // تمرير userType
                    ),
              ),
            );
          } else {
            // إذا لم يتم العثور على الإيميل
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Email not found. Please check and try again.',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          // إذا حدث خطأ في الاتصال بالخادم
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Failed to connect to the server. Please try again later.',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        print('Error during password reset: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'An error occurred. Please try again later.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppTheme.light.colorScheme.primary,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
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
                            padding: const EdgeInsets.only(right: 8),
                            child: Image.asset(
                              'assets/icons/recycle.png',
                              width: 350,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.light.colorScheme.secondary,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(30),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  offset: Offset(0, -4),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Forgot Your Password?",
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.light.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 25),
                                  Text(
                                    textAlign: TextAlign.center,
                                    'Please enter the email address registered with your account so we can send a verification code.',
                                    style: TextStyle(
                                      color: AppTheme.light.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                  // إضافة حقل اختيار نوع المستخدم
                                  buildSelectableFormField(
                                    label: 'User Type',
                                    hintText: 'Select user type',
                                    controller: _userTypeController,
                                    onTap: _selectType,
                                  ),
                                  const SizedBox(height: 20),
                                  // حقل الإيميل
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Email Address',
                                        style: TextStyle(
                                          color:
                                              AppTheme
                                                  .light
                                                  .colorScheme
                                                  .primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 15),
                                      TextFormField(
                                        controller: _emailController,
                                        validator: (value) {
                                          if (value!.isEmpty) {
                                            return 'This field is required';
                                          }
                                          if (!RegExp(
                                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                          ).hasMatch(value)) {
                                            return 'Please enter a valid email';
                                          }
                                          return null;
                                        },
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        style: const TextStyle(
                                          color: Colors.black,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Enter your email',
                                          hintStyle: const TextStyle(
                                            color: Colors.grey,
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                vertical: 10,
                                                horizontal: 15,
                                              ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                            borderSide: BorderSide(
                                              color:
                                                  AppTheme
                                                      .light
                                                      .colorScheme
                                                      .primary,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                            borderSide: BorderSide(
                                              color:
                                                  AppTheme
                                                      .light
                                                      .colorScheme
                                                      .primary,
                                              width: 2,
                                            ),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Colors.red,
                                            ),
                                          ),
                                          focusedErrorBorder:
                                              OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(30),
                                                borderSide: const BorderSide(
                                                  color: Colors.red,
                                                  width: 2,
                                                ),
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 50),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          AppTheme.light.colorScheme.primary,
                                      minimumSize: const Size(
                                        double.infinity,
                                        55,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                    ),
                                    onPressed: _resetPassword,
                                    child: Text(
                                      "Reset Password",
                                      style: TextStyle(
                                        color:
                                            AppTheme
                                                .light
                                                .colorScheme
                                                .secondary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 30),
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
}
