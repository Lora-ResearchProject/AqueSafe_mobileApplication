import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../services/sos_trigger_service.dart';
import '../services/bluetooth_service.dart';
import '../screens/sos_alerts_list.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String sosMessage = '';
  String sosTimeAgo = '';
  bool isSOSInProgress = false;

  // Initialize SOSTriggerService
  final SOSTriggerService _sosTriggerService = SOSTriggerService();
  final BluetoothService _bluetoothService = BluetoothService();

  @override
  void initState() {
    super.initState();
    _loadSOSStatus();
  }

  // Load SOS status from SharedPreferences
  Future<void> _loadSOSStatus() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? lastSOS = prefs.getString('lastSOS');

    if (lastSOS != null) {
      final sosData = jsonDecode(lastSOS);
      final String timestamp = sosData['timestamp'];
      final DateTime sosTime = DateTime.parse(timestamp);
      //final DateTime now = DateTime.now();

      final String timeAgo = timeago.format(sosTime, locale: 'en_short');

      setState(() {
        sosMessage = 'SOS Alert in Progress';
        sosTimeAgo = (timeAgo == 'now') ? 'now' : '$timeAgo ago';
        isSOSInProgress = true;
      });
    }
  }

  // Dashboard({Key? key})
  //     : _sosTriggerService = SOSTriggerService(),
  //       super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151d67), // Dark blue background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Connection Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildConnectionStatus(
                    label: 'Bluetooth',
                    isConnected: true, // Dynamically update this
                  ),
                  _buildConnectionStatus(
                    label: 'LoRa',
                    isConnected: false, // Dynamically update this
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Large SOS Button
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    _showSOSConfirmationDialog(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      vertical: 24.0,
                      horizontal: 80.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "TRIGGER SOS",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Notifications Section
              const Text(
                'Notifications',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              if (isSOSInProgress)
                GestureDetector(
                  // onTap: () {
                  //   Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //         builder: (context) => SOSAlertDetailsScreen()),
                  //   );
                  // },
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(
                          255, 95, 14, 14), // Dark red background
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Info Icon
                            Icon(
                              Icons.info_outline,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 12),

                            // SOS Alert Text
                            Expanded(
                              child: Text(
                                'SOS Alert in Progress',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            // Active Status
                            CircleAvatar(
                              backgroundColor: Colors.green,
                              radius: 8,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const SizedBox(width: 36),
                            Text(
                              sosTimeAgo,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // Quick Links
              const Text(
                'Quick Links',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              // Quick Links Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildQuickLinkCard(
                      icon: Icons.anchor,
                      label: 'Fishing Spots',
                      color: const Color.fromARGB(255, 36, 163, 183),
                    ),
                    _buildQuickLinkCard(
                      icon: Icons.sos,
                      label: 'SOS Alerts',
                      color: const Color.fromARGB(255, 195, 41, 59),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SOSAlertScreen()),
                        );
                      },
                    ),
                    _buildQuickLinkCard(
                      icon: Icons.chat,
                      label: 'Chat',
                      color: const Color.fromARGB(255, 174, 116, 23),
                    ),
                    _buildQuickLinkCard(
                      icon: Icons.cloud,
                      label: 'Weather',
                      color: const Color.fromARGB(255, 1, 95, 142),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1C3D72),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLinkCard({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: color.withOpacity(0.85),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: Colors.white,
              ),
              SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatus(
      {required String label, required bool isConnected}) {
    return Row(
      children: [
        Icon(
          isConnected ? Icons.check_circle : Icons.cancel,
          color: isConnected ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 8),
        Text(
          "$label: ${isConnected ? 'Connected' : 'Disconnected'}",
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ],
    );
  }

  void _showSOSConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissal by tapping outside
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151d67),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(
          child: Text(
            "Are you sure you want to send an SOS?",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        content: const Text(
          "This will notify all nearby vessels and emergency contacts.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: Color.fromARGB(179, 229, 229, 229),
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 36),
              side: const BorderSide(color: Color(0xFF151d67), width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Color(0xFF151d67), fontSize: 20),
            ),
          ),
          ElevatedButton(
            onPressed: () => _sosTriggerService.handleConfirm(
                context, _bluetoothService, ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 18, 115, 194),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "Confirm",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationItem extends StatelessWidget {
  final IconData icon;
  final String message;

  const NotificationItem({
    Key? key,
    required this.icon,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}
