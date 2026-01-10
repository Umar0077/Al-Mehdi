import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class TeacherProfileMobileProvider extends ChangeNotifier {
  String fullName = '';
  String phone = '';
  String degree = '';
  String email = '';
  String profilePictureUrl = '';
  List<String> assignedStudentIds = [];
  int assignedStudentsCount = 0;
  
  File? selectedImage;
  bool isLoading = true;
  bool isUploading = false;
  bool isSaving = false;
  String? error;
  
  final picker = ImagePicker();

  // Form controllers for editing
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController degreeController = TextEditingController();
  
  // Validation states
  bool get isFullNameValid => fullName.trim().length >= 2;
  bool get isPhoneValid => phone.trim().length >= 10;
  bool get isDegreeValid => degree.trim().length >= 2;
  bool get isFormValid => isFullNameValid && isPhoneValid && isDegreeValid;

  TeacherProfileMobileProvider() {
    loadProfile();
  }

  // Enhanced data fetching with error handling and student count
  Future<void> loadProfile() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not authenticated");
      }

      final doc = await FirebaseFirestore.instance
          .collection('teachers')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        fullName = data['fullName'] ?? '';
        phone = data['phoneNumber'] ?? '';
        degree = data['degree'] ?? '';
        email = data['email'] ?? user.email ?? '';
        profilePictureUrl = data['profilePictureUrl'] ?? '';
        assignedStudentIds = List<String>.from(data['assignedStudents'] ?? []);

        // Update controllers
        fullNameController.text = fullName;
        phoneController.text = phone;
        degreeController.text = degree;

        // Get assigned students count
        await _fetchAssignedStudentsCount();

        isLoading = false;
        notifyListeners();

        if (kDebugMode) {
          print('✅ Teacher profile data loaded successfully');
        }
      } else {
        throw Exception("Teacher profile not found");
      }
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      
      if (kDebugMode) {
        print('❌ Error fetching teacher data: $e');
      }
    }
  }

  // Fetch count of assigned students
  Future<void> _fetchAssignedStudentsCount() async {
    try {
      final studentsQuery = await FirebaseFirestore.instance
          .collection('students')
          .where('assignedTeacherId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .get();
      
      assignedStudentsCount = studentsQuery.docs.length;
      notifyListeners();

      if (kDebugMode) {
        print('✅ Assigned students count: $assignedStudentsCount');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error fetching students count: $e');
      }
    }
  }

  // Enhanced profile update with validation
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
      degree = degreeController.text.trim();

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('teachers')
          .doc(user.uid)
          .update({
        'fullName': fullName,
        'phoneNumber': phone,
        'degree': degree,
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
        print('✅ Teacher profile updated successfully');
      }
    } catch (e) {
      isSaving = false;
      notifyListeners();

      if (kDebugMode) {
        print('❌ Error updating teacher profile: $e');
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
    await loadProfile();
  }

  // Reset form to original values
  void resetForm() {
    fullNameController.text = fullName;
    phoneController.text = phone;
    degreeController.text = degree;
    selectedImage = null;
    notifyListeners();
  }

  // Check if form has unsaved changes
  bool get hasUnsavedChanges {
    return fullNameController.text.trim() != fullName ||
           phoneController.text.trim() != phone ||
           degreeController.text.trim() != degree ||
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

  // Validate degree
  String? validateDegree(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Degree is required';
    }
    if (value.trim().length < 2) {
      return 'Degree must be at least 2 characters';
    }
    return null;
  }

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    degreeController.dispose();
    super.dispose();
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
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
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
        try {
          final previousRef = FirebaseStorage.instance.refFromURL(profilePictureUrl);
          await previousRef.delete();
          if (kDebugMode) {
            print('🗑️ Previous profile picture deleted');
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Could not delete previous image: $e');
          }
        }
      }

      // Upload new image
      final storageRef = FirebaseStorage.instance.ref().child(
        'teacher_profile_pictures/${user.uid}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final uploadTask = storageRef.putFile(selectedImage!);
      
      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        if (kDebugMode) {
          print('📤 Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
        }
      });

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Update Firestore with new URL
      await FirebaseFirestore.instance
          .collection('teachers')
          .doc(user.uid)
          .update({'profilePictureUrl': downloadUrl});

      profilePictureUrl = downloadUrl;
      isUploading = false;
      selectedImage = null;
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
        print('✅ Profile picture uploaded successfully');
      }
    } catch (e) {
      isUploading = false;
      selectedImage = null;
      notifyListeners();

      if (kDebugMode) {
        print('❌ Error uploading profile picture: $e');
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
}
