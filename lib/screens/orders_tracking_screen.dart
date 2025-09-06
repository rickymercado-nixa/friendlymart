import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  GoogleMapController? _mapController;
  LatLng? _riderLocation;
  LatLng? _deliveryLocation;
  String _orderStatus = "Loading...";
  String? _riderId;

  // Store location
  final LatLng storeLocation = LatLng(6.220447249809727, 125.0647953991407);

  StreamSubscription<DocumentSnapshot>? _orderSubscription;
  StreamSubscription<DocumentSnapshot>? _riderSubscription;

  @override
  void initState() {
    super.initState();
    _listenToOrder();
  }

  void _listenToOrder() {
    _orderSubscription = FirebaseFirestore.instance
        .collection("orders")
        .doc(widget.orderId)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) return;
      final data = doc.data()!;
      if (!mounted) return;

      setState(() {
        _orderStatus = data['orderStatus'] ?? "Unknown";

        // Delivery location
        if (data['deliveryLocation'] != null &&
            data['deliveryLocation']['lat'] != null &&
            data['deliveryLocation']['lng'] != null) {
          _deliveryLocation = LatLng(
            data['deliveryLocation']['lat'],
            data['deliveryLocation']['lng'],
          );
        }

        // Get riderId and start listening to rider location
        if (_riderId == null && data['riderId'] != null) {
          _riderId = data['riderId'];
          _listenToRiderLocation(_riderId!);
        }

        // Optional: handle delivered order
        if (_orderStatus == "Delivered") {
          _orderSubscription?.cancel();
          _riderSubscription?.cancel();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Your order has been delivered!")),
          );
        }
      });
    });
  }

  void _listenToRiderLocation(String riderId) {
    _riderSubscription = FirebaseFirestore.instance
        .collection("users")
        .doc(riderId)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) return;
      final data = doc.data();
      if (data == null || data['currentLocation'] == null) return;

      final GeoPoint loc = data['currentLocation'];
      setState(() {
        _riderLocation = LatLng(loc.latitude, loc.longitude);
      });

      // Animate camera to follow rider
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(_riderLocation!),
        );
      }
    });
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    _riderSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Set<Marker> markers = {
      Marker(
        markerId: const MarkerId("store"),
        position: storeLocation,
        infoWindow: const InfoWindow(title: "Store"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
      if (_deliveryLocation != null)
        Marker(
          markerId: const MarkerId("delivery"),
          position: _deliveryLocation!,
          infoWindow: const InfoWindow(title: "Delivery Location"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      if (_riderLocation != null)
        Marker(
          markerId: const MarkerId("rider"),
          position: _riderLocation!,
          infoWindow: const InfoWindow(title: "Rider"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
    };

    Set<Polyline> polylines = {};
    if (_riderLocation != null && _deliveryLocation != null) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId("route"),
          points: [storeLocation, _riderLocation!, _deliveryLocation!],
          color: Colors.orange,
          width: 5,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Order Tracking")),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            color: Colors.blue.shade100,
            child: Text(
              "Status: $_orderStatus",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: storeLocation,
                zoom: 14,
              ),
              markers: markers,
              polylines: polylines,
              onMapCreated: (controller) => _mapController = controller,
            ),
          ),
        ],
      ),
    );
  }
}
