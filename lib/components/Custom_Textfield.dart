import 'package:flutter/material.dart';
import 'package:al_mehdi_online_school/constants/colors.dart';

class CustomTextfield extends StatelessWidget {
  final String labelText;
  final double? width;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final VoidCallback? onEditingComplete;
  final Function(String)? onChanged;

  const CustomTextfield({
    super.key,
    required this.labelText,
    this.width,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autofocus = false,
    this.onEditingComplete,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (!obscureText) {
      return SizedBox(
        width: width ?? 400,
        child: TextField(
          controller: controller,
          cursorColor: appGreen,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofocus: autofocus,
          onEditingComplete: onEditingComplete,
          onChanged: onChanged,
          // Performance optimizations
          autocorrect: false,
          enableSuggestions: false,
          smartDashesType: SmartDashesType.disabled,
          smartQuotesType: SmartQuotesType.disabled,
          decoration: InputDecoration(
            labelText: labelText,
            labelStyle: TextStyle(
              color: Theme.of(context).textTheme.displayMedium?.color,
            ),
            floatingLabelStyle: const TextStyle(color: appGreen),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color.fromARGB(255, 206, 206, 206)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: appGreen),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color.fromARGB(255, 206, 206, 206)),
            ),
          ),
        ),
      );
    }
    // For password fields, use a local stateful widget
    return _PasswordTextField(
      labelText: labelText,
      width: width,
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofocus: autofocus,
      onEditingComplete: onEditingComplete,
      onChanged: onChanged,
    );
  }
}

class _PasswordTextField extends StatefulWidget {
  final String labelText;
  final double? width;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final VoidCallback? onEditingComplete;
  final Function(String)? onChanged;

  const _PasswordTextField({
    Key? key,
    required this.labelText,
    this.width,
    this.controller,
    this.keyboardType,
    this.textInputAction,
    this.autofocus = false,
    this.onEditingComplete,
    this.onChanged,
  }) : super(key: key);

  @override
  State<_PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<_PasswordTextField> {
  bool _obscureText = true;

  void _toggleVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width ?? 400,
      child: TextField(
        controller: widget.controller,
        obscureText: _obscureText,
        cursorColor: appGreen,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        autofocus: widget.autofocus,
        onEditingComplete: widget.onEditingComplete,
        onChanged: widget.onChanged,
        // Performance optimizations
        autocorrect: false,
        enableSuggestions: false,
        smartDashesType: SmartDashesType.disabled,
        smartQuotesType: SmartQuotesType.disabled,
        decoration: InputDecoration(
          labelText: widget.labelText,
          labelStyle: TextStyle(
            color: Theme.of(context).textTheme.displayMedium?.color,
          ),
          floatingLabelStyle: const TextStyle(color: appGreen),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color.fromARGB(255, 206, 206, 206)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: appGreen),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color.fromARGB(255, 206, 206, 206)),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility_off : Icons.visibility,
              color: Theme.of(context).textTheme.displayMedium?.color,
            ),
            onPressed: _toggleVisibility,
          ),
        ),
      ),
    );
  }
}
