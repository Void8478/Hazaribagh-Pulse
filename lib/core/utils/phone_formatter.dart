import 'package:flutter/services.dart';

class IndianPhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // If the new value is empty, return to prefix
    if (newValue.text.isEmpty) {
      return const TextEditingValue(
        text: '+91 ',
        selection: TextSelection.collapsed(offset: 4),
      );
    }

    // Keep only numbers that come after the prefix +91
    String numbersOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Remove the 91 from the beginning if it exists because of our prefix
    if (numbersOnly.startsWith('91') && newValue.text.startsWith('+91')) {
      numbersOnly = numbersOnly.substring(2);
    }

    // Only allow up to 10 digits
    if (numbersOnly.length > 10) {
      numbersOnly = numbersOnly.substring(0, 10);
    }

    // Format the number like +91 98765 43210
    StringBuffer formatted = StringBuffer('+91 ');
    for (int i = 0; i < numbersOnly.length; i++) {
      formatted.write(numbersOnly[i]);
      if (i == 4 && numbersOnly.length > 5) {
        formatted.write(' ');
      }
    }

    // Return the formatted text
    return TextEditingValue(
      text: formatted.toString(),
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
