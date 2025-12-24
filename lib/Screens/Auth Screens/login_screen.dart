import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:al_mehdi_online_school/Screens/AdminDashboard/Unassigned%20Users%20Screens/wait_for_assignment_screen.dart';
import 'package:al_mehdi_online_school/Screens/Auth%20Screens/Main_page.dart';
import 'package:al_mehdi_online_school/Screens/Auth%20Screens/register_screen.dart';
import 'package:al_mehdi_online_school/Screens/Auth%20Screens/forgot_password.dart';
import 'package:al_mehdi_online_school/Screens/support_screen.dart';
import 'package:al_mehdi_online_school/components/Custom_Textfield.dart';
import 'package:al_mehdi_online_school/components/Custom_button.dart';
import 'package:al_mehdi_online_school/components/Social_Login_button.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:al_mehdi_online_school/Screens/Auth%20Screens/admin_login_screen.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:device_info_plus/device_info_plus.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false; // <-- Add this line

  @override
  void initState() {
    super.initState();
    // Precache images to avoid jank when keyboard opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage('assets/logo/Google.png'), context);
      precacheImage(const AssetImage('assets/logo/apple.png'), context);
    });
  }

  Future<void> signIn() async {
    if (mounted) {
      setState(() {
        _isLoading = true; // Show loader
      });
    }
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Get the current logged-in user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("No authenticated user found");

      // Check if the user is disabled
      final studentDoc =
          await FirebaseFirestore.instance.collection('students').doc(user.uid).get();
      final teacherDoc =
          await FirebaseFirestore.instance.collection('teachers').doc(user.uid).get();
      final userDoc = studentDoc.exists ? studentDoc : teacherDoc;
      if (userDoc.exists && userDoc.data()?['enabled'] == false) {
        await FirebaseAuth.instance.signOut();
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Account Disabled'),
            content: const Text('You are currently disabled. Please contact admin.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      // Check if the user is in the unassigned_students collection
      final unassignedStudentDoc =
          await FirebaseFirestore.instance
              .collection('unassigned_students')
              .doc(user.uid)
              .get();
      final unassignedTeacherDoc =
          await FirebaseFirestore.instance
              .collection('unassigned_teachers')
              .doc(user.uid)
              .get();

      // Check for unassigned student
      if (unassignedStudentDoc.exists &&
          unassignedStudentDoc['assigned'] == false) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WaitForAssignmentScreen(role: 'Student'),
          ),
        );
      } else if (unassignedTeacherDoc.exists &&
          unassignedTeacherDoc['assigned'] == false) {
        // Check for unassigned teacher
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WaitForAssignmentScreen(role: 'Teacher'),
          ),
        );
      } else {
        // Check if the user is a student or teacher and navigate accordingly
        final studentDoc =
            await FirebaseFirestore.instance
                .collection('students')
                .doc(user.uid)
                .get();
        final teacherDoc =
            await FirebaseFirestore.instance
                .collection('teachers')
                .doc(user.uid)
                .get();

        if (studentDoc.exists) {
          // If the user is a student, navigate to the student home page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MainPage(),
            ), // Replace with Student Home
          );
        } else if (teacherDoc.exists) {
          // If the user is a teacher, navigate to the teacher home page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MainPage(),
            ), // Replace with Teacher Home
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Login failed: ${e.toString()}")));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Hide loader
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final user = userCredential.user;

      if (user == null) return;

      // Check if the user is disabled
      final studentDoc = await FirebaseFirestore.instance.collection('students').doc(user.uid).get();
      final teacherDoc = await FirebaseFirestore.instance.collection('teachers').doc(user.uid).get();
      final userDoc = studentDoc.exists ? studentDoc : teacherDoc;
      if (userDoc.exists && userDoc.data()?['enabled'] == false) {
        await FirebaseAuth.instance.signOut();
        await GoogleSignIn().signOut();
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Account Disabled'),
            content: const Text('You are currently disabled. Please contact admin.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      // Check if the user is in the unassigned_students collection
      final unassignedStudentDoc =
      await FirebaseFirestore.instance
          .collection('unassigned_students')
          .doc(user.uid)
          .get();
      final unassignedTeacherDoc =
      await FirebaseFirestore.instance
          .collection('unassigned_teachers')
          .doc(user.uid)
          .get();

      if (unassignedStudentDoc.exists &&
          unassignedStudentDoc['assigned'] == false) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WaitForAssignmentScreen(role: 'Student'),
          ),
        );
      } else if (unassignedTeacherDoc.exists &&
          unassignedTeacherDoc['assigned'] == false) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WaitForAssignmentScreen(role: 'Teacher'),
          ),
        );
      } else {
        final docStudent =
        await FirebaseFirestore.instance
            .collection('students')
            .doc(user.uid)
            .get();
        final docTeacher =
        await FirebaseFirestore.instance
            .collection('teachers')
            .doc(user.uid)
            .get();

        if (!docStudent.exists && !docTeacher.exists) {
          await FirebaseAuth.instance.signOut();
          await GoogleSignIn().signOut();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Account not found. Please register first."),
            ),
          );
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainPage()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Google sign-in failed: $e")));
    }
  }

  // Add this method inside _LoginScreenState
  Future<void> _signInWithApple() async {
          if (mounted) {
        setState(() => _isLoading = true); // Show loader
      }
    try {
      // Check if we're running on iOS simulator
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        // Check if this is a simulator by attempting to detect simulator characteristics
        try {
          final deviceInfo = await DeviceInfoPlugin().iosInfo;
          if (deviceInfo.isPhysicalDevice == false) {
                              ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Apple Sign In is not fully supported in iOS Simulator. Please test on a physical device."),
                      duration: Duration(seconds: 4),
                    ),
                  );
                  if (mounted) {
                    setState(() => _isLoading = false);
                  }
                  return;
          }
        } catch (e) {
          // If we can't determine device type, continue with the flow
          print("Could not determine device type: $e");
        }
      }

      // Check if Apple Sign In is available
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Apple Sign In is not available on this platform"),
          ),
        );
        return;
      }

      late AuthorizationCredentialAppleID credential;
      if (kIsWeb) {
        credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          webAuthenticationOptions: WebAuthenticationOptions(
            clientId: 'com.almehdi.onlineschool.web', // Services ID for web
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
      if (credential.identityToken == null || credential.identityToken!.isEmpty) {
        throw Exception("Failed to get identity token from Apple");
      }

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      final user = userCredential.user;
      if (user == null) return;

      // Check if the user is disabled
      final studentDoc = await FirebaseFirestore.instance.collection('students').doc(user.uid).get();
      final teacherDoc = await FirebaseFirestore.instance.collection('teachers').doc(user.uid).get();
      final userDoc = studentDoc.exists ? studentDoc : teacherDoc;
      if (userDoc.exists && userDoc.data()?['enabled'] == false) {
        await FirebaseAuth.instance.signOut();
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Account Disabled'),
            content: const Text('You are currently disabled. Please contact admin.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      // Check if the user is in the unassigned_students collection
      final unassignedStudentDoc = await FirebaseFirestore.instance.collection('unassigned_students').doc(user.uid).get();
      final unassignedTeacherDoc = await FirebaseFirestore.instance.collection('unassigned_teachers').doc(user.uid).get();

      if (unassignedStudentDoc.exists && unassignedStudentDoc['assigned'] == false) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WaitForAssignmentScreen(role: 'Student'),
          ),
        );
      } else if (unassignedTeacherDoc.exists && unassignedTeacherDoc['assigned'] == false) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WaitForAssignmentScreen(role: 'Teacher'),
          ),
        );
      } else {
        // Check if the user is a student or teacher and navigate accordingly
        final studentDoc = await FirebaseFirestore.instance.collection('students').doc(user.uid).get();
        final teacherDoc = await FirebaseFirestore.instance.collection('teachers').doc(user.uid).get();
        if (studentDoc.exists) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MainPage(),
            ),
          );
        } else if (teacherDoc.exists) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MainPage(),
            ),
          );
        } else {
          await FirebaseAuth.instance.signOut();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Account not found. Please register first."),
            ),
          );
        }
      }
    } catch (e) {
      String errorMessage = "Apple Sign In failed";
      
      // Handle specific Apple Sign In errors
      if (e.toString().contains("1000")) {
        errorMessage = "Apple Sign In configuration error. This is common in iOS Simulator. Please test on a physical device.";
      } else if (e.toString().contains("1001")) {
        errorMessage = "Apple Sign In was cancelled by the user.";
      } else if (e.toString().contains("1002")) {
        errorMessage = "Apple Sign In failed due to invalid response.";
      } else if (e.toString().contains("1003")) {
        errorMessage = "Apple Sign In failed due to invalid user.";
      } else if (e.toString().contains("1004")) {
        errorMessage = "Apple Sign In failed due to invalid state.";
      } else if (e.toString().contains("1005")) {
        errorMessage = "Apple Sign In failed due to invalid client.";
      } else if (e.toString().contains("1006")) {
        errorMessage = "Apple Sign In failed due to invalid scope.";
      } else if (e.toString().contains("1007")) {
        errorMessage = "Apple Sign In failed due to invalid redirect URI.";
      } else if (e.toString().contains("1008")) {
        errorMessage = "Apple Sign In failed due to invalid response type.";
      } else if (e.toString().contains("1009")) {
        errorMessage = "Apple Sign In failed due to invalid grant type.";
      } else if (e.toString().contains("1010")) {
        errorMessage = "Apple Sign In failed due to invalid code.";
      } else if (e.toString().contains("AKAuthenticationError") || e.toString().contains("ASAuthorizationController")) {
        errorMessage = "Apple Sign In is not supported in iOS Simulator. Please test on a physical device for full functionality.";
      } else {
        errorMessage = "Apple Sign In failed: ${e.toString()}";
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false); // Hide loader
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  void _navigateToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgotPassword()),
    );
  }

  void _goToAdminScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
    );
  }

  void _goToSupportScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SupportScreen()),
    );
  }

  double _getResponsiveWidth(double screenWidth) {
    if (screenWidth >= 800) {
      return 400;
    } else if (screenWidth >= 600) {
      return 350;
    } else {
      return screenWidth * 0.9;
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double textScale = screenWidth > 600 ? 1.2 : 1.0;
    double responsiveWidth = _getResponsiveWidth(screenWidth);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  SizedBox(
                    width: responsiveWidth,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Welcome Back!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 50 * textScale,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  CustomTextfield(
                    labelText: 'Email',
                    width: responsiveWidth,
                    controller: _emailController,
                    obscureText: false, // Email field should not obscure text
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 20),
                  CustomTextfield(
                    labelText: 'Password',
                    width: responsiveWidth,
                    controller: _passwordController,
                    obscureText: true,
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 30),
                  CustomButton(
                    text: 'Login',
                    onPressed: signIn,
                    width: responsiveWidth,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: responsiveWidth,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: _navigateToForgotPassword,
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(color: Color(0xff02D185)),
                          ),
                        ),
                        TextButton(
                          onPressed: _navigateToRegister,
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(color: Color(0xff02D185)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: responsiveWidth,
                    child: Row(
                      children: [
                        const Expanded(
                          child: Divider(
                            color: Colors.grey,
                            thickness: 1,
                            endIndent: 10,
                          ),
                        ),
                        const Text('OR', style: TextStyle(color: Colors.grey)),
                        const Expanded(
                          child: Divider(
                            color: Colors.grey,
                            thickness: 1,
                            indent: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SocialLoginButton(
                    imagePath: 'assets/logo/Google.png',
                    labelText: 'Continue with Google',
                    imagePadding: const EdgeInsets.only(left: 15),
                    width: responsiveWidth,
                    onPressed: _signInWithGoogle,
                  ),
                  const SizedBox(height: 10),
                  SocialLoginButton(
                    imagePath: 'assets/logo/apple.png',
                    labelText: 'Continue with Apple',
                    imagePadding: const EdgeInsets.only(left: 10),
                    width: responsiveWidth,
                    onPressed: _signInWithApple,
                  ),
                  const SizedBox(height: 10),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: _goToAdminScreen,
                    child: const Text(
                      'Login as Admin',
                      style: TextStyle(color: Color(0xff02D185)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _goToSupportScreen,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.support_agent,
                          color: Color(0xff02D185),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Need Help? Contact Support',
                          style: TextStyle(color: Color(0xff02D185)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
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
