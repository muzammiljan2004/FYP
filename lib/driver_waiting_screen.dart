import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'heading_to_destination_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverWaitingScreen extends StatefulWidget {
  final String rideId;
  final Map<String, dynamic> routeData;
  final int? pickupStopIndex;

  const DriverWaitingScreen({Key? key, required this.rideId, required this.routeData, this.pickupStopIndex}) : super(key: key);

  @override
  _DriverWaitingScreenState createState() => _DriverWaitingScreenState();
}

class _DriverWaitingScreenState extends State<DriverWaitingScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _driverProfile;
  bool _isLoading = true;
  LatLng? _driverLocation;
  LatLng? _pickupLocation;
  List<Map<String, dynamic>> _allRouteStops = [];
  String? _driverCurrentStopName;
  Map<String, dynamic>? _rideData;
  int? _currentStopIndexFromRideData;
  int? _passengerPickupStopIndex;
  String _estimatedTimeToPickup = 'Calculating...';

  @override
  void initState() {
    super.initState();
    _allRouteStops = List<Map<String, dynamic>>.from(widget.routeData['stops'] ?? []);
    _passengerPickupStopIndex = widget.pickupStopIndex;
    _listenToRideAndDriverProfileUpdates();
  }

  Future<void> _listenToRideAndDriverProfileUpdates() async {
    _firestore.collection('active_rides').doc(widget.rideId).snapshots().listen((snapshot) async {
      if (snapshot.exists && snapshot.data() != null) {
        final rideData = snapshot.data() as Map<String, dynamic>;
        setState(() {
          _rideData = rideData;
          _driverLocation = (rideData['CurrentLocation'] != null && rideData['CurrentLocation']['lat'] is num && rideData['CurrentLocation']['lng'] is num)
              ? LatLng(rideData['CurrentLocation']['lat'], rideData['CurrentLocation']['lng'])
              : null;
          _currentStopIndexFromRideData = (rideData['current_stop_index'] as int?) ?? 0;
        });

        final newDriverId = rideData['DId'];
        if (_driverProfile == null || _driverProfile!['DId'] != newDriverId) {
          if (newDriverId != null) {
            final driverDoc = await _firestore.collection('users').doc(newDriverId).get();
            if (driverDoc.exists) {
              setState(() {
                _driverProfile = driverDoc.data();
                _isLoading = false;
              });
            }
          }
        }

        await _updateStopProgressAndETA();

      } else {
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    });
  }

  Future<void> _updateStopProgressAndETA() async {
    if (_currentStopIndexFromRideData != null && _currentStopIndexFromRideData! >= 0 && _currentStopIndexFromRideData! < _allRouteStops.length) {
      setState(() {
        _driverCurrentStopName = _allRouteStops[_currentStopIndexFromRideData!]['name'];
      });
    } else {
      setState(() {
        _driverCurrentStopName = null;
      });
    }

    if (_currentStopIndexFromRideData != null && _passengerPickupStopIndex != null) {
      if (_currentStopIndexFromRideData! < _passengerPickupStopIndex!) {
        final stopsRemaining = _passengerPickupStopIndex! - _currentStopIndexFromRideData!;
        final estimatedTime = stopsRemaining * 5;
        setState(() {
          _estimatedTimeToPickup = '$estimatedTime min';
        });
      } else if (_currentStopIndexFromRideData! == _passengerPickupStopIndex!) {
        setState(() {
          _estimatedTimeToPickup = 'Arrived!';
        });
      } else {
        setState(() {
          _estimatedTimeToPickup = 'Passed Pickup!';
        });
      }
    } else {
      setState(() {
        _estimatedTimeToPickup = 'N/A';
      });
    }

    if (_rideData != null && _rideData!['From'] != null) {
      final fromStopData = _rideData!['From'] as Map<String, dynamic>?;
      if (fromStopData != null && fromStopData['lat'] is num && fromStopData['lng'] is num) {
        setState(() {
          _pickupLocation = LatLng(fromStopData['lat'], fromStopData['lng']);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _rideData == null || _driverProfile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final rideData = _rideData!;
    final driverId = rideData['DId'];
    final fromStopData = rideData['From'] as Map<String, dynamic>?;
    final toStopData = rideData['To'] as Map<String, dynamic>?;

    final driverLocationData = rideData['CurrentLocation'] as Map<String, dynamic>?;
    final driverLocation = (driverLocationData != null &&
            driverLocationData['lat'] != null &&
            driverLocationData['lng'] != null)
        ? LatLng(driverLocationData['lat'], driverLocationData['lng'])
        : null;

    final mapCenter = driverLocation ?? _pickupLocation ?? LatLng(33.6844, 73.0479);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              center: mapCenter,
              zoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              ),
              MarkerLayer(
                markers: [
                  if (driverLocation != null)
                    Marker(
                      width: 40.0,
                      height: 40.0,
                      point: driverLocation,
                      child: const Icon(Icons.directions_car, color: Color(0xFF2D2F7D), size: 32),
                    ),
                  if (_pickupLocation != null)
                    Marker(
                      width: 40,
                      height: 40,
                      point: _pickupLocation!,
                      child: const Icon(Icons.person_pin_circle, color: Colors.red, size: 40),
                    ),
                ],
              ),
            ],
          ),

          Positioned(
            top: 60,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Your driver is at ${_driverCurrentStopName ?? 'an unknown location'}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Estimated Time to Pickup: $_estimatedTimeToPickup',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pickup at: ${fromStopData?['name'] ?? 'N/A'}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  Text(
                    'Drop-off at: ${toStopData?['name'] ?? 'N/A'}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Color(0xFF2D2F7D),
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _driverProfile?['name'] ?? 'Driver Name',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          Text(
                            _driverProfile?['phoneNumber'] ?? 'N/A',
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      Spacer(),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.call, color: Colors.green, size: 28),
                            onPressed: () {
                              // Implement call functionality
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.chat, color: Colors.blue, size: 28),
                            onPressed: () {
                              // Implement chat functionality
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Vehicle: ${_driverProfile?['vehicleMake'] ?? 'N/A'} ${_driverProfile?['vehicleModel'] ?? 'N/A'}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                  ),
                  Text(
                    'License Plate: ${_driverProfile?['licensePlate'] ?? 'N/A'}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 