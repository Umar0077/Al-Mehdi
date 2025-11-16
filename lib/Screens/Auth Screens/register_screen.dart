import 'package:al_mehdi_online_school/Screens/Auth%20Screens/Students_registration.dart';
import 'package:al_mehdi_online_school/Screens/Auth%20Screens/Teachers_registration.dart';
import 'package:al_mehdi_online_school/Screens/Auth%20Screens/login_screen.dart';
import 'package:al_mehdi_online_school/components/Custom_Textfield.dart';
import 'package:al_mehdi_online_school/components/Custom_button.dart';
import 'package:al_mehdi_online_school/components/Social_Login_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../../constants/colors.dart';

class MyDropdown extends StatelessWidget {
  final String selectedRole;
  final ValueChanged<String?> onChanged;
  final double? width;

  const MyDropdown({
    super.key,
    required this.selectedRole,
    required this.onChanged,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    Color dropdownColor =
        Theme.of(context).brightness == Brightness.dark
            ? darkBackground
            : appLightGreen;

    return Container(
      width: width ?? 400,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButton<String>(
        focusColor: Colors.transparent,
        dropdownColor: dropdownColor,
        underline: const SizedBox.shrink(),
        value: selectedRole,
        onChanged: onChanged,
        items: const [
          DropdownMenuItem<String>(value: "Role", child: Text('Role')),
          DropdownMenuItem<String>(value: "Student", child: Text('Student')),
          DropdownMenuItem<String>(value: "Teacher", child: Text('Teacher')),
        ],
        isExpanded: true,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRole = "Role";
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

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Future<void> _registerAndNavigate() async {
    String fullName = _fullNameController.text.trim();
    String email = _emailController.text.trim().toLowerCase();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    if (_selectedRole == "Role") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a valid role")),
      );
      return;
    }

    if (fullName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("All fields are required")));
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    if (mounted) {
        setState(() => _isLoading = true); // Show loader
      }
    try {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              _selectedRole == "Student"
                  ? StudentsRegistration(
                      email: email,
                      role: _selectedRole,
                      fullName: fullName,
                      password: password,
                    )
                  : TeachersRegistration(
                      email: email,
                      role: _selectedRole,
                      fullName: fullName,
                      password: password,
                    ),
        ),
      );
    } finally {
      if (mounted) {
        if (mounted) {
                    setState(() => _isLoading = false);
                  } // Hide loader
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_selectedRole == "Role") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a role before continuing with Google"),
        ),
      );
      return;
    }

    if (mounted) {
        setState(() => _isLoading = true); // Show loader
      }
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => _selectedRole == "Student"
              ? StudentsRegistration(
                  email: user.email ?? '',
                  role: _selectedRole,
                  fullName: user.displayName ?? '',
                )
              : TeachersRegistration(
                  email: user.email ?? '',
                  role: _selectedRole,
                  fullName: user.displayName ?? '',
                ),
        ),
      );
    } finally {
      if (mounted) {
        if (mounted) {
                    setState(() => _isLoading = false);
                  } // Hide loader
      }
    }
  }

  Future<void> _signInWithApple() async {
    if (_selectedRole == "Role") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a role before continuing with Apple"),
        ),
      );
      return;
    }

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
      
      // Different configuration for web vs mobile
      if (kIsWeb) {
        // Web configuration
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
        // Mobile configuration
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

      // Create OAuth credential for Firebase
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      // Sign in to Firebase
      final userCredential = await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      final user = userCredential.user;

      if (user == null) return;

      // Get display name from Apple ID credential
      String displayName = '';
      if (credential.givenName != null && credential.familyName != null) {
        displayName = '${credential.givenName} ${credential.familyName}';
      } else if (user.displayName != null) {
        displayName = user.displayName!;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => _selectedRole == "Student"
              ? StudentsRegistration(
                  email: user.email ?? '',
                  role: _selectedRole,
                  fullName: displayName,
                )
              : TeachersRegistration(
                  email: user.email ?? '',
                  role: _selectedRole,
                  fullName: displayName,
                ),
        ),
      );
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
        if (mounted) {
                    setState(() => _isLoading = false);
                  } // Hide loader
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  double _getResponsiveWidth(double screenWidth) {
    if (screenWidth >= 800) return 400;
    if (screenWidth >= 600) return 350;
    return screenWidth * 0.9;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double textScale = screenWidth > 600 ? 1.2 : 1.0;
    double responsiveWidth = _getResponsiveWidth(screenWidth);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: const BackButton(),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  SizedBox(
                    width: responsiveWidth,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Create Account',
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
                    labelText: 'Full Name',
                    width: responsiveWidth,
                    controller: _fullNameController,
                    obscureText: false, // Full name field should not be obscured
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 20),
                  CustomTextfield(
                    labelText: 'Email',
                    width: responsiveWidth,
                    controller: _emailController,
                    obscureText: false, // Email field should not be obscured
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
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 20),
                  CustomTextfield(
                    labelText: 'Confirm Password',
                    width: responsiveWidth,
                    controller: _confirmPasswordController,
                    obscureText: true,
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 20),
                  MyDropdown(
                    width: responsiveWidth,
                    selectedRole: _selectedRole,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedRole = value);
                      }
                    },
                  ),
                  const SizedBox(height: 30),
                  CustomButton(
                    text: 'Next',
                    onPressed: _registerAndNavigate,
                    width: responsiveWidth,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 20),
                      const Text(
                        'Already have an account?',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 2),
                      TextButton(
                        onPressed: _navigateToLogin,
                        child: const Text(
                          'Log In',
                          style: TextStyle(
                            color: Color(0xff02D185),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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
