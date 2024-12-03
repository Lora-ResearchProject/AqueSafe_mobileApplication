import 'dart:convert';

import 'package:flutter/material.dart';
import '../cards/sos_alert_card.dart';
import '../services/bluetooth_service.dart';

class SOSAlertScreen extends StatefulWidget {
  @override
  _SOSAlertScreenState createState() => _SOSAlertScreenState();
}

class _SOSAlertScreenState extends State<SOSAlertScreen> {
  List<Map<String, dynamic>> sosAlerts = [];
  final BluetoothService _bluetoothService = BluetoothService();

 // Fetch SOS alerts from Bluetooth service
  void fetchSOSAlerts() async {
    try {
      String fetchedData = await _bluetoothService.fetchSOSAlerts();

      if (fetchedData.isNotEmpty) {
        final List<Map<String, dynamic>> fetchedSOS = parseSOSData(fetchedData);
        setState(() {
          sosAlerts = fetchedSOS;  
        });
      }
    } catch (e) {
      print("Error fetching SOS alerts: $e");
    }
  }

  // Parse the fetched SOS data into a list of maps
  List<Map<String, dynamic>> parseSOSData(String data) {
    final List<dynamic> sosList = jsonDecode(data);
    return sosList.map((alert) {
      return {
        'id': alert['id'],
        'l': alert['l'],  
        's': alert['s'],  
      };
    }).toList();
  }

  // void fetchSOSAlerts() async {
  //   try {
  //     setState(() {
  //       sosAlerts = [
  //         {
  //           "id": "004-0000",
  //           "l": "7.01713-79.96301",
  //           "s": 1,
  //         },
  //         {
  //           "id": "004-0001",
  //           "l": "7.01714-79.96302",
  //           "s": 1,
  //         },
  //         {
  //           "id": "004-0002",
  //           "l": "7.01715-79.96303",
  //           "s": 1,
  //         },
  //       ];
  //     });
  //   } catch (e) {
  //     print("Error fetching SOS alerts: $e");
  //   }
  // }

  @override
  void initState() {
    super.initState();
    fetchSOSAlerts(); // when the screen loaded
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151d67),
      appBar: AppBar(
        title: const Text('SOS Alerts'),
        titleTextStyle: TextStyle(
            color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
        backgroundColor: const Color(0xFF151d67),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Large refresh button at the top
            ElevatedButton(
              onPressed: () {
                fetchSOSAlerts();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 130),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Refresh',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF151d67),
                ),
              ),
            ),

            // Displaying SOS alerts in a list
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ListView.builder(
                  itemCount: sosAlerts.length,
                  itemBuilder: (context, index) {
                    var alert = sosAlerts[index];
                    return SOSAlertCard(alert: alert);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
