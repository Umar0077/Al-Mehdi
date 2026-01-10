import 'dart:io';

import 'package:al_mehdi_online_school/models/student_data.dart';
import 'package:al_mehdi_online_school/models/teacher_data.dart';
import 'package:al_mehdi_online_school/models/user_role.dart';
import 'package:al_mehdi_online_school/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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
      String message = 'Login failed';
      if (e.code == 'user-not-found') {
        message = 'No user found with this email';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      } else {
        message = e.message ?? 'Login failed';
      }

      _setState(_state.copyWith(isLoading: false, errorMessage: message));
      return false;
    } catch (e) {
      _setState(_state.copyWith(isLoading: false, errorMessage: e.toString()));
      return false;
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    _setState(_state.copyWith(isLoading: true, errorMessage: null));

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _setState(_state.copyWith(isLoading: false));
        return false;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        _setState(_state.copyWith(isLoading: false));
        return false;
      }

      // Check user status and get role
      final result = await _checkUserStatusAndRole(user.uid);

      if (!result['success']) {
        await _auth.signOut();
        await _googleSignIn.signOut();
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
    } catch (e) {
      _setState(
        _state.copyWith(
          isLoading: false,
          errorMessage: 'Google sign-in failed: ${e.toString()}',
        ),
      );
      return false;
    }
  }

  /// Sign in with Apple
  Future<bool> signInWithApple() async {
    _setState(_state.copyWith(isLoading: true, errorMessage: null));

    try {
      // Check if running on iOS simulator
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        try {
          final deviceInfo = await DeviceInfoPlugin().iosInfo;
          if (!deviceInfo.isPhysicalDevice) {
            _setState(
              _state.copyWith(
                isLoading: false,
                errorMessage:
                    "Apple Sign In is not fully supported in iOS Simulator. Please test on a physical device.",
              ),
            );
            return false;
          }
        } catch (e) {
          if (kDebugMode) {
            print("Could not determine device type: $e");
          }
        }
      }

      // Check if Apple Sign In is available
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        _setState(
          _state.copyWith(
            isLoading: false,
            errorMessage: "Apple Sign In is not available on this platform",
          ),
        );
        return false;
      }

      // Get Apple credentials
      late AuthorizationCredentialAppleID credential;
      if (kIsWeb) {
        credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          webAuthenticationOptions: WebAuthenticationOptions(
            clientId: 'com.almehdi.onlineschool.web',
            redirectUri: Uri.parse(
              'https://sample-firebase-ai-app-456c6.firebaseapp.com/__/auth/handler',
            ),
          ),
        );
      } else {
        credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
        );
      }

      // Check if we have valid tokens
      if (credential.identityToken == null ||
          credential.identityToken!.isEmpty) {
        throw Exception("Failed to get identity token from Apple");
      }

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);
      final user = userCredential.user;

      if (user == null) {
        _setState(_state.copyWith(isLoading: false));
        return false;
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
    } catch (e) {
      String errorMessage = _parseAppleSignInError(e);
      _setState(_state.copyWith(isLoading: false, errorMessage: errorMessage));
      return false;
    }
  }

  /// Parse Apple Sign In errors
  String _parseAppleSignInError(dynamic error) {
    final errorStr = error.toString();

    if (errorStr.contains("1000")) {
      return "Apple Sign In configuration error. This is common in iOS Simulator. Please test on a physical device.";
    } else if (errorStr.contains("1001")) {
      return "Apple Sign In was cancelled by the user.";
    } else if (errorStr.contains("AKAuthenticationError") ||
        errorStr.contains("ASAuthorizationController")) {
      return "Apple Sign In is not supported in iOS Simulator. Please test on a physical device for full functionality.";
    }

    return "Apple Sign In failed: $errorStr";
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
    await _auth.signOut();
    await _googleSignIn.signOut();
    _setState(const AuthState());
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

    if (email.trim().isEmpty || password.trim().isEmpty) {
      _setState(
        _state.copyWith(
          isLoading: false,
          errorMessage: 'Please fill in all fields.',
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

  /// Register with Google (for new users)
  Future<Map<String, dynamic>?> registerWithGoogle() async {
    _setState(_state.copyWith(isLoading: true, errorMessage: null));

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _setState(_state.copyWith(isLoading: false));
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        _setState(_state.copyWith(isLoading: false));
        return null;
      }

      _setState(_state.copyWith(isLoading: false));

      return {
        'email': user.email ?? '',
        'fullName': user.displayName ?? '',
        'uid': user.uid,
      };
    } catch (e) {
      _setState(
        _state.copyWith(
          isLoading: false,
          errorMessage: 'Google sign-in failed: ${e.toString()}',
        ),
      );
      return null;
    }
  }

  /// Register with Apple (for new users)
  Future<Map<String, dynamic>?> registerWithApple() async {
    _setState(_state.copyWith(isLoading: true, errorMessage: null));

    try {
      // Check if running on iOS simulator
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        try {
          final deviceInfo = await DeviceInfoPlugin().iosInfo;
          if (!deviceInfo.isPhysicalDevice) {
            _setState(
              _state.copyWith(
                isLoading: false,
                errorMessage:
                    "Apple Sign In is not fully supported in iOS Simulator. Please test on a physical device.",
              ),
            );
            return null;
          }
        } catch (e) {
          if (kDebugMode) {
            print("Could not determine device type: $e");
          }
        }
      }

      // Check if Apple Sign In is available
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        _setState(
          _state.copyWith(
            isLoading: false,
            errorMessage: "Apple Sign In is not available on this platform",
          ),
        );
        return null;
      }

      // Get Apple credentials
      late AuthorizationCredentialAppleID credential;
      if (kIsWeb) {
        credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          webAuthenticationOptions: WebAuthenticationOptions(
            clientId: 'com.almehdi.onlineschool.web',
            redirectUri: Uri.parse(
              'https://sample-firebase-ai-app-456c6.firebaseapp.com/__/auth/handler',
            ),
          ),
        );
      } else {
        credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
        );
      }

      // Check if we have valid tokens
      if (credential.identityToken == null ||
          credential.identityToken!.isEmpty) {
        throw Exception("Failed to get identity token from Apple");
      }

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);
      final user = userCredential.user;

      if (user == null) {
        _setState(_state.copyWith(isLoading: false));
        return null;
      }

      // Get display name from Apple ID credential
      String displayName = '';
      if (credential.givenName != null && credential.familyName != null) {
        displayName = '${credential.givenName} ${credential.familyName}';
      } else if (user.displayName != null) {
        displayName = user.displayName!;
      }

      _setState(_state.copyWith(isLoading: false));

      return {
        'email': user.email ?? '',
        'fullName': displayName,
        'uid': user.uid,
      };
    } catch (e) {
      String errorMessage = _parseAppleSignInError(e);
      _setState(_state.copyWith(isLoading: false, errorMessage: errorMessage));
      return null;
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

    if (fullName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _setState(_state.copyWith(errorMessage: "All fields are required"));
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

  /// Register student with existing Google/Apple account
  Future<bool> registerStudentWithSocial({
    required StudentData studentData,
  }) async {
    _setState(_state.copyWith(isLoading: true, errorMessage: null));

    try {
      // User should already be signed in from Google/Apple
      final user = _auth.currentUser;
      if (user == null) {
        _setState(
          _state.copyWith(
            isLoading: false,
            errorMessage: "User not authenticated",
          ),
        );
        return false;
      }

      // Save to Firestore students collection
      await _firestore
          .collection('students')
          .doc(user.uid)
          .set(
            studentData.toFirestoreMap(uid: user.uid, email: user.email ?? '')
              ..['createdAt'] = FieldValue.serverTimestamp(),
          );

      // Save to unassigned_students collection
      await _firestore
          .collection('unassigned_students')
          .doc(user.uid)
          .set(
            studentData.toUnassignedMap(uid: user.uid, email: user.email ?? '')
              ..['createdAt'] = FieldValue.serverTimestamp(),
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
      final storageRef = FirebaseStorage.instance.ref().child(
        'degree_proofs/$uid/${file.name}',
      );
      final metadata = SettableMetadata(contentDisposition: 'inline');

      UploadTask uploadTask;
      if (file.bytes != null) {
        uploadTask = storageRef.putData(file.bytes!, metadata);
      } else if (file.path != null) {
        uploadTask = storageRef.putFile(File(file.path!), metadata);
      } else {
        return null;
      }

      final snapshot = await uploadTask.whenComplete(() {});
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading degree proof: $e');
      }
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

  /// Register teacher with existing Google/Apple account
  Future<bool> registerTeacherWithSocial({
    required TeacherData teacherData,
  }) async {
    _setState(_state.copyWith(isLoading: true, errorMessage: null));

    try {
      // User should already be signed in from Google/Apple
      final user = _auth.currentUser;
      if (user == null) {
        _setState(
          _state.copyWith(
            isLoading: false,
            errorMessage: "User not authenticated",
          ),
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
              email: user.email ?? '',
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
              email: user.email ?? '',
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
