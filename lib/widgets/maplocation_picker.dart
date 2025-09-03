import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MapLocationPicker extends StatefulWidget {
  final String initialAddress;
  final double? initialLat;
  final double? initialLng;

  const MapLocationPicker({
    Key? key,
    required this.initialAddress,
    this.initialLat,
    this.initialLng,
  }) : super(key: key);

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  LatLng _selectedLatLng = LatLng(14.5995, 120.9842); // temporary Manila center
  final MapController _mapController = MapController();
  bool _userLocationLoaded = false; // true when saved address is ready

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  void _initLocation() async {
    LatLng? latLng;

    // Use explicit lat/lng if available
    if (widget.initialLat != null && widget.initialLng != null) {
      latLng = LatLng(widget.initialLat!, widget.initialLng!);
    }
    // If "lat,lng" string
    else if (widget.initialAddress.contains(",")) {
      final parts = widget.initialAddress.split(",");
      final lat = double.tryParse(parts[0].trim());
      final lng = double.tryParse(parts[1].trim());
      if (lat != null && lng != null) latLng = LatLng(lat, lng);
    }
    // Otherwise forward geocode textual address
    else {
      latLng = await _getLatLngFromAddress(widget.initialAddress);
    }

    if (latLng != null) {
      setState(() {
        _selectedLatLng = latLng!;
        _userLocationLoaded = true;
      });

      // Move map safely after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(latLng!, 16);
      });
    }
  }

  Future<LatLng?> _getLatLngFromAddress(String address) async {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$address&format=json&limit=1');

    try {
      final response = await http.get(url, headers: {
        "User-Agent": "friendlymart-flutter-app",
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          return LatLng(lat, lon);
        }
      }
    } catch (e) {
      print("Forward geocoding error: $e");
    }
    return null;
  }

  Future<String> _getAddressFromLatLng(double lat, double lng) async {
    final url = Uri.parse(
        "https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1");

    try {
      final response = await http.get(url, headers: {
        "User-Agent": "friendlymart-flutter-app",
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final road = data['address']['road'] ?? '';
        final suburb = data['address']['suburb'] ?? '';
        final city = data['address']['city'] ?? data['address']['town'] ?? '';
        return "$road, $suburb, $city".trim();
      }
    } catch (e) {
      print("Reverse geocoding error: $e");
    }
    return "$lat, $lng"; // fallback
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Delivery Location")),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _selectedLatLng,
          initialZoom: 16,
          onTap: (tapPosition, point) {
            setState(() => _selectedLatLng = point);
          },
        ),
        children: [
          TileLayer(
            urlTemplate:
            'https://api.maptiler.com/maps/streets-v2/256/{z}/{x}/{y}.png?key=O0zbT6CeL3jwwKYbfAQN',
            userAgentPackageName: 'com.example.friendlymart',
            tileDimension: 256,
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: _selectedLatLng,
                width: 80,
                height: 80,
                child: const Icon(Icons.location_on, color: Colors.red, size: 40),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final lat = _selectedLatLng.latitude;
          final lng = _selectedLatLng.longitude;
          String address = await _getAddressFromLatLng(lat, lng);
          Navigator.pop(context, {
            "lat": lat,
            "lng": lng,
            "address": address,
          });
        },
        label: const Text("Confirm Location"),
        icon: const Icon(Icons.check),
      ),
    );
  }
}
