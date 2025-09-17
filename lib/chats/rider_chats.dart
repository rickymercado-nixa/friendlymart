import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../chats/chat_screen.dart';
import 'package:friendlymart/screens/delete/rider_delete_chat.dart';

class RiderChatsScreen extends StatelessWidget {
  const RiderChatsScreen({super.key});

  Future<Map<String, String>> _getChatDetails(Map<String, dynamic> chatData) async {
    final orderId = chatData['orderId'];
    String customerName = "Customer";
    String orderProduct = "Order";


    // Fetch order details
    final orderDoc = await FirebaseFirestore.instance.collection("orders").doc(orderId).get();
    if (orderDoc.exists) {
      final orderData = orderDoc.data()!;

      // ✅ Get first product name from items array
      if (orderData['items'] != null && orderData['items'] is List && orderData['items'].isNotEmpty) {
        final firstItem = orderData['items'][0];
        orderProduct = firstItem['name'] ?? "Order";

        // Optional: if you want to show "Burger Combo + 2 more"
        if (orderData['items'].length > 1) {
          orderProduct = "${firstItem['name']} + ${orderData['items'].length - 1} more";
        }
      }

      // Resolve customer reference
      if (orderData['customerId'] is DocumentReference) {
        final customerRef = orderData['customerId'] as DocumentReference;
        final customerDoc = await customerRef.get();
        if (customerDoc.exists) {
          final userData = customerDoc.data() as Map<String, dynamic>;
          customerName = userData['name'] ?? "Customer";
        }
      }
    }

    return {
      "customerName": customerName,
      "orderProduct": orderProduct,
    };
  }

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

              return FutureBuilder<Map<String, String>>(
                future: _getChatDetails(data),
                builder: (context, detailsSnap) {
                  if (!detailsSnap.hasData) {
                    return const ListTile(title: Text("Loading..."));
                  }

                  final details = detailsSnap.data!;

                  return ListTile(
                    title: Text("Order: ${details['orderProduct']}"),
                    subtitle: Text("Customer: ${details['customerName']}"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            chatId: chat.id,
                            orderId: data['orderId'],
                            customerName: details['customerName']!,
                            riderName: "You",
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
