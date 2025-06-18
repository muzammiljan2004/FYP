import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SelectAddressScreen extends StatefulWidget {
  final LatLng? currentLocation;
  final bool isFrom;

  const SelectAddressScreen({
    Key? key,
    this.currentLocation,
    required this.isFrom,
  }) : super(key: key);

  @override
  State<SelectAddressScreen> createState() => _SelectAddressScreenState();
}

class _SelectAddressScreenState extends State<SelectAddressScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  LatLng? _selectedLocation;
  List<Map<String, dynamic>> _recentLocations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _loadRecentLocations();
  }

  Future<void> _initializeLocation() async {
    try {
      if (widget.currentLocation != null) {
        setState(() {
          _selectedLocation = widget.currentLocation;
          _isLoading = false;
        });
        return;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoading = false);
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
    } catch (e) {
      print('Error getting location: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRecentLocations() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return;

      final data = doc.data();
      if (data == null) return;

      final recentLocations = List<Map<String, dynamic>>.from(data['recentLocations'] ?? []);
      setState(() {
        _recentLocations = recentLocations;
      });
    } catch (e) {
      print('Error loading recent locations: $e');
    }
  }

  Future<void> _saveLocation() async {
    if (_selectedLocation == null) return;

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final location = {
        'name': _searchController.text.isEmpty ? 'Selected Location' : _searchController.text,
        'location': {
          'lat': _selectedLocation!.latitude,
          'lng': _selectedLocation!.longitude,
        },
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _firestore.collection('users').doc(userId).set({
        'recentLocations': FieldValue.arrayUnion([location]),
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pop(context, location);
      }
    } catch (e) {
      print('Error saving location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save location. Please try again.')),
      );
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isFrom ? 'Select Pickup Location' : 'Select Destination'),
        backgroundColor: const Color(0xFF2D2F7D),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search location',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    center: _selectedLocation ?? const LatLng(0, 0),
                    zoom: 15,
                    onTap: (_, point) {
                      setState(() {
                        _selectedLocation = point;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                    ),
                    if (_selectedLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            width: 40,
                            height: 40,
                            point: _selectedLocation!,
                            child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                          ),
                        ],
                      ),
                  ],
                ),
                if (_recentLocations.isNotEmpty)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Recent Locations',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 200,
                              child: ListView.builder(
                                itemCount: _recentLocations.length,
                                itemBuilder: (context, index) {
                                  final location = _recentLocations[index];
                                  return ListTile(
                                    leading: const Icon(Icons.history),
                                    title: Text(location['name']),
                                    onTap: () {
                                      setState(() {
                                        _selectedLocation = LatLng(
                                          location['location']['lat'],
                                          location['location']['lng'],
                                        );
                                        _searchController.text = location['name'];
                                      });
                                      _mapController.move(_selectedLocation!, 15);
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveLocation,
        backgroundColor: const Color(0xFF2D2F7D),
        icon: const Icon(Icons.check),
        label: const Text('Confirm Location'),
      ),
    );
  }
}
