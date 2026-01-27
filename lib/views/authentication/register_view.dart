import 'package:al_mehdi_online_school/components/custom_button.dart';
import 'package:al_mehdi_online_school/components/custom_textfield.dart';
import 'package:al_mehdi_online_school/components/social_login_button.dart';
import 'package:al_mehdi_online_school/providers/auth/auth_provider.dart';
import 'package:al_mehdi_online_school/views/authentication/login_view.dart';
import 'package:al_mehdi_online_school/views/authentication/student_registeration_view.dart';
import 'package:al_mehdi_online_school/views/authentication/teacher_registration_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  final Map<String, dynamic>? oauthData;

  const RegisterScreen({super.key, this.oauthData});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRole = "Role";
  bool _isOAuthSignup = false;

  @override
  void initState() {
    super.initState();

    // Check if this is OAuth signup and pre-fill fields
    if (widget.oauthData != null) {
      _isOAuthSignup = true;
      _emailController.text = widget.oauthData!['email'] ?? '';
      _fullNameController.text = widget.oauthData!['fullName'] ?? '';
      // For OAuth, we don't need password fields

      if (kDebugMode) {
        print('📝 RegisterScreen - OAuth Data Received:');
        print('  Email: ${widget.oauthData!['email']}');
        print('  Full Name: ${widget.oauthData!['fullName']}');
        print('  Provider: ${widget.oauthData!['provider']}');
      }
    } else {
      if (kDebugMode) {
        print('📝 RegisterScreen - No OAuth data (manual registration)');
      }
    }

    // Precache images to avoid jank when keyboard opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage('assets/logo/Google.png'), context);
      precacheImage(const AssetImage('assets/logo/apple.png'), context);
    });
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginView()),
    );
  }

  void _handleRegistration(AuthProvider authProvider) {
    // For OAuth signup, we don't need password validation
    if (_isOAuthSignup) {
      if (_selectedRole == "Role") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a role to continue")),
        );
        return;
      }

      // Navigate directly to registration form with OAuth data
      _navigateToRegistrationForm(
        email: _emailController.text.trim().toLowerCase(),
        fullName: _fullNameController.text.trim(),
      );
      return;
    }

    // For regular email/password signup
    final isValid = authProvider.validateRegistrationFields(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim().toLowerCase(),
      password: _passwordController.text.trim(),
      confirmPassword: _confirmPasswordController.text.trim(),
      role: _selectedRole,
    );

    if (!isValid) {
      if (authProvider.state.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.state.errorMessage!)),
        );
      }
      return;
    }

    _navigateToRegistrationForm(
      email: _emailController.text.trim().toLowerCase(),
      fullName: _fullNameController.text.trim(),
      password: _passwordController.text.trim(),
    );
  }

  Future<void> _handleGoogleRegistration(AuthProvider authProvider) async {
    if (_selectedRole == "Role") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a role before continuing with Google"),
        ),
      );
      return;
    }

    final userData = await authProvider.registerWithGoogle();

    if (!mounted) return;

    if (userData != null) {
      _navigateToRegistrationForm(
        email: userData['email'] ?? '',
        fullName: userData['fullName'] ?? '',
      );
    } else if (authProvider.state.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(authProvider.state.errorMessage!)));
    }
  }

  Future<void> _handleAppleRegistration(AuthProvider authProvider) async {
    if (_selectedRole == "Role") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a role before continuing with Apple"),
        ),
      );
      return;
    }

    final userData = await authProvider.registerWithApple();

    if (!mounted) return;

    if (userData != null) {
      _navigateToRegistrationForm(
        email: userData['email'] ?? '',
        fullName: userData['fullName'] ?? '',
      );
    } else if (authProvider.state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.state.errorMessage!),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _navigateToRegistrationForm({
    required String email,
    required String fullName,
    String? password,
  }) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
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

    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              leading: const BackButton(),
              centerTitle: true,
              elevation: 0,
            ),
            body: SafeArea(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 24.0),
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
                            obscureText:
                                false, // Full name field should not be obscured
                            keyboardType: TextInputType.name,
                            textInputAction: TextInputAction.next,
                            enabled: !_isOAuthSignup, // Disable for OAuth
                          ),
                          const SizedBox(height: 20),
                          CustomTextfield(
                            labelText: 'Email',
                            width: responsiveWidth,
                            controller: _emailController,
                            obscureText:
                                false, // Email field should not be obscured
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            enabled: !_isOAuthSignup, // Disable for OAuth
                          ),
                          // Only show password fields for non-OAuth signup
                          if (!_isOAuthSignup) ...[
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
                          ],
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
                          // Show OAuth info message if coming from social login
                          if (_isOAuthSignup) ...[
                            Container(
                              width: responsiveWidth,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xff02D185).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(
                                    0xff02D185,
                                  ).withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    color: Color(0xff02D185),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Complete your ${widget.oauthData?['provider'] == 'google' ? 'Google' : 'Apple'} signup by selecting your role',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xff02D185),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          CustomButton(
                            text: 'Next',
                            onPressed: () => _handleRegistration(authProvider),
                            width: responsiveWidth,
                          ),
                          // Only show social login buttons for non-OAuth signups
                          if (!_isOAuthSignup) ...[
                            const SizedBox(height: 20),

                            SocialLoginButton(
                              imagePath: 'assets/logo/Google.png',
                              labelText: 'Continue with Google',
                              imagePadding: const EdgeInsets.only(left: 15),
                              width: responsiveWidth,
                              onPressed:
                                  () => _handleGoogleRegistration(authProvider),
                            ),
                            const SizedBox(height: 10),
                            if (defaultTargetPlatform == TargetPlatform.iOS ||
                                kIsWeb)
                              SocialLoginButton(
                                imagePath: 'assets/logo/apple.png',
                                labelText: 'Continue with Apple',
                                imagePadding: const EdgeInsets.only(left: 10),
                                width: responsiveWidth,
                                onPressed:
                                    () =>
                                        _handleAppleRegistration(authProvider),
                              ),
                            const SizedBox(height: 10),
                          ] else
                            const SizedBox(height: 20),
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
                  if (authProvider.state.isLoading)
                    Container(
                      color: Colors.black.withOpacity(0.3),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
