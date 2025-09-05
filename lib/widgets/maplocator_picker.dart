import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  late GoogleMapController _mapController;
  LatLng _selectedLatLng = const LatLng(6.2303, 125.0829); // Polomolok
  bool _isLoading = true;
  String _currentAddress = '';
  bool _mapControllerReady = false;

  // ✅ Replace with your OpenCage API key
  static const String _apiKey = "dc4945bc771f4780bc040ec0f7708044";

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    setState(() => _isLoading = true);

    LatLng? latLng;

    // Priority 1: Explicit coordinates
    if (widget.initialLat != null && widget.initialLng != null) {
      latLng = LatLng(widget.initialLat!, widget.initialLng!);
      _currentAddress = widget.initialAddress;
    }
    // Priority 2: Parse if address is "lat,lng"
    else if (widget.initialAddress.contains(",") &&
        _isCoordinateString(widget.initialAddress)) {
      final parts = widget.initialAddress.split(",");
      final lat = double.tryParse(parts[0].trim());
      final lng = double.tryParse(parts[1].trim());
      if (lat != null && lng != null) {
        latLng = LatLng(lat, lng);
        _currentAddress = await _getAddressFromLatLng(lat, lng);
      }
    }
    // Priority 3: Forward geocode text address
    else if (widget.initialAddress.isNotEmpty) {
      latLng = await _getLatLngFromAddress(widget.initialAddress);
      if (latLng != null) {
        _currentAddress = widget.initialAddress;
      } else {
        latLng = const LatLng(6.2303, 125.0829);
        _currentAddress = "Polomolok, South Cotabato";
      }
    }

    if (latLng != null) {
      setState(() {
        _selectedLatLng = latLng!;
        _isLoading = false;
      });
      _moveCameraWhenReady(latLng);
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _moveCameraWhenReady(LatLng target) async {
    while (!_mapControllerReady) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (mounted) {
      await _mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 17),
        ),
      );
    }
  }

  bool _isCoordinateString(String address) {
    final parts = address.split(",");
    if (parts.length == 2) {
      final lat = double.tryParse(parts[0].trim());
      final lng = double.tryParse(parts[1].trim());
      return lat != null && lng != null;
    }
    return false;
  }

  /// ✅ Forward Geocoding with OpenCage
  Future<LatLng?> _getLatLngFromAddress(String address) async {
    final url =
        "https://api.opencagedata.com/geocode/v1/json?q=${Uri.encodeComponent(address)}&key=$_apiKey&countrycode=ph";

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {"User-Agent": "maplocation-picker-app"},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry'];
          return LatLng(location['lat'], location['lng']);
        }
      }
    } catch (e) {
      debugPrint("OpenCage forward geocoding error: $e");
    }
    return null;
  }

  /// ✅ Reverse Geocoding with OpenCage
  Future<String> _getAddressFromLatLng(double lat, double lng) async {
    final url =
        "https://api.opencagedata.com/geocode/v1/json?q=$lat,$lng&key=$_apiKey";

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {"User-Agent": "maplocation-picker-app"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['results'] != null && data['results'].isNotEmpty) {
          final formatted = data['results'][0]['formatted'];
          debugPrint("✅ Reverse geocode result: $formatted");
          return formatted; // ✅ return human-readable address
        } else {
          debugPrint("⚠️ No results from OpenCage for $lat,$lng");
        }
      } else {
        debugPrint("❌ OpenCage API error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ OpenCage reverse geocoding exception: $e");
    }

    return "$lat, $lng"; // fallback only if API fails
  }


  /// ✅ Get detailed location info with OpenCage
  Future<Map<String, dynamic>> _getCurrentLocationDetails() async {
    final lat = _selectedLatLng.latitude;
    final lng = _selectedLatLng.longitude;

    final url =
        "https://api.opencagedata.com/geocode/v1/json?q=$lat,$lng&key=$_apiKey";

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {"User-Agent": "maplocation-picker-app"},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'].isNotEmpty) {
          var result = data['results'][0];
          return {
            'formatted_address': result['formatted'],
            'components': result['components'],
            'geometry': result['geometry'],
          };
        }
      }
    } catch (e) {
      debugPrint("Error getting location details: $e");
    }

    return {
      'formatted_address': "$lat, $lng",
      'components': {},
      'geometry': {
        'lat': lat,
        'lng': lng,
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Delivery Location"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showAddressSearchDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLatLng,
              zoom: 16,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              _mapControllerReady = true;
            },
            markers: {
              Marker(
                markerId: const MarkerId("selected"),
                position: _selectedLatLng,
                draggable: true,
                onDragEnd: (newPosition) async {
                  setState(() {
                    _selectedLatLng = newPosition;
                    _isLoading = true;
                  });

                  _currentAddress = await _getAddressFromLatLng(
                    newPosition.latitude,
                    newPosition.longitude,
                  );

                  setState(() => _isLoading = false);
                },
              ),
            },
            onTap: (LatLng tappedPoint) async {
              setState(() {
                _selectedLatLng = tappedPoint;  // fixed: you had _selectedLocation
                _isLoading = true;
              });

              final address = await _getAddressFromLatLng(
                tappedPoint.latitude,
                tappedPoint.longitude,
              );

              setState(() {
                _currentAddress = address; // ✅ show formatted address
                _isLoading = false;
              });
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapType: MapType.normal,
            zoomControlsEnabled: true,
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.location_on, size: 16, color: Colors.red),
                      SizedBox(width: 4),
                      Text(
                        "Selected Location:",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentAddress.isNotEmpty
                        ? _currentAddress
                        : "Loading address...",
                    style: const TextStyle(fontSize: 14),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Lat: ${_selectedLatLng.latitude.toStringAsFixed(6)}, "
                        "Lng: ${_selectedLatLng.longitude.toStringAsFixed(6)}",
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading
            ? null
            : () async {
          final locationDetails = await _getCurrentLocationDetails();

          Navigator.pop(context, {
            "lat": _selectedLatLng.latitude,
            "lng": _selectedLatLng.longitude,
            "address": locationDetails['formatted_address'],
            "address_components": locationDetails['components'],
          });
        },
        backgroundColor: Colors.green,
        label: const Text("Confirm Location",
            style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.check, color: Colors.white),
      ),
    );
  }

  /// Show dialog for manual address search
  Future<void> _showAddressSearchDialog() async {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Search Address"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Try: 'Purok Esposado, Poblacion, Polomolok'",
            border: OutlineInputBorder(),
            helperText: "Include barangay and municipality for best results",
            helperMaxLines: 2,
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (value) {
            Navigator.pop(context);
            _searchAndMoveToAddress(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _searchAndMoveToAddress(controller.text);
            },
            child: const Text("Search"),
          ),
        ],
      ),
    );
  }

  /// Search for address and move map to location
  Future<void> _searchAndMoveToAddress(String address) async {
    if (address.trim().isEmpty) return;

    setState(() => _isLoading = true);

    final latLng = await _getLatLngFromAddress(address.trim());

    if (latLng != null) {
      setState(() {
        _selectedLatLng = latLng;
        _currentAddress = address;
      });

      await _mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: latLng, zoom: 17),
        ),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Address not found. Please try a different search term."),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }
}
