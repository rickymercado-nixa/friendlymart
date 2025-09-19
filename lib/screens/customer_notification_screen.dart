import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String customerId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _markAllAsRead();
  }

  Future<void> _markAllAsRead() async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('customerId', isEqualTo: _firestore.doc('users/$customerId'))
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.update({'isRead': true});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notifications"),
        backgroundColor: Colors.blue[600],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('notifications')
            .where('customerId', isEqualTo: _firestore.doc('users/$customerId'))
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text("No notifications yet"),
            );
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index].data() as Map<String, dynamic>;
              final message = notif['message'] ?? '';
              final type = notif['type'] ?? '';
              final timestamp = notif['timestamp'] != null
                  ? (notif['timestamp'] as Timestamp).toDate()
                  : null;

              return ListTile(
                leading: Icon(
                  type == 'PickedUp' ? Icons.local_shipping : Icons.info,
                  color: Colors.blue[600],
                ),
                title: Text(message),
                subtitle: timestamp != null
                    ? Text('${timestamp.toLocal()}')
                    : null,
                onTap: () {
                  // Optional: Navigate to order detail page if orderId exists
                  final orderId = notif['orderId'];
                  if (orderId != null) {
                    // Navigator.push(... to order detail)
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
