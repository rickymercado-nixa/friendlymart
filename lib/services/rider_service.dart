import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class RiderService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  StreamSubscription<Position>? _positionStream;

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

  /// 🚴 Start updating rider's location every ~10 seconds
  void startUpdatingLocation(String riderId) {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // update every 10 meters
      ),
    ).listen((Position position) {
      _firestore.collection("users").doc(riderId).update({
        "currentLocation": GeoPoint(position.latitude, position.longitude),
        "lastUpdated": FieldValue.serverTimestamp(),
      });
    });
  }

  /// 🛑 Stop updating rider's location
  void stopUpdatingLocation() {
    _positionStream?.cancel();
    _positionStream = null;
  }
}
