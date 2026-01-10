import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class TeacherProfileWebProvider extends ChangeNotifier {
  // Profile fields
  String fullName = '';
  String email = '';
  String phone = '';
  String degree = '';
  String degreeProofUrl = '';
  String profilePictureUrl = '';
  List<String> assignedStudentIds = [];
  int assignedStudentsCount = 0;
  
  Uint8List? uploadedImageBytes;
  bool isLoading = true;
  bool isEditMode = false;
  bool isSubmitting = false;
  bool isUploadingProfile = false;
  String? error;

  // Controllers for edit mode
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  String? selectedDegree;
  PlatformFile? newDegreeFile;
  bool hasNewDegreeFile = false;

  final List<String> degrees = [
    'Bachelor',
    'Master',
    'PhD',
    'Diploma',
    'Associate',
  ];

  // Validation states
  bool get isFullNameValid => fullNameController.text.trim().length >= 2;
  bool get isPhoneValid => phoneController.text.trim().length >= 10;
  bool get isDegreeValid => selectedDegree != null && selectedDegree!.isNotEmpty;
  bool get isFormValid => isFullNameValid && isPhoneValid && isDegreeValid;

  TeacherProfileWebProvider() {
    fetchTeacherInfo();
  }

  // Enhanced data fetching with error handling and student count
  Future<void> fetchTeacherInfo() async {
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
        email = data['email'] ?? user.email ?? '';
        phone = data['phoneNumber'] ?? '';
        degree = data['degree'] ?? '';
        degreeProofUrl = data['degreeProofUrl'] ?? '';
        profilePictureUrl = data['profilePictureUrl'] ?? '';
        assignedStudentIds = List<String>.from(data['assignedStudents'] ?? []);

        // Update controllers
        fullNameController.text = fullName;
        phoneController.text = phone;
        selectedDegree = degree.isNotEmpty ? degree : null;

        // Get assigned students count
        await _fetchAssignedStudentsCount();

        isLoading = false;
        notifyListeners();

        if (kDebugMode) {
          print('✅ Teacher web profile data loaded successfully');
        }
      } else {
        throw Exception("Teacher profile not found");
      }
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      
      if (kDebugMode) {
        print('❌ Error fetching teacher web data: $e');
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
        print('✅ Assigned students count for web: $assignedStudentsCount');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error fetching students count for web: $e');
      }
    }
  }

  // Enhanced image upload handling with better error management
  Future<void> handleImageUpload(BuildContext context, Future<Uint8List?> Function() pickImagePlatform) async {
    try {
      final bytes = await pickImagePlatform();
      if (bytes != null) {
        uploadedImageBytes = bytes;
        isUploadingProfile = true;
        notifyListeners();
        
        if (context.mounted) {
          await uploadProfilePicture(context, bytes);
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
  Future<void> uploadProfilePicture(BuildContext context, Uint8List imageBytes) async {
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
        'teacher_profile_pictures/${user.uid}/web_profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
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
          print('📤 Teacher web upload progress: ${(progress * 100).toStringAsFixed(1)}%');
        }
      });

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Update Firestore with new URL and timestamp
      await FirebaseFirestore.instance
          .collection('teachers')
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
        print('✅ Teacher web profile picture uploaded successfully');
      }
    } catch (e) {
      isUploadingProfile = false;
      uploadedImageBytes = null;
      notifyListeners();
      
      if (kDebugMode) {
        print('❌ Error uploading teacher web profile picture: $e');
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
      selectedDegree = degree.isNotEmpty ? degree : null;
      newDegreeFile = null;
      hasNewDegreeFile = false;
    } else {
      // Reset to original values when canceling
      resetForm();
    }
    notifyListeners();
  }

  // Enhanced document picker
  Future<void> pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );
      
      if (result != null) {
        newDegreeFile = result.files.first;
        hasNewDegreeFile = true;
        notifyListeners();

        if (kDebugMode) {
          print('✅ Document selected: ${newDegreeFile!.name}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error picking document: $e');
      }
    }
  }

  // Enhanced profile update with comprehensive validation
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
      isSubmitting = true;
      notifyListeners();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not authenticated");

      String? uploadedDegreeUrl;

      // Upload degree proof if new file is selected
      if (hasNewDegreeFile && newDegreeFile != null) {
        // Delete previous degree proof if exists
        if (degreeProofUrl.isNotEmpty) {
          try {
            final previousRef = FirebaseStorage.instance.refFromURL(degreeProofUrl);
            await previousRef.delete();
            if (kDebugMode) {
              print('🗑️ Previous degree proof deleted');
            }
          } catch (e) {
            if (kDebugMode) {
              print('⚠️ Could not delete previous degree proof: $e');
            }
          }
        }

        // Upload new degree proof
        final degreeRef = FirebaseStorage.instance.ref().child(
          'degree_proofs/${user.uid}/degree_${DateTime.now().millisecondsSinceEpoch}.${newDegreeFile!.extension}',
        );
        
        await degreeRef.putData(newDegreeFile!.bytes!);
        uploadedDegreeUrl = await degreeRef.getDownloadURL();

        if (kDebugMode) {
          print('✅ Degree proof uploaded successfully');
        }
      }

      // Update profile data
      final updateData = {
        'fullName': fullNameController.text.trim(),
        'phoneNumber': phoneController.text.trim(),
        'degree': selectedDegree!,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (uploadedDegreeUrl != null) {
        updateData['degreeProofUrl'] = uploadedDegreeUrl;
      }

      await FirebaseFirestore.instance
          .collection('teachers')
          .doc(user.uid)
          .update(updateData);

      // Update local state
      fullName = fullNameController.text.trim();
      phone = phoneController.text.trim();
      degree = selectedDegree!;
      if (uploadedDegreeUrl != null) {
        degreeProofUrl = uploadedDegreeUrl;
      }

      isEditMode = false;
      isSubmitting = false;
      hasNewDegreeFile = false;
      newDegreeFile = null;
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
        print('✅ Teacher web profile updated successfully');
      }
    } catch (e) {
      isSubmitting = false;
      notifyListeners();
      
      if (kDebugMode) {
        print('❌ Error updating teacher web profile: $e');
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
    selectedDegree = degree.isNotEmpty ? degree : null;
    newDegreeFile = null;
    hasNewDegreeFile = false;
    uploadedImageBytes = null;
    notifyListeners();
  }

  // Check if form has unsaved changes
  bool get hasUnsavedChanges {
    return fullNameController.text.trim() != fullName ||
           phoneController.text.trim() != phone ||
           selectedDegree != degree ||
           hasNewDegreeFile ||
           uploadedImageBytes != null;
  }

  // Refresh profile data
  Future<void> refreshProfile() async {
    await fetchTeacherInfo();
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
