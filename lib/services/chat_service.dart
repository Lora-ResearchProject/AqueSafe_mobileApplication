import 'dart:async';
import 'dart:convert';
import 'package:aqua_safe/services/bluetooth_service.dart';
import 'package:aqua_safe/services/generate_unique_id_service.dart';
import 'package:aqua_safe/services/predefined_msg_scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatService {
  final BluetoothService _bluetoothService = BluetoothService();
  final ChatMessageScheduler _msgScheduler = ChatMessageScheduler();
  StreamSubscription? _chatSubscription; // Track the subscription

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

      List<Map<String, dynamic>> cachedMessages =
          await _msgScheduler.getCachedChatMessages();
      Map<String, dynamic>? msgEntry = cachedMessages.firstWhere(
          (msg) => msg['messageNumber'] == messageNumber,
          orElse: () => {});

      String messageContent =
          msgEntry.isNotEmpty ? msgEntry['message'] : "Unknown message";
      String formattedMsg = "S-$uniqueMsgId-[$messageNumber]-$messageContent";

      // Store sent message locally
      await _storeMessageLocally(formattedMsg);

      print("✅ Chat Message Sent & Stored locally: $formattedMsg");
    } catch (e) {
      print("❌ Error sending chat message via BLE: $e");
    }
  }

  // Stores a chat message locally in SharedPreferences
  Future<void> _storeMessageLocally(String formattedMessage) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> chatHistory = prefs.getStringList("chatHistory") ?? [];

    chatHistory.add(jsonEncode({"msg": formattedMessage}));

    if (chatHistory.length > 10) {
      chatHistory.removeAt(0);
    }

    await prefs.setStringList("chatHistory", chatHistory);
    print("✅ Messeage stored locally");
  }

  // Check if the message with the same message ID is already stored
  Future<bool> _isMessageAlreadyStored(String messageId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> chatHistory = prefs.getStringList('chatHistory') ?? [];

    for (var message in chatHistory) {
      var messageData = jsonDecode(message);
      String storedMessageId = messageData['msg'].split('-')[1];

      if (storedMessageId == messageId) {
        return true;
      }
    }

    return false;
  }

  void startListeningForMessages(
      Function(Map<String, dynamic>) onMessageReceived) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? vesselId = prefs.getString('vesselId');

    if (vesselId == null || vesselId.isEmpty) {
      print("❌ Error: Vessel ID not found in SharedPreferences.");
      return;
    }

    _bluetoothService.listenForChatMessages((message) async {
      if (!message.containsKey("id") || !message.containsKey("m")) {
        print("❌ Invalid message format: $message");
        return;
      }

      String receivedId = message['id'];
      String senderVesselId = receivedId.split('|')[0];

      // Ignore messages not meant for this vessel
      if (senderVesselId == vesselId) {
        print(
            "✅ Chat message received for this vessel($senderVesselId): $message");

        String messageId = receivedId.split('|')[1];

        // Check if the message with the same ID is already stored locally
        bool isMessageAlreadyStored = await _isMessageAlreadyStored(messageId);
        if (isMessageAlreadyStored) {
          print(
              "⚠️ Message with ID $messageId already stored locally. Skipping storage.");
          return;
        }

        List<Map<String, dynamic>> cachedMessages =
            await _msgScheduler.getCachedChatMessages();
        Map<String, dynamic>? msgEntry = cachedMessages.firstWhere(
            (msg) => msg['messageNumber'] == message['m'],
            orElse: () => {});

        String messageContent =
            msgEntry.isNotEmpty ? msgEntry['message'] : "Unknown message";
        String formattedMsg =
            "R-${receivedId.split('|')[1]}-[${message['m']}]-$messageContent";

        // Store received message locally
        await _storeMessageLocally(formattedMsg);

        print("✅ Chat Message Received & Stored locally: $formattedMsg");

        onMessageReceived(message);
      } else {
        print("⚠️ Ignoring message from another vessel: $message");
      }
    });
  }

  // Retrieves chat history from SharedPreferences
  Future<List<Map<String, dynamic>>> getChatHistory() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> chatHistory = prefs.getStringList("chatHistory") ?? [];

    print("--- 📦 Raw chatHistory from prefs: $chatHistory");

    List<Map<String, dynamic>> messages = chatHistory.map((chatData) {
      Map<String, dynamic> chatEntry = jsonDecode(chatData);
      String fullMsg = chatEntry["msg"];
      String message = "${fullMsg.split('-')[2]}-${fullMsg.split('-')[3]}";
      String messageId = fullMsg.split('-')[1];
      int timestamp = GenerateUniqueIdService().getTimestampFromId(messageId);

      print(
          ">>>>>>> Parsed message with timestamp: $timestamp, message: $message");

      return {
        'message': message,
        'timestamp': timestamp,
        'type': fullMsg.startsWith("S") ? 'sent' : 'received',
      };
    }).toList();

    // Sort messages by timestamp
    messages.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));

    return messages;
  }

  // Stop listening for BLE chat messages (Unsubscribe from the BLE stream)
  void stopListeningForChatMessages() {
    if (_chatSubscription != null) {
      _chatSubscription?.cancel(); // Cancel the current subscription
      _chatSubscription = null; // Clear the subscription
      print("🔕 Stopped listening for chat messages.");
    }
  }
}
