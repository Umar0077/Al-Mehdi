import 'dart:io';

import 'package:al_mehdi_online_school/models/student_data.dart';
import 'package:al_mehdi_online_school/models/teacher_data.dart';
import 'package:al_mehdi_online_school/models/user_role.dart';
import 'package:al_mehdi_online_school/services/notification_service.dart';
import 'package:al_mehdi_online_school/services/firebase_storage_upload_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Authentication state for the user
class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final User? user;
  final UserRole? userRole;
  final bool isUnassigned;
  final String? adminId; // For admin login

  const AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.user,
    this.userRole,
    this.isUnassigned = false,
    this.adminId,
  });

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    User? user,
    UserRole? userRole,
    bool? isUnassigned,
    String? adminId,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      user: user ?? this.user,
      userRole: userRole ?? this.userRole,
      isUnassigned: isUnassigned ?? this.isUnassigned,
      adminId: adminId ?? this.adminId,
    );
  }
}

/// Provider for handling authentication logic
class AuthProvider extends ChangeNotifier {
  AuthState _state = const AuthState();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthState get state => _state;

  void _setState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Sign in with email and password
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    _setState(_state.copyWith(isLoading: true, errorMessage: null));

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception("No authenticated user found");
      }

      // Check user status and get role
      final result = await _checkUserStatusAndRole(user.uid);

      if (!result['success']) {
        await _auth.signOut();
        _setState(
          _state.copyWith(isLoading: false, errorMessage: result['message']),
        );
        return false;
      }

      // Request web notifications after successful login
      if (kIsWeb) {
        _requestWebNotifications();
      }

      _setState(
        _state.copyWith(
          isLoading: false,
          user: user,
          userRole: result['role'],
          isUnassigned: result['isUnassigned'],
        ),
      );

      return true;
    } on FirebaseAuthException catch (e) {
      String message = 'Invalid email or password';
      if (e.code == 'user-not-found') {
        message = 'Invalid email';
      } else if (e.code == 'wrong-password') {
        message = 'Invalid password';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email';
      } else if (e.code == 'invalid-credential') {
        message = 'Invalid email or password';
      } else if (e.code == 'INVALID_LOGIN_CREDENTIALS') {
        message = 'Invalid email or password';
      }

      _setState(_state.copyWith(isLoading: false, errorMessage: message));
      return false;
    } catch (e) {
      // For any other errors, show a simple generic message
      _setState(
        _state.copyWith(
          isLoading: false,
          errorMessage: 'Invalid email or password',
        ),
      );
      return false;
    }
  }

  /// Check user status and determine role
  Future<Map<String, dynamic>> _checkUserStatusAndRole(String uid) async {
    try {
      // Check student collection
      final studentDoc =
          await _firestore
              .collection(UserRole.student.collectionName)
              .doc(uid)
              .get();

      // Check teacher collection
      final teacherDoc =
          await _firestore
              .collection(UserRole.teacher.collectionName)
              .doc(uid)
              .get();

      // Determine which document exists
      final userDoc = studentDoc.exists ? studentDoc : teacherDoc;
      final role = studentDoc.exists ? UserRole.student : UserRole.teacher;

      // Check if user is disabled
      if (userDoc.exists && userDoc.data()?['enabled'] == false) {
        return {
          'success': false,
          'message': 'You are currently disabled. Please contact admin.',
        };
      }

      // Check if user is unassigned
      final unassignedDoc =
          await _firestore
              .collection(role.unassignedCollectionName)
              .doc(uid)
              .get();

      if (unassignedDoc.exists && unassignedDoc.data()?['assigned'] == false) {
        return {'success': true, 'role': role, 'isUnassigned': true};
      }

      // Check if user exists in either collection
      if (!studentDoc.exists && !teacherDoc.exists) {
        return {
          'success': false,
          'message': 'Account not found. Please register first.',
        };
      }

      return {'success': true, 'role': role, 'isUnassigned': false};
    } catch (e) {
      return {
        'success': false,
        'message': 'Error checking user status: ${e.toString()}',
      };
    }
  }

  /// Request web notifications after login
  Future<void> _requestWebNotifications() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      await NotificationService.requestWebNotificationPermission();
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error requesting web notifications: $e');
      }
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      // Sign out from Firebase Auth
      await _auth.signOut();
      _setState(const AuthState());

      if (kDebugMode) {
        print('✅ Successfully signed out');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error during sign out: $e');
      }
      // Still clear the state even if there's an error
      _setState(const AuthState());
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    _setState(_state.copyWith(isLoading: true, errorMessage: null));

    if (email.trim().isEmpty) {
      _setState(
        _state.copyWith(
          isLoading: false,
          errorMessage: "Please enter your email",
        ),
      );
      return false;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      _setState(_state.copyWith(isLoading: false));
      return true;
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found') {
        message = "No user found for that email.";
      } else if (e.code == 'invalid-email') {
        message = "The email address is not valid.";
      } else {
        message = e.message ?? "Error sending password reset email";
      }
      _setState(_state.copyWith(isLoading: false, errorMessage: message));
      return false;
    } catch (e) {
      _setState(
        _state.copyWith(
          isLoading: false,
          errorMessage: "An unexpected error occurred.",
        ),
      );
      return false;
    }
  }

  /// Admin login with email and password (Firestore-based)
  Future<bool> signInAdmin(String email, String password) async {
    _setState(_state.copyWith(isLoading: true, errorMessage: null));

    if (email.trim().isEmpty) {
      _setState(
        _state.copyWith(
          isLoading: false,
          errorMessage: 'Please enter your email address',
        ),
      );
      return false;
    }

    if (password.trim().isEmpty) {
      _setState(
        _state.copyWith(
          isLoading: false,
          errorMessage: 'Please enter your password',
        ),
      );
      return false;
    }

    try {
      final query =
          await _firestore
              .collection('admin')
              .where('email', isEqualTo: email.trim())
              .get();

      if (query.docs.isEmpty) {
        _setState(
          _state.copyWith(
            isLoading: false,
            errorMessage: 'Admin email not found.',
          ),
        );
        return false;
      }

      final data = query.docs.first.data();

      if (data['password'] != password.trim()) {
        _setState(
          _state.copyWith(
            isLoading: false,
            errorMessage: 'Incorrect password.',
          ),
        );
        return false;
      }

      // Save admin token
      try {
        await NotificationService.initialize();
        await NotificationService.saveTokenToFirestore(query.docs.first.id);
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Notification init error: $e');
        }
      }

      _setState(
        _state.copyWith(
          isLoading: false,
          userRole: UserRole.admin,
          adminId: query.docs.first.id,
        ),
      );

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Login error: $e');
      }
      _setState(
        _state.copyWith(
          isLoading: false,
          errorMessage: 'Something went wrong. Please try again.',
        ),
      );
      return false;
    }
  }

  /// Validate registration fields
  bool validateRegistrationFields({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
    required String role,
  }) {
    if (role == "Role") {
      _setState(_state.copyWith(errorMessage: "Please select a valid role"));
      return false;
    }

    if (fullName.trim().isEmpty) {
      _setState(_state.copyWith(errorMessage: "Please enter your full name"));
      return false;
    }

    if (email.trim().isEmpty) {
      _setState(_state.copyWith(errorMessage: "Please enter your email address"));
      return false;
    }

    if (password.isEmpty) {
      _setState(_state.copyWith(errorMessage: "Please enter a password"));
      return false;
    }

    if (confirmPassword.isEmpty) {
      _setState(_state.copyWith(errorMessage: "Please confirm your password"));
      return false;
    }

    if (password != confirmPassword) {
      _setState(_state.copyWith(errorMessage: "Passwords do not match"));
      return false;
    }

    return true;
  }

  /// Register student with email/password and save to Firestore
  Future<bool> registerStudent({
    required String email,
    required String password,
    required StudentData studentData,
  }) async {
    _setState(_state.copyWith(isLoading: true, errorMessage: null));

    try {
      // Create user with email and password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        _setState(
          _state.copyWith(isLoading: false, errorMessage: "User not created"),
        );
        return false;
      }

      // Save to Firestore students collection
      await _firestore
          .collection('students')
          .doc(user.uid)
          .set(
            studentData.toFirestoreMap(
              uid: user.uid,
              email: user.email ?? email,
            )..['createdAt'] = FieldValue.serverTimestamp(),
          );

      // Save to unassigned_students collection
      await _firestore
          .collection('unassigned_students')
          .doc(user.uid)
          .set(
            studentData.toUnassignedMap(
              uid: user.uid,
              email: user.email ?? email,
            )..['createdAt'] = FieldValue.serverTimestamp(),
          );

      // Send notification to admin
      await NotificationService.sendNewUserRegisteredNotificationToAdmin(
        newUserId: user.uid,
        newUserName: studentData.fullName,
        newUserRole: 'student',
      );

      // Initialize notification service
      await NotificationService.initialize();

      _setState(_state.copyWith(isLoading: false, user: user));
      return true;
    } catch (e) {
      final errorMessage = e.toString();
      _setState(_state.copyWith(isLoading: false, errorMessage: errorMessage));
      return false;
    }
  }

  /// Check if student is assigned to a teacher
  Future<String?> getStudentAssignedTeacherId(String uid) async {
    try {
      final doc = await _firestore.collection('students').doc(uid).get();
      return doc.data()?['assignedTeacherId'] as String?;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking student assignment: $e');
      }
      return null;
    }
  }

  /// Upload degree proof to Firebase Storage
  Future<String?> _uploadDegreeProof(
    String uid,
    TeacherData teacherData,
  ) async {
    try {
      final file = teacherData.degreeFile;
      
      // Use the centralized upload service
      final uploadService = FirebaseStorageUploadService();
      final result = await uploadService.uploadDegreeProof(
        bytes: file.bytes,
        file: file.path != null ? File(file.path!) : null,
        fileName: file.name,
        userId: uid,
      );

      if (result.success && result.downloadUrl != null) {
        if (kDebugMode) {
          print('✅ Degree proof uploaded: ${result.downloadUrl}');
        }
        return result.downloadUrl;
      } else {
        if (kDebugMode) {
          print('❌ Degree proof upload failed: ${result.errorMessage}');
        }
        _setState(_state.copyWith(
          errorMessage: result.errorMessage ?? 'Failed to upload degree proof',
        ));
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error uploading degree proof: $e');
      }
      _setState(_state.copyWith(
        errorMessage: 'Failed to upload degree proof: ${e.toString()}',
      ));
      return null;
    }
  }

  /// Register teacher with email/password and save to Firestore
  Future<bool> registerTeacher({
    required String email,
    required String password,
    required TeacherData teacherData,
  }) async {
    _setState(_state.copyWith(isLoading: true, errorMessage: null));

    try {
      // Create user with email and password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        _setState(
          _state.copyWith(isLoading: false, errorMessage: "User not created"),
        );
        return false;
      }

      // Upload degree proof
      final degreeProofUrl = await _uploadDegreeProof(user.uid, teacherData);
      if (degreeProofUrl == null) {
        _setState(
          _state.copyWith(
            isLoading: false,
            errorMessage: "Failed to upload degree proof",
          ),
        );
        return false;
      }

      // Save to Firestore teachers collection
      await _firestore
          .collection('teachers')
          .doc(user.uid)
          .set(
            teacherData.toFirestoreMap(
              uid: user.uid,
              email: user.email ?? email,
              degreeProofUrl: degreeProofUrl,
            )..['createdAt'] = Timestamp.now(),
          );

      // Save to unassigned_teachers collection
      await _firestore
          .collection('unassigned_teachers')
          .doc(user.uid)
          .set(
            teacherData.toUnassignedMap(
              uid: user.uid,
              email: user.email ?? email,
              degreeProofUrl: degreeProofUrl,
            )..['createdAt'] = FieldValue.serverTimestamp(),
          );

      // Send notification to admin
      await NotificationService.sendNewUserRegisteredNotificationToAdmin(
        newUserId: user.uid,
        newUserName: teacherData.fullName,
        newUserRole: 'teacher',
      );

      // Initialize notification service
      await NotificationService.initialize();

      _setState(_state.copyWith(isLoading: false, user: user));
      return true;
    } catch (e) {
      final errorMessage = e.toString();
      _setState(_state.copyWith(isLoading: false, errorMessage: errorMessage));
      return false;
    }
  }

  /// Check if teacher is assigned to a student
  Future<String?> getTeacherAssignedStudentId(String uid) async {
    try {
      final doc = await _firestore.collection('teachers').doc(uid).get();
      return doc.data()?['assignedStudentId'] as String?;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking teacher assignment: $e');
      }
      return null;
    }
  }
}
