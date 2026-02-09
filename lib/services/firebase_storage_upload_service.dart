import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Centralized Firebase Storage Upload Service
/// Handles all image/file uploads with proper validation, error handling, and logging
class FirebaseStorageUploadService {
  static final FirebaseStorageUploadService _instance = FirebaseStorageUploadService._internal();
  factory FirebaseStorageUploadService() => _instance;
  FirebaseStorageUploadService._internal();

  /// Upload profile picture for students or teachers
  /// 
  /// [bytes] - Image bytes (required for web)
  /// [file] - Image file (required for mobile)
  /// [userId] - User ID (defaults to current user)
  /// [folderName] - Storage folder ('profile_pictures' or 'teacher_profile_pictures')
  /// [firestoreCollection] - Firestore collection to update ('students' or 'teachers')
  Future<UploadResult> uploadProfilePicture({
    Uint8List? bytes,
    File? file,
    required String folderName,
    required String firestoreCollection,
    String? userId,
    Function(double)? onProgress,
  }) async {
    try {
      // Step 1: Validate authentication
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return UploadResult.error('User not authenticated. Please log in again.');
      }

      final uid = userId ?? user.uid;
      if (uid.isEmpty) {
        return UploadResult.error('Invalid user ID');
      }

      // Step 2: Validate file data
      if (kIsWeb) {
        if (bytes == null || bytes.isEmpty) {
          return UploadResult.error('No image data provided for web upload');
        }
        if (kDebugMode) {
          print('✅ Web upload - Bytes validated: ${bytes.length} bytes');
        }
      } else {
        if (file == null || !file.existsSync()) {
          return UploadResult.error('No image file provided or file does not exist');
        }
        final fileSize = await file.length();
        if (fileSize == 0) {
          return UploadResult.error('Image file is empty (0 bytes)');
        }
        if (kDebugMode) {
          print('✅ Mobile upload - File validated: $fileSize bytes');
        }
      }

      // Step 3: Validate folder name (prevent path injection)
      if (!_isValidFolderName(folderName)) {
        return UploadResult.error('Invalid storage folder name');
      }

      // Step 4: Construct safe storage path
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final platform = kIsWeb ? 'web' : 'mobile';
      final fileName = '${platform}_profile_$timestamp.jpg';
      final storagePath = '$folderName/$uid/$fileName';

      if (kDebugMode) {
        print('📤 Upload path: $storagePath');
      }

      // Step 5: Create storage reference
      final storageRef = FirebaseStorage.instance.ref().child(storagePath);

      // Step 6: Set metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedFrom': platform,
          'uploadedAt': DateTime.now().toIso8601String(),
          'userId': uid,
        },
      );

      // Step 7: Upload file
      UploadTask uploadTask;
      if (kIsWeb && bytes != null) {
        uploadTask = storageRef.putData(bytes, metadata);
      } else if (!kIsWeb && file != null) {
        uploadTask = storageRef.putFile(file, metadata);
      } else {
        return UploadResult.error('Invalid upload configuration');
      }

      // Step 8: Monitor progress
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
          if (kDebugMode) {
            print('📊 Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
          }
        });
      }

      // Step 9: Wait for upload completion
      final snapshot = await uploadTask.whenComplete(() {});
      
      // Step 10: Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      if (downloadUrl.isEmpty) {
        return UploadResult.error('Upload completed but download URL is empty');
      }

      if (kDebugMode) {
        print('✅ Upload successful: $downloadUrl');
      }

      // Step 11: Update Firestore
      try {
        await FirebaseFirestore.instance
            .collection(firestoreCollection)
            .doc(uid)
            .update({
          'profilePictureUrl': downloadUrl,
          'profilePictureUpdatedAt': FieldValue.serverTimestamp(),
        });
        
        if (kDebugMode) {
          print('✅ Firestore updated successfully');
        }
      } catch (firestoreError) {
        // Upload succeeded but Firestore update failed
        // Still return success with the download URL
        if (kDebugMode) {
          print('⚠️ Firestore update failed: $firestoreError');
        }
        return UploadResult.success(downloadUrl, 
          message: 'Image uploaded but profile update failed. Please refresh.');
      }

      return UploadResult.success(downloadUrl);
      
    } on FirebaseException catch (e) {
      return _handleFirebaseException(e);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Upload error: $e');
        print('Stack trace: $stackTrace');
      }
      return UploadResult.error('Upload failed: ${e.toString()}');
    }
  }

  /// Delete old profile picture from storage
  Future<bool> deleteOldProfilePicture(String? oldUrl) async {
    if (oldUrl == null || oldUrl.isEmpty) return true;

    try {
      final ref = FirebaseStorage.instance.refFromURL(oldUrl);
      await ref.delete();
      if (kDebugMode) {
        print('🗑️ Old profile picture deleted: $oldUrl');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Could not delete old image (may not exist): $e');
      }
      return false; // Don't fail if deletion fails
    }
  }

  /// Upload degree proof document
  Future<UploadResult> uploadDegreeProof({
    required Uint8List? bytes,
    required File? file,
    required String fileName,
    required String userId,
  }) async {
    try {
      // Validate authentication
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return UploadResult.error('User not authenticated');
      }

      if (userId.isEmpty) {
        return UploadResult.error('Invalid user ID');
      }

      // Validate file data
      if (kIsWeb) {
        if (bytes == null || bytes.isEmpty) {
          return UploadResult.error('No document data provided');
        }
      } else {
        if (file == null || !file.existsSync()) {
          return UploadResult.error('Document file not found');
        }
      }

      // Validate filename
      if (!_isValidFileName(fileName)) {
        return UploadResult.error('Invalid file name');
      }

      // Create storage path
      final storagePath = 'degree_proofs/$userId/$fileName';
      final storageRef = FirebaseStorage.instance.ref().child(storagePath);

      // Set metadata
      final metadata = SettableMetadata(
        contentDisposition: 'inline',
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'userId': userId,
        },
      );

      // Upload
      UploadTask uploadTask;
      if (kIsWeb && bytes != null) {
        uploadTask = storageRef.putData(bytes, metadata);
      } else if (!kIsWeb && file != null) {
        uploadTask = storageRef.putFile(file, metadata);
      } else {
        return UploadResult.error('Invalid upload configuration');
      }

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      if (kDebugMode) {
        print('✅ Degree proof uploaded: $downloadUrl');
      }

      return UploadResult.success(downloadUrl);
      
    } on FirebaseException catch (e) {
      return _handleFirebaseException(e);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Degree proof upload error: $e');
      }
      return UploadResult.error('Upload failed: ${e.toString()}');
    }
  }

  /// Validate folder name (prevent path injection)
  bool _isValidFolderName(String folderName) {
    final validFolders = [
      'profile_pictures',
      'teacher_profile_pictures',
      'degree_proofs',
    ];
    return validFolders.contains(folderName);
  }

  /// Validate filename (prevent path injection)
  bool _isValidFileName(String fileName) {
    if (fileName.isEmpty) return false;
    if (fileName.contains('..')) return false;
    if (fileName.contains('/')) return false;
    if (fileName.contains('\\')) return false;
    return true;
  }

  /// Handle Firebase exceptions with specific error messages
  UploadResult _handleFirebaseException(FirebaseException e) {
    String message;
    
    switch (e.code) {
      case 'unauthorized':
      case 'permission-denied':
        message = 'You do not have permission to upload files. Please check your account status.';
        break;
        
      case 'invalid-checksum':
        message = 'File upload failed due to corruption. Please try again.';
        break;
        
      case 'canceled':
        message = 'Upload was canceled';
        break;
        
      case 'unknown':
        if (e.message?.contains('412') ?? false) {
          message = 'Upload failed due to precondition error (HTTP 412). This may be a temporary issue. Please try again.';
        } else if (e.message?.contains('404') ?? false) {
          message = 'Storage bucket not found (HTTP 404). Please contact support.';
        } else {
          message = 'Upload failed with unknown error. Please check your internet connection and try again.';
        }
        break;
        
      case 'retry-limit-exceeded':
        message = 'Upload failed after multiple retries. Please check your internet connection.';
        break;
        
      case 'invalid-argument':
        message = 'Invalid file or upload configuration. Please try selecting a different image.';
        break;
        
      default:
        message = 'Upload failed: ${e.message ?? e.code}';
    }

    if (kDebugMode) {
      print('❌ Firebase Storage Error:');
      print('   Code: ${e.code}');
      print('   Message: ${e.message}');
      print('   Details: $e');
    }

    return UploadResult.error(message, code: e.code);
  }
}

/// Upload result class
class UploadResult {
  final bool success;
  final String? downloadUrl;
  final String? errorMessage;
  final String? errorCode;
  final String? message;

  UploadResult._({
    required this.success,
    this.downloadUrl,
    this.errorMessage,
    this.errorCode,
    this.message,
  });

  factory UploadResult.success(String downloadUrl, {String? message}) {
    return UploadResult._(
      success: true,
      downloadUrl: downloadUrl,
      message: message,
    );
  }

  factory UploadResult.error(String errorMessage, {String? code}) {
    return UploadResult._(
      success: false,
      errorMessage: errorMessage,
      errorCode: code,
    );
  }

  @override
  String toString() {
    if (success) {
      return 'UploadResult(success: true, url: $downloadUrl)';
    } else {
      return 'UploadResult(success: false, error: $errorMessage, code: $errorCode)';
    }
  }
}
