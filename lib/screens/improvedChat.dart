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
    setState(() {
      messages = chatHistory;

      // ✅ Automatically hide predefined box if messages now exist
      if (messages.isNotEmpty) {
        showPredefinedBox = false;
      }
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
    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSent ? const Color(0xFFA3E2FF) : Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text, style: const TextStyle(fontSize: 18)),
      ),
    );
  }

  Widget _buildDynamicHeader() {
    if (messages.isEmpty && showPredefinedBox) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 16.0, bottom: 10, top: 10),
            child: Text(
              "Select the message code to send",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
          // Wrap in a fixed-height container instead of Expanded
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white),
              borderRadius: BorderRadius.circular(10),
              color: const Color(0xFF10194E),
            ),
            height: 250, // Adjust height as needed
            child: FutureBuilder(
              future: _chatMessageScheduler.getCachedChatMessages(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data as List<Map<String, dynamic>>;
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
                            fontSize: 18,
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
      );
    } else if (messages.isEmpty && !showPredefinedBox) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 40),
          child: Text(
            "No messages yet",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      );
    } else {
      // Show chat history if messages exist
      return Padding(
        padding: const EdgeInsets.only(top: 10, left: 16),
        child: Column(
          children: messages
              .map((msg) =>
                  _buildMessageTile(msg['message'], msg['type'] == 'sent'))
              .toList(),
        ),
      );
    }
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
              margin: const EdgeInsets.all(5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: selectedNumbers.contains(item)
                    ? const Color(0xFF0C1243)
                    : Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                item.toString(),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: selectedNumbers.contains(item)
                      ? Colors.white
                      : const Color(0xFF01546B),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
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
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('chatHistory');
              Navigator.of(ctx).pop();
              setState(() {
                messages.clear();
                selectedNumbers.clear();
                selectedMessageNumber = "";
                showPredefinedBox = false;
              });
            },
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
    final isChatStarted = messages.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF151d67),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151d67),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Vessel 003",
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: _buildDynamicHeader(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () =>
                  setState(() => showPredefinedBox = !showPredefinedBox),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: Text(
                showPredefinedBox
                    ? "Close message box"
                    : "Pick a message to send",
                style: const TextStyle(
                    color: Color(0xFF151d67),
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: _buildNumberPad(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton(
              onPressed: selectedMessageNumber.isNotEmpty ? _sendMessage : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedMessageNumber.isNotEmpty
                    ? Colors.white
                    : Colors.grey.shade600,
                minimumSize: const Size(double.infinity, 55),
              ),
              child: Text(
                "Send",
                style: TextStyle(
                  color: selectedMessageNumber.isNotEmpty
                      ? const Color(0xFF151d67)
                      : Colors.grey.shade400,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _chatService.stopListeningForChatMessages();
    super.dispose();
  }
}
