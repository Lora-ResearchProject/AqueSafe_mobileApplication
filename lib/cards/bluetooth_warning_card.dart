import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';

class BluetoothWarningCard extends StatefulWidget {
  final bool isConnected;

  const BluetoothWarningCard({Key? key, required this.isConnected})
      : super(key: key);

  @override
  _BluetoothWarningCardState createState() => _BluetoothWarningCardState();
}

class _BluetoothWarningCardState extends State<BluetoothWarningCard> {
  bool _isReconnecting = false;
  final BluetoothService _bluetoothService =
      BluetoothService(); // ✅ Instance of BluetoothService

  Future<void> _reconnect() async {
    setState(() {
      _isReconnecting = true;
    });

    bool connected = await _bluetoothService.scanAndConnect();

    setState(() {
      _isReconnecting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(connected ? "Reconnected to ESP32" : "Failed to reconnect"),
        backgroundColor:
            connected ? const Color.fromARGB(255, 0, 184, 58) : Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isConnected) return const SizedBox.shrink();

    return Container(
      color: const Color.fromRGBO(236, 148, 44, 1),
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Not Connected to ESP32! Please Reconnect.",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          ElevatedButton(
            onPressed: _isReconnecting ? null : _reconnect,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isReconnecting ? Colors.grey : Colors.white,
            ),
            child: _isReconnecting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Color.fromARGB(255, 1, 54, 97), strokeWidth: 3),
                  )
                : const Text("Reconnect"),
          ),
        ],
      ),
    );
  }
}
