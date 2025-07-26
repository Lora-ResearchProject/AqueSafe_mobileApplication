import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151d67),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151d67),
        elevation: 0,
        title: const Text(
          "Help & Support",
          style: TextStyle(
            fontSize: 26,
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
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          HelpTile(
            title: "How to use AquaSafe?",
            content:
                "Navigate to the Hotspots section to see suggested fishing locations. Use Chat for quick communication and SOS during emergencies.",
          ),
          HelpTile(
            title: "How to report an emergency?",
            content:
                "Tap the SOS button in the bottom menu. This sends your location to nearby vessels instantly.",
          ),
          HelpTile(
            title: "Viewing and using Weather Info",
            content:
                "Check the weather section for rain conditions. This helps plan safer fishing trips and avoid rough weather.",
          ),
          HelpTile(
            title: "Changing account details",
            content:
                "Go to Settings > Edit Account to update your vessel name or email address.",
          ),
          HelpTile(
            title: "Still need help?",
            content:
                "Contact our support team at: support@aquasafe.io or call: +1 234 567 8900",
          ),
        ],
      ),
    );
  }
}

class HelpTile extends StatelessWidget {
  final String title;
  final String content;

  const HelpTile({required this.title, required this.content, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 0),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            content,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      ],
    );
  }
}
