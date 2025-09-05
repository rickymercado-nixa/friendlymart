import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;       // Firestore chat doc ID
  final String orderId;      // Related order
  final String customerName; // For display
  final String riderName;    // For display

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.orderId,
    required this.customerName,
    required this.riderName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;

  Future<void> _sendMessage() async {
    if (_msgController.text.trim().isEmpty) return;

    final message = {
      "senderId": user!.uid,
      "text": _msgController.text.trim(),
      "image": "",
      "read": false,
      "timestamp": FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection("chats")
        .doc(widget.chatId)
        .collection("messages")
        .add(message);

    _msgController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.customerName} ↔ ${widget.riderName}"),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("chats")
                  .doc(widget.chatId)
                  .collection("messages")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg =
                    messages[index].data() as Map<String, dynamic>;
                    final isMe = msg["senderId"] == user!.uid;

                    return Align(
                      alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.green[300] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          msg["text"] ?? "",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      decoration: const InputDecoration(
                        hintText: "Type a message...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.green),
                    onPressed: _sendMessage,
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
