import 'package:flutter/material.dart';

class SOSAlertCard extends StatelessWidget {
  final Map<String, dynamic> alert;

  SOSAlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    String sender = alert['id'].substring(0, 3);
    String latitude = alert['l'].split('-')[0];
    String longitude = alert['l'].split('-')[1];
    String status = 'Active';

    return Card(
      color: const Color(0xFF151d67),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sender
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Sender: Vessel $sender",
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Latitude and Longitude
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Location: ${latitude}N, ${longitude}W",
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status
            Text(
              "Status: $status",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}
