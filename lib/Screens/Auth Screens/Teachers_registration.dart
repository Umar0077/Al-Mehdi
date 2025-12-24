import 'package:al_mehdi_online_school/Screens/AdminDashboard/Unassigned%20Users%20Screens/wait_for_assignment_screen.dart';
import 'package:al_mehdi_online_school/components/Custom_button.dart';
import 'package:al_mehdi_online_school/components/Custom_Textfield.dart';
import 'package:al_mehdi_online_school/constants/colors.dart';
import 'package:al_mehdi_online_school/constants/countries.dart';
import 'package:al_mehdi_online_school/teachers/teacher_home_screen/teacher_home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

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
  bool isSubmitting = false;
  double? _cachedResponsiveWidth; // Cache responsive width calculation

  final _fullNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _degreeController = TextEditingController();

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

  Future<String?> _uploadDegreeProof(String uid) async {
    if (degreeFile == null) return null;
    final storageRef = FirebaseStorage.instance.ref().child(
      'degree_proofs/$uid/${degreeFile!.name}',
    );
    final metadata = SettableMetadata(contentDisposition: 'inline');
    UploadTask uploadTask;
    if (degreeFile!.bytes != null) {
      uploadTask = storageRef.putData(degreeFile!.bytes!, metadata);
    } else if (degreeFile!.path != null) {
      uploadTask = storageRef.putFile(File(degreeFile!.path!), metadata);
    } else {
      return null;
    }
    final snapshot = await uploadTask.whenComplete(() {});
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> _submitRegistration() async {
    if (_fullNameController.text.isEmpty ||
        _phoneNumberController.text.isEmpty ||
        selectedCountry == null ||
        selectedDegree == null ||
        degreeFile == null ||
        (widget.email == null || widget.email!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "All fields including full name, phone number, email, and document are required",
          ),
        ),
      );
      return;
    }
    setState(() => isSubmitting = true);
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
      // Upload degree proof to Firebase Storage
      final degreeProofUrl = await _uploadDegreeProof(uid);
      await FirebaseFirestore.instance.collection('teachers').doc(uid).set({
        'uid': uid,
        'email': email,
        'fullName': _fullNameController.text.trim(),
        'phoneNumber': _phoneNumberController.text.trim(),
        'country': selectedCountry,
        'degree': selectedDegree,
        'degreeProofUrl': degreeProofUrl,
        'assignedStudentId': null,
        'createdAt': Timestamp.now(),
      });
      await FirebaseFirestore.instance
          .collection('unassigned_teachers')
          .doc(uid)
          .set({
            'uid': uid,
            'email': email,
            'fullName': _fullNameController.text.trim(),
            'phoneNumber': _phoneNumberController.text.trim(),
            'country': selectedCountry,
            'degree': selectedDegree,
            'degreeProofUrl': degreeProofUrl,
            'role': 'Teacher',
            'assigned': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
      await NotificationService.sendNewUserRegisteredNotificationToAdmin(
        newUserId: uid,
        newUserName: _fullNameController.text.trim(),
        newUserRole: 'teacher',
      );
      await NotificationService.initialize();
      final doc =
          await FirebaseFirestore.instance
              .collection('teachers')
              .doc(uid)
              .get();
      final assignedStudentId = doc.data()?['assignedStudentId'];
      if (assignedStudentId == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => const WaitForAssignmentScreen(role: 'Teacher'),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TeacherHomeScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: " + e.toString())));
    } finally {
      setState(() => isSubmitting = false);
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
                        style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold),
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

                  // Full Name
                  CustomTextfield(
                    labelText: 'Full Name',
                    width: responsiveWidth,
                    controller: _fullNameController,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  CustomTextfield(
                    labelText: 'Phone Number',
                    width: responsiveWidth,
                    controller: _phoneNumberController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  CustomTextfield(
                    labelText: 'Degree',
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
                      onChanged: (value) => setState(() => selectedDegree = value),
                      items:
                          degrees
                              .map(
                                (d) => DropdownMenuItem(value: d, child: Text(d)),
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
                      icon: const Icon(Icons.upload_file, color: Color(0xff02D185)),
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
                      onPressed: isSubmitting ? null : _submitRegistration,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isSubmitting)
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
