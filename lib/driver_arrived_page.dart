import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/home_screen_passenger.dart';

class DriverArrivedPage extends StatefulWidget {
  final String rideId;
  final Map<String, dynamic> routeData; // New parameter
  final int? pickupStopIndex; // New parameter

  const DriverArrivedPage({
    Key? key,
    required this.rideId,
    required this.routeData,
    this.pickupStopIndex,
  }) : super(key: key);

  @override
  State<DriverArrivedPage> createState() => _DriverArrivedPageState();
}

class _DriverArrivedPageState extends State<DriverArrivedPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _driverProfile;
  bool _isLoading = true;
  LatLng? _passengerPickupLocation; // Location of the passenger's pickup stop
  Map<String, dynamic>? _rideData; // To hold the active ride data
  String _driverCurrentStopName = 'Loading...'; // Driver's current stop name
  String _estimatedTimeToPickup = 'N/A'; // This will likely be 'Arrived!'

  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _listenToRideUpdates(); // Start listening for ride updates
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _listenToRideUpdates() async {
    _firestore.collection('active_rides').doc(widget.rideId).snapshots().listen((snapshot) async {
      if (snapshot.exists && snapshot.data() != null) {
        final rideData = snapshot.data() as Map<String, dynamic>;
        setState(() {
          _rideData = rideData;
          // Update passenger pickup location if available
          final pickupStopData = rideData['From'] as Map<String, dynamic>?;
          if (pickupStopData != null && pickupStopData['lat'] is num && pickupStopData['lng'] is num) {
            _passengerPickupLocation = LatLng(pickupStopData['lat'], pickupStopData['lng']);
          }
        });

        // Load driver profile if not already loaded or if DId changes
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

        _updateDisplayInfo(rideData); // Update displayed info based on ride data

      } else {
        // Ride no longer exists (completed or cancelled), navigate back to passenger home
        if (mounted) {
          // Using pushAndRemoveUntil to clear the stack and go to PassengerHomeScreen
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const PassengerHomeScreen()),
            (Route<dynamic> route) => false,
          );
        }
      }
    });
  }

  void _updateDisplayInfo(Map<String, dynamic> rideData) {
    final driverCurrentStopIndex = rideData['current_stop_index'] as int?;

    setState(() {
      if (driverCurrentStopIndex != null &&
          driverCurrentStopIndex >= 0 &&
          driverCurrentStopIndex < widget.routeData['stops'].length) {
        _driverCurrentStopName = widget.routeData['stops'][driverCurrentStopIndex]['name'];
      } else {
        _driverCurrentStopName = 'Unknown Location';
      }

      // As per requirement, if driver is at passenger's stop, show 'Arrived!'
      if (widget.pickupStopIndex != null && driverCurrentStopIndex != null &&
          driverCurrentStopIndex >= widget.pickupStopIndex!) {
        _estimatedTimeToPickup = 'Arrived!';
      } else if (widget.pickupStopIndex != null && driverCurrentStopIndex != null) {
        final stopsRemaining = widget.pickupStopIndex! - driverCurrentStopIndex;
        final estimatedTime = stopsRemaining * 5; // Assuming 5 minutes per stop
        _estimatedTimeToPickup = '$estimatedTime min';
      } else {
        _estimatedTimeToPickup = 'N/A';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _rideData == null || _driverProfile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final rideData = _rideData!;
    final driverId = rideData['DId'];
    final fromStopData = rideData['From'] as Map<String, dynamic>?; // Passenger's original pickup stop
    final toStopData = rideData['To'] as Map<String, dynamic>?; // Passenger's original dropoff stop

    final driverLocationRaw = rideData['CurrentLocation'];
    LatLng? driverLocation; // Driver's actual GPS location (if provided)
    if (driverLocationRaw != null &&
        driverLocationRaw is Map<String, dynamic> &&
        driverLocationRaw.containsKey('lat') &&
        driverLocationRaw['lat'] is num &&
        driverLocationRaw.containsKey('lng') &&
        driverLocationRaw['lng'] is num) {
      driverLocation = LatLng(driverLocationRaw['lat'], driverLocationRaw['lng']);
    }

    final mapCenter = driverLocation ?? _passengerPickupLocation ?? LatLng(33.6844, 73.0479); // Default to Islamabad coords

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Arrived'), // Or "Driver is Approaching"
        backgroundColor: const Color(0xFF2D2F7D),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: mapCenter,
              zoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              ),
              MarkerLayer(
                markers: [
                  if (_passengerPickupLocation != null)
                    Marker(
                      width: 40,
                      height: 40,
                      point: _passengerPickupLocation!,
                      child: const Icon(Icons.person_pin_circle, color: Colors.red, size: 40),
                    ),
                  if (driverLocation != null)
                    Marker(
                      width: 40,
                      height: 40,
                      point: driverLocation,
                      child: const Icon(Icons.directions_car, color: Color(0xFF2D2F7D), size: 32),
                    ),
                ],
              ),
            ],
          ),
          // Driver Info Card
          Positioned(
            left: 16,
            right: 16,
            top: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Color(0xFF2D2F7D),
                      child: Icon(Icons.person, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _driverProfile?['name'] ?? 'Driver',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _driverProfile?['phoneNumber'] ?? 'No phone number',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Ride Status and ETA Card
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
                      'Ride Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.directions_bus, color: Colors.blue),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your driver is at: $_driverCurrentStopName',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.timer, color: Colors.orange),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Estimated Time to Pickup: $_estimatedTimeToPickup',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Pickup Location: ${fromStopData?['name'] ?? 'N/A'}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    Text(
                      'Drop-off Location: ${toStopData?['name'] ?? 'N/A'}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 