import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../constants/colors.dart';

class TextFields extends StatelessWidget {
  final String label;
  final int maxLines;
  final IconData? icon;
  final bool isDatePicker;
  final bool isTimePicker;
  final TextEditingController? controller;
  final String? value;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  const TextFields({
    super.key,
    required this.label,
    this.maxLines = 1,
    this.icon,
    this.isDatePicker = false,
    this.isTimePicker = false,
    this.controller,
    this.value,
    this.onChanged,
    this.keyboardType,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController internalController =
        controller ?? TextEditingController(text: value ?? '');

    // Keep controller in sync with value
    if (internalController.text != (value ?? '')) {
      internalController.text = value ?? '';
      internalController.selection = TextSelection.fromPosition(
        TextPosition(offset: internalController.text.length),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputTextColor = isDark ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: (isDatePicker || isTimePicker)
          ? () async {
              FocusScope.of(context).unfocus(); // Hide keyboard

              if (isDatePicker) {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                  builder: (BuildContext context, Widget? child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: appGreen,
                          onPrimary: Color(0xFFe5faf3),
                          onSurface: Colors.black,
                        ),
                        textButtonTheme: TextButtonThemeData(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.green,
                          ),
                        ),
                        dialogTheme: const DialogThemeData(backgroundColor: Color(0xFFe5faf3)),
                      ),
                      child: child!,
                    );
                  },
                );
                if (pickedDate != null) {
                  final formatted = DateFormat('MM/dd/yyyy').format(pickedDate);
                  internalController.text = formatted;
                  if (onChanged != null) onChanged!(formatted);
                }
              }

              if (isTimePicker) {
                TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                  builder: (BuildContext context, Widget? child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: appGreen,
                          onPrimary: Color(0xFFe5faf3),
                          onSurface: Colors.black,
                        ),
                        textButtonTheme: TextButtonThemeData(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.green,
                          ),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (pickedTime != null) {
                  final now = DateTime.now();
                  final time = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    pickedTime.hour,
                    pickedTime.minute,
                  );
                  final formatted = DateFormat('hh:mm a').format(time);
                  internalController.text = formatted;
                  if (onChanged != null) onChanged!(formatted);
                }
              }
            }
          : null,
      child: AbsorbPointer(
        absorbing: isDatePicker || isTimePicker,
        child: TextField(
          cursorColor: appGreen,
          controller: internalController,
          maxLines: maxLines,
          style: TextStyle(fontSize: 15, color: inputTextColor),
          onChanged: onChanged,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          decoration: InputDecoration(
            label: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            floatingLabelStyle: TextStyle(
              color: isDark ? Colors.white : appGreen,
            ),
            prefixIcon: icon != null ? Icon(icon, color: appGreen) : null,
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.grey),
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: appGreen),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }
}

class DropdownField extends StatelessWidget {
  final String label;
  final List<String> options;
  final String? value;
  final ValueChanged<String?>? onChanged;

  const DropdownField({
    super.key,
    required this.label,
    this.options = const ['Math', 'Science', 'English'],
    this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white : Colors.black;
    return DropdownButtonFormField<String>(
      dropdownColor: appLightGreen,
      icon: const Icon(Icons.arrow_drop_down, color: appGreen),
      value: value,
      hint: Text(label, style: TextStyle(fontSize: 15, color: labelColor)),
      style: TextStyle(fontSize: 15, color: labelColor),
      selectedItemBuilder: (context) => options
          .map((e) => Align(
                alignment: Alignment.centerLeft,
                child: Text(e, style: TextStyle(fontSize: 15, color: labelColor)),
              ))
          .toList(),
      items: options
          .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e, style: TextStyle(fontSize: 15, color: labelColor)),
              ))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.grey),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: appGreen),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}