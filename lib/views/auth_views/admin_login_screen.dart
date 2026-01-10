import 'package:al_mehdi_online_school/components/Custom_Textfield.dart';
import 'package:al_mehdi_online_school/components/Custom_button.dart';
import 'package:al_mehdi_online_school/providers/auth_provider.dart';
import 'package:al_mehdi_online_school/services/session_helper.dart';
import 'package:al_mehdi_online_school/views/admin_dashboard/admin_home_view.dart';
import 'package:al_mehdi_online_school/views/auth_views/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Check if admin is already logged in
    getAdminSessionFlag().then((isLoggedIn) {
      if (isLoggedIn) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigateToAdminHome();
        });
      }
    });
  }

  Future<void> _handleAdminLogin(AuthProvider authProvider) async {
    final success = await authProvider.signInAdmin(
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      await setAdminSessionFlag(true);
      await setAdminEmail(_emailController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login successful'),
          backgroundColor: Colors.green,
        ),
      );

      _navigateToAdminHome();
    } else if (authProvider.state.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(authProvider.state.errorMessage!)));
    }
  }

  void _navigateToAdminHome() async {
    await setAdminSessionFlag(true);
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => AdminHomeView()),
      (route) => false,
    );
  }

  void _goBackToLoginScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  double _getResponsiveWidth(double screenWidth) {
    if (screenWidth >= 800) return 400;
    if (screenWidth >= 600) return 350;
    return screenWidth * 0.9;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final textScale = screenWidth > 600 ? 1.2 : 1.0;
    final responsiveWidth = _getResponsiveWidth(screenWidth);

    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
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
            body: Stack(
              children: [
                SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight:
                            MediaQuery.of(context).size.height -
                            MediaQuery.of(context).padding.top -
                            kToolbarHeight -
                            20,
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
                                      keyboardType:
                                          TextInputType.visiblePassword,
                                      textInputAction: TextInputAction.done,
                                    ),
                                    const SizedBox(height: 30),
                                    CustomButton(
                                      text: 'Login',
                                      onPressed:
                                          () => _handleAdminLogin(authProvider),
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
