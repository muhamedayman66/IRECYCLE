import 'package:flutter/material.dart';
import 'package:graduation_project11/core/api/api_constants.dart';
import 'package:graduation_project11/core/themes/app__theme.dart';
import 'package:graduation_project11/features/auth/sign_in/presentation/screen/sign_in_screen.dart';
import 'package:graduation_project11/features/auth/sign_up/presentation/screen/sign_up_screen3.dart';
import 'package:graduation_project11/features/auth/sign_up/presentation/widget/arrow_in_circle.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SignUpScreen2 extends StatefulWidget {
  final String email;
  final String userType;

  const SignUpScreen2({Key? key, required this.email, required this.userType})
    : super(key: key);

  @override
  State<SignUpScreen2> createState() => _SignUpScreen2State();
}

class _SignUpScreen2State extends State<SignUpScreen2> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController governorateController = TextEditingController();
  final TextEditingController displayGovernorateController = TextEditingController();

  String? selectedYear, selectedMonth, selectedDay;
  String? _selectedDate;
  bool _hasError = false;
  bool _dobError = false;

  // إضافة governorateMap كمتغير في الكلاس
  final Map<String, String> governorateMap = {
    'Alexandria': 'alexandria',
    'Aswan': 'aswan',
    'Asyut': 'asyut',
    'Beheira': 'beheira',
    'Beni Suef': 'beni_suef',
    'Cairo': 'cairo',
    'Dakahlia': 'dakahlia',
    'Damietta': 'damietta',
    'Faiyum': 'faiyum',
    'Gharbia': 'gharbia',
    'Giza': 'giza',
    'Ismailia': 'ismailia',
    'Kafr El Sheikh': 'kafr_el_sheikh',
    'Luxor': 'luxor',
    'Matruh': 'matruh',
    'Minya': 'minya',
    'Monufia': 'monufia',
    'New Valley': 'new_valley',
    'North Sinai': 'north_sinai',
    'Port Said': 'port_said',
    'Qalyubia': 'qalyubia',
    'Qena': 'qena',
    'Red Sea': 'red_sea',
    'Sharqia': 'sharqia',
    'Sohag': 'sohag',
    'South Sinai': 'south_sinai',
    'Suez': 'suez',
  };

  final List<String> governorates = [
    'Alexandria',
    'Aswan',
    'Asyut',
    'Beheira',
    'Beni Suef',
    'Cairo',
    'Dakahlia',
    'Damietta',
    'Faiyum',
    'Gharbia',
    'Giza',
    'Ismailia',
    'Kafr El Sheikh',
    'Luxor',
    'Matruh',
    'Minya',
    'Monufia',
    'New Valley',
    'North Sinai',
    'Port Said',
    'Qalyubia',
    'Qena',
    'Red Sea',
    'Sharqia',
    'Sohag',
    'South Sinai',
    'Suez',
  ];

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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User not found')));
            Navigator.pop(context); // Return to previous screen
          }
          return;
        }

        final int id = user['id'];

        final int? year = int.tryParse(selectedYear ?? '');
        final int? day = int.tryParse(selectedDay ?? '');
        final int? month =
            selectedMonth != null
                ? [
                      'January',
                      'February',
                      'March',
                      'April',
                      'May',
                      'June',
                      'July',
                      'August',
                      'September',
                      'October',
                      'November',
                      'December',
                    ].indexOf(selectedMonth!) +
                    1
                : null;

        String formattedDate = "";
        if (year != null && month != null && day != null) {
          final DateTime date = DateTime(year, month, day);
          if (date.isAfter(DateTime.now())) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Date of birth cannot be in the future'),
                ),
              );
            }
            return;
          }
          formattedDate = date.toIso8601String().split('T')[0];
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select a valid date of birth'),
              ),
            );
          }
          return;
        }

        final updatedUserData = {
          'first_name': user['first_name'],
          'last_name': user['last_name'],
          'gender': user['gender'],
          'governorate':
              governorateController
                  .text, // القيمة المخزنة بالفعل في الـ controller
          'type': user['type'],
          'birth_date': formattedDate,
          'phone_number': _phoneNumberController.text,
          'email': user['email'],
          'password': user['password'],
        };

        final updateEndpoint =
            widget.userType.toLowerCase() == 'customer'
                ? ApiConstants.registerUpdate(id)
                : '${ApiConstants.baseUrl}/delivery_boys/$id/update/';

        final updateResponse = await http.put(
          Uri.parse(updateEndpoint),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(updatedUserData),
        );

        if (updateResponse.statusCode == 200) {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => SignUpScreen3(
                      email: widget.email,
                      userType: widget.userType,
                    ),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to update profile: ${updateResponse.body}',
                ),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to fetch user data')),
          );
        }
      }
    } catch (e) {
      print('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred while updating profile'),
          ),
        );
      }
    }
  }

  void _selectGovernorate() {
    TextEditingController searchController = TextEditingController();
    List<String> filteredGovernorates = List.from(governorates);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
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
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "Search for a governorate",
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.search),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(
                          color: AppTheme.light.colorScheme.primary,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(
                          color: AppTheme.light.colorScheme.primary,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        filteredGovernorates = governorates
                            .where((gov) =>
                                gov.toLowerCase().contains(value.toLowerCase()))
                            .toList();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: ListView.builder(
                      itemCount: filteredGovernorates.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppTheme.light.colorScheme.primary,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: ListTile(
                              leading: Icon(
                                Icons.location_city,
                                color: AppTheme.light.colorScheme.primary,
                              ),
                              title: Text(
                                filteredGovernorates[index],
                                style: const TextStyle(color: Colors.black),
                              ),
                              onTap: () {
                                setState(() {
                                  // تخزين القيمة في الباك إند
                                  governorateController.text =
                                      governorateMap[filteredGovernorates[index]] ??
                                      filteredGovernorates[index]
                                          .toLowerCase()
                                          .replaceAll(' ', '_');
                                  
                                  // عرض الاسم للمستخدم بأول حرف كبير
                                  displayGovernorateController.text = filteredGovernorates[index]
                                      .split(' ')
                                      .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
                                      .join(' ');
                                });
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.light.colorScheme.primary,
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Stack(
                  children: [
                    Positioned(
                      top: 40,
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
                                const SizedBox(height: 20),
                                buildTextField(
                                  label: 'Phone Number',
                                  controller: _phoneNumberController,
                                  hint: 'Enter Phone Number',
                                  keyboardType: TextInputType.phone,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'This field is required';
                                    }
                                    if (value.length < 11) {
                                      return 'Phone number must be 11 digits';
                                    }
                                    String phonePattern = r'^01[0125][0-9]{8}$';
                                    if (!RegExp(phonePattern).hasMatch(value)) {
                                      return 'Please enter a valid Egyptian phone number';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 30),
                                buildDatePickerField(
                                  label: 'Date Of Birth',
                                  hint: 'Enter Date of birth',
                                  value: _selectedDate,
                                  onTap: () => _showDatePicker(context),
                                ),
                                const SizedBox(height: 30),
                                buildSelectableFormField(
                                  label: 'Governorate',
                                  hintText: 'Select your governorate',
                                  controller: governorateController,
                                  onTap: _selectGovernorate,
                                  validator:
                                      (value) =>
                                          value == null || value.isEmpty
                                              ? 'This field is required'
                                              : null,
                                ),
                                const SizedBox(height: 90),
                                ArrowInCircle(
                                  progress: 0.5,
                                  progressColor:
                                      _hasError || _dobError
                                          ? Colors.red
                                          : Colors.green,
                                  onTap: () {
                                    setState(() {
                                      _hasError =
                                          !_formKey.currentState!.validate();
                                      _dobError =
                                          _selectedDate == null ||
                                          _selectedDate!.isEmpty;
                                    });

                                    if (!_hasError && !_dobError) {
                                      update();
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

  Widget buildDatePickerField({
    required String label,
    required String hint,
    required VoidCallback onTap,
    String? value,
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
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 15),
            decoration: BoxDecoration(
              border: Border.all(
                color:
                    _dobError ? Colors.red : AppTheme.light.colorScheme.primary,
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              value ?? hint,
              style: TextStyle(
                color: value == null ? Colors.grey : Colors.black,
                fontSize: 16,
              ),
            ),
          ),
        ),
        if (_dobError)
          const Padding(
            padding: EdgeInsets.only(top: 8, left: 12),
            child: Text(
              'This field is required',
              style: TextStyle(color: Colors.red, fontSize: 12),
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
          controller: controller == governorateController ? displayGovernorateController : controller,
          readOnly: true,
          onTap: onTap,
          validator: validator,
          style: const TextStyle(color: Colors.black),
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

  void _showDatePicker(BuildContext context) {
    List<int> years = List.generate(2030 - 1980 + 1, (i) => 1980 + i);
    List<String> months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    List<int> days = List.generate(31, (i) => i + 1);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 400,
                child: Column(
                  children: [
                    Center(
                      child: Text(
                        "Select Date",
                        style: TextStyle(
                          fontSize: 20,
                          color: AppTheme.light.colorScheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Row(
                        children: [
                          buildDateColumn(
                            years.map((e) => e.toString()).toList(),
                            (val) {
                              setModalState(() => selectedYear = val);
                            },
                            selectedValue: selectedYear,
                          ),
                          buildDateColumn(months, (val) {
                            setModalState(() => selectedMonth = val);
                          }, selectedValue: selectedMonth),
                          buildDateColumn(
                            days.map((e) => e.toString()).toList(),
                            (val) {
                              setModalState(() => selectedDay = val);
                            },
                            selectedValue: selectedDay,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        if (selectedYear != null &&
                            selectedMonth != null &&
                            selectedDay != null) {
                          setState(() {
                            _selectedDate =
                                "$selectedDay $selectedMonth $selectedYear";
                          });
                          Navigator.pop(context);
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Text(
                          "Add",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget buildDateColumn(
    List<String> items,
    Function(String) onSelected, {
    String? selectedValue,
  }) {
    return Expanded(
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (_, index) {
          final isSelected = items[index] == selectedValue;
          return GestureDetector(
            onTap: () {
              onSelected(items[index]);
            },
            child: Container(
              alignment: Alignment.center,
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.green[800] : Colors.green[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                items[index],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
