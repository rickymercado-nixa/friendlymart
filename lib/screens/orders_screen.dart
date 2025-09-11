import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'orders_tracking_screen.dart';

class CustomerOrdersPage extends StatefulWidget {
  const CustomerOrdersPage({super.key});

  @override
  State<CustomerOrdersPage> createState() => _CustomerOrdersPageState();
}

class _CustomerOrdersPageState extends State<CustomerOrdersPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userRef = FirebaseFirestore.instance.collection('users').doc(currentUser!.uid);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? "My Active Orders"
              : _selectedIndex == 1
              ? "My Cancelled Orders"
              : "My Completed Orders",
        ),
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
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          // filter based on selected tab
          final allOrders = snapshot.data!.docs;
          final orders = allOrders.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['orderStatus'] ?? "Pending";

            if (_selectedIndex == 0) {
              // Active orders (not cancelled or completed)
              return status != "Cancelled" && status != "Delivered";
            } else if (_selectedIndex == 1) {
              // Cancelled orders
              return status == "Cancelled";
            } else {
              // Completed orders
              return status == "Delivered";
            }
          }).toList();

          if (orders.isEmpty) {
            return _buildEmptyState();
          }

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
                  leading: Icon(
                    Icons.receipt,
                    color: orderStatus == "Cancelled"
                        ? Colors.red
                        : orderStatus == "Delivered"
                        ? Colors.green
                        : Colors.blue[700],
                  ),
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
                          if (_selectedIndex == 0 && createdAt != null) ...[
                            const SizedBox(height: 8),
                            if (DateTime.now().difference(createdAt).inMinutes < 5 &&
                                (orderStatus == "Pending" || orderStatus == "Processing"))
                              ElevatedButton.icon(
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection("orders")
                                      .doc(order.id)
                                      .update({"orderStatus": "Cancelled"});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Order cancelled successfully"),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.cancel, color: Colors.white),
                                label: const Text("Cancel Order"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                              )
                            else
                              Text(
                                "❌ Cannot cancel (time expired)",
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                          ],
                          if(_selectedIndex == 0)
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OrderTrackingScreen(orderId: order.id),
                                ),
                              );
                            },
                            icon: const Icon(Icons.location_on),
                            label: const Text("Track Order"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: "Active",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cancel),
            label: "Cancelled",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: "Completed",
          ),
        ],
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
