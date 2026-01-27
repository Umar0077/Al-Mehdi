import 'dart:io';

import 'package:al_mehdi_online_school/models/oauth_user_data.dart';
import 'package:al_mehdi_online_school/models/student_data.dart';
import 'package:al_mehdi_online_school/models/teacher_data.dart';
import 'package:al_mehdi_online_school/models/user_role.dart';
import 'package:al_mehdi_online_school/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
  final Map<String, dynamic>? oauthSignupData; // OAuth data for signup flow
  final bool needsSignup; // Flag to indicate user needs to complete signup

  const AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.user,
    this.userRole,
    this.isUnassigned = false,
    this.adminId,
    this.oauthSignupData,
    this.needsSignup = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    User? user,
    UserRole? userRole,
    bool? isUnassigned,
    String? adminId,
    Map<String, dynamic>? oauthSignupData,
    bool? needsSignup,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      user: user ?? this.user,
      userRole: userRole ?? this.userRole,
      isUnassigned: isUnassigned ?? this.isUnassigned,
      adminId: adminId ?? this.adminId,
      oauthSignupData: oauthSignupData,
      needsSignup: needsSignup ?? this.needsSignup,
    );
  }
}

/// Provider for handling authentication logic
class AuthProvider extends ChangeNotifier {
  AuthState _state = const AuthState();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // iOS client ID from GoogleService-Info.plist
    // For web, specify the OAuth 2.0 Client ID that can issue ID tokens
    clientId:
        kIsWeb
            ? '295791005487-tjq0itcgalq9mg2jbkb39jrp0hs9k7a5.apps.googleusercontent.com' // Web OAuth client ID
            : (Platform.isIOS
                ? '295791005487-epsbj47r76kp3id081iaj921thttjduc.apps.googleusercontent.com'
                : null),
  );

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

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    _setState(_state.copyWith(isLoading: true, errorMessage: null));

    try {
      late UserCredential userCredential;
      late User? user;
      String fullName = '';

      if (kIsWeb) {
        // On web, use Firebase's signInWithPopup for better ID token handling
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');

        userCredential = await _auth.signInWithPopup(googleProvider);
        user = userCredential.user;

        if (user != null) {
          // Get name from Firebase user
          fullName = user.displayName ?? '';
        }
      } else {
        // On native platforms, use google_sign_in package
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          _setState(_state.copyWith(isLoading: false));
          return false;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        if (kDebugMode) {
          print('🔑 Google Auth Tokens Debug:');
          print(
            '  accessToken: ${googleAuth.accessToken != null ? "present" : "null"}',
          );
          print(
            '  idToken: ${googleAuth.idToken != null ? "present" : "null"}',
          );
        }

        // Ensure we have the required idToken
        if (googleAuth.idToken == null || googleAuth.idToken!.isEmpty) {
          if (kDebugMode) {
            print('❌ No idToken received from Google Sign-In');
          }
          _setState(
            _state.copyWith(
              isLoading: false,
              errorMessage:
                  'Failed to authenticate with Google. Please try again.',
            ),
          );
          return false;
        }

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
        user = userCredential.user;

        if (user != null) {
          // Get full name from GoogleSignInAccount (most reliable on native)
          fullName = googleUser.displayName ?? user.displayName ?? '';
        }
      }

      if (user == null) {
        _setState(_state.copyWith(isLoading: false));
        return false;
      }

      // Check user status and get role
      final result = await _checkUserStatusAndRole(user.uid);

      if (!result['success']) {
        // Check if it's an "Account not found" error
        if (result['message'] == 'Account not found. Please register first.') {
          // Don't sign out, instead prepare data for signup
          final oauthData = {
            'email': user.email ?? '',
            'fullName': fullName,
            'provider': 'google',
            'uid': user.uid,
          };

          _setState(
            _state.copyWith(
              isLoading: false,
              user: user,
              oauthSignupData: oauthData,
              needsSignup: true,
            ),
          );
          return false; // Still return false but with signup data
        }

        // For other errors (like disabled account), sign out
        await _auth.signOut();
        if (!kIsWeb) {
          await _googleSignIn.signOut();
        }
        _setState(
          _state.copyWith(isLoading: false, errorMessage: result['message']),
        );
        return false;
      }

      // Save Google OAuth data for future reference
      await _saveOAuthUserData(
        uid: user.uid,
        email: user.email ?? '',
        fullName: fullName,
        provider: 'google',
      );

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
    } on PlatformException catch (e) {
      String errorMessage = 'Google sign-in failed';

      if (e.code == 'sign_in_failed') {
        errorMessage =
            'Google sign-in failed. Please check your configuration.';
      } else if (e.code == 'network_error') {
        errorMessage = 'Network error. Please check your connection.';
      } else if (e.code == 'sign_in_canceled') {
        errorMessage = 'Sign in was cancelled';
      }

      if (kDebugMode) {
        print('Google Sign-In PlatformException: ${e.code} - ${e.message}');
      }

      _setState(_state.copyWith(isLoading: false, errorMessage: errorMessage));
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Google Sign-In Error: ${e.toString()}');
        if (kIsWeb) {
          print(
            'Web Platform - This error can be ignored if it\'s about gapi.client',
          );
        }
      }

      // Check if it's just a gapi.client warning (harmless on web)
      String errorMessage = 'Google sign-in failed. Please try again.';
      if (e.toString().contains('gapi.client')) {
        errorMessage =
            'Google sign-in configuration issue. Please refresh and try again.';
      }

      _setState(_state.copyWith(isLoading: false, errorMessage: errorMessage));
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
        // Check if it's an "Account not found" error
        if (result['message'] == 'Account not found. Please register first.') {
          // Don't sign out, instead prepare data for signup
          String displayName = '';

          if (kDebugMode) {
            print('🍎 Apple Sign-In (New User) Debug:');
            print('  givenName: ${credential.givenName}');
            print('  familyName: ${credential.familyName}');
            print('  user.displayName: ${user.displayName}');
          }

          // First, try Apple credential (only available on first sign-in)
          if (credential.givenName != null && credential.familyName != null) {
            displayName = '${credential.givenName} ${credential.familyName}';
            if (kDebugMode) print('  ✅ Got name from Apple credential');
          }
          // Second, try stored OAuth data (critical for subsequent sign-ins)
          if (displayName.isEmpty) {
            final storedOAuthData = await getOAuthUserData(user.uid);
            if (storedOAuthData != null &&
                storedOAuthData.fullName.isNotEmpty) {
              displayName = storedOAuthData.fullName;
              if (kDebugMode) print('  ✅ Got name from stored OAuth data');
            }
          }
          // Third, try Firebase user displayName as final fallback
          if (displayName.isEmpty && user.displayName != null) {
            displayName = user.displayName!;
            if (kDebugMode) print('  ✅ Got name from Firebase user');
          }

          if (kDebugMode) {
            print('  Final displayName for signup: "$displayName"');
          }

          final oauthData = {
            'email': user.email ?? '',
            'fullName': displayName,
            'provider': 'apple',
            'uid': user.uid,
            'appleUserId': credential.userIdentifier,
          };

          _setState(
            _state.copyWith(
              isLoading: false,
              user: user,
              oauthSignupData: oauthData,
              needsSignup: true,
            ),
          );
          return false; // Still return false but with signup data
        }

        // For other errors (like disabled account), sign out
        await _auth.signOut();
        _setState(
          _state.copyWith(isLoading: false, errorMessage: result['message']),
        );
        return false;
      }

      // For Apple sign-in, save/update OAuth data with the best available name
      String displayName = '';

      if (kDebugMode) {
        print('🍎 Apple Sign-In (Existing User) Debug:');
        print('  givenName: ${credential.givenName}');
        print('  familyName: ${credential.familyName}');
        print('  user.displayName: ${user.displayName}');
      }

      // First, try Apple credential (only available on first sign-in)
      if (credential.givenName != null && credential.familyName != null) {
        displayName = '${credential.givenName} ${credential.familyName}';
        if (kDebugMode) print('  ✅ Got name from Apple credential');
      }
      // Second, try stored OAuth data (don't overwrite with empty)
      if (displayName.isEmpty) {
        final storedOAuthData = await getOAuthUserData(user.uid);
        if (storedOAuthData != null && storedOAuthData.fullName.isNotEmpty) {
          displayName = storedOAuthData.fullName;
          if (kDebugMode) print('  ✅ Got name from stored OAuth data');
        }
      }
      // Third, try Firebase user displayName as final fallback
      if (displayName.isEmpty && user.displayName != null) {
        displayName = user.displayName!;
        if (kDebugMode) print('  ✅ Got name from Firebase user');
      }

      if (kDebugMode) {
        print('  Final displayName: "$displayName"');
      }

      // Save/update OAuth data
      await _saveOAuthUserData(
        uid: user.uid,
        email: user.email ?? '',
        fullName: displayName,
        provider: 'apple',
        appleUserId: credential.userIdentifier,
      );

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

  /// Sign out - checks provider and signs out properly
  Future<void> signOut() async {
    try {
      final user = _auth.currentUser;

      if (user != null) {
        // Check which provider the user is using
        bool isGoogleUser = false;
        bool isAppleUser = false;

        for (final providerInfo in user.providerData) {
          if (providerInfo.providerId == 'google.com') {
            isGoogleUser = true;
          } else if (providerInfo.providerId == 'apple.com') {
            isAppleUser = true;
          }
        }

        // Sign out from specific provider
        if (isGoogleUser) {
          try {
            await _googleSignIn.signOut();
            if (kDebugMode) {
              print('✅ Signed out from Google');
            }
          } catch (e) {
            if (kDebugMode) {
              print('⚠️ Error signing out from Google: $e');
            }
          }
        }

        // Note: Apple Sign In doesn't require explicit sign out
        // The token is revoked when Firebase Auth signs out
        if (isAppleUser && kDebugMode) {
          print('✅ Signing out from Apple (via Firebase)');
        }

        if (!isGoogleUser && !isAppleUser && kDebugMode) {
          print('✅ Signing out from email/password');
        }
      }

      // Always sign out from Firebase Auth
      await _auth.signOut();
      _setState(const AuthState());

      if (kDebugMode) {
        print('✅ Successfully signed out from all providers');
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
      late UserCredential userCredential;
      late User? user;
      String fullName = '';

      if (kIsWeb) {
        // On web, use Firebase's signInWithPopup for better ID token handling
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');

        userCredential = await _auth.signInWithPopup(googleProvider);
        user = userCredential.user;

        if (user != null) {
          // Get name from Firebase user
          fullName = user.displayName ?? '';
        }
      } else {
        // On native platforms, use google_sign_in package
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          _setState(_state.copyWith(isLoading: false));
          return null;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        if (kDebugMode) {
          print('🔑 Google Auth Tokens Debug (Registration):');
          print(
            '  accessToken: ${googleAuth.accessToken != null ? "present" : "null"}',
          );
          print(
            '  idToken: ${googleAuth.idToken != null ? "present" : "null"}',
          );
        }

        // Ensure we have the required idToken
        if (googleAuth.idToken == null || googleAuth.idToken!.isEmpty) {
          if (kDebugMode) {
            print('❌ No idToken received from Google Sign-In');
          }
          _setState(
            _state.copyWith(
              isLoading: false,
              errorMessage:
                  'Failed to authenticate with Google. Please try again.',
            ),
          );
          return null;
        }

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
        user = userCredential.user;

        if (user != null) {
          // Get full name from GoogleSignInAccount (most reliable on native)
          fullName = googleUser.displayName ?? user.displayName ?? '';
        }
      }

      if (user == null) {
        _setState(_state.copyWith(isLoading: false));
        return null;
      }

      // Check if user already exists in students or teachers collection
      final studentDoc =
          await _firestore.collection('students').doc(user.uid).get();
      final teacherDoc =
          await _firestore.collection('teachers').doc(user.uid).get();

      if (studentDoc.exists || teacherDoc.exists) {
        // User already registered - sign them out and show error
        await _auth.signOut();
        if (!kIsWeb) {
          await _googleSignIn.signOut();
        }
        _setState(
          _state.copyWith(
            isLoading: false,
            errorMessage:
                'This account is already registered. Please use the login screen to sign in.',
          ),
        );
        return null;
      }

      // Get full name - prioritize what we already have, then stored OAuth data
      if (fullName.isEmpty) {
        final storedOAuthData = await getOAuthUserData(user.uid);
        if (storedOAuthData != null && storedOAuthData.fullName.isNotEmpty) {
          fullName = storedOAuthData.fullName;
        }
      }

      // Save OAuth data to Firestore for future reference
      await _saveOAuthUserData(
        uid: user.uid,
        email: user.email ?? '',
        fullName: fullName,
        provider: 'google',
      );

      _setState(_state.copyWith(isLoading: false));

      return {
        'email': user.email ?? '',
        'fullName': fullName,
        'uid': user.uid,
        'provider': 'google',
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

      // Check if user already exists in students or teachers collection
      final studentDoc =
          await _firestore.collection('students').doc(user.uid).get();
      final teacherDoc =
          await _firestore.collection('teachers').doc(user.uid).get();

      if (studentDoc.exists || teacherDoc.exists) {
        // User already registered - sign them out and show error
        await _auth.signOut();
        _setState(
          _state.copyWith(
            isLoading: false,
            errorMessage:
                'This account is already registered. Please use the login screen to sign in.',
          ),
        );
        return null;
      }

      // Get display name from Apple ID credential, stored data, or Firebase user
      String displayName = '';

      if (kDebugMode) {
        print('🍎 Apple Registration Debug:');
        print('  givenName: ${credential.givenName}');
        print('  familyName: ${credential.familyName}');
        print('  user.displayName: ${user.displayName}');
        print('  email: ${credential.email}');
      }

      // First, try to get from Apple credential (only available on first sign-in)
      if (credential.givenName != null && credential.familyName != null) {
        displayName = '${credential.givenName} ${credential.familyName}';
        if (kDebugMode) print('  ✅ Got name from Apple credential');
      }
      // Second, try stored OAuth data (critical for subsequent sign-ins)
      if (displayName.isEmpty) {
        final storedOAuthData = await getOAuthUserData(user.uid);
        if (storedOAuthData != null && storedOAuthData.fullName.isNotEmpty) {
          displayName = storedOAuthData.fullName;
          if (kDebugMode) print('  ✅ Got name from stored OAuth data');
        }
      }
      // Third, try Firebase user displayName as final fallback
      if (displayName.isEmpty && user.displayName != null) {
        displayName = user.displayName!;
        if (kDebugMode) print('  ✅ Got name from Firebase user');
      }

      if (kDebugMode) {
        print('  Final displayName: "$displayName"');
      }

      // Save OAuth data to Firestore for future reference
      // This is critical because Apple may not return name/email on subsequent logins
      await _saveOAuthUserData(
        uid: user.uid,
        email: user.email ?? '',
        fullName: displayName,
        provider: 'apple',
        appleUserId: credential.userIdentifier,
      );

      _setState(_state.copyWith(isLoading: false));

      return {
        'email': user.email ?? '',
        'fullName': displayName,
        'uid': user.uid,
        'provider': 'apple',
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

  /// Save OAuth user data (Apple/Google) to Firestore
  /// This persists name and email for future logins when provider may not return them
  Future<void> _saveOAuthUserData({
    required String uid,
    required String email,
    required String fullName,
    required String provider,
    String? appleUserId,
  }) async {
    try {
      final now = DateTime.now();
      final oauthData = OAuthUserData(
        uid: uid,
        email: email,
        fullName: fullName,
        provider: provider,
        appleUserId: appleUserId,
        createdAt: now,
        lastUpdatedAt: now,
      );

      // Check if OAuth data already exists
      final existingDoc =
          await _firestore.collection('oauth_users').doc(uid).get();

      if (existingDoc.exists) {
        // Update only if we have new data (name or email is not empty)
        if (fullName.isNotEmpty || email.isNotEmpty) {
          await _firestore.collection('oauth_users').doc(uid).update({
            if (fullName.isNotEmpty) 'fullName': fullName,
            if (email.isNotEmpty) 'email': email,
            'lastUpdatedAt': now,
          });
        }
      } else {
        // Create new OAuth data document
        await _firestore
            .collection('oauth_users')
            .doc(uid)
            .set(oauthData.toFirestore());
      }

      if (kDebugMode) {
        print('✅ Saved OAuth data for $provider user: $uid');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving OAuth user data: $e');
      }
    }
  }

  /// Get OAuth user data from Firestore
  /// Returns stored name and email for Apple/Google users
  Future<OAuthUserData?> getOAuthUserData(String uid) async {
    try {
      final doc = await _firestore.collection('oauth_users').doc(uid).get();

      if (!doc.exists) {
        return null;
      }

      return OAuthUserData.fromFirestore(doc.data()!);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error retrieving OAuth user data: $e');
      }
      return null;
    }
  }

  /// Get signup method for current user
  /// Returns 'manual', 'google', or 'apple'
  Future<String> getSignupMethod(String uid) async {
    try {
      // Check if user has OAuth data stored
      final oauthData = await getOAuthUserData(uid);
      if (oauthData != null) {
        return oauthData.provider;
      }

      // Fallback: check providerData from Firebase Auth
      final user = _auth.currentUser;
      if (user != null) {
        for (final provider in user.providerData) {
          if (provider.providerId == 'google.com') {
            return 'google';
          } else if (provider.providerId == 'apple.com') {
            return 'apple';
          }
        }
      }

      // Default to manual if no OAuth provider found
      return 'manual';
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting signup method: $e');
      }
      return 'manual';
    }
  }
}
