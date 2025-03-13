import 'dart:convert';
import 'package:aqua_safe/services/generate_unique_id_service.dart';
import 'package:aqua_safe/services/predefined_msg_scheduler.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatScreen extends StatefulWidget {
  final String vesselId;

  const ChatScreen({Key? key, required this.vesselId}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Map<String, dynamic>> messages = [];
  String selectedMessage = "";
  String selectedMessageNumber = "";
  bool isFirstMessageSent = false;
  List<int> selectedNumbers = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    messages = await ChatMessageScheduler().getCachedChatMessages();
    setState(() {});
  }

  Future<void> _sendMessage() async {
    if (selectedMessageNumber.isEmpty) return;

    GenerateUniqueIdService idService = GenerateUniqueIdService();
    String uniqueMsgId = idService.generateId();

    final String id = "${widget.vesselId}|$uniqueMsgId";
    final int messageNumber = int.parse(selectedMessageNumber);

    final Map<String, dynamic> payload = {
      "id": id,
      "m": messageNumber,
    };

    try {
      final response = await http.post(
        Uri.parse("https://app.aquasafe.fish/backend/api/chat/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        print("✅ Message Sent: $selectedMessageNumber");
        setState(() {
          isFirstMessageSent = true;
          selectedNumbers.clear();
          selectedMessageNumber = "";
        });
      } else {
        print("❌ Message send failed: ${response.body}");
      }
    } catch (e) {
      print("❌ Error sending message: $e");
    }
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
            color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Text(
              "Select the message code to send",
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.left, // Left-aligned
            ),
          ),
          if (!isFirstMessageSent) ...[
            Expanded(
              child: Container(
                width: double.infinity,
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 12, 18, 67),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color.fromARGB(184, 249, 249, 249),
                      width: 1.5), // White border
                ),
                child: Scrollbar(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: messages.map((msg) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Text(
                            "[${msg['messageNumber']}] - ${msg['message']}",
                            style: const TextStyle(
                                color: Colors.white, fontSize: 24),
                            textAlign: TextAlign.left, // Left-aligned text
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButton<String>(
                value: selectedMessage.isEmpty ? null : selectedMessage,
                dropdownColor: const Color(0xFF151d67),
                hint: const Text("Pick a message to send",
                    style: TextStyle(color: Colors.white)),
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_up, color: Colors.white),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() {
                    selectedMessage = value ?? "";
                    isFirstMessageSent = false; // Show message box again
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
          ],
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: ElevatedButton(
              onPressed: selectedMessageNumber.isNotEmpty ? _sendMessage : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 50),
                textStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF151d67),
                ),
              ),
              child: const Text("Send"),
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
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 42, 48, 94),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
