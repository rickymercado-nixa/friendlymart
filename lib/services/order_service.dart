import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new order from cart data
  static Future<bool> createOrder({
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    String paymentMethod = "Cash on Delivery",
    double deliveryFee = 0,
    String deliveryLocation = "",
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      await _firestore.collection('orders').add({
        'acceptedBy': "",
        'assignedBy': "System",
        'createdAt': FieldValue.serverTimestamp(),
        'customerId': _firestore.doc('users/${user.uid}'),
        'deliveryFee': deliveryFee,
        'deliveryLocation': deliveryLocation,
        'items': items,
        'orderStatus': "Pending",
        'paymentMethod': paymentMethod,
        'paymentStatus': "Pending",
        'riderId': "",
        'totalAmount': totalAmount,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error creating order: $e');
      return false;
    }
  }

  // Get user's orders stream
  static Stream<QuerySnapshot>? getUserOrdersStream() {
    final user = _auth.currentUser;
    if (user == null) return null;

    return _firestore
        .collection('orders')
        .where('customerId', isEqualTo: _firestore.doc('users/${user.uid}'))
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get specific order by ID
  static Future<DocumentSnapshot?> getOrder(String orderId) async {
    try {
      return await _firestore.collection('orders').doc(orderId).get();
    } catch (e) {
      print('Error getting order: $e');
      return null;
    }
  }

  // Update order status (if needed for customer actions)
  static Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'orderStatus': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating order status: $e');
      return false;
    }
  }
}