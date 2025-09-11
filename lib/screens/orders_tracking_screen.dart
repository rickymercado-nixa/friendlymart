import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

String _etaText = "";

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  GoogleMapController? _mapController;
  LatLng? _riderLocation;
  LatLng? _deliveryLocation;
  String _orderStatus = "Loading...";
  String? _riderId;

  final LatLng storeLocation = LatLng(6.220447249809727, 125.0647953991407);

  StreamSubscription<DocumentSnapshot>? _orderSubscription;
  StreamSubscription<DocumentSnapshot>? _riderSubscription;

  Set<Polyline> polylines = {};

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

        if (data['deliveryLocation'] != null &&
            data['deliveryLocation']['lat'] != null &&
            data['deliveryLocation']['lng'] != null) {
          _deliveryLocation = LatLng(
            data['deliveryLocation']['lat'],
            data['deliveryLocation']['lng'],
          );
        }

        if (_riderId == null && data['riderId'] != null) {
          _riderId = data['riderId'];
          _listenToRiderLocation(_riderId!);
        }

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
        .listen((doc) async {
      if (!doc.exists) return;
      final data = doc.data();
      if (data == null || data['currentLocation'] == null) return;

      final GeoPoint loc = data['currentLocation'];
      LatLng newRiderLocation = LatLng(loc.latitude, loc.longitude);

      setState(() {
        _riderLocation = newRiderLocation;
      });

      if (_deliveryLocation != null) {
        await _fetchRoute(_riderLocation!, _deliveryLocation!);
      }

      if (_mapController != null && _riderLocation != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(_riderLocation!),
        );
      }
    });
  }

  Future<void> _fetchRoute(LatLng start, LatLng end) async {
    final url =
        "https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['routes'].isNotEmpty) {
        final route = data['routes'][0];
        final coords = data['routes'][0]['geometry']['coordinates'] as List;
        final List<LatLng> polyPoints = coords
            .map((c) => LatLng(c[1].toDouble(), c[0].toDouble()))
            .toList();

        // distance & duration
        final double distanceMeters = (route['distance'] as num).toDouble();
        final double durationSeconds = (route['duration'] as num).toDouble();

        // Convert to readable format
        final km = (distanceMeters / 1000).toStringAsFixed(2);
        final minutes = (durationSeconds / 60).round();

        setState(() {
          polylines = {
            Polyline(
              polylineId: const PolylineId("rider_to_delivery"),
              points: polyPoints,
              color: Colors.orange,
              width: 5,
            ),
          };
          _etaText = "ETA: $minutes min • $km km";
        });
      }
    }
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

    return Scaffold(
      appBar: AppBar(title: const Text("Order Tracking")),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            color: Colors.blue.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Status: $_orderStatus",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_etaText.isNotEmpty)
                  Text(
                    _etaText,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
              ],
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
