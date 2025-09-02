import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RiderService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  /// Get the rider's status (approved, pending, rejected)
  Future<String?> getRiderStatus() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _firestore.collection("users").doc(uid).get();
    return doc.data()?["riderStatus"];
  }

  /// Logout the rider
  Future<void> logout() async {
    await _auth.signOut();
  }
}
