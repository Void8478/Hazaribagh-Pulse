import 'package:flutter/services.dart';
import 'dart:math';

class IndianPhoneFormatter extends TextInputFormatter {
  static const String prefix = '+91 ';

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 1. Block prefix deletion
    if (newValue.text.length < prefix.length) {
      return oldValue.text.startsWith(prefix) 
          ? const TextEditingValue(
              text: prefix,
              selection: TextSelection.collapsed(offset: prefix.length),
            )
          : const TextEditingValue(
              text: prefix,
              selection: TextSelection.collapsed(offset: prefix.length),
            );
    }

    // 2. Handle pasted/complete inputs properly
    String input = newValue.text;
    if (!input.startsWith(prefix)) {
      // If user pasted something bypassing the prefix
      String digitsOnly = input.replaceAll(RegExp(r'\D'), '');
      if (digitsOnly.startsWith('91')) {
        digitsOnly = digitsOnly.substring(2); // Strip native 91 if included
      }
      input = prefix + digitsOnly;
    }

    // 3. Extract digits specifically typed after the prefix
    String afterPrefix = input.substring(prefix.length);
    String digitsOnly = afterPrefix.replaceAll(RegExp(r'\D'), '');

    // 4. Cap at exactly 10 digits
    if (digitsOnly.length > 10) {
      digitsOnly = digitsOnly.substring(0, 10);
    }

    // 5. Reconstruct formatted string (+91 XXXXX XXXXX)
    StringBuffer formatted = StringBuffer(prefix);
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i == 5) {
        formatted.write(' ');
      }
      formatted.write(digitsOnly[i]);
    }

    final String resultText = formatted.toString();

    // 6. Calculate smooth cursor position natively using relative digit positioning
    int cursorInNew = newValue.selection.end;
    cursorInNew = max(0, min(cursorInNew, newValue.text.length));
    
    int digitsBeforeCursor = 0;
    for (int i = 0; i < cursorInNew; i++) {
      if (RegExp(r'\d').hasMatch(newValue.text[i])) {
        digitsBeforeCursor++;
      }
    }

    int newCursorIndex = 0;
    int digitsSeen = 0;
    for (int i = 0; i < resultText.length; i++) {
      if (digitsSeen == digitsBeforeCursor) {
        newCursorIndex = i;
        break;
      }
      if (RegExp(r'\d').hasMatch(resultText[i])) {
        digitsSeen++;
      }
      newCursorIndex = i + 1;
    }

    // Ensures cursor never falls behind the required prefix (+91 )
    if (newCursorIndex < prefix.length) {
      newCursorIndex = prefix.length;
    }

    return TextEditingValue(
      text: resultText,
      selection: TextSelection.collapsed(offset: newCursorIndex),
    );
  }
}
