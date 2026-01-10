import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import '../../components/teacher_image_picker.dart';

class ProfileScreenProvider extends ChangeNotifier {
  String fullName = '';
  String email = '';
  String phone = '';
  String role = 'Admin';
  String? profileImageUrl;
  bool isLoading = false;

  ProfileScreenProvider() {
    loadAdminProfile();
  }

  Future<void> loadAdminProfile() async {
    isLoading = true;
    notifyListeners();
    final adminDoc =
        await FirebaseFirestore.instance.collection('admin').limit(1).get();
    if (adminDoc.docs.isNotEmpty) {
      final data = adminDoc.docs.first.data();
      fullName = data['full name'] ?? '';
      email = data['email'] ?? '';
      phone = data['phone'] ?? '';
      profileImageUrl = data['profilePictureUrl'];
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> updateAdminProfile({
    required String fullName,
    required String email,
    required String phone,
  }) async {
    isLoading = true;
    notifyListeners();
    final adminDoc =
        await FirebaseFirestore.instance.collection('admin').limit(1).get();
    if (adminDoc.docs.isNotEmpty) {
      final docId = adminDoc.docs.first.id;
      await FirebaseFirestore.instance.collection('admin').doc(docId).update({
        'full name': fullName,
        'email': email,
        'phone': phone,
      });
      this.fullName = fullName;
      this.email = email;
      this.phone = phone;
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> pickAndUploadImage(BuildContext context) async {
    try {
      isLoading = true;
      notifyListeners();

      // Sign in anonymously for upload permission if not already signed in
      if (FirebaseAuth.instance.currentUser == null) {
        if (kDebugMode) {
          print('🔐 Signing in anonymously for upload...');
        }
        await FirebaseAuth.instance.signInAnonymously();
      }

      // Use the web-compatible image picker
      final bytes = await pickImagePlatform();

      if (bytes != null) {
        await _uploadImage(bytes);
      } else {
        if (kDebugMode) {
          print('📷 No image selected');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in pickAndUploadImage: $e');
      }
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _uploadImage(Uint8List imageBytes) async {
    try {
      if (kDebugMode) {
        print('📷 Image picked, size: ${imageBytes.length} bytes');
      }

      // Check file size (limit to 10MB)
      if (imageBytes.length > 10 * 1024 * 1024) {
        throw Exception(
          'File size too large. Please select an image smaller than 10MB.',
        );
      }

      // Get admin document
      final adminDoc =
          await FirebaseFirestore.instance.collection('admin').limit(1).get();
      if (adminDoc.docs.isNotEmpty) {
        final docId = adminDoc.docs.first.id;

        // Create unique filename with timestamp
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'admin_profile_${docId}_$timestamp.jpg';

        if (kDebugMode) {
          print('📤 Uploading image: $fileName');
        }

        // Delete previous profile picture if exists
        if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
          try {
            final previousRef = FirebaseStorage.instance.refFromURL(
              profileImageUrl!,
            );
            await previousRef.delete();
            if (kDebugMode) {
              print('🗑️ Previous admin profile picture deleted');
            }
          } catch (e) {
            if (kDebugMode) {
              print('⚠️ Could not delete previous image: $e');
            }
          }
        }

        // Upload to Firebase Storage
        final ref = FirebaseStorage.instance.ref().child(
          'admin_profile_pictures/$fileName',
        );

        final uploadTask = ref.putData(
          imageBytes,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'upload_time': timestamp.toString(),
              'uploaded_by': 'admin',
              'admin_doc_id': docId,
            },
          ),
        );

        // Monitor upload progress
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          if (kDebugMode) {
            print(
              '📤 Admin upload progress: ${(progress * 100).toStringAsFixed(1)}%',
            );
          }
        });

        // Wait for upload to complete
        final snapshot = await uploadTask;

        if (kDebugMode) {
          print('✅ Upload completed: ${snapshot.state}');
        }

        // Get download URL
        final url = await ref.getDownloadURL();

        if (kDebugMode) {
          print('🔗 Download URL: $url');
        }

        // Update Firestore with new image URL
        await FirebaseFirestore.instance.collection('admin').doc(docId).update({
          'profilePictureUrl': url,
          'profilePictureUpdatedAt': FieldValue.serverTimestamp(),
        });

        // Update local state
        profileImageUrl = url;

        if (kDebugMode) {
          print('✅ Admin profile image updated successfully');
        }
      } else {
        if (kDebugMode) {
          print('❌ No admin document found');
        }
        throw Exception('Admin profile not found');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error uploading admin image: $e');
      }
      rethrow;
    }
  }
}
