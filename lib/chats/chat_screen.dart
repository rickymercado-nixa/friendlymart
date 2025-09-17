import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String orderId;
  final String customerName;
  final String riderName;

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
      "status": "sending",
      "timestamp": FieldValue.serverTimestamp(),
    };

    final ref = await FirebaseFirestore.instance
        .collection("chats")
        .doc(widget.chatId)
        .collection("messages")
        .add(message);

    await ref.update({"status": "sent"});

    _msgController.clear();
  }

  void _markMessagesAsSeen() {
    FirebaseFirestore.instance
        .collection("chats")
        .doc(widget.chatId)
        .collection("messages")
        .where("senderId", isNotEqualTo: user!.uid)
        .get()
        .then((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.update({"status": "seen"});
      }
    });
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

                messages.sort((a, b) {
                  final aTime = (a["timestamp"] as Timestamp?)?.toDate() ?? DateTime.now();
                  final bTime = (b["timestamp"] as Timestamp?)?.toDate() ?? DateTime.now();
                  return bTime.compareTo(aTime);
                });

                _markMessagesAsSeen();

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg =
                    messages[index].data() as Map<String, dynamic>;
                    final isMe = msg["senderId"] == user!.uid;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment:
                        isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
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
                          if (isMe) // show status only for my messages
                            Padding(
                              padding: const EdgeInsets.only(right: 12, top: 2),
                              child: Icon(
                                msg["status"] == "sending"
                                    ? Icons.access_time
                                    : msg["status"] == "sent"
                                    ? Icons.done
                                    : Icons.done_all,
                                size: 16,
                                color: msg["status"] == "seen"
                                    ? Colors.yellow
                                    : Colors.grey,
                              ),
                            ),
                        ],
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
