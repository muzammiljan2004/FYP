import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'review_page.dart';

class HeadingToDestinationPage extends StatefulWidget {
  final String rideId;
  final Map<String, dynamic> fromStop;
  final Map<String, dynamic> toStop;

  const HeadingToDestinationPage({
    Key? key,
    required this.rideId,
    required this.fromStop,
    required this.toStop,
  }) : super(key: key);

  @override
  State<HeadingToDestinationPage> createState() => _HeadingToDestinationPageState();
}

class _HeadingToDestinationPageState extends State<HeadingToDestinationPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _driverProfile;
  bool _isLoading = true;
  LatLng? _driverLocation;
  LatLng? _destinationLocation;
  List<LatLng> _routePoints = []; // This will be removed later

  Map<String, dynamic>? _currentRideData;
  List<Map<String, dynamic>> _allRouteStops = [];
  Map<String, dynamic>? _driverCurrentStop; // The stop the driver is currently at/closest to
  List<Map<String, dynamic>> _remainingStops = []; // Stops from _driverCurrentStop to destination

  @override
  void initState() {
    super.initState();
    _listenToRideAndRouteUpdates(); // New method to listen to data
  }

  Future<void> _listenToRideAndRouteUpdates() async {
    _firestore.collection('active_rides').doc(widget.rideId).snapshots().listen((snapshot) async {
      if (snapshot.exists && snapshot.data() != null) {
        final rideData = snapshot.data() as Map<String, dynamic>;
        setState(() {
          _currentRideData = rideData;
          _driverLocation = (rideData['CurrentLocation'] != null && rideData['CurrentLocation']['lat'] is num && rideData['CurrentLocation']['lng'] is num)
              ? LatLng(rideData['CurrentLocation']['lat'], rideData['CurrentLocation']['lng'])
              : null;
          _destinationLocation = (rideData['To'] != null && rideData['To']['lat'] is num && rideData['To']['lng'] is num)
              ? LatLng(rideData['To']['lat'], rideData['To']['lng'])
              : null;
        });

        // Load driver profile only once or if driverId changes
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

        // Update route stops and determine current/remaining stops
        await _updateRouteAndStopProgress(rideData);

      } else {
        // Handle ride completion or cancellation (e.g., navigate back to passenger home)
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    });
  }

  Future<void> _updateRouteAndStopProgress(Map<String, dynamic> rideData) async {
    final routeName = rideData['RouteId'];
    if (routeName == null) {
      print('[PAX_DEST] _updateRouteAndStopProgress: RouteId is null.');
      return;
    }

    final routeSnap = await _firestore.collection('routes').where('name', isEqualTo: routeName).get();
    if (routeSnap.docs.isEmpty) {
      print('[PAX_DEST] _updateRouteAndStopProgress: No route found for name: $routeName');
      return;
    }

    final routeData = routeSnap.docs.first.data() as Map<String, dynamic>;
    final fetchedStops = List<Map<String, dynamic>>.from(routeData['stops'] ?? []);

    setState(() {
      _allRouteStops = fetchedStops;
      print('[PAX_DEST] _updateRouteAndStopProgress: Fetched stops count: ${_allRouteStops.length}');

      if (_driverLocation != null && _allRouteStops.isNotEmpty) {
        print('[PAX_DEST] _updateRouteAndStopProgress: Driver Location: ${_driverLocation!.latitude}, ${_driverLocation!.longitude}');
        // Find the closest stop to the driver's current location
        double minDistance = double.infinity;
        Map<String, dynamic>? closestStop;
        int closestStopIndex = -1;
        final distance = Distance();

        for (int i = 0; i < _allRouteStops.length; i++) {
          final stop = _allRouteStops[i];
          final stopLat = stop['lat'];
          final stopLng = stop['lng'];

          if (stopLat is num && stopLng is num) {
            final stopLocation = LatLng(stopLat.toDouble(), stopLng.toDouble());
            final currentDistance = distance.as(LengthUnit.Kilometer, _driverLocation!, stopLocation);
            print('[PAX_DEST] Stop: ${stop['name']}, Distance: $currentDistance km');
            if (currentDistance < minDistance) {
              minDistance = currentDistance;
              closestStop = stop;
              closestStopIndex = i;
            }
          }
        }
        _driverCurrentStop = closestStop; // This is the stop the driver is AT or closest to
        print('[PAX_DEST] Determined closest stop: ${_driverCurrentStop?['name']}');

        // Determine remaining stops from current driver stop up to destination
        _remainingStops = [];
        if (_driverCurrentStop != null) {
          final dropStopName = (rideData['To'] as Map<String, dynamic>?)?['name'];
          bool foundCurrent = false;

          for (int i = 0; i < _allRouteStops.length; i++) {
            final stop = _allRouteStops[i];
            if (!foundCurrent) {
              if (stop['name'] == _driverCurrentStop!['name']) {
                foundCurrent = true; // Start adding stops from the next one
                // DO NOT add the current stop to _remainingStops
              }
            } else {
              _remainingStops.add(stop);
            }
            if (stop['name'] == dropStopName) {
              print('[PAX_DEST] Destination stop $dropStopName reached in remaining stops list.');
              break; // Stop adding once destination is reached
            }
          }
          print('[PAX_DEST] Remaining Stops: ${_remainingStops.map((s) => s['name']).join(', ')}');
        }
      } else {
        print('[PAX_DEST] Driver location is null or no route stops.');
        _driverCurrentStop = null;
        _remainingStops = [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _currentRideData == null || _driverProfile == null || _driverLocation == null || _destinationLocation == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride in Progress'),
        backgroundColor: const Color(0xFF2D2F7D),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              center: _driverLocation ?? _destinationLocation ?? LatLng(33.6844, 73.0479),
              zoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              ),
              MarkerLayer(
                markers: [
                  // Driver's current location marker
                  if (_driverLocation != null)
                    Marker(
                      width: 40,
                      height: 40,
                      point: _driverLocation!,
                      child: const Icon(Icons.directions_car, color: Color(0xFF2D2F7D), size: 32),
                    ),
                  // Markers for remaining stops
                  ..._remainingStops.map((stop) {
                    final stopLat = stop['lat'];
                    final stopLng = stop['lng'];
                    if (stopLat is num && stopLng is num) {
                      final isCurrentStop = _driverCurrentStop != null && stop['name'] == _driverCurrentStop!['name'];
                      return Marker(
                        width: isCurrentStop ? 50 : 30,
                        height: isCurrentStop ? 50 : 30,
                        point: LatLng(stopLat.toDouble(), stopLng.toDouble()),
                        child: Column(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: isCurrentStop ? Colors.purple : Colors.blue,
                              size: isCurrentStop ? 40 : 30,
                            ),
                            if (isCurrentStop)
                              Text(
                                'Current',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                          ],
                        ),
                      );
                    }
                    return Marker(
                      width: 0,
                      height: 0,
                      point: LatLng(0,0), // Invisible marker if data is bad
                      child: Container(),
                    );
                  }).toList(),
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
          // Ride Progress Card
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
                      'Ride Progress',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_driverCurrentStop != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.pin_drop, color: Colors.purple, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Current Stop: ${_driverCurrentStop!['name']}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Text(
                      'Upcoming Stops:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_remainingStops.isEmpty)
                      const Text(
                        'No upcoming stops.',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      )
                    else
                      ..._remainingStops.map((stop) {
                        final isDestination = _currentRideData!['To'] != null &&
                            stop['name'] == (_currentRideData!['To'] as Map<String, dynamic>)['name'];
                        return Padding(
                          padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                          child: Row(
                            children: [
                              Icon(
                                isDestination ? Icons.location_on : Icons.arrow_right,
                                color: isDestination ? Colors.green : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  stop['name'] ?? 'Unknown Stop',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDestination ? Colors.green : Colors.black87,
                                    fontWeight: isDestination ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    const SizedBox(height: 16),
                    // You can add a dynamic progress bar here based on actual stops passed
                    // For now, I'm removing the old static progress bar.
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