import 'package:al_mehdi_online_school/views/auth_views/Otp_verfication_Screen.dart';
import 'package:al_mehdi_online_school/components/Custom_Textfield.dart';
import 'package:al_mehdi_online_school/components/Custom_button.dart';
import 'package:flutter/material.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword({super.key});

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  void _goToOtpScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const OtpVerficationScreen()),
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
      appBar: AppBar(leading: BackButton(), elevation: 0),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Responsive "Change Password" text
              SizedBox(
                width: responsiveWidth,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Change Password',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 50 * textScale,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              CustomTextfield(labelText: 'Email', width: responsiveWidth),

              const SizedBox(height: 20),

              CustomButton(
                text: 'Send OTP Code',
                onPressed: _goToOtpScreen,
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
    );
  }
}
