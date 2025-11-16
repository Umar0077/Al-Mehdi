import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:al_mehdi_online_school/Screens/AdminDashboard/admin_home_screen.dart';
import 'package:al_mehdi_online_school/Screens/Auth%20Screens/login_screen.dart';
import 'package:al_mehdi_online_school/components/Custom_Textfield.dart';
import 'package:al_mehdi_online_school/components/Custom_button.dart';
import 'package:al_mehdi_online_school/services/session_helper.dart';
import 'package:al_mehdi_online_school/services/notification_service.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  void _goToAdminScreen() async {
    await setAdminSessionFlag(true);
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => AdminHomeScreen()),
      (route) => false,
    );
  }

  void _goBackToLoginScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  double _getResponsiveWidth(double screenWidth) {
    if (screenWidth >= 800) return 400;
    if (screenWidth >= 600) return 350;
    return screenWidth * 0.9;
  }

  Future<void> _loginAdmin() async {
    setState(() => _isLoading = true);

    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields.');
      setState(() => _isLoading = false);
      return;
    }

    try {
      final query = await FirebaseFirestore.instance
          .collection('admin')
          .where('email', isEqualTo: email)
          .get();

      if (query.docs.isEmpty) {
        _showError('Admin email not found.');
      } else {
        final data = query.docs.first.data();

        if (data['password'] == password) {
          await setAdminSessionFlag(true);
          await setAdminEmail(email);

          try {
            await NotificationService.initialize();
            await NotificationService.saveTokenToFirestore(query.docs.first.id);
          } catch (e) {
            print('Notification init error: $e');
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login successful'),
              backgroundColor: Colors.green,
            ),
          );

          _goToAdminScreen();
        } else {
          _showError('Incorrect password.');
        }
      }
    } catch (e) {
      print('Login error: $e');
      _showError('Something went wrong. Please try again.');
    }

    setState(() => _isLoading = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void initState() {
    super.initState();
    getAdminSessionFlag().then((isLoggedIn) {
      if (isLoggedIn) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _goToAdminScreen();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final textScale = screenWidth > 600 ? 1.2 : 1.0;
    final responsiveWidth = _getResponsiveWidth(screenWidth);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBackToLoginScreen,
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height
                  - MediaQuery.of(context).padding.top
                  - kToolbarHeight
                  - 20,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 1),
                  const SizedBox(height: 30),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Welcome Admin',
                      style: TextStyle(
                        fontSize: 50 * textScale,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Login to your account',
                    style: TextStyle(
                      fontSize: 20 * textScale,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: SizedBox(
                      width: responsiveWidth,
                      child: Column(
                        children: [
                          CustomTextfield(
                            labelText: 'Email',
                            controller: _emailController,
                            width: responsiveWidth,
                            obscureText: false,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 15),
                          CustomTextfield(
                            labelText: 'Password',
                            controller: _passwordController,
                            obscureText: true,
                            width: responsiveWidth,
                            keyboardType: TextInputType.visiblePassword,
                            textInputAction: TextInputAction.done,
                          ),
                          const SizedBox(height: 30),
                          _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : CustomButton(
                                  text: 'Login',
                                  onPressed: _loginAdmin,
                                  width: responsiveWidth,
                                ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
