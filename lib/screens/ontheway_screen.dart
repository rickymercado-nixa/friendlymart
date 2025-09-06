import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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
  State<DeliveryNavigationScreen> createState() => _DeliveryNavigationScreenState();
}

class _DeliveryNavigationScreenState extends State<DeliveryNavigationScreen> {
  LatLng? _riderLocation;
  final LatLng storeLocation = LatLng(6.220447249809727, 125.0647953991407);

  @override
  void initState() {
    super.initState();
    _listenToRiderLocation();
  }

  void _listenToRiderLocation() {
    FirebaseFirestore.instance
        .collection("users")
        .doc(widget.riderId)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) return;

      final data = doc.data();
      if (data != null && data['currentLocation'] != null) {
        final loc = data['currentLocation'] as GeoPoint;
        setState(() {
          _riderLocation = LatLng(loc.latitude, loc.longitude);
        });
      }
    });
  }

  Future<void> _openGoogleMapsNavigation() async {
    final riderLat = storeLocation.latitude; // Start from store
    final riderLng = storeLocation.longitude;
    final customerLat = widget.customerLocation.latitude;
    final customerLng = widget.customerLocation.longitude;

    final Uri url = Uri.parse(
      "https://www.google.com/maps/dir/?api=1&origin=$riderLat,$riderLng&destination=$customerLat,$customerLng&travelmode=driving",
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not launch Google Maps")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Set<Marker> markers = {
      // Customer marker
      Marker(
        markerId: const MarkerId("customer"),
        position: widget.customerLocation,
        infoWindow: InfoWindow(title: widget.address),
      ),
      // Store marker
      Marker(
        markerId: const MarkerId("store"),
        position: storeLocation,
        infoWindow: const InfoWindow(title: "Store"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    };

    // Optional: show rider's current location
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
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: storeLocation, // Center the map on the store
          zoom: 15,
        ),
        markers: markers,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openGoogleMapsNavigation,
        label: const Text("Navigate"),
        icon: const Icon(Icons.navigation),
      ),
    );
  }
}
