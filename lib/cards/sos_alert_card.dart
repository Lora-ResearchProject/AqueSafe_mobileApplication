import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SOSAlertCard extends StatelessWidget {
  final Map<String, dynamic> alert;

  const SOSAlertCard({Key? key, required this.alert}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ✅ Use correct API field names
    String sender = alert['vesselId'] ?? "Unknown";
    String latitude = alert['lat']?.toString() ?? "N/A";
    String longitude = alert['lng']?.toString() ?? "N/A";
    String status = alert['sosStatus'] ?? "Unknown";
    String rawDateTime = alert['dateTime'] ?? "No Date";

    // Format Date & Time Separately
    String formattedDate = "N/A";
    String formattedTime = "N/A";
    try {
      DateTime parsedDateTime = DateTime.parse(rawDateTime);
      // Add 5 hours and 30 minutes
      parsedDateTime =
          parsedDateTime.add(const Duration(hours: 5, minutes: 30));

      formattedDate = DateFormat('yyyy-MM-dd').format(parsedDateTime);
      formattedTime = DateFormat('hh:mm a')
          .format(parsedDateTime); // 🕰 Readable 12-hour format
    } catch (e) {
      print("Error parsing date: $e");
    }

    Color statusColor =
        (status.toLowerCase() == "active") ? Colors.green : Colors.yellow;
    String statusText =
        (status.toLowerCase() == "active") ? "Active" : "Resolved";

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
                  "Sender: $sender",
                  style: const TextStyle(
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
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status with Color
            Row(
              children: [
                const Text(
                  "Status: ",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Date & Time (Date First, Time After Space)
            Row(
              children: [
                Text(
                  "Date: $formattedDate",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "Time: $formattedTime",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
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
