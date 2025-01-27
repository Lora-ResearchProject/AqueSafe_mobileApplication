import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/snack_bar.dart';

class EditAccountScreen extends StatefulWidget {
  const EditAccountScreen({Key? key}) : super(key: key);

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  TextEditingController vesselNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAccountInfo();
  }

  Future<void> _loadAccountInfo() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      vesselNameController.text = prefs.getString('vesselName') ?? "-";
      emailController.text = prefs.getString('vesselEmail') ?? "-";
    });
  }

  Future<void> _updateAccount() async {
    final String vesselName = vesselNameController.text.trim();
    final String email = emailController.text.trim();

    if (vesselName.isEmpty || email.isEmpty) {
      SnackbarUtils.showWarningMessage(context, "All fields are required.");
      return;
    }

    final String? baseUrl = dotenv.env['MAIN_API_BASE_URL'];
    if (baseUrl == null) {
      SnackbarUtils.showErrorMessage(context, 'API base URL not configured.');
      return;
    }

    try {
      // Retrieve the vesselId from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final String? vesselId = prefs.getString('vesselId');
      if (vesselId == null) {
        SnackbarUtils.showErrorMessage(
            context, "Vessel ID not found. Please log in again.");
        return;
      }

      // Make PATCH API call to update details
      final response = await http.patch(
        Uri.parse('$baseUrl/vessel-auth/$vesselId/change-details'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'vesselName': vesselName,
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['message'] == "Vessel updated successfully") {
          await prefs.setString('vesselName', vesselName);
          await prefs.setString('vesselEmail', email);

          SnackbarUtils.showSuccessMessage(
              context, "Account updated successfully!");
        } else {
          SnackbarUtils.showErrorMessage(
              context, "Failed to update account. Try again.");
        }
      } else {
        SnackbarUtils.showErrorMessage(
            context, "Failed to update account. Try again.");
      }
    } catch (e) {
      SnackbarUtils.showErrorMessage(context, "An error occurred: $e");
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
          "Edit Account",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            // Vessel Name Input
            _buildEditableField(
                "Vessel Name", "Enter vessel name", vesselNameController),
            const SizedBox(height: 22),
            // Email Input
            _buildEditableField(
                "Email Address", "Enter email address", emailController),
            const SizedBox(height: 50),
            Center(
              child: ElevatedButton(
                onPressed: _updateAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 140, vertical: 20),
                ),
                child: const Text(
                  "Update",
                  style: TextStyle(
                    color: Color(0xFF151d67),
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

  /// Build Input Field for Vessel Name and Email
  Widget _buildEditableField(
      String label, String hint, TextEditingController controller) {
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
