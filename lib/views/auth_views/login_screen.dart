import 'package:al_mehdi_online_school/components/Custom_Textfield.dart';
import 'package:al_mehdi_online_school/components/Custom_button.dart';
import 'package:al_mehdi_online_school/components/Social_Login_button.dart';
import 'package:al_mehdi_online_school/providers/auth_provider.dart';
import 'package:al_mehdi_online_school/views/admin_dashboard/unassigned_users_view/wait_for_assignment_view.dart';
import 'package:al_mehdi_online_school/views/auth_views/Main_page.dart';
import 'package:al_mehdi_online_school/views/auth_views/admin_login_screen.dart';
import 'package:al_mehdi_online_school/views/auth_views/forgot_password.dart';
import 'package:al_mehdi_online_school/views/auth_views/register_screen.dart';
import 'package:al_mehdi_online_school/views/support_screen.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Precache images to avoid jank when keyboard opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage('assets/logo/Google.png'), context);
      precacheImage(const AssetImage('assets/logo/apple.png'), context);
    });
  }

  Future<void> _handleSignIn(AuthProvider authProvider) async {
    final success = await authProvider.signInWithEmailAndPassword(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (success && mounted) {
      _navigateBasedOnAuthState(authProvider.state);
    } else if (authProvider.state.errorMessage != null && mounted) {
      _showErrorSnackBar(authProvider.state.errorMessage!);
    }
  }

  Future<void> _handleGoogleSignIn(AuthProvider authProvider) async {
    final success = await authProvider.signInWithGoogle();

    if (success && mounted) {
      _navigateBasedOnAuthState(authProvider.state);
    } else if (authProvider.state.errorMessage != null && mounted) {
      _showErrorSnackBar(authProvider.state.errorMessage!);
    }
  }

  Future<void> _handleAppleSignIn(AuthProvider authProvider) async {
    final success = await authProvider.signInWithApple();

    if (success && mounted) {
      _navigateBasedOnAuthState(authProvider.state);
    } else if (authProvider.state.errorMessage != null && mounted) {
      _showErrorSnackBar(authProvider.state.errorMessage!);
    }
  }

  void _navigateBasedOnAuthState(AuthState state) {
    if (state.isUnassigned) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  WaitForAssignmentView(role: state.userRole!.displayName),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainPage()),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
    );
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

    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
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
                          obscureText: false,
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
                          onPressed: () => _handleSignIn(authProvider),
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
                              const Text(
                                'OR',
                                style: TextStyle(color: Colors.grey),
                              ),
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
                        if (defaultTargetPlatform == TargetPlatform.android ||
                            kIsWeb)
                          SocialLoginButton(
                            imagePath: 'assets/logo/Google.png',
                            labelText: 'Continue with Google',
                            imagePadding: const EdgeInsets.only(left: 15),
                            width: responsiveWidth,
                            onPressed: () => _handleGoogleSignIn(authProvider),
                          ),
                        const SizedBox(height: 10),
                        if (defaultTargetPlatform == TargetPlatform.iOS ||
                            kIsWeb)
                          SocialLoginButton(
                            imagePath: 'assets/logo/apple.png',
                            labelText: 'Continue with Apple',
                            imagePadding: const EdgeInsets.only(left: 10),
                            width: responsiveWidth,
                            onPressed: () => _handleAppleSignIn(authProvider),
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
                if (authProvider.state.isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
