import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomerOrdersPage extends StatelessWidget {
  const CustomerOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userRef = FirebaseFirestore.instance.collection('users').doc(currentUser!.uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Orders"),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("orders")
            .where("customerId", isEqualTo: userRef)
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            print("Fetched documents: ${snapshot.data!.docs.length}");
            print("Fetched documents: $userRef");
            for (var doc in snapshot.data!.docs) {
              print("Doc ID: ${doc.id}, Data: ${doc.data()}");
            }
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          print("Fetched orders: ${snapshot.data!.docs.length}");
          for (var doc in snapshot.data!.docs) {
            print(doc.data());
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: orders.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final order = orders[index];
              final data = order.data() as Map<String, dynamic>;

              final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
              final orderStatus = data['orderStatus'] ?? "Pending";
              final totalAmount = data['totalAmount'] ?? 0;
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: ExpansionTile(
                  leading: Icon(Icons.receipt, color: Colors.blue[700]),
                  title: Text("Order #${order.id.substring(0, 6)}"),
                  subtitle: Text(
                    "Status: $orderStatus • ₱$totalAmount",
                    style: const TextStyle(fontSize: 14),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (createdAt != null)
                            Text("Placed: ${createdAt.toLocal()}"),
                          const SizedBox(height: 8),
                          Text("Items:",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          ...items.map((item) {
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.shopping_bag_outlined),
                              title: Text(item['name'] ?? "Unknown"),
                              subtitle: Text("Qty: ${item['quantity']}"),
                              trailing: Text("₱${item['price']}"),
                            );
                          }).toList(),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "No orders found",
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
