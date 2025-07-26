import 'package:aqua_safe/screens/help_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/edit_account.dart';
import '../screens/change_password.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String vesselName = "Loading...";
  String email = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadAccountInfo();
  }

  Future<void> _loadAccountInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      vesselName = prefs.getString('vesselName') ?? "Unkwon Vessel Name";
      email = prefs.getString('vesselEmail') ?? "Unknown Email";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151d67),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151d67),
        elevation: 0,
        title: const Text(
          "Settings",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.directions_boat,
                    color: Color(0xFF151d67),
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vesselName, // Display vessel name
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email, // Display email
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 50),
            _buildSettingsOption(
              context,
              icon: Icons.person,
              title: "Edit Account",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditAccountScreen(),
                  ),
                ).then((_) {
                  _loadAccountInfo();
                });
              },
            ),
            // _buildSettingsOption(
            //   context,
            //   icon: Icons.notifications,
            //   title: "Notifications",
            //   onTap: () {},
            // ),
            _buildSettingsOption(
              context,
              icon: Icons.lock,
              title: "Change Password",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChangePasswordScreen(),
                  ),
                );
              },
            ),
            // _buildSettingsOption(
            //   context,
            //   icon: Icons.history,
            //   title: "Route History",
            //   onTap: () {},
            // ),
            _buildSettingsOption(
              context,
              icon: Icons.help,
              title: "Help & Support",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HelpScreen()),
                );
              },
            ),
            _buildSettingsOption(
              context,
              icon: Icons.logout,
              title: "Logout",
              onTap: () {
                // Show confirmation popup
                _showLogoutConfirmationDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsOption(BuildContext context,
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.white, size: 28),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios,
              color: Colors.white, size: 20),
          onTap: onTap,
        ),
        const Divider(color: Colors.white24),
      ],
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF151d67), // Dark background
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Are you sure you want to Logout?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22, // Larger title
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  "This will end your current session and you will need to log in again.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18, // Larger content text
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.white24, // Dim background for Cancel
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(); // Close dialog
                      },
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18, // Larger button text
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red, // Highlight Logout button
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.clear(); // Clear preferences

                        Navigator.of(context).pushReplacementNamed(
                            '/login'); // Navigate to login
                      },
                      child: const Text(
                        "Logout",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18, // Larger button text
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
      },
    );
  }
}
