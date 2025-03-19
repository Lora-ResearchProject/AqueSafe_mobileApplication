import 'dart:convert';
import 'package:aqua_safe/services/chat_service.dart';
import 'package:aqua_safe/services/generate_unique_id_service.dart';
import 'package:aqua_safe/services/predefined_msg_scheduler.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final ChatMessageScheduler _chatMessageScheduler = ChatMessageScheduler();
  List<Map<String, dynamic>> messages = [];
  String selectedMessage = "";
  String selectedMessageNumber = "";
  List<int> selectedNumbers = [];
  bool isFirstMessageSent = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();

    // Start listening for BLE chat messages
    _chatService.startListeningForMessages((message) async {
      if (mounted) {
        // Retrieve the message content using message number
        List<Map<String, dynamic>> cachedMessages =
            await _chatMessageScheduler.getCachedChatMessages();
        Map<String, dynamic>? msgEntry = cachedMessages.firstWhere(
          (msg) => msg['messageNumber'] == message['m'],
          orElse: () => {},
        );

        String messageContent =
            msgEntry.isNotEmpty ? msgEntry['message'] : "Unknown message";

        String formattedMsg = "[${message['m']}] - $messageContent";
        setState(() {
          messages.add({
            'message': formattedMsg,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'type': 'received',
          });
          messages.sort((a, b) =>
              a['timestamp'].compareTo(b['timestamp'])); // Sort by timestamp
        });
      }
    });
  }

  // Load messages from SharedPreferences
  Future<void> _loadMessages() async {
    List<Map<String, dynamic>> chatHistory =
        await _chatService.getChatHistory();
    setState(() {
      messages = chatHistory;
      if (messages.isNotEmpty) {
        isFirstMessageSent = true;
      }
    });
  }

  // Send message
  Future<void> _sendMessage() async {
    if (selectedMessageNumber.isEmpty) {
      print("❌ Error: No message selected.");
      return;
    }

    int? messageNumber = int.tryParse(selectedMessageNumber);
    if (messageNumber == null) {
      print("❌ Error: Invalid message number.");
      return;
    }

    await _chatService.sendChatMessage(messageNumber);

    // Get the message content from the predefined messages list
    List<Map<String, dynamic>> cachedMessages =
        await _chatMessageScheduler.getCachedChatMessages();
    Map<String, dynamic>? msgEntry = cachedMessages.firstWhere(
      (msg) => msg['messageNumber'] == messageNumber,
      orElse: () => {},
    );

    String messageContent =
        msgEntry.isNotEmpty ? msgEntry['message'] : "Unknown message";

    String formattedMsg = "[$messageNumber] - $messageContent";

    setState(() {
      isFirstMessageSent = true;
      selectedMessageNumber = "";
      selectedMessage = "";

      messages.add({
        'message': formattedMsg,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'type': 'sent',
      });
      messages.sort((a, b) =>
          a['timestamp'].compareTo(b['timestamp'])); // Sort by timestamp
    });
  }

  // Select number for predefined message
  void _selectNumber(int number) {
    setState(() {
      if (selectedNumbers.length < 2) {
        selectedNumbers.add(number);
        selectedMessageNumber = selectedNumbers.join("");
      }
    });
  }

  void _discardSelection() {
    setState(() {
      selectedNumbers.clear();
      selectedMessageNumber = "";
    });
  }

  void _enableMultiDigitSelection() {
    // No change in UI, just allows another number selection
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151d67),
      appBar: AppBar(
        title: const Text('Web Server'),
        titleTextStyle: const TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        backgroundColor: const Color(0xFF151d67),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                const Text("Active Now",
                    style: TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(width: 6),
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.cyanAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show predefined messages if no first message is sent
          if (!isFirstMessageSent)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Select the message code to send",
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),

          // Display received & sent messages
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (var msg in messages)
                  Align(
                    alignment: msg['type'] == 'received'
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: msg['type'] == 'received'
                            ? Colors.white
                            : const Color.fromARGB(255, 163, 226, 255),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(msg['message'],
                          style: const TextStyle(
                              color: Colors.black, fontSize: 18)),
                    ),
                  ),
              ],
            ),
          ),

          // Display predefined messages if chat history is empty
          if (!isFirstMessageSent)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButton<String>(
                value: selectedMessage.isEmpty ? null : selectedMessage,
                dropdownColor: const Color(0xFF151d67),
                hint: const Text("Pick a message to send",
                    style: TextStyle(color: Colors.white)),
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_up,
                    color: Colors.white), // Opens Up
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() {
                    selectedMessage = value ?? "";
                  });
                },
                items: const [
                  DropdownMenuItem<String>(
                    value: "[1] - On route to location",
                    child: Text("[1] - On route to location"),
                  ),
                  DropdownMenuItem<String>(
                    value: "[2] - Need assistance immediately",
                    child: Text("[2] - Need assistance immediately"),
                  ),
                  DropdownMenuItem<String>(
                    value: "[3] - Location confirmed",
                    child: Text("[3] - Location confirmed"),
                  ),
                  DropdownMenuItem<String>(
                    value: "[4] - Need assistance immediately",
                    child: Text("[4] - Need assistance immediately"),
                  ),
                  DropdownMenuItem<String>(
                    value: "[5] - Emergency! Respond ASAP",
                    child: Text("[5] - Emergency! Respond ASAP"),
                  ),
                ],
              ),
            ),

          // Number Keyboard
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Column(
              children: [
                _buildNumberRow([1, 2, 3]),
                _buildNumberRow([4, 5, 6]),
                _buildNumberRow([7, 8, 9]),
                _buildNumberRow(['X', 0, '+']),
              ],
            ),
          ),

          // Send Button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: ElevatedButton(
              onPressed: selectedMessageNumber.isNotEmpty ? _sendMessage : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedMessageNumber.isNotEmpty
                    ? Colors.white
                    : Colors.grey.shade600,
                minimumSize: const Size(double.infinity, 55),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 50),
                textStyle: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: selectedMessageNumber.isNotEmpty
                      ? const Color(0xFF151d67)
                      : Colors.grey.shade400,
                ),
              ),
              child: Text(
                "Send",
                style: TextStyle(
                  color: selectedMessageNumber.isNotEmpty
                      ? const Color(0xFF151d67)
                      : Colors.grey.shade400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberRow(List<dynamic> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: numbers.map((number) {
        return Expanded(
          child: GestureDetector(
            onTap: () {
              if (number == 'X') {
                _discardSelection();
              } else if (number == '+') {
                _enableMultiDigitSelection();
              } else {
                _selectNumber(number as int);
              }
            },
            child: Container(
              margin: const EdgeInsets.all(5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: selectedNumbers.contains(number)
                    ? const Color.fromARGB(255, 12, 18, 67)
                    : Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                number.toString(),
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: selectedNumbers.contains(number)
                        ? Colors.white
                        : const Color.fromARGB(255, 1, 84, 107)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
