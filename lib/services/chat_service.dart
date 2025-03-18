import 'dart:convert';
import 'package:aqua_safe/services/bluetooth_service.dart';
import 'package:aqua_safe/services/generate_unique_id_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatService {
  final BluetoothService _bluetoothService = BluetoothService();

  Future<void> sendChatMessage(int messageNumber) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? vesselId = prefs.getString('vesselId');

      if (vesselId == null || vesselId.isEmpty) {
        throw Exception("❌ Vessel ID not found in SharedPreferences");
      }

      GenerateUniqueIdService idService = GenerateUniqueIdService();
      String uniqueMsgId = idService.generateId();

      final Map<String, dynamic> chatPayload = {
        "id": "$vesselId|$uniqueMsgId",
        "m": messageNumber
      };

      String messageJson = jsonEncode(chatPayload);

      await _bluetoothService.sendChatMessage(messageJson);

      print("✅ Chat Message Sent Successfully");
    } catch (e) {
      print("❌ Error sending chat message via BLE: $e");
    }
  }

  Future<void> storeMessageLocally(String messageId, String message) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    List<String> chatHistory = prefs.getStringList("chatHistory") ?? [];

    chatHistory.add(jsonEncode({"id": messageId, "msg": message}));

    if (chatHistory.length > 10) {
      chatHistory.removeAt(0);
    }

    await prefs.setStringList("chatHistory", chatHistory);
  }

  void startListeningForMessages(
      Function(Map<String, dynamic>) onMessageReceived) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? vesselId = prefs.getString('vesselId');

    if (vesselId == null || vesselId.isEmpty) {
      print("❌ Error: Vessel ID not found in SharedPreferences.");
      return;
    }

    _bluetoothService.listenForChatMessages((message) {
      if (!message.containsKey("id") || !message.containsKey("m")) {
        print("❌ Invalid message format: $message");
        return;
      }

      String receivedId = message['id'];
      String senderVesselId = receivedId.split('|')[0];

      // Ignore msgs recived for other vessels
      if (senderVesselId == vesselId) {
        print("✅ Chat message received for this vessel: $message");
        onMessageReceived(message);
        storeMessageLocally("R-${receivedId.split('|')[1]}",
            "[${message['m']}] - Received");
      } else {
        print("⚠️ Ignoring message from another vessel: $message");
      }
    });
  }
}
