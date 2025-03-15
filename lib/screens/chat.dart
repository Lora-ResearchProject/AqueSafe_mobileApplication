import 'dart:convert';
import 'package:aqua_safe/services/chat_service.dart';
import 'package:aqua_safe/services/generate_unique_id_service.dart';
import 'package:aqua_safe/services/predefined_msg_scheduler.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();

  List<Map<String, dynamic>> messages = [];
  List<String> sentMessages = []; // Store sent messages
  List<String> receivedMessages = []; // Store received messages
  String selectedMessage = "";
  String selectedMessageNumber = "";
  bool isFirstMessageSent = false;
  List<int> selectedNumbers = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();

    // Start listening for BLE chat messages
    _chatService.startListeningForMessages((message) {
      setState(() {
        receivedMessages.add("[${message['m']}] - Received");
      });
    });
  }

  Future<void> _loadMessages() async {
    messages = await ChatMessageScheduler().getCachedChatMessages();
    setState(() {});
  }

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

    setState(() {
      isFirstMessageSent = true;
      selectedNumbers.clear();
      selectedMessageNumber = "";

      // ✅ Save sent message for display - need to modify to cache locally and display history
      final sentMsg = messages.firstWhere(
        (msg) => msg['messageNumber'] == messageNumber,
        orElse: () => {},
      );

      if (sentMsg.isNotEmpty) {
        sentMessages
            .add("[${sentMsg['messageNumber']}] - ${sentMsg['message']}");
      }
    });
  }

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
        crossAxisAlignment: CrossAxisAlignment.start, // Left-align everything
        children: [
          if (!isFirstMessageSent) // Hide this text after first message
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: Text(
                "Select the message code to send",
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.left, // Left-aligned
              ),
            ),

          // Display Received & Sent Messages
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (var msg in receivedMessages)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(msg,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 18)),
                    ),
                  ),
                for (var msg in sentMessages)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.lightBlueAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(msg,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 18)),
                    ),
                  ),
              ],
            ),
          ),

          if (!isFirstMessageSent)
            Expanded(
              // ✅ Takes full available space
              child: Container(
                width: double.infinity,
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 12, 18, 67),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Scrollbar(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start, // Left-align text
                      children: messages.map((msg) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Text(
                            "[${msg['messageNumber']}] - ${msg['message']}",
                            style: const TextStyle(
                                color: Colors.white, fontSize: 20),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            )
          else
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
                    isFirstMessageSent = false;
                  });
                },
                items: messages.map((msg) {
                  return DropdownMenuItem<String>(
                    value: "[${msg['messageNumber']}] - ${msg['message']}",
                    child:
                        Text("[${msg['messageNumber']}] - ${msg['message']}"),
                  );
                }).toList(),
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
