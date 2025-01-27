import 'package:aqua_safe/utils/snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For encoding/decoding JSON
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/snack_bar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkSession(); // Check for an existing session on screen load
  }

  // Check if vesselId is stored in SharedPreferences
  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final vesselId = prefs.getString('vesselId');
    if (vesselId != null) {
      // If vesselId exists, navigate to the dashboard
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  Future<void> _loginUser() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    // Access the base URL from the .env file
    final String? baseUrl = dotenv.env['MAIN_API_BASE_URL'];
    if (baseUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API base URL not configured.')),
      );
      return;
    }

    final Uri loginUrl = Uri.parse('$baseUrl/vessel-auth/vessel-login/');

    try {
      final response = await http.post(
        loginUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['message'] == 'Login successful') {
          final vesselId = responseData['vesselId'];

          // Check if the required vesselId is present
          if (vesselId != null) {
            await _fetchVesselDetailsAndCache(vesselId, password);
          } else {
            SnackbarUtils.showErrorMessage(
                context, 'Login failed: Incomplete user data.');
          }
        } else {
          SnackbarUtils.showErrorMessage(context, 'Login failed');
        }
      } else {
        SnackbarUtils.showErrorMessage(context, 'Invalid email or password.');
      }
    } catch (e) {
      SnackbarUtils.showErrorMessage(context, 'An error occurred: $e');
    }
  }

  Future<void> _fetchVesselDetailsAndCache(
      String vesselId, String password) async {
    final String? baseUrl = dotenv.env['MAIN_API_BASE_URL'];
    if (baseUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API base URL not configured.')),
      );
      return;
    }

    final Uri getVesselUrl = Uri.parse('$baseUrl/vessel-auth/$vesselId');

    try {
      final response = await http.get(
        getVesselUrl,
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint(
          "API Response: ${response.statusCode}, Body: ${response.body}");

      if (response.statusCode == 200) {
        final vesselData = json.decode(response.body);

        final vesselName = vesselData['vesselName'];
        final vesselEmail = vesselData['email'];

        if (vesselName != null && vesselEmail != null) {
          // Save vessel details in SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          final storage = const FlutterSecureStorage();

          await prefs.setString('vesselId', vesselId);
          await prefs.setString('vesselName', vesselName);
          await prefs.setString('vesselEmail', vesselEmail);
          await storage.write(key: 'vesselPassword', value: password);

          SnackbarUtils.showSuccessMessage(context, 'Login successful!');

          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          SnackbarUtils.showErrorMessage(
              context, 'Failed to retrieve vessel details.');
        }
      } else {
        debugPrint(
            "Failed Response: ${response.statusCode}, Body: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch vessel details.')),
        );
      }
    } catch (e) {
      SnackbarUtils.showErrorMessage(
          context, 'An error occurred while fetching details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151d67),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo
            Center(
              child: Image.asset(
                'assets/logo.png',
                height: 100,
                width: 100,
              ),
            ),
            const SizedBox(height: 30),

            // Title
            const Text(
              'Login',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Email Input
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: 'Email',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1C3D72),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),

            // Password Input
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Password',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1C3D72),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 10),

            // Forgot Password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // Add Forgot Password functionality here
                },
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Login Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _loginUser,
              child: const Text(
                'Log in',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),

            // Create Account Link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Don't have an account?",
                  style: TextStyle(color: Colors.white70),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  child: const Text(
                    'Create an account',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
