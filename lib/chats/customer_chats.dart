import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class CustomerChatsScreen extends StatelessWidget {
  const CustomerChatsScreen({super.key});

  Future<Map<String, String>> _getChatDetails(Map<String, dynamic> chatData) async {
    final orderId = chatData['orderId'];
    String riderName = "Rider";
    String orderProduct = "Order";

    // Fetch order details
    final orderDoc =
    await FirebaseFirestore.instance.collection("orders").doc(orderId).get();
    if (orderDoc.exists) {
      final orderData = orderDoc.data()!;

      // ✅ Get first product name from items array
      if (orderData['items'] != null &&
          orderData['items'] is List &&
          orderData['items'].isNotEmpty) {
        final firstItem = orderData['items'][0];
        orderProduct = firstItem['name'] ?? "Order";

        if (orderData['items'].length > 1) {
          orderProduct = "${firstItem['name']} + ${orderData['items'].length - 1} more";
        }
      }

      // ✅ Resolve riderId (string UID, not reference)
      if (orderData['riderId'] != null && orderData['riderId'] is String) {
        final riderUid = orderData['riderId'];
        final riderDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(riderUid)
            .get();
        if (riderDoc.exists) {
          final riderData = riderDoc.data() as Map<String, dynamic>;
          riderName = riderData['name'] ?? "Rider";
        }
      }
    }

    return {
      "riderName": riderName,
      "orderProduct": orderProduct,
    };
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Messages"),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("chats")
            .where("participants", arrayContains: user!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No conversations yet."));
          }

          final chats = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final data = chat.data() as Map<String, dynamic>;

              return FutureBuilder<Map<String, String>>(
                future: _getChatDetails(data),
                builder: (context, detailsSnap) {
                  if (!detailsSnap.hasData) {
                    return const ListTile(title: Text("Loading..."));
                  }

                  final details = detailsSnap.data!;

                  return ListTile(
                    leading: const Icon(Icons.chat_bubble_outline),
                    title: Text("Order: ${details['orderProduct']}"),
                    subtitle: Text("Rider: ${details['riderName']}"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            chatId: chat.id,
                            orderId: data['orderId'],
                            customerName: "You",
                            riderName: details['riderName']!,
                          ),
                        ),
                      );
                    },
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
