import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../login.dart';
import 'package:friendlymart/services/rider_service.dart';

class RiderDashboard extends StatelessWidget {
  RiderDashboard({super.key});

  final RiderService _riderService = RiderService();

  void _logout(BuildContext context) async {
    await _riderService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  /// Fetch all users referenced in these orders and map them
  Future<Map<String, dynamic>> _fetchUsersForOrders(
      List<QueryDocumentSnapshot> orders) async {
    // Collect all user document IDs from customerId references
    final userIds = orders
        .map((o) => (o['customerId'] as DocumentReference).id)
        .toSet()
        .toList();

    if (userIds.isEmpty) return {};

    // Fetch all users with a single query
    final usersSnap = await FirebaseFirestore.instance
        .collection("users")
        .where(FieldPath.documentId, whereIn: userIds)
        .get();

    return {for (var u in usersSnap.docs) u.id: u.data()};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Rider Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: "Logout",
          ),
        ],
      ),
      body: FutureBuilder<String?>(
        future: _riderService.getRiderStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text("Unable to load rider status."));
          }

          final status = snapshot.data;

          if (status == "approved") {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("orders")
                  .where("orderStatus", isEqualTo: "Pending")
                  .snapshots(),
              builder: (context, orderSnapshot) {
                if (orderSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!orderSnapshot.hasData ||
                    orderSnapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No new orders right now."));
                }

                final orders = orderSnapshot.data!.docs;

                return FutureBuilder<Map<String, dynamic>>(
                  future: _fetchUsersForOrders(orders),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final userMap = userSnapshot.data ?? {};

                    return ListView.builder(
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final doc = orders[index];
                        final data = doc.data() as Map<String, dynamic>;

                        // customerId is a DocumentReference
                        final DocumentReference customerRef =
                        data["customerId"];
                        final customerData = userMap[customerRef.id] ?? {};
                        final customerName =
                            customerData['name'] ?? "Unknown";
                        final customerPhone =
                            customerData['phone'] ?? "N/A";

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: ExpansionTile(
                            title: Text(
                              "Deliver to: ${data['deliveryLocation'] ?? 'No location'}",
                              style:
                              const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text("Order ID: ${doc.id}"),
                            childrenPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Customer: $customerName"),
                                    Text("Phone: $customerPhone"),
                                    Text(
                                        "Total: \₱${data['totalAmount'] ?? '0.00'}"),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        ElevatedButton(
                                          onPressed: () async {
                                            final riderUid = FirebaseAuth
                                                .instance.currentUser!.uid;
                                            await FirebaseFirestore.instance
                                                .collection("orders")
                                                .doc(doc.id)
                                                .update({
                                              "riderId": riderUid,
                                              "orderStatus": "Accepted",
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                          ),
                                          child: const Text("Accept"),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: () async {
                                            await FirebaseFirestore.instance
                                                .collection("orders")
                                                .doc(doc.id)
                                                .update({
                                              "riderId": null,
                                              "orderStatus": "Rejected",
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          child: const Text("Reject"),
                                        ),
                                      ],
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
                );
              },
            );
          } else if (status == "pending") {
            return const Center(
              child: Text(
                "Your application as a rider is under review.\nPlease wait for store approval.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          } else if (status == "rejected") {
            return const Center(
              child: Text(
                "Your rider application has been rejected.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          } else {
            return const Center(child: Text("Unknown status."));
          }
        },
      ),
    );
  }
}
