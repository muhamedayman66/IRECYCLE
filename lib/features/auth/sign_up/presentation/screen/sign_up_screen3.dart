import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:graduation_project11/core/api/api_constants.dart';
import 'package:graduation_project11/core/themes/app__theme.dart';
import 'package:graduation_project11/features/auth/sign_in/presentation/screen/sign_in_screen.dart';
import 'package:graduation_project11/features/auth/sign_up/presentation/screen/sign_up_screen4.dart';
import 'package:graduation_project11/features/auth/sign_up/presentation/widget/arrow_in_circle.dart';
import 'package:http/http.dart' as http;

class SignUpScreen3 extends StatefulWidget {
  const SignUpScreen3({super.key, required this.email, required this.userType});
  final String email;
  final String userType; // إضافة userType

  @override
  State<SignUpScreen3> createState() => _SignUpScreen3State();
}

class _SignUpScreen3State extends State<SignUpScreen3> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _hasError = false;
  bool isPasswordValid = false;
  bool hasMinLength = false;
  bool hasNumber = false;
  bool hasUpperLower = false;
  bool passwordsMatch = false;
  bool _obscureText = true;

  Future<void> update() async {
    try {
      final String endpoint =
          widget.userType.toLowerCase() == 'customer'
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
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('User not found')));
            Navigator.pop(context); // Return to previous screen
          }
          return;
        }

        final int id = user['id'];
        final updatedUserData = {
          'first_name': user['first_name'],
          'last_name': user['last_name'],
          'gender': user['gender'],
          'governorate': user['governorate'],
          'type': user['type'],
          'birth_date': user['birth_date'],
          'phone_number': user['phone_number'],
          'email': user['email'],
          'password': _passwordController.text,
        };

        final updateEndpoint =
            widget.userType.toLowerCase() == 'customer'
                ? ApiConstants.registerUpdate(id)
                : ApiConstants.deliveryBoyUpdate(id);

        final updateResponse = await http.put(
          Uri.parse(updateEndpoint),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(updatedUserData),
        );

        if (updateResponse.statusCode == 200) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => SignUpScreen4(
                    email: widget.email,
                    userType: widget.userType,
                  ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update profile: ${updateResponse.body}'),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch user data')),
        );
      }
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred while updating profile'),
        ),
      );
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.light.colorScheme.primary,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
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
                                  const SizedBox(height: 25),
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
                                  const SizedBox(height: 50),
                                  ArrowInCircle(
                                    progress: 0.75,
                                    progressColor:
                                        _hasError ? Colors.red : Colors.green,
                                    onTap: () {
                                      setState(() {
                                        bool isFormValid =
                                            _formKey.currentState!.validate();
                                        _hasError =
                                            !(isFormValid && isPasswordValid);
                                      });

                                      if (!_hasError) {
                                        update();
                                      } else if (_passwordController
                                              .text
                                              .isNotEmpty &&
                                          _confirmPasswordController
                                              .text
                                              .isNotEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: const Text(
                                              'Please make sure your password meets all the rules.',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                            backgroundColor: Colors.red,
                                            behavior: SnackBarBehavior.floating,
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 10,
                                            ),
                                            duration: const Duration(
                                              seconds: 2,
                                            ),
                                          ),
                                        );
                                      }
                                    },
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
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'This field is required';
            }
            return null;
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
              borderSide: const BorderSide(color: Colors.red, width: 2),
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
