import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class StudentProfileWebProvider extends ChangeNotifier {
  String fullName = '';
  String email = '';
  String phone = '';
  String studentClass = '';
  String profilePictureUrl = '';
  String? assignedTeacherId;
  String? assignedTeacherName;
  
  Uint8List? uploadedImageBytes;
  bool isLoading = true;
  bool isSaving = false;
  bool isUploadingProfile = false;
  bool isEditMode = false;
  String? error;

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController classController = TextEditingController();

  final List<String> classes = [
    'Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6',
    'Grade 7', 'Grade 8', 'Grade 9', 'Grade 10', 'Grade 11', 'Grade 12',
  ];

  // Validation states
  bool get isFullNameValid => fullNameController.text.trim().length >= 2;
  bool get isPhoneValid => phoneController.text.trim().length >= 10;
  bool get isClassValid => classController.text.trim().isNotEmpty;
  bool get isFormValid => isFullNameValid && isPhoneValid && isClassValid;

  StudentProfileWebProvider() {
    fetchStudentInfo();
  }

  // Enhanced data fetching with error handling and teacher information
  Future<void> fetchStudentInfo() async {
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
        
        // Set class controller text
        _setClassText();

        // Fetch assigned teacher info if available
        if (assignedTeacherId != null) {
          await _fetchTeacherInfo();
        }

        isLoading = false;
        notifyListeners();

        if (kDebugMode) {
          print('✅ Student web profile data loaded successfully');
        }
      } else {
        throw Exception("Student profile not found");
      }
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      
      if (kDebugMode) {
        print('❌ Error fetching student web data: $e');
      }
    }
  }

  // Initialize class text field from stored value
  void _setClassText() {
    classController.text = studentClass;
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
          print('✅ Teacher info loaded for web: $assignedTeacherName');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error fetching teacher info for web: $e');
      }
    }
  }

  // Enhanced image upload handling with better error management
  Future<void> handleImageUpload(Future<Uint8List?> Function() pickImagePlatform, BuildContext context) async {
    try {
      final bytes = await pickImagePlatform();
      if (bytes != null) {
        uploadedImageBytes = bytes;
        isUploadingProfile = true;
        notifyListeners();
        
        if (context.mounted) {
          await uploadProfilePicture(bytes, context);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling image upload: $e');
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

  // Enhanced profile picture upload with progress and better error handling
  Future<void> uploadProfilePicture(Uint8List imageBytes, BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not authenticated");

      // Delete previous profile picture if exists
      if (profilePictureUrl.isNotEmpty) {
        try {
          final previousRef = FirebaseStorage.instance.refFromURL(profilePictureUrl);
          await previousRef.delete();
          if (kDebugMode) {
            print('🗑️ Previous web profile picture deleted');
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Could not delete previous web image: $e');
          }
        }
      }

      // Upload new image with metadata
      final storageRef = FirebaseStorage.instance.ref().child(
        'profile_pictures/${user.uid}/web_profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedFrom': 'web',
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );
      
      final uploadTask = storageRef.putData(imageBytes, metadata);
      
      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        if (kDebugMode) {
          print('📤 Web upload progress: ${(progress * 100).toStringAsFixed(1)}%');
        }
      });

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Update Firestore with new URL and timestamp
      await FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .update({
        'profilePictureUrl': downloadUrl,
        'profilePictureUpdatedAt': FieldValue.serverTimestamp(),
      });

      profilePictureUrl = downloadUrl;
      isUploadingProfile = false;
      uploadedImageBytes = null;
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile picture updated successfully"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      if (kDebugMode) {
        print('✅ Web profile picture uploaded successfully');
      }
    } catch (e) {
      isUploadingProfile = false;
      uploadedImageBytes = null;
      notifyListeners();
      
      if (kDebugMode) {
        print('❌ Error uploading web profile picture: $e');
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

  // Enhanced edit mode with better state management
  void toggleEditMode() {
    isEditMode = !isEditMode;
    if (isEditMode) {
      // Initialize controllers with current values
      fullNameController.text = fullName;
      phoneController.text = phone;
      _setClassText();
    } else {
      // Reset to original values when canceling
      resetForm();
    }
    notifyListeners();
  }

  // Enhanced save changes with validation
  Future<void> saveChanges(BuildContext context) async {
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

      // Update Firestore with timestamp
      await FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .update({
        'fullName': fullNameController.text.trim(),
        'phoneNumber': phoneController.text.trim(),
        'grade': classController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile updated successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Refresh data and exit edit mode
      await fetchStudentInfo();
      isEditMode = false;
      isSaving = false;
      notifyListeners();

      if (kDebugMode) {
        print('✅ Web profile updated successfully');
      }
    } catch (e) {
      isSaving = false;
      notifyListeners();
      
      if (kDebugMode) {
        print('❌ Error updating web profile: $e');
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

  // Cancel edit mode and reset form
  void cancelEdit() {
    isEditMode = false;
    resetForm();
    notifyListeners();
  }

  // Reset form to original values
  void resetForm() {
    fullNameController.text = fullName;
    phoneController.text = phone;
    _setClassText();
    uploadedImageBytes = null;
    notifyListeners();
  }

  // Check if form has unsaved changes
  bool get hasUnsavedChanges {
    return fullNameController.text.trim() != fullName ||
           phoneController.text.trim() != phone ||
           classController.text.trim() != studentClass ||
           uploadedImageBytes != null;
  }

  // Refresh profile data
  Future<void> refreshProfile() async {
    await fetchStudentInfo();
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
    classController.dispose();
    super.dispose();
  }
}
