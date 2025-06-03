import 'package:flutter/material.dart';
import 'package:graduation_project11/core/themes/app__theme.dart';
import 'package:graduation_project11/core/widgets/custom_appbar.dart';
import 'package:graduation_project11/features/delivery%20boy/profile/data/services/profile_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class DeliveryEditProfileScreen extends StatefulWidget {
  final String? email;
  const DeliveryEditProfileScreen({super.key, this.email});

  @override
  _DeliveryEditProfileScreenState createState() =>
      _DeliveryEditProfileScreenState();
}

class _DeliveryEditProfileScreenState extends State<DeliveryEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController genderController = TextEditingController();
  TextEditingController dobController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController governorateController = TextEditingController();
  TextEditingController phoneController = TextEditingController();

  File? _profileImage;
  String? _profileImageUrl;
  bool _isLoading = false;
  bool _hasError = false;
  bool _dobError = false;

  String? selectedYear, selectedMonth, selectedDay;

  final List<Map<String, String>> governorates = [
    {'value': 'alexandria', 'display': 'Alexandria'},
    {'value': 'aswan', 'display': 'Aswan'},
    {'value': 'asyut', 'display': 'Asyut'},
    {'value': 'beheira', 'display': 'Beheira'},
    {'value': 'beni_suef', 'display': 'Beni Suef'},
    {'value': 'cairo', 'display': 'Cairo'},
    {'value': 'dakahlia', 'display': 'Dakahlia'},
    {'value': 'damietta', 'display': 'Damietta'},
    {'value': 'faiyum', 'display': 'Faiyum'},
    {'value': 'gharbia', 'display': 'Gharbia'},
    {'value': 'giza', 'display': 'Giza'},
    {'value': 'ismailia', 'display': 'Ismailia'},
    {'value': 'kafr_el_sheikh', 'display': 'Kafr El Sheikh'},
    {'value': 'luxor', 'display': 'Luxor'},
    {'value': 'matruh', 'display': 'Matruh'},
    {'value': 'minya', 'display': 'Minya'},
    {'value': 'monufia', 'display': 'Monufia'},
    {'value': 'new_valley', 'display': 'New Valley'},
    {'value': 'north_sinai', 'display': 'North Sinai'},
    {'value': 'port_said', 'display': 'Port Said'},
    {'value': 'qalyubia', 'display': 'Qalyubia'},
    {'value': 'qena', 'display': 'Qena'},
    {'value': 'red_sea', 'display': 'Red Sea'},
    {'value': 'sharqia', 'display': 'Sharqia'},
    {'value': 'sohag', 'display': 'Sohag'},
    {'value': 'south_sinai', 'display': 'South Sinai'},
    {'value': 'suez', 'display': 'Suez'},
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    if (widget.email == null) return;

    try {
      setState(() => _isLoading = true);
      final profileData = await DeliveryProfileService.getProfile(
        widget.email!,
      );

      setState(() {
        firstNameController.text = profileData['first_name'] ?? '';
        lastNameController.text = profileData['last_name'] ?? '';
        genderController.text = profileData['gender'] ?? '';
        dobController.text = profileData['dob'] ?? '';
        emailController.text = widget.email!;
        phoneController.text = profileData['phone'] ?? '';
        _profileImageUrl = profileData['profile_image'];
        final governorateValue =
            profileData['governorate']?.toString().toLowerCase() ?? '';
        final governorate = governorates.firstWhere(
          (g) => g['value'] == governorateValue,
          orElse: () => {'value': '', 'display': ''},
        );
        governorateController.text = governorate['display'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
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

  void _selectGovernorate() {
    TextEditingController searchController = TextEditingController();
    List<Map<String, String>> filteredGovernorates = List.from(governorates);

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
                        filteredGovernorates =
                            governorates
                                .where(
                                  (g) => g['display']!.toLowerCase().contains(
                                    value.toLowerCase(),
                                  ),
                                )
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
                          child: buildOptionItem(
                            text: filteredGovernorates[index]['display']!,
                            icon: Icon(
                              Icons.location_city,
                              color: AppTheme.light.colorScheme.primary,
                            ),
                            onTap: () {
                              setState(() {
                                governorateController.text =
                                    filteredGovernorates[index]['display']!;
                              });
                              Navigator.pop(context);
                            },
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

  void _showDatePicker(BuildContext context) {
    List<int> years = List.generate(2030 - 1980 + 1, (i) => 1980 + i);
    List<String> months = [
      '01',
      '02',
      '03',
      '04',
      '05',
      '06',
      '07',
      '08',
      '09',
      '10',
      '11',
      '12',
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
                            days
                                .map((e) => e.toString().padLeft(2, '0'))
                                .toList(),
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
                            dobController.text =
                                "$selectedYear-$selectedMonth-$selectedDay";
                            _dobError = false;
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

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final governorateDisplay = governorateController.text;
      final governorate = governorates.firstWhere(
        (g) => g['display'] == governorateDisplay,
        orElse: () => {'value': '', 'display': ''},
      );

      final success = await DeliveryProfileService.updateProfile(
        email: widget.email!,
        firstName: firstNameController.text,
        lastName: lastNameController.text,
        gender: genderController.text,
        dob: dobController.text,
        governorate: governorate['value'] ?? '',
        phone: phoneController.text,
        profileImage: _profileImage,
      );

      setState(() => _isLoading = false);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_outlined,
            color: AppTheme.light.colorScheme.secondary,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: 'Edit Profile',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage:
                          _profileImage != null
                              ? FileImage(_profileImage!) as ImageProvider
                              : (_profileImageUrl != null &&
                                      _profileImageUrl!.isNotEmpty
                                  ? NetworkImage(_profileImageUrl!)
                                  : null),
                      backgroundColor: Colors.grey[300],
                      child:
                          _profileImage == null &&
                                  (_profileImageUrl == null ||
                                      _profileImageUrl!.isEmpty)
                              ? Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.grey[600],
                              )
                              : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 15,
                          backgroundColor: AppTheme.light.colorScheme.primary,
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: buildTextField(
                      label: 'First Name',
                      controller: firstNameController,
                      hint: 'Enter your first name',
                      validator:
                          (value) =>
                              value!.isEmpty ? 'This field is required' : null,
                    ),
                  ),
                  const SizedBox(width: 40),
                  Expanded(
                    child: buildTextField(
                      label: 'Last Name',
                      controller: lastNameController,
                      hint: 'Enter your last name',
                      validator:
                          (value) =>
                              value!.isEmpty ? 'This field is required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              buildSelectableFormField(
                label: 'Gender',
                hintText: 'Select your gender',
                controller: genderController,
                onTap: _selectGender,
              ),
              const SizedBox(height: 20),
              buildSelectableFormField(
                label: 'Date Of Birth',
                hintText: 'Select your date of birth',
                controller: dobController,
                onTap: () => _showDatePicker(context),
              ),
              const SizedBox(height: 20),
              buildSelectableFormField(
                label: 'Governorate',
                hintText: 'Select your governorate',
                controller: governorateController,
                onTap: _selectGovernorate,
              ),
              const SizedBox(height: 20),
              buildTextField(
                label: 'Phone Number',
                controller: phoneController,
                hint: 'Enter your phone number',
                validator: (value) {
                  if (value!.isEmpty) return 'This field is required';
                  if (value.length < 11) return 'Phone Number Is Not Valid';
                  String phonePattern = r'^01[0125][0-9]{8}$';
                  if (!RegExp(phonePattern).hasMatch(value)) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? CircularProgressIndicator(
                    color: AppTheme.light.colorScheme.primary,
                  )
                  : ElevatedButton(
                    onPressed: _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.light.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 30,
                      ),
                    ),
                    child: Text(
                      'Update Profile',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.light.colorScheme.secondary,
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.light.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: AppTheme.light.colorScheme.primary),
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
    bool readOnly = true,
    bool showCursor = false,
    bool enableInteractiveSelection = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.light.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          showCursor: showCursor,
          enableInteractiveSelection: enableInteractiveSelection,
          onTap: onTap,
          validator:
              (value) =>
                  value == null || value.isEmpty
                      ? 'This field is required'
                      : null,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.grey),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
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
