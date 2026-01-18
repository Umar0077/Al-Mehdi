import 'package:al_mehdi_online_school/components/custom_button.dart';
import 'package:al_mehdi_online_school/components/custom_textfield.dart';
import 'package:al_mehdi_online_school/constants/colors.dart';
import 'package:al_mehdi_online_school/constants/countries.dart';
import 'package:al_mehdi_online_school/models/teacher_data.dart';
import 'package:al_mehdi_online_school/providers/auth/auth_provider.dart';
import 'package:al_mehdi_online_school/services/location_service.dart';
import 'package:al_mehdi_online_school/views/admin_dashboard/unassigned_users_view/wait_for_assignment_view.dart';
import 'package:al_mehdi_online_school/views/teachers/teacher_home_screen/teacher_home_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TeachersRegistration extends StatefulWidget {
  final String? uid;
  final String? email;
  final String? role;
  final String? fullName;
  final String? password;
  const TeachersRegistration({
    super.key,
    this.uid,
    this.email,
    this.role,
    this.fullName,
    this.password,
  });

  @override
  State<TeachersRegistration> createState() => _TeachersRegistrationState();
}

class _TeachersRegistrationState extends State<TeachersRegistration> {
  String? selectedCountry;
  String? selectedDegree;
  PlatformFile? degreeFile;
  double? _cachedResponsiveWidth; // Cache responsive width calculation

  final _fullNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _degreeController = TextEditingController();

  // OAuth detection
  bool _isOAuthUser = false;
  String _signupMethod = 'manual'; // 'manual', 'google', or 'apple'
  String _oauthEmail = '';
  bool _isLoadingOAuthData = true;

  Future<void> _openCountrySearch() async {
    final controller = TextEditingController();
    String? result = await showDialog<String>(
      context: context,
      builder: (context) {
        List<String> filtered = List.from(CountryConstants.countries);
        return StatefulBuilder(
          builder: (context, setState) {
            // Get available height considering keyboard
            final availableHeight =
                MediaQuery.of(context).size.height -
                MediaQuery.of(context).viewInsets.bottom;

            return Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                  constraints: BoxConstraints(
                    maxHeight: availableHeight * 0.7,
                    maxWidth: 400,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).dialogBackgroundColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          controller: controller,
                          autofocus: true,
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.search,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                            hintText: 'Search country',
                            hintStyle: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white54
                                  : Colors.black45,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white30
                                    : Colors.black26,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white30
                                    : Colors.black26,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: appGreen,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onChanged: (val) {
                            setState(() {
                              filtered =
                                  CountryConstants.countries
                                      .where(
                                        (c) => c.toLowerCase().contains(
                                          val.toLowerCase(),
                                        ),
                                      )
                                      .toList();
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final c = filtered[index];
                            return ListTile(
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              title: Text(
                                c,
                                style: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                              hoverColor: appLightGreen,
                              onTap: () => Navigator.pop(context, c),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    if (result != null) {
      setState(() => selectedCountry = result);
    }
  }

  final List<String> degrees = [
    'Bachelor',
    'Master',
    'PhD',
    'Diploma',
    'Associate',
  ];

  double _getResponsiveWidth(double screenWidth) {
    // Cache the calculation to avoid repeated computation
    if (_cachedResponsiveWidth != null) return _cachedResponsiveWidth!;

    if (screenWidth >= 800) {
      _cachedResponsiveWidth = 400;
    } else if (screenWidth >= 600) {
      _cachedResponsiveWidth = 350;
    } else {
      _cachedResponsiveWidth = screenWidth * 0.9;
    }
    return _cachedResponsiveWidth!;
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null) {
      setState(() {
        degreeFile = result.files.first;
      });
    }
  }

  Future<void> _submitRegistration(AuthProvider authProvider) async {
    // Validate all required fields
    if (_fullNameController.text.isEmpty ||
        _phoneNumberController.text.isEmpty ||
        selectedCountry == null ||
        selectedDegree == null ||
        degreeFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "All fields including full name, phone number, and document are required",
          ),
        ),
      );
      return;
    }

    // Validate email
    final email = _isOAuthUser ? _oauthEmail : widget.email;
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email is required'),
        ),
      );
      return;
    }

    // Create teacher data model
    final teacherData = TeacherData(
      fullName: _fullNameController.text.trim(),
      phoneNumber: _phoneNumberController.text.trim(),
      country: selectedCountry!,
      degree: selectedDegree!,
      degreeFile: degreeFile!,
    );

    bool success;

    // Register with email/password or social login
    if (widget.password != null) {
      // Email/password registration
      success = await authProvider.registerTeacher(
        email: email,
        password: widget.password!,
        teacherData: teacherData,
      );
    } else {
      // Google/Apple registration
      success = await authProvider.registerTeacherWithSocial(
        teacherData: teacherData,
      );
    }

    if (!mounted) return;

    if (!success) {
      // Show error message from provider
      if (authProvider.state.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.state.errorMessage!)),
        );
      }
      return;
    }

    // Check assignment and navigate
    final user = authProvider.state.user;
    if (user != null) {
      final assignedStudentId = await authProvider.getTeacherAssignedStudentId(
        user.uid,
      );

      if (!mounted) return;

      if (assignedStudentId == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const WaitForAssignmentView(role: 'Teacher'),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TeacherHomeScreen()),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Check if this is OAuth signup (no password means OAuth)
    if (widget.password == null && widget.email != null) {
      _isOAuthUser = true;
      _oauthEmail = widget.email!;
      
      // Determine signup method
      if (widget.email!.contains('privaterelay.appleid.com')) {
        _signupMethod = 'apple';
      } else {
        _signupMethod = 'google';
      }
      
      // Pre-fill name if provided
      if (widget.fullName != null && widget.fullName!.isNotEmpty) {
        _fullNameController.text = widget.fullName!;
      }
    }
    _isLoadingOAuthData = false;
    
    // Auto-detect country from IP
    _autoDetectCountry();
  }

  /// Auto-detect user's country from their IP address
  Future<void> _autoDetectCountry() async {
    final country = await LocationService.getCountryFromIP();
    if (country != null && mounted) {
      // Check if the detected country exists in our country list
      if (CountryConstants.countries.contains(country)) {
        setState(() {
          selectedCountry = country;
        });
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color dropdownColor =
        Theme.of(context).brightness == Brightness.dark
            ? darkBackground
            : appLightGreen;

    double screenWidth = MediaQuery.of(context).size.width;
    double responsiveWidth = _getResponsiveWidth(screenWidth);

    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
            ),
            resizeToAvoidBottomInset: true, // Optimize keyboard handling
            body: Stack(
              children: [
                SingleChildScrollView(
                  physics: const ClampingScrollPhysics(), // Better performance
                  padding: const EdgeInsets.fromLTRB(0, 20, 0, 40),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: responsiveWidth,
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.center,
                            child: Text(
                              'Teachers Registration',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: responsiveWidth,
                          child: const Text(
                            'Please fill in the details below to register as a teacher.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Show loading indicator while fetching OAuth data
                        if (_isLoadingOAuthData)
                          SizedBox(
                            width: responsiveWidth,
                            child: const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          ),
                        // Show info banner for OAuth users
                        if (_isOAuthUser && !_isLoadingOAuthData)
                          Container(
                            width: responsiveWidth,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: appGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: appGreen, width: 1),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _signupMethod == 'apple'
                                      ? Icons.apple
                                      : Icons.g_mobiledata,
                                  color: appGreen,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _signupMethod == 'apple'
                                        ? 'Name and email auto-filled from Apple Sign In'
                                        : 'Name and email auto-filled from Google Sign In',
                                    style: const TextStyle(
                                      color: appGreen,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Full Name
                        CustomTextfield(
                          labelText: 'Full Name',
                          width: responsiveWidth,
                          controller: _fullNameController,
                          keyboardType: TextInputType.name,
                          textInputAction: TextInputAction.next,
                          enabled: !_isOAuthUser, // Disable for OAuth users
                        ),
                        const SizedBox(height: 16),
                        // Show locked email field for OAuth users
                        if (_isOAuthUser && _oauthEmail.isNotEmpty)
                          Container(
                            width: responsiveWidth,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color.fromARGB(255, 206, 206, 206),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Email',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _oauthEmail,
                                        style: const TextStyle(
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.lock,
                                  color: Colors.grey[400],
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 24),
                        CustomTextfield(
                          labelText: 'Phone Number',
                          width: responsiveWidth,
                          controller: _phoneNumberController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),
                        CustomTextfield(
                          labelText: 'Degree title',
                          width: responsiveWidth,
                          controller: _degreeController,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),

                        // Country with search
                        SizedBox(
                          width: responsiveWidth,
                          child: TextField(
                            readOnly: true,
                            onTap: _openCountrySearch,
                            cursorColor: appGreen,
                            decoration: InputDecoration(
                              labelText: 'Country',
                              hintText: 'Tap to search and select',
                              suffixIcon: const Icon(Icons.search),
                              floatingLabelStyle: const TextStyle(
                                color: appGreen,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color.fromARGB(255, 206, 206, 206),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color.fromARGB(255, 206, 206, 206),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: appGreen),
                              ),
                            ),
                            controller: TextEditingController(
                              text: selectedCountry ?? '',
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Degree dropdown
                        Container(
                          width: responsiveWidth,
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButton<String>(
                            underline: const SizedBox.shrink(),
                            value: selectedDegree,
                            hint: const Text('Select your degree'),
                            onChanged:
                                (value) =>
                                    setState(() => selectedDegree = value),
                            items:
                                degrees
                                    .map(
                                      (d) => DropdownMenuItem(
                                        value: d,
                                        child: Text(d),
                                      ),
                                    )
                                    .toList(),
                            isExpanded: true,
                            dropdownColor: dropdownColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Upload document
                        SizedBox(
                          width: responsiveWidth,
                          child: OutlinedButton.icon(
                            onPressed: _pickDocument,
                            icon: const Icon(
                              Icons.upload_file,
                              color: Color(0xff02D185),
                            ),
                            label: Text(
                              degreeFile != null
                                  ? degreeFile!.name
                                  : 'Upload Degree Document',
                              style: const TextStyle(color: Color(0xff02D185)),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xff02D185)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Submit button
                        SizedBox(
                          width: responsiveWidth,
                          height: 45,
                          child: CustomButton(
                            text: 'Register',
                            onPressed: () => _submitRegistration(authProvider),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (authProvider.state.isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
