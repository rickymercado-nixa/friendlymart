import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderReviewScreen extends StatefulWidget {
  const OrderReviewScreen({super.key});

  @override
  State<OrderReviewScreen> createState() => _OrderReviewScreenState();
}

class _OrderReviewScreenState extends State<OrderReviewScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? "Pending Orders"
              : _selectedIndex == 1
              ? "In Progress Orders"
              : _selectedIndex == 2
              ? "Cancelled Orders"
              : "Completed Orders",
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("orders")
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

          final allOrders = snapshot.data!.docs;
          for (var doc in allOrders) {
            final data = doc.data() as Map<String, dynamic>;
            print("Order ${doc.id} -> ${data['orderStatus']}");
          }


          // Filter based on status
          final orders = allOrders.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['orderStatus'] ?? "Pending";

            if (_selectedIndex == 0) {
              return status == "Accepted" || status == "Pending";
            } else if (_selectedIndex == 1) {
              return status == "Processing" || status == "OnTheWay";
            } else if (_selectedIndex == 2) {
              return status == "Cancelled";
            } else if (_selectedIndex == 3) {
              return status == "Delivered";
            }
            return false;
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
              final customerId = data['customerId'];

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
                  subtitle: FutureBuilder<DocumentSnapshot>(
                    future: (data['customerId'] as DocumentReference).get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text("Loading customer... • ₱$totalAmount");
                      }
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return Text("Unknown Customer • ₱$totalAmount");
                      }
                      final userData = snapshot.data!.data() as Map<String, dynamic>;
                      final customerName = userData['name'] ?? "Unnamed";
                      return Text("$customerName • ₱$totalAmount");
                    },
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

                          const SizedBox(height: 10),
                          Text("Current Status: $orderStatus",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                            SizedBox(height: 10),
                          // Only Admin can update order status
                          if (orderStatus != "Delivered" &&
                              orderStatus != "Cancelled")
                            DropdownButtonFormField<String>(
                              value: orderStatus,
                              items: const [
                                DropdownMenuItem(value: "Accepted", child: Text("Accepted")),
                                DropdownMenuItem(value: "Pending", child: Text("Pending")),
                                DropdownMenuItem(value: "Processing", child: Text("Processing")),
                                DropdownMenuItem(value: "OnTheWay", child: Text("Out for Delivery")),
                                DropdownMenuItem(value: "Delivered", child: Text("Delivered")),
                                DropdownMenuItem(value: "Cancelled", child: Text("Cancelled")),
                              ],
                              onChanged: (newStatus) async {
                                if (newStatus != null) {
                                  await FirebaseFirestore.instance
                                      .collection("orders")
                                      .doc(order.id)
                                      .update({"orderStatus": newStatus});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Order status updated to $newStatus"),
                                      backgroundColor: Colors.blue,
                                    ),
                                  );
                                }
                              },
                              decoration: InputDecoration(
                                labelText: "Update Status",
                                border: OutlineInputBorder(
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
        selectedItemColor: Colors.blue[700],
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.pending_actions),
            label: "Pending",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping),
            label: "In Progress",
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
