import 'package:flutter/material.dart';

class SnackbarUtils {
  static void showSuccessMessage(BuildContext context, String message) {
    _showSnackbar(context, message, Colors.green);
  }

  static void showErrorMessage(BuildContext context, String message) {
    _showSnackbar(context, message, Colors.red);
  }

  static void showWarningMessage(BuildContext context, String message) {
    _showSnackbar(context, message, Colors.orange);
  }

  // Generic Snackbar method
  static void _showSnackbar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
