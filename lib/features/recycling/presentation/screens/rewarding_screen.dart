import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for SystemNavigator
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:graduation_project11/core/api/api_constants.dart';
import 'package:graduation_project11/core/themes/app__theme.dart';
import 'package:graduation_project11/features/home/presentation/screen/home_screen.dart';
import 'package:graduation_project11/features/recycling/presentation/screens/recycle_bag_screen.dart'; // Ensure this is imported
import 'package:graduation_project11/core/utils/shared_keys.dart';

class RewardingScreen extends StatefulWidget {
  final int totalPoints;
  final int? assignmentId;

  const RewardingScreen({
    super.key,
    required this.totalPoints,
    this.assignmentId,
  });

  @override
  State<RewardingScreen> createState() => _RewardingScreenState();
}

class _RewardingScreenState extends State<RewardingScreen> {
  bool _isLoading = false;
  double _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  int? _assignmentId;

  @override
  void initState() {
    super.initState();
    print('Assignment ID received in RewardingScreen: ${widget.assignmentId}');
    _verifyAssignmentId();
  }

  Future<void> _verifyAssignmentId() async {
    if (widget.assignmentId == null) {
      print('Warning: Assignment ID is null in RewardingScreen');
      // محاولة استرجاع assignment_id من الذاكرة المحلية
      final prefs = await SharedPreferences.getInstance();
      final lastAssignmentId = prefs.getInt(SharedKeys.lastAssignmentId);

      if (lastAssignmentId == null) {
        print('Error: No assignment ID found in SharedPreferences');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'لا يمكن العثور على معرف الطلب. يرجى المحاولة مرة أخرى.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
        return;
      }

      setState(() {
        _assignmentId = lastAssignmentId;
      });
    } else {
      setState(() {
        _assignmentId = widget.assignmentId!;
      });
    }
  }

  Future<void> _submitRating() async {
    // Ensure _assignmentId is verified before proceeding
    if (_assignmentId == null) {
      await _verifyAssignmentId(); // Await verification
      // If still null after verification (e.g., error occurred in _verifyAssignmentId), prevent submission
      if (_assignmentId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لم يتم تحديد معرف الطلب. حاول مرة أخرى.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار تقييم'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get user email from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString(SharedKeys.userEmail);

      if (userEmail == null) {
        throw Exception('لم يتم العثور على بيانات المستخدم');
      }

      final response = await http.post(
        Uri.parse(ApiConstants.userRateOrder(_assignmentId!)),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'stars': _rating.toInt(),
          'comment': _commentController.text.trim(),
          'user_email': userEmail,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Accept 201 as success
        // حفظ النقاط في الذاكرة المحلية
        await prefs.setInt(SharedKeys.lastEarnedPoints, widget.totalPoints);

        // مسح معرف الطلب بعد التقييم الناجح
        await prefs.remove(SharedKeys.lastAssignmentId);
        // Clear the resume flag as the flow is completed
        await prefs.setBool(SharedKeys.shouldResumeToRewardingScreen, false);

        if (mounted) {
          RecycleBagScreen.markOrderAsCompleted(); // Mark order as completed to clear bag
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        }
      } else {
        print(
          'Failed to submit rating. Status: ${response.statusCode}, Body: ${response.body}',
        ); // Added logging
        throw Exception(
          'فشل في إرسال التقييم: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'خطأ: ${e.toString()}'; // Default error
        // Check if the exception message from the backend contains the specific error
        if (e.toString().contains('No delivery boy assigned to this order') ||
            (e is Exception &&
                e.toString().contains(
                  '{"error":"No delivery boy assigned to this order."}',
                ))) {
          errorMessage =
              'لا يمكن تقييم هذا الطلب لأنه لا يوجد مندوب توصيل معين له حاليًا.';
        } else if (e.toString().contains('فشل في إرسال التقييم')) {
          // Try to extract a more specific message if available from the backend response
          RegExp regExp = RegExp(r'Body: ({.*?})');
          Match? match = regExp.firstMatch(e.toString());
          if (match != null && match.groupCount > 0) {
            try {
              var jsonError = jsonDecode(match.group(1)!);
              if (jsonError['error'] != null) {
                errorMessage = 'فشل في إرسال التقييم: ${jsonError['error']}';
              }
            } catch (jsonErr) {
              // Fallback to the generic part of the message if JSON parsing fails
              errorMessage = e.toString().substring(
                e.toString().indexOf('فشل في إرسال التقييم'),
              );
            }
          } else {
            errorMessage = e.toString().substring(
              e.toString().indexOf('فشل في إرسال التقييم'),
            );
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final newBalance = (widget.totalPoints / 20).floor();
    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;
    final screenWidth = size.width;
    final isSmallScreen = screenHeight < 700;
    final borderRadius = screenWidth * 0.08;

    return WillPopScope(
      onWillPop: () async {
        // Save state and exit app
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(SharedKeys.shouldResumeToRewardingScreen, true);
        await prefs.setInt(
          SharedKeys.rewardingScreenTotalPoints,
          widget.totalPoints,
        );
        if (_assignmentId != null) {
          await prefs.setInt(
            SharedKeys.rewardingScreenAssignmentId,
            _assignmentId!,
          );
        } else {
          // If _assignmentId is somehow still null, try to get it from widget or last known
          final lastKnownId =
              widget.assignmentId ?? prefs.getInt(SharedKeys.lastAssignmentId);
          if (lastKnownId != null) {
            await prefs.setInt(
              SharedKeys.rewardingScreenAssignmentId,
              lastKnownId,
            );
          } else {
            print(
              'Error: Could not save assignmentId for resume as it is null.',
            );
            // Optionally, don't set the resume flag if critical info is missing
            // await prefs.setBool(SharedKeys.shouldResumeToRewardingScreen, false);
          }
        }
        SystemNavigator.pop(); // Exits the app
        return false; // Prevents default back navigation
      },
      child: Scaffold(
        backgroundColor: AppTheme.light.colorScheme.primary,
        body: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: SizedBox(
            height: screenHeight,
            child: Stack(
              children: [
                Column(
                  children: [
                    SizedBox(height: screenHeight * 0.08),
                    SizedBox(
                      height: screenHeight * 0.2,
                      child: Image.asset(
                        'assets/icons/recycle.png',
                        width: screenWidth * 0.4,
                        height: screenHeight * 0.15,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.only(top: screenHeight * 0.08),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(borderRadius * 0.7),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, -1),
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.08,
                            vertical: screenHeight * 0.02,
                          ),
                          child: Column(
                            children: [
                              SizedBox(height: screenHeight * 0.02),
                              CircleAvatar(
                                radius: screenWidth * 0.04,
                                backgroundColor: Colors.green.withOpacity(0.1),
                                child: Icon(
                                  Icons.recycling,
                                  color: const Color(0xFF2E8B57),
                                  size: screenWidth * 0.04,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.015),
                              Text(
                                'Thank you for recycling!',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.light.colorScheme.primary,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              Text(
                                'You have earned points for your contribution',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 11 : 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.015),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.06,
                                  vertical: screenHeight * 0.02,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                    borderRadius * 0.4,
                                  ),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF2E8B57,
                                    ).withOpacity(0.1),
                                    width: 0.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Text(
                                            '${widget.totalPoints}',
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 18 : 22,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF2E8B57),
                                            ),
                                          ),
                                          Text(
                                            'Points',
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 10 : 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      margin: EdgeInsets.symmetric(
                                        horizontal: screenWidth * 0.04,
                                      ),
                                      width: 1,
                                      height: screenHeight * 0.02,
                                      color: const Color(
                                        0xFF2E8B57,
                                      ).withOpacity(0.1),
                                    ),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Text(
                                            '$newBalance',
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 18 : 22,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF2E8B57),
                                            ),
                                          ),
                                          Text(
                                            'EGP',
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 10 : 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.025),
                              Text(
                                'Rate Your Experience',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.010),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(5, (index) {
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _rating = index + 1.0;
                                      });
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.all(
                                        screenWidth * 0.01,
                                      ),
                                      child: Icon(
                                        index < _rating
                                            ? Icons.star_rounded
                                            : Icons.star_border_rounded,
                                        color: Colors.amber,
                                        size: isSmallScreen ? 24 : 28,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              TextField(
                                controller: _commentController,
                                maxLines: 3,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 13 : 15,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'أضف تعليقك (اختياري)',
                                  hintStyle: TextStyle(
                                    fontSize: isSmallScreen ? 13 : 15,
                                    color: Colors.grey[400],
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.04,
                                    vertical: screenHeight * 0.015,
                                  ),
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      borderRadius * 0.3,
                                    ),
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                      width: 1,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      borderRadius * 0.3,
                                    ),
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      borderRadius * 0.3,
                                    ),
                                    borderSide: BorderSide(
                                      color: AppTheme.light.colorScheme.primary,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              SizedBox(
                                height: screenHeight * 0.055,
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _submitRating,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        AppTheme.light.colorScheme.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        borderRadius * 0.4,
                                      ),
                                    ),
                                    elevation: 0,
                                  ),
                                  child:
                                      _isLoading
                                          ? SizedBox(
                                            height: screenHeight * 0.025,
                                            width: screenHeight * 0.025,
                                            child:
                                                const CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                          )
                                          : Text(
                                            'Submit',
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 14 : 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
