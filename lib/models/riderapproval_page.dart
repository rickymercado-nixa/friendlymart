import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RiderApprovalPage extends StatelessWidget {
  const RiderApprovalPage({super.key});

  void _updateRiderStatus(String uid, String status) async {
    await FirebaseFirestore.instance.collection("users").doc(uid).update({
      "riderStatus": status,
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Pending, Approved, Rejected
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Rider Management"),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: "Pending"),
              Tab(text: "Approved"),
              Tab(text: "Rejected"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            RiderListTab(status: "pending"),
            RiderListTab(status: "approved"),
            RiderListTab(status: "rejected"),
          ],
        ),
      ),
    );
  }
}

class RiderListTab extends StatelessWidget {
  final String status;
  const RiderListTab({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("users")
          .where("role", isEqualTo: "rider")
          .where("riderStatus", isEqualTo: status)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text("No $status riders."),
          );
        }

        final riders = snapshot.data!.docs;

        return ListView.builder(
          itemCount: riders.length,
          itemBuilder: (context, index) {
            final rider = riders[index];
            final data = rider.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: const Icon(Icons.motorcycle, color: Colors.blue),
                title: Text(data["name"] ?? "Unknown"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Email: ${data["email"] ?? ""}"),
                    Text("Phone: ${data["phone"] ?? ""}"),
                    Text("Address: ${data["address"] ?? ""}"),
                  ],
                ),
                trailing: status == "pending"
                    ? Wrap(
                  spacing: 8,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () {
                        FirebaseFirestore.instance
                            .collection("users")
                            .doc(rider.id)
                            .update({"riderStatus": "approved"});
                      },
                      tooltip: "Approve",
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () {
                        FirebaseFirestore.instance
                            .collection("users")
                            .doc(rider.id)
                            .update({"riderStatus": "rejected"});
                      },
                      tooltip: "Reject",
                    ),
                  ],
                )
                    : null, // Hide buttons for approved/rejected
              ),
            );
          },
        );
      },
    );
  }
}
