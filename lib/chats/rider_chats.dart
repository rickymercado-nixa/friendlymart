import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../chats/chat_screen.dart';

class RiderChatsScreen extends StatelessWidget {
  const RiderChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final riderUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("My Chats")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("chats")
            .where("participants", arrayContains: riderUid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data!.docs;

          if (chats.isEmpty) {
            return const Center(child: Text("No chats yet."));
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final data = chat.data() as Map<String, dynamic>;

              return ListTile(
                title: Text("Order: ${data['orderId']}"),
                subtitle: Text("Chat ID: ${chat.id}"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        chatId: chat.id,
                        orderId: data['orderId'],
                        customerName: "Customer",
                        riderName: "You",
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
