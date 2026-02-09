import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:al_mehdi_online_school/services/firebase_storage_upload_service.dart';
import '../../../constants/colors.dart';

class StudentProfileMobileProvider extends ChangeNotifier {
  String fullName = '';
  String email = '';
  String phone = '';
  String studentClass = '';
  String profilePictureUrl = '';
  String? assignedTeacherId;
  String? assignedTeacherName;
  
  File? selectedImage;
  bool isLoading = true;
  bool isUploading = false;
  bool isSaving = false;
  String? error;
  
  final picker = ImagePicker();

  // Form controllers for editing
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  
  // Validation states
  bool get isFullNameValid => fullName.trim().length >= 2;
  bool get isPhoneValid => phone.trim().length >= 10;
  bool get isFormValid => isFullNameValid && isPhoneValid;

  StudentProfileMobileProvider() {
    fetchStudentData();
  }

  // Enhanced data fetching with teacher information
  Future<void> fetchStudentData() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not authenticated");
      }

      final doc = await FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        fullName = data['fullName'] ?? '';
        email = data['email'] ?? user.email ?? '';
        phone = data['phoneNumber'] ?? '';
        studentClass = data['grade'] ?? '';
        profilePictureUrl = data['profilePictureUrl'] ?? '';
        assignedTeacherId = data['assignedTeacherId'];

        // Update controllers
        fullNameController.text = fullName;
        phoneController.text = phone;

        // Fetch assigned teacher info if available
        if (assignedTeacherId != null) {
          await _fetchTeacherInfo();
        }

        isLoading = false;
        notifyListeners();

        if (kDebugMode) {
          print('✅ Student profile data loaded successfully');
        }
      } else {
        throw Exception("Student profile not found");
      }
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      
      if (kDebugMode) {
        print('❌ Error fetching student data: $e');
      }
    }
  }

  // Fetch assigned teacher information
  Future<void> _fetchTeacherInfo() async {
    try {
      if (assignedTeacherId == null) return;

      final teacherDoc = await FirebaseFirestore.instance
          .collection('teachers')
          .doc(assignedTeacherId)
          .get();

      if (teacherDoc.exists) {
        final teacherData = teacherDoc.data()!;
        assignedTeacherName = teacherData['fullName'] ?? 'Teacher';
        notifyListeners();

        if (kDebugMode) {
          print('✅ Teacher info loaded: $assignedTeacherName');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error fetching teacher info: $e');
      }
    }
  }

  // Enhanced image picking with multiple sources
  Future<void> pickImage(BuildContext context, {ImageSource? source}) async {
    try {
      ImageSource selectedSource = source ?? ImageSource.gallery;
      
      // Show source selection if not specified
      if (source == null) {
        selectedSource = await _showImageSourceDialog(context) ?? ImageSource.gallery;
      }

      final pickedFile = await picker.pickImage(
        source: selectedSource,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        selectedImage = File(pickedFile.path);
        notifyListeners();
        if (context.mounted) {
          await uploadProfilePicture(context);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error picking image: $e');
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Show image source selection dialog
  Future<ImageSource?> _showImageSourceDialog(BuildContext context) async {
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? darkBackground
              : appLightGreen,
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.photo_library,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? appGreen
                      : Colors.black87,
                ),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: Icon(
                  Icons.camera_alt,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? appGreen
                      : Colors.black87,
                ),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );
  }

  // Enhanced profile picture upload with progress
  Future<void> uploadProfilePicture(BuildContext context) async {
    if (selectedImage == null) return;

    try {
      isUploading = true;
      notifyListeners();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not authenticated");

      // Delete previous profile picture if exists
      if (profilePictureUrl.isNotEmpty) {
        final uploadService = FirebaseStorageUploadService();
        await uploadService.deleteOldProfilePicture(profilePictureUrl);
      }

      // Upload new image using centralized service
      final uploadService = FirebaseStorageUploadService();
      final result = await uploadService.uploadProfilePicture(
        file: selectedImage,
        folderName: 'profile_pictures',
        firestoreCollection: 'students',
        userId: user.uid,
        onProgress: (progress) {
          if (kDebugMode) {
            print('📤 Student mobile upload progress: ${(progress * 100).toStringAsFixed(1)}%');
          }
        },
      );

      if (result.success && result.downloadUrl != null) {
        profilePictureUrl = result.downloadUrl!;
        isUploading = false;
        selectedImage = null;
        notifyListeners();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? "Profile picture updated successfully"),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        if (kDebugMode) {
          print('✅ Student mobile profile picture uploaded successfully');
        }
      } else {
        throw Exception(result.errorMessage ?? 'Upload failed');
      }
    } catch (e) {
      isUploading = false;
      selectedImage = null;
      notifyListeners();

      if (kDebugMode) {
        print('❌ Error uploading student mobile profile picture: $e');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error uploading profile picture: ${e.toString()}"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Update profile information
  Future<void> updateProfile(BuildContext context) async {
    if (!isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all required fields correctly"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      isSaving = true;
      notifyListeners();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not authenticated");

      // Update local values from controllers
      fullName = fullNameController.text.trim();
      phone = phoneController.text.trim();

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .update({
        'fullName': fullName,
        'phoneNumber': phone,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      isSaving = false;
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile updated successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }

      if (kDebugMode) {
        print('✅ Profile updated successfully');
      }
    } catch (e) {
      isSaving = false;
      notifyListeners();

      if (kDebugMode) {
        print('❌ Error updating profile: $e');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error updating profile: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Refresh profile data
  Future<void> refreshProfile() async {
    await fetchStudentData();
  }

  // Reset form to original values
  void resetForm() {
    fullNameController.text = fullName;
    phoneController.text = phone;
    selectedImage = null;
    notifyListeners();
  }

  // Check if form has unsaved changes
  bool get hasUnsavedChanges {
    return fullNameController.text.trim() != fullName ||
           phoneController.text.trim() != phone ||
           selectedImage != null;
  }

  // Validate full name
  String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 2) {
      return 'Full name must be at least 2 characters';
    }
    return null;
  }

  // Validate phone number
  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    if (value.trim().length < 10) {
      return 'Phone number must be at least 10 digits';
    }
    // Basic phone number format validation
    final phoneRegex = RegExp(r'^[\+]?[0-9\-\(\)\s]+$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    super.dispose();
  }
}
