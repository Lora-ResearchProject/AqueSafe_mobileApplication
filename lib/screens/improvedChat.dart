import 'package:aqua_safe/services/chat_service.dart';
import 'package:aqua_safe/services/predefined_msg_scheduler.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImprovedChatScreen extends StatefulWidget {
  const ImprovedChatScreen({Key? key}) : super(key: key);

  @override
  State<ImprovedChatScreen> createState() => _ImprovedChatScreenState();
}

class _ImprovedChatScreenState extends State<ImprovedChatScreen> {
  final ChatService _chatService = ChatService();
  final ChatMessageScheduler _chatMessageScheduler = ChatMessageScheduler();
  List<Map<String, dynamic>> messages = [];
  String selectedMessageNumber = "";
  List<int> selectedNumbers = [];
  bool showPredefinedBox = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();

    _chatService.startListeningForMessages((message) async {
      await _loadMessages(); // Auto refresh
    });
  }

  Future<void> _loadMessages() async {
    List<Map<String, dynamic>> chatHistory =
        await _chatService.getChatHistory();
    if (!mounted) return;

    for (var msg in chatHistory) {
      print(
          ">>>>>>>>> Loaded Msg: ${msg['message']} - Timestamp: ${msg['timestamp']} - Type: ${msg['type']}");
    }

    setState(() {
      messages = chatHistory;
    });
  }

  Future<void> _sendMessage() async {
    if (selectedMessageNumber.isEmpty) return;
    int? messageNumber = int.tryParse(selectedMessageNumber);
    if (messageNumber == null) return;

    await _chatService.sendChatMessage(messageNumber);
    _discardSelection();
    await _loadMessages();
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

  Widget _buildMessageTile(String text, bool isSent) {
    // Check if the message contains the word 'Location'
    bool containsLocation = text.contains("Location");

    Color backgroundColor = containsLocation
        ? const Color.fromARGB(255, 255, 179, 174) // Light red color
        : (isSent ? const Color(0xFFA3E2FF) : Colors.white); // Default color

    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.fromLTRB(
          isSent ? 30 : 8, // Left padding
          5, // Top
          isSent ? 10 : 30, // Right padding
          5, // Bottom
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSent ? const Color(0xFFA3E2FF) : backgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 20,
            color: isSent ? Colors.black : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicHeader() {
    final screenHeight = MediaQuery.of(context).size.height;
    final predefinedBoxHeight = screenHeight * 0.30; // 30% of screen
    final chatBoxHeight = screenHeight * 0.35;

    return Container(
      // Temporary border to identify the space used by _buildDynamicHeader
      // decoration: BoxDecoration(
      //   border: Border.all(
      //       color: Colors.yellow,
      //       width: 2),
      // ),
      child: showPredefinedBox
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, bottom: 10, top: 10),
                  child: Text(
                    "Select the message code to send",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
                // Container for the message list
                Container(
                  margin: const EdgeInsets.only(left: 16, right: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white),
                    borderRadius: BorderRadius.circular(10),
                    color: const Color(0xFF10194E),
                  ),
                  height: predefinedBoxHeight, // Adjust height as needed
                  child: FutureBuilder(
                    future: _chatMessageScheduler.getCachedChatMessages(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final messages =
                          snapshot.data as List<Map<String, dynamic>>;
                      return Scrollbar(
                        thumbVisibility: true,
                        child: ListView.builder(
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Text(
                                "[${msg['messageNumber']}] - ${msg['message']}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            )
          : (messages.isEmpty
              ? const Center(
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 60, vertical: 100),
                    child: Text(
                      "No messages yet",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ),
                )
              : Container(
                  height: chatBoxHeight,
                  margin: const EdgeInsets.only(left: 12.0, right: 12.0),
                  child: Scrollbar(
                    thumbVisibility: true,
                    radius: const Radius.circular(10),
                    child: ListView.builder(
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        return _buildMessageTile(
                            msg['message'], msg['type'] == 'sent');
                      },
                    ),
                  ),
                )),
    );
  }

  Widget _buildNumberPad() {
    return Column(
      children: [
        _buildNumberRow([1, 2, 3]),
        _buildNumberRow([4, 5, 6]),
        _buildNumberRow([7, 8, 9]),
        _buildNumberRow(['X', 0, 'C']),
      ],
    );
  }

  Widget _buildNumberRow(List<dynamic> row) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: row.map((item) {
        return Expanded(
          child: GestureDetector(
              onTap: () {
                if (item == 'X') {
                  _discardSelection();
                } else if (item == 'C') {
                  _showClearChatConfirmationDialog(); // Call the dialog method
                } else {
                  _selectNumber(item as int);
                }
              },
              child: Container(
                margin: const EdgeInsets.all(6),
                height: 60,
                decoration: BoxDecoration(
                  color: selectedNumbers.contains(item)
                      ? const Color(0xFF0C1243)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: selectedNumbers.contains(item)
                      ? Border.all(color: Colors.white, width: 2)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    )
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  item.toString(),
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: selectedNumbers.contains(item)
                        ? Colors.white
                        : const Color(0xFF01546B),
                  ),
                ),
              )),
        );
      }).toList(),
    );
  }

  Future<void> _clearChat() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chatHistory');

    if (!mounted) return;

    Navigator.of(context).pop(); // Optional: remove if not inside dialog

    setState(() {
      messages.clear();
      selectedNumbers.clear();
      selectedMessageNumber = "";
      showPredefinedBox = false;
    });
  }

  Future<void> _showClearChatConfirmationDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151d67),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(
          child: Text(
            "Are you sure you want to clear the chat history?",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        content: const Text(
          "This will permanently remove all chat messages from local storage.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Color.fromARGB(179, 229, 229, 229),
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Cancel
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
              side: const BorderSide(color: Color(0xFF151d67), width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "No",
              style: TextStyle(color: Color(0xFF151d67), fontSize: 18),
            ),
          ),
          ElevatedButton(
            onPressed: _clearChat,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 18, 115, 194),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "Yes, Clear",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFF151d67),
        appBar: AppBar(
          backgroundColor: const Color(0xFF151d67),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text("Web Client",
              style: TextStyle(color: Colors.white, fontSize: 20)),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                children: const [
                  Text("Active Now",
                      style: TextStyle(color: Colors.white, fontSize: 14)),
                  SizedBox(width: 6),
                  CircleAvatar(radius: 5, backgroundColor: Colors.cyanAccent),
                ],
              ),
            ),
          ],
        ),
        body: Container(
          // Temporary border to identify the space used by body
          // decoration: BoxDecoration(
          //   border:
          //       Border.all(color: Colors.yellow, width: 2),
          // ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: _buildDynamicHeader(),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18.0, vertical: 0),
                child: Container(
                  // Temporary border to identify the space used by clear and pick message buttons
                  // decoration: BoxDecoration(
                  //   border: Border.all(
                  //       color: Colors.yellow,
                  //       width: 2),
                  // ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => setState(
                              () => showPredefinedBox = !showPredefinedBox),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF27548A),
                            minimumSize: const Size.fromHeight(48),
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            shadowColor: Colors.black.withOpacity(0.25),
                          ),
                          child: Text(
                            showPredefinedBox ? "Hide" : "Pick a message",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _showClearChatConfirmationDialog,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0XFFE3D095),
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Clear chat",
                            style: TextStyle(
                              color: Color.fromARGB(255, 37, 34, 0),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
                child: _buildNumberPad(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton(
                  onPressed:
                      selectedMessageNumber.isNotEmpty ? _sendMessage : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedMessageNumber.isNotEmpty
                        ? Color.fromRGBO(2, 9, 72, 1)
                        : Colors.grey.shade600,
                    minimumSize: const Size(double.infinity, 55),
                    side: selectedMessageNumber.isEmpty
                        ? const BorderSide(color: Colors.grey, width: 1)
                        : BorderSide(
                            color: Colors.white), // no border when enabled
                  ),
                  child: Text(
                    "Send",
                    style: TextStyle(
                      color: selectedMessageNumber.isNotEmpty
                          ? Colors.white
                          : Colors.grey.shade400,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ));
  }

  @override
  void dispose() {
    super.dispose();
    _chatService.stopListeningForChatMessages();
  }
}
