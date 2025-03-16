import 'package:aqua_safe/utils/snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../utils/popup_dialog_utils.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  String? errorMessage; // To display error message if passwords don't match
  bool isUpdateEnabled = false; // To enable/disable the Update button

  @override
  void initState() {
    super.initState();
    // Add listeners to dynamically check password match
    newPasswordController.addListener(_validatePasswords);
    confirmPasswordController.addListener(_validatePasswords);
  }

  @override
  void dispose() {
    // Dispose controllers and listeners
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _validatePasswords() {
    final String newPassword = newPasswordController.text.trim();
    final String confirmPassword = confirmPasswordController.text.trim();

    setState(() {
      // Check if passwords match
      if (newPassword != confirmPassword) {
        errorMessage = "New password and confirm password should match.";
        isUpdateEnabled = false;
      } else {
        errorMessage = null;
        // Check if all fields are filled
        isUpdateEnabled = oldPasswordController.text.trim().isNotEmpty &&
            newPassword.isNotEmpty &&
            confirmPassword.isNotEmpty;
      }
    });
  }

  Future<void> _updatePassword() async {
    final String oldPassword = oldPasswordController.text.trim();
    final String newPassword = newPasswordController.text.trim();

    if (oldPassword.isEmpty || newPassword.isEmpty) {
      setState(() {
        errorMessage = "All fields are required.";
      });
      return;
    }

    if (newPassword != confirmPasswordController.text.trim()) {
      setState(() {
        errorMessage = "New password and confirm password should match.";
      });
      return;
    }

    final String? baseUrl = dotenv.env['MAIN_API_BASE_URL'];
    if (baseUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API base URL not configured.')),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? vesselId = prefs.getString('vesselId');
      if (vesselId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vessel ID not found. Please log in.')),
        );
        return;
      }

      final Uri apiUrl =
          Uri.parse('$baseUrl/vessel-auth/$vesselId/change-password');

      final response = await http.patch(
        apiUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['message'] == "Password changed successfully") {
          PopupDialogUtils.showMessageDialog(
            context,
            "Success",
            "Password updated successfully!. Please log in again.",
            // onOkPressed: () {
            //   oldPasswordController.clear();
            //   newPasswordController.clear();
            //   confirmPasswordController.clear();
            //   setState(() {
            //     isUpdateEnabled = false;
            //   });
            // },
            onOkPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (route) => false);
            },
          );
        } else {
          SnackbarUtils.showErrorMessage(
              context, responseData['message'] ?? 'Failed to update password.');
        }
      } else {
        final responseData = json.decode(response.body);
        SnackbarUtils.showErrorMessage(
            context,
            responseData['message'] ??
                'Failed to update password. Please try again.');
      }
    } catch (e) {
      SnackbarUtils.showErrorMessage(context, 'An error occurred: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151d67),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151d67),
        elevation: 0,
        title: const Text(
          "Change Password",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Old Password Field
            _buildPasswordField(
              "Old Password",
              "Enter old password",
              oldPasswordController,
              obscureText: true,
            ),
            const SizedBox(height: 16),

            // New Password Field
            _buildPasswordField(
              "Enter New Password",
              "Enter new password",
              newPasswordController,
              obscureText: true,
            ),
            const SizedBox(height: 16),

            // Confirm Password Field
            _buildPasswordField(
              "Confirm Password",
              "Confirm new password",
              confirmPasswordController,
              obscureText: true,
            ),
            const SizedBox(height: 10),

            // Error Message (if any)
            if (errorMessage != null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
              ),
            const SizedBox(height: 30),

            Center(
              child: ElevatedButton(
                onPressed: isUpdateEnabled ? _updatePassword : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isUpdateEnabled ? Colors.white : Colors.grey[400],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 140, vertical: 20),
                ),
                child: Text(
                  "Update",
                  style: TextStyle(
                    color: isUpdateEnabled
                        ? const Color(0xFF151d67)
                        : Colors.grey[400],
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField(
      String label, String hint, TextEditingController controller,
      {bool obscureText = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white10,
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.white24),
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.white),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }
}
