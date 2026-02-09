import 'package:al_mehdi_online_school/constants/colors.dart';
import 'package:flutter/material.dart';

class SocialLoginButton extends StatelessWidget {
  final String imagePath;
  final String labelText;
  final EdgeInsetsGeometry imagePadding;
  final VoidCallback onPressed;
  final double? width;

  const SocialLoginButton({
    super.key,
    required this.imagePath,
    required this.labelText,
    required this.imagePadding,
    required this.onPressed,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width ?? 400,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: appGreen),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: imagePadding,
              child: Image.asset(imagePath, width: 30, height: 30),
            ),
            const SizedBox(width: 10),
            Text(
              labelText,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
