import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class DeliveryNavigationScreen extends StatefulWidget {
  final LatLng customerLocation;
  final String address;
  final String riderId;

  const DeliveryNavigationScreen({
    super.key,
    required this.customerLocation,
    required this.address,
    required this.riderId,
  });

  @override
  State<DeliveryNavigationScreen> createState() =>
      _DeliveryNavigationScreenState();
}

String _etaText = "";

class _DeliveryNavigationScreenState extends State<DeliveryNavigationScreen> {
  StreamSubscription<Position>? _positionStream;
  LatLng? _riderLocation;
  GoogleMapController? _mapController;
  Set<Polyline> _polylines = {};

  final LatLng storeLocation =
  const LatLng(6.220447249809727, 125.0647953991407);

  @override
  void initState() {
    super.initState();
    _startRiderLocationUpdates();
  }

  void _startRiderLocationUpdates() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission denied")),
        );
        return;
      }
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) async {
      final newLoc = LatLng(position.latitude, position.longitude);

      setState(() {
        _riderLocation = newLoc;
      });

      await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.riderId)
          .set({
        "currentLocation": GeoPoint(position.latitude, position.longitude),
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (_mapController != null && _riderLocation != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(_riderLocation!),
        );
      }
    });
  }

  Future<void> _drawRoute() async {
    if (_riderLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Rider location not available")),
      );
      return;
    }

    const apiKey = "eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImIwM2JhZjI3OWQyZDQ4MGE5YjBkYzVmZjhlOWQ1ODMyIiwiaCI6Im11cm11cjY0In0="; // 🔑 replace with your ORS key
    final url =
        "https://api.openrouteservice.org/v2/directions/driving-car?api_key=$apiKey&start=${_riderLocation!.longitude},${_riderLocation!.latitude}&end=${widget.customerLocation.longitude},${widget.customerLocation.latitude}";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final List<dynamic> coords =
        data["features"][0]["geometry"]["coordinates"];

        List<LatLng> polylinePoints = coords
            .map((c) => LatLng(c[1], c[0]))
            .toList();

        final double distanceMeters = (data["features"][0]["properties"]["segments"][0]["distance"] as num).toDouble();
        final double durationSeconds = (data["features"][0]["properties"]["segments"][0]["duration"] as num).toDouble();

        final km = (distanceMeters / 1000).toStringAsFixed(2);
        final minutes = (durationSeconds / 60).round();

        setState(() {
          _polylines.clear();
          _polylines.add(
            Polyline(
              polylineId: const PolylineId("route"),
              points: polylinePoints,
              color: Colors.blue,
              width: 5,
            ),
          );
          _etaText = "ETA: $minutes min • $km km";
        });

        // Auto fit map
        LatLngBounds bounds = LatLngBounds(
          southwest: LatLng(
            polylinePoints.map((p) => p.latitude).reduce((a, b) => a < b ? a : b),
            polylinePoints.map((p) => p.longitude).reduce((a, b) => a < b ? a : b),
          ),
          northeast: LatLng(
            polylinePoints.map((p) => p.latitude).reduce((a, b) => a > b ? a : b),
            polylinePoints.map((p) => p.longitude).reduce((a, b) => a > b ? a : b),
          ),
        );

        _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Route error: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching route: $e")),
      );
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Set<Marker> markers = {
      Marker(
        markerId: const MarkerId("customer"),
        position: widget.customerLocation,
        infoWindow: InfoWindow(title: widget.address),
      ),
      Marker(
        markerId: const MarkerId("store"),
        position: storeLocation,
        infoWindow: const InfoWindow(title: "Store"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    };

    if (_riderLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId("rider"),
        position: _riderLocation!,
        infoWindow: const InfoWindow(title: "Rider"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
    }

    return Scaffold(
    appBar: AppBar(title: const Text("Delivery Navigation")),
    body: Column(
      children: [
        if (_etaText != null)
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            color: Colors.blue.shade100,
            child: Text(
              _etaText!,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        Expanded(
          child: _riderLocation == null
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _riderLocation!,
              zoom: 15,
            ),
            markers: markers,
            polylines: _polylines,
            onMapCreated: (controller) => _mapController = controller,
          ),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _drawRoute,
      label: const Text("Navigation"),
      icon: const Icon(Icons.alt_route),
    ),
    );
  }
}
