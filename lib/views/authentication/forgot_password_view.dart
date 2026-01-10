import 'package:al_mehdi_online_school/components/custom_button.dart';
import 'package:al_mehdi_online_school/components/custom_textfield.dart';
import 'package:al_mehdi_online_school/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ForgotPasswordView extends StatefulWidget {
  final bool isFromSettings;

  const ForgotPasswordView({super.key, this.isFromSettings = false});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _emailController = TextEditingController();

  Future<void> _handleResetPassword(AuthProvider authProvider) async {
    final success = await authProvider.sendPasswordResetEmail(
      _emailController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "A password reset link has been sent to ${_emailController.text.trim()}",
          ),
        ),
      );
      // Pop back to login after a short delay
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    } else if (authProvider.state.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(authProvider.state.errorMessage!)));
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
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
            body: Stack(
              children: [
                SingleChildScrollView(
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
                              'Forgot Password',
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
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                        ),
                        const SizedBox(height: 20),
                        CustomButton(
                          text: 'Reset Password',
                          onPressed: () => _handleResetPassword(authProvider),
                          width: responsiveWidth,
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Back to Login',
                            style: TextStyle(
                              color: const Color(0xff02D185),
                              fontSize: 16 * textScale,
                            ),
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
