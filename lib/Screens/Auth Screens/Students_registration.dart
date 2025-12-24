import 'package:al_mehdi_online_school/Screens/AdminDashboard/Unassigned%20Users%20Screens/wait_for_assignment_screen.dart';
import 'package:al_mehdi_online_school/components/Custom_Textfield.dart';
import 'package:flutter/material.dart';
import 'package:al_mehdi_online_school/constants/colors.dart';
import 'package:al_mehdi_online_school/components/Custom_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:al_mehdi_online_school/constants/countries.dart';
// colors import removed: not used here
import '../../students/student_home_screen/student_home_screen.dart';
import '../../services/notification_service.dart';

class StudentsRegistration extends StatefulWidget {
  final String? uid;
  final String? email;
  final String? role;
  final String? fullName;
  final String? password;
  const StudentsRegistration({
    super.key,
    this.uid,
    this.email,
    this.role,
    this.fullName,
    this.password,
  });

  @override
  State<StudentsRegistration> createState() => _StudentsRegistrationState();
}

class _StudentsRegistrationState extends State<StudentsRegistration> {
  String? selectedCountry;
  final _fullNameController = TextEditingController();
  final _gradeController = TextEditingController();
  final _subjectController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  bool _isLoading = false;
  double? _cachedResponsiveWidth; // Cache responsive width calculation

  Future<void> _openCountrySearch() async {
    final controller = TextEditingController();
    String? result = await showDialog<String>(
      context: context,
      builder: (context) {
        List<String> filtered = List.from(CountryConstants.countries);
        return StatefulBuilder(builder: (context, setState) {
          // Get available height considering keyboard
          final availableHeight = MediaQuery.of(context).size.height -
              MediaQuery.of(context).viewInsets.bottom;

          return Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
                        // Performance optimizations
                        autocorrect: false,
                        enableSuggestions: false,
                        smartDashesType: SmartDashesType.disabled,
                        smartQuotesType: SmartQuotesType.disabled,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Search country',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {
                            filtered = CountryConstants.countries
                                .where((c) => c.toLowerCase().contains(val.toLowerCase()))
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
                            title: Text(c),
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
        });
      },
    );
    if (result != null) {
      setState(() => selectedCountry = result);
    }
  }

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

  Future<void> _submitStudentData() async {
    if (_fullNameController.text.isEmpty ||
        selectedCountry == null ||
        _gradeController.text.isEmpty ||
        _subjectController.text.isEmpty ||
        _phoneNumberController.text.isEmpty ||
        (widget.email == null || widget.email!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'All fields including full name, phone number, and email are required',
          ),
        ),
      );
      return;
    }
    setState(() {
      _isLoading = true; // Show loader
    });
    try {
      String? uid;
      String? email;
      if (widget.password != null) {
        // Email/password registration
        final password = widget.password!;
        final userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: widget.email!,
              password: password,
            );
        final user = userCredential.user;
        if (user == null) throw Exception("User not created");
        uid = user.uid;
        email = user.email;
      } else {
        // Google registration: user is already signed in
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception("User not authenticated");
        uid = user.uid;
        email = user.email;
      }
      final studentData = {
        'uid': uid,
        'email': email,
        'fullName': _fullNameController.text.trim(),
        'country': selectedCountry,
        'grade': _gradeController.text.trim(),
        'favouriteSubject': _subjectController.text.trim(),
        'phoneNumber': _phoneNumberController.text.trim(),
        'role': 'Student',
        'assignedTeacherId': null,
        'createdAt': FieldValue.serverTimestamp(),
      };
      await FirebaseFirestore.instance
          .collection('students')
          .doc(uid)
          .set(studentData);
      await FirebaseFirestore.instance
          .collection('unassigned_students')
          .doc(uid)
          .set({
            'uid': uid,
            'email': email,
            'fullName': _fullNameController.text.trim(),
            'country': selectedCountry,
            'grade': _gradeController.text.trim(),
            'favouriteSubject': _subjectController.text.trim(),
            'phoneNumber': _phoneNumberController.text.trim(),
            'role': 'Student',
            'assigned': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
      await NotificationService.sendNewUserRegisteredNotificationToAdmin(
        newUserId: uid,
        newUserName: _fullNameController.text.trim(),
        newUserRole: 'student',
      );
      await NotificationService.initialize();
      final doc =
          await FirebaseFirestore.instance
              .collection('students')
              .doc(uid)
              .get();
      final assignedTeacherId = doc.data()?['assignedTeacherId'];
      if (assignedTeacherId == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => const WaitForAssignmentScreen(role: 'Student'),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const StudentHomeScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ' + e.toString())));
    } finally {
      setState(() {
        _isLoading = false; // Hide loader
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.fullName != null) _fullNameController.text = widget.fullName!;
    // You can prefill other fields if needed
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _gradeController.dispose();
    _subjectController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Cache responsive width to avoid recalculating on every build
    double screenWidth = MediaQuery.of(context).size.width;
    double responsiveWidth = _getResponsiveWidth(screenWidth);

    return Scaffold(
      appBar: AppBar(elevation: 0, surfaceTintColor: Colors.transparent),
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
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: const Text(
                        'Students Registration',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: responsiveWidth,
                    child: const Text(
                      'Please fill in the details below to register as a student.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomTextfield(
                    labelText: 'Full Name',
                    width: responsiveWidth,
                    controller: _fullNameController,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 24),
                  CustomTextfield(
                    labelText: 'Phone Number',
                    width: responsiveWidth,
                    controller: _phoneNumberController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: responsiveWidth,
                    child: TextField(
                      readOnly: true,
                      onTap: _openCountrySearch,
                      cursorColor: appGreen,
                      // Performance optimizations
                      autocorrect: false,
                      enableSuggestions: false,
                      smartDashesType: SmartDashesType.disabled,
                      smartQuotesType: SmartQuotesType.disabled,
                      decoration: InputDecoration(
                        labelText: 'Country',
                        hintText: 'Tap to search and select',
                        suffixIcon: const Icon(Icons.search),
                        floatingLabelStyle: const TextStyle(color: appGreen),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color.fromARGB(255, 206, 206, 206)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color.fromARGB(255, 206, 206, 206)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: appGreen),
                        ),
                      ),
                      controller: TextEditingController(text: selectedCountry ?? ''),
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomTextfield(
                    labelText: 'Grade',
                    width: responsiveWidth,
                    controller: _gradeController,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 24),
                  CustomTextfield(
                    labelText: 'Favourite Subject',
                    width: responsiveWidth,
                    controller: _subjectController,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: responsiveWidth,
                    height: 45,
                    child: CustomButton(
                      text: 'Register',
                      onPressed: _submitStudentData,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
