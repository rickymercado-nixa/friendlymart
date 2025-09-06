import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:friendlymart/screens/ontheway_screen.dart';
import '../login.dart';
import '../../chats/rider_chats.dart';
import 'package:friendlymart/services/rider_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


class RiderDashboard extends StatefulWidget {
  const RiderDashboard({super.key});

  @override
  State<RiderDashboard> createState() => _RiderDashboardState();
}

class _RiderDashboardState extends State<RiderDashboard> {
  final RiderService _riderService = RiderService();
  int _selectedIndex = 0;

  void _logout(BuildContext context) async {
    await _riderService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  final List<String> _statuses = [
    "Pending",
    "Accepted",
    "PickedUp",
    "OnTheWay",
    "Delivered"
  ];

  Widget _buildOrdersList(String status) {
    Query query = FirebaseFirestore.instance
        .collection("orders")
        .where("orderStatus", isEqualTo: status);

    if (status != "Pending") {
      query = query.where("riderId", isEqualTo: FirebaseAuth.instance.currentUser!.uid);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              "No $status orders",
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
          );
        }

        final orders = snapshot.data!.docs;

        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final doc = orders[index];
            final data = doc.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: Text(
                  "Order ID: ${doc.id}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("Total: ₱${data['totalAmount'] ?? '0.00'}"),
                trailing: () {
                  final riderUid = FirebaseAuth.instance.currentUser!.uid;

                  if (status == "Pending") {
                    return ElevatedButton(
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection("orders")
                            .doc(doc.id)
                            .update({
                          "riderId": riderUid,
                          "orderStatus": "Accepted",
                        });
                      },
                      child: const Text("Accept"),
                    );
                  } else if (status == "Accepted") {
                    return ElevatedButton(
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection("orders")
                            .doc(doc.id)
                            .update({
                          "orderStatus": "PickedUp",
                        });

                        await FirebaseFirestore.instance.collection(
                            "notifications").add({
                          "orderId": doc.id,
                          "type": "PickedUp",
                          "message": "Your order has been picked up by the rider",
                          "timestamp": FieldValue.serverTimestamp(),
                          "customerId": data['customerId'],
                        });
                      },
                      child: const Text("Picked Up"),
                    );
                  } else if (status == "PickedUp") {
                    return ElevatedButton(
                      onPressed: () async {
                        final deliveryLoc = data["deliveryLocation"];
                        final riderUid = FirebaseAuth.instance.currentUser!.uid;

                        if (deliveryLoc != null && deliveryLoc['lat'] != null && deliveryLoc['lng'] != null) {
                          final customerGeo = LatLng(
                            (deliveryLoc['lat'] as num).toDouble(),
                            (deliveryLoc['lng'] as num).toDouble(),
                          );

                          // Navigate to the map first
                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DeliveryNavigationScreen(
                                  customerLocation: customerGeo,
                                  address: deliveryLoc['address'] ?? "Customer Address",
                                  riderId: riderUid,
                                ),
                              ),
                            );
                          }

                          // Then update Firestore to "OnTheWay"
                          await FirebaseFirestore.instance
                              .collection("orders")
                              .doc(doc.id)
                              .update({
                            "orderStatus": "OnTheWay",
                          });
                        }
                      },
                      child: const Text("On The Way"),
                    );
                  } else {
                    return null;
                  }
                }(),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primaryColor: Colors.blue[800],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue[800],
          foregroundColor: Colors.yellow[600],
          titleTextStyle: TextStyle(
            color: Colors.yellow[600],
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.yellow[600]),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.yellow[700],
            foregroundColor: Colors.blue[900],
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Rider Dashboard"),
          actions: [
            IconButton(
              icon: const Icon(Icons.chat),
              tooltip: "Chats",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RiderChatsScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: "Logout",
              onPressed: () => _logout(context),
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
              return _buildOrdersList(_statuses[_selectedIndex]);
            } else if (status == "pending") {
              return Center(
                child: Text(
                  "Your application is under review.\nPlease wait for approval.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.orange[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            } else if (status == "rejected") {
              return Center(
                child: Text(
                  "Your rider application has been rejected.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.red[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            } else {
              return const Center(child: Text("Unknown status."));
            }
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.blue[800],
          selectedItemColor: Colors.yellow[600],
          unselectedItemColor: Colors.yellow[400],
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.pending_actions),
              label: "Pending",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.check_circle),
              label: "Accepted",
            ),
            BottomNavigationBarItem(
                icon: Icon(Icons.inventory),
                label: "PickedUp"
            ),
            BottomNavigationBarItem(
                icon: Icon(Icons.directions_bike),
                label: "OnTheWay"
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_shipping),
              label: "Delivered",
            ),
            /*
            BottomNavigationBarItem(
              icon: Icon(Icons.cancel),
              label: "Rejected",
            ),
      */
          ],
        ),
      ),
    );
  }
}
