// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:graduation_project11/core/api/api_constants.dart';
import 'package:graduation_project11/core/themes/app__theme.dart';
import 'package:graduation_project11/features/auth/sign_in/presentation/screen/sign_in_screen.dart';
import 'package:graduation_project11/features/auth/update_password/screens/set_password_screen2.dart';
import 'package:http/http.dart' as http;

class SetPasswordScreen1 extends StatefulWidget {
  const SetPasswordScreen1({
    super.key,
    required this.email,
    required this.userType,
  });

  final String email;
  final String userType;

  @override
  State<SetPasswordScreen1> createState() => _SetPasswordScreen1State();
}

class _SetPasswordScreen1State extends State<SetPasswordScreen1> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool isPasswordValid = false;
  bool hasMinLength = false;
  bool hasNumber = false;
  bool hasUpperLower = false;
  bool passwordsMatch = false;
  bool _obscureText = true;
  bool _isLoading = false; // إضافة متغير التحميل

  void _validatePassword(String value) {
    setState(() {
      hasMinLength = value.length >= 8;
      hasNumber = value.contains(RegExp(r'\d'));
      hasUpperLower =
          value.contains(RegExp(r'[A-Z]')) && value.contains(RegExp(r'[a-z]'));

      bool bothFieldsNotEmpty =
          _passwordController.text.isNotEmpty &&
          _confirmPasswordController.text.isNotEmpty;

      passwordsMatch =
          bothFieldsNotEmpty &&
          _passwordController.text == _confirmPasswordController.text;

      isPasswordValid =
          hasMinLength && hasNumber && hasUpperLower && passwordsMatch;
    });
  }

  Future<void> _updatePassword() async {
    // التحقق من أن الحقول ليست فارغة
    if (_passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    // التحقق من صحة userType
    if (!['regular_user', 'delivery_boy'].contains(widget.userType)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid user type')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // تحديد الـ endpoint بناءً على نوع المستخدم
      final String apiUrl =
          widget.userType == 'regular_user'
              ? ApiConstants.registers
              : ApiConstants.deliveryBoys;

      // جلب بيانات المستخدم
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // البحث عن المستخدم بالإيميل
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

        // تحديد endpoint التحديث بناءً على نوع المستخدم
        final String updateUrl =
            widget.userType == 'regular_user'
                ? ApiConstants.registerUpdate(userId)
                : ApiConstants.deliveryBoyUpdate(userId);

        // إرسال طلب PUT لتحديث كلمة المرور
        final updateResponse = await http.put(
          Uri.parse(updateUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'first_name': user['first_name'],
            'last_name': user['last_name'],
            'gender': user['gender'],
            'country': user['country'],
            'type': user['type'],
            'birth_date': user['birth_date'],
            'phone_number': user['phone_number'],
            'email': user['email'],
            'password': _passwordController.text,
          }),
        );

        if (updateResponse.statusCode == 200) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SetPasswordScreen2()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update password')),
          );
          return;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch user data')),
        );
        return;
      }
    } catch (e) {
      print('Error updating password: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred while updating password'),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.light.colorScheme.primary,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: LayoutBuilder(
            builder: (context, constraints) {
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
                          mainAxisAlignment: MainAxisAlignment.center,
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
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Set New Password",
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.light.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 35),
                                  _buildPasswordField(
                                    "Password",
                                    _passwordController,
                                    "Enter Password",
                                  ),
                                  const SizedBox(height: 20),
                                  _buildPasswordField(
                                    "Confirm Password",
                                    _confirmPasswordController,
                                    "Re-enter Password",
                                  ),
                                  const SizedBox(height: 25),
                                  _buildPasswordValidationRules(),
                                  const SizedBox(height: 45),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          isPasswordValid
                                              ? AppTheme
                                                  .light
                                                  .colorScheme
                                                  .primary
                                              : Colors.grey,
                                      minimumSize: const Size(
                                        double.infinity,
                                        55,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                    ),
                                    onPressed:
                                        (isPasswordValid && !_isLoading)
                                            ? _updatePassword
                                            : null,
                                    child:
                                        _isLoading
                                            ? const CircularProgressIndicator(
                                              color: Colors.white,
                                            )
                                            : Text(
                                              "Save Password",
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
      ),
    );
  }

  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    String hintText,
  ) {
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
          obscureText: _obscureText,
          onChanged: (value) {
            _validatePassword(value);
          },
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: hintText,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
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
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordValidationRules() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildValidationItem(
          "Password must be at least 8 characters long",
          hasMinLength,
        ),
        const SizedBox(height: 5),
        _buildValidationItem("Password must contain numbers", hasNumber),
        const SizedBox(height: 5),
        _buildValidationItem(
          "Password must contain uppercase and lowercase letters",
          hasUpperLower,
        ),
        const SizedBox(height: 5),
        _buildValidationItem(
          "Both passwords must be identical",
          passwordsMatch,
        ),
      ],
    );
  }

  Widget _buildValidationItem(String text, bool isValid) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.cancel,
          size: 15,
          color: isValid ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: isValid ? Colors.green : Colors.red,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
