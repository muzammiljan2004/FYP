import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'home_screen_driver.dart'; // Changed to relative import path
import 'package:flutter_application_1/services/notification_service.dart';

class RideStartedPage extends StatefulWidget {
  final String driverId;
  final String rideId;
  final Map<String, dynamic> routeData; // New parameter to receive route data

  const RideStartedPage({Key? key, required this.driverId, required this.rideId, required this.routeData}) : super(key: key);

  @override
  State<RideStartedPage> createState() => _RideStartedPageState();
}

class _RideStartedPageState extends State<RideStartedPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _currentRideData;
  Map<String, dynamic>? _driverProfile; // Declare driver profile
  List<Map<String, dynamic>> _routeStops = [];
  Map<String, dynamic>? _driverCurrentStop;
  Map<String, dynamic>? _driverNextStop;
  String _estimatedArrivalTime = 'Calculating...'; // Placeholder for ETA
  int _currentStopIndex = 0; // Tracks the driver's current stop index on the route

  @override
  void initState() {
    super.initState();
    _loadDriverProfile(); // Load driver's profile
    _routeStops = List<Map<String, dynamic>>.from(widget.routeData['stops'] ?? []);
    _listenToRideUpdates();
  }

  Future<void> _loadDriverProfile() async {
    final driverDoc = await _firestore.collection('users').doc(widget.driverId).get();
    if (mounted && driverDoc.exists) {
      setState(() {
        _driverProfile = driverDoc.data();
      });
    }
  }

  void _listenToRideUpdates() {
    _firestore.collection('active_rides').doc(widget.rideId).snapshots().listen((snapshot) async {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          _currentRideData = data;
          // Update _currentStopIndex from Firestore, default to 0
          _currentStopIndex = (data['current_stop_index'] as int?) ?? 0;
        });
        _updateStopInfo(); // Call without parameters, as it now uses _currentStopIndex
      } else {
        // Handle ride completion or cancellation (e.g., navigate back)
        if (mounted) {
          Navigator.pop(context); // Go back if ride no longer exists
        }
      }
    });
  }

  Future<void> _updateStopInfo() async {
    // No need to fetch route data again, it's from widget.routeData
    // Use _currentStopIndex to determine current and next stops
    if (_routeStops.isNotEmpty) {
      setState(() {
        if (_currentStopIndex >= 0 && _currentStopIndex < _routeStops.length) {
          _driverCurrentStop = _routeStops[_currentStopIndex];
        } else {
          _driverCurrentStop = null; // No valid current stop
        }

        if (_currentStopIndex + 1 < _routeStops.length) {
          _driverNextStop = _routeStops[_currentStopIndex + 1];
        } else {
          _driverNextStop = null;
        }

        _estimatedArrivalTime = _driverNextStop != null ? '5-10 min' : 'N/A';
      });
    }
  }

  Future<void> _updateRideStatus(String status, {int? currentStopIndex}) async {
    Map<String, dynamic> updateData = {
      'status': status,
      'LastUpdated': FieldValue.serverTimestamp(),
    };
    if (currentStopIndex != null) {
      updateData['current_stop_index'] = currentStopIndex;
    }
    await _firestore.collection('active_rides').doc(widget.rideId).update(updateData);

    // --- Notification logic ---
    if (currentStopIndex != null) {
      // Query all passengers for this ride
      final rideDoc = await _firestore.collection('active_rides').doc(widget.rideId).get();
      if (rideDoc.exists) {
        final rideData = rideDoc.data() as Map<String, dynamic>;
        final passengers = rideData['passengers'] as List<dynamic>?;
        if (passengers != null) {
          for (final passenger in passengers) {
            final passengerId = passenger['PId'];
            final pickupStopIndex = passenger['pickup_stop_index'];
            if (pickupStopIndex != null && pickupStopIndex == currentStopIndex) {
              // Get driver name and pickup stop name
              final driverDoc = await _firestore.collection('users').doc(rideData['DId']).get();
              final driverName = driverDoc.data()?['name'] ?? 'Driver';
              final pickupStopName = passenger['pickup_stop_name'] ?? 'your stop';
              // Send notification
              await NotificationService().sendDriverArrivalNotification(
                passengerId: passengerId,
                driverName: driverName,
                pickupLocation: pickupStopName,
              );
            }
          }
        }
      }
    }
  }

  void _handleArrived() async {
    // This method is no longer needed as the status will be controlled by start/stop
    // Removed as per new requirements
  }

  void _handleStartStop() async {
    if (_currentRideData == null) return; // Should not happen in normal flow

    final String rideStatus = _currentRideData!['status'] ?? 'pending';

    if (rideStatus == 'pending') {
      // Start the ride, set status to in_progress, and set current_stop_index to 0 (first stop)
      await _updateRideStatus('in_progress', currentStopIndex: 0);
    } else if (rideStatus == 'in_progress') {
      if (_currentStopIndex < _routeStops.length - 1) {
        // Move to the next stop if not at the last stop
        final nextIndex = _currentStopIndex + 1;
        await _updateRideStatus('in_progress', currentStopIndex: nextIndex);
      } else {
        // Driver is at the last stop, complete the ride
        await _completeRideAndMoveToCompletedCollection();
      }
    }
  }

  Future<void> _completeRideAndMoveToCompletedCollection() async {
    try {
      final activeRideRef = _firestore.collection('active_rides').doc(widget.rideId);
      final activeRideDoc = await activeRideRef.get();

      if (activeRideDoc.exists) {
        final rideData = activeRideDoc.data() as Map<String, dynamic>;

        // Add to completed_ride collection
        await _firestore.collection('completed_ride').add({
          ...rideData,
          'status': 'completed',
          'completedTime': FieldValue.serverTimestamp(),
        });

        // Delete from active_rides collection
        await activeRideRef.delete();

        if (mounted) {
          // Navigate driver back to their home screen as ride is completed
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const DriverHomeScreen()),
            (Route<dynamic> route) => false, // Remove all previous routes
          );
        }
      }
    } catch (e) {
      print('Error completing and moving ride: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to complete ride. Please try again.')),
        );
      }
    }
  }

  void _notifyPassengerOfArrival(int stopIndex) async {
    try {
      final rideDoc = await _firestore.collection('active_rides').doc(widget.rideId).get();
      if (!rideDoc.exists) return;

      final rideData = rideDoc.data() as Map<String, dynamic>;
      final passengerId = rideData['PId'];
      final pickupStopIndex = rideData['pickup_stop_index'];
      final driverName = _driverProfile?['name'] ?? 'Your Driver';
      final stopName = _driverCurrentStop?['name'] ?? 'your pickup location';

      if (pickupStopIndex == stopIndex) {
        await NotificationService().sendDriverArrivalNotification(
          passengerId: passengerId,
          driverName: driverName,
          pickupLocation: stopName,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Arrival notification sent!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No passengers to notify at this stop.')),
          );
        }
      }
    } catch (e) {
      print('Error notifying passenger: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending notification: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentRideData == null || _routeStops.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // --- Recalculate passengers at current stop directly in build method ---
    final passengers = _currentRideData!['passengers'] as List<dynamic>? ?? [];
    final passengersAtCurrentStop = passengers
        .where((p) => p['pickup_stop_index'] == _currentStopIndex)
        .toList();
    // --- End of recalculation ---

    final rideStatus = _currentRideData!['status'];

    // Determine button text and color based on ride status and stop progression
    String buttonText;
    Color buttonColor;

    if (rideStatus == 'pending') {
      buttonText = 'Start Ride';
      buttonColor = const Color(0xFF2D2F7D);
    } else if (rideStatus == 'in_progress') {
      if (_currentStopIndex < _routeStops.length - 1) {
        buttonText = 'Next Stop';
        buttonColor = Colors.orange;
      } else {
        buttonText = 'Complete Ride';
        buttonColor = Colors.green;
      }
    } else {
      buttonText = 'Ride Ended'; // Should not be seen if navigation works correctly
      buttonColor = Colors.grey;
    }

    // Get current and next stop names for display
    final currentStopName = _driverCurrentStop?['name'] ?? 'Loading Current Stop...';
    final nextStopName = _driverNextStop?['name'] ?? 'No Next Stop';

    // Map markers
    List<Marker> mapMarkers = [];
    LatLng? mapCenterLocation;

    // Add marker for current driver stop
    if (_driverCurrentStop != null && _driverCurrentStop!['location'] != null && _driverCurrentStop!['location']['lat'] != null && _driverCurrentStop!['location']['lng'] != null) {
      mapMarkers.add(
        Marker(
          width: 40,
          height: 40,
          point: LatLng(_driverCurrentStop!['location']['lat'], _driverCurrentStop!['location']['lng']),
          child: const Icon(Icons.location_on, color: Colors.blue, size: 40),
        ),
      );
      mapCenterLocation = LatLng(_driverCurrentStop!['location']['lat'], _driverCurrentStop!['location']['lng']);
    }

    // Add marker for next driver stop (if exists)
    if (_driverNextStop != null && _driverNextStop!['location'] != null && _driverNextStop!['location']['lat'] != null && _driverNextStop!['location']['lng'] != null) {
      mapMarkers.add(
        Marker(
          width: 40,
          height: 40,
          point: LatLng(_driverNextStop!['location']['lat'], _driverNextStop!['location']['lng']),
          child: const Icon(Icons.location_on, color: Colors.green, size: 40),
        ),
      );
      if (mapCenterLocation == null) { // Fallback if current stop has no location
        mapCenterLocation = LatLng(_driverNextStop!['location']['lat'], _driverNextStop!['location']['lng']);
      }
    }

    // Default map center if no stops have location data
    mapCenterLocation ??= LatLng(33.6844, 73.0479); // Default to Islamabad if no location available

    return Scaffold(
      extendBodyBehindAppBar: true, // Allow body to extend behind AppBar area
      body: Stack(
        children: [
          // Map Background
          FlutterMap(
            mapController: MapController(), // Use local map controller for this page
            options: MapOptions(
              center: mapCenterLocation,
              zoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              ),
              PolylineLayer(
                polylines: [
                  // Draw polyline only for remaining stops from current to destination
                  Polyline(
                    points: _routeStops
                        .skip(_currentStopIndex) // Start from current stop
                        .where((stop) => stop['location'] != null && stop['location']['lat'] != null && stop['location']['lng'] != null)
                        .map((stop) => LatLng(stop['location']['lat'], stop['location']['lng']))
                        .toList(),
                    color: const Color(0xFF2D2F7D),
                    strokeWidth: 6,
                  ),
                ],
              ),
              MarkerLayer(
                markers: mapMarkers,
              ),
            ],
          ),
          // Top-left Menu Button
          Positioned(
            top: 40,
            left: 16,
            child: Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 2,
              child: IconButton(
                icon: const Icon(Icons.menu, color: Color(0xFF2D2F7D)),
                onPressed: () {
                  // Handle menu button press (e.g., open drawer)
                },
              ),
            ),
          ),
          // Top-right Bell Icon
          Positioned(
            top: 40,
            right: 16,
            child: Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 2,
              child: IconButton(
                icon: const Icon(Icons.notifications, color: Color(0xFF2D2F7D)),
                onPressed: () {
                  // Handle notification button press
                },
              ),
            ),
          ),
          // Start/Stop Button
          Positioned(
            top: MediaQuery.of(context).size.height * 0.35, // Adjust vertical position as needed
            right: 16,
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: _handleStartStop,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                // --- "Arrived" Button Logic moved here ---
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      _notifyPassengerOfArrival(_currentStopIndex);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text(
                      'Arrived',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
                // --- End of "Arrived" Button Logic ---
              ],
            ),
          ),
          // Bottom Info Card
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.4, // Occupy bottom 40%
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Ride Status Display
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      rideStatus == 'in_progress' ? 'Ride Status: In Progress' : 'Ride Status: Pending',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D2F7D)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Current and Next Stop Info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Stop: $currentStopName',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Next Stop: $nextStopName',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Estimated Arrival Time: $_estimatedArrivalTime',
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Passenger Info Section
                  const Text('Passengers on board (TODO)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 80,
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomNavItem(Icons.home, 'Home', 0),
            _buildBottomNavItem(Icons.monetization_on, 'My Income', 1),
            _buildHexagonalWalletIcon(), // Custom hexagonal wallet icon
            _buildBottomNavItem(Icons.star, 'Rating', 3),
            _buildBottomNavItem(Icons.person, 'Profile', 4),
          ],
        ),
      ),
    );
  }

  // Helper method for building bottom navigation items
  Widget _buildBottomNavItem(IconData icon, String label, int index) {
    return GestureDetector(
      onTap: () {
        // Handle navigation for these items
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.grey[600]),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  // Helper method for building the hexagonal wallet icon
  Widget _buildHexagonalWalletIcon() {
    return GestureDetector(
      onTap: () {
        // Handle wallet icon tap
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF2D2F7D),
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(10), // Adjust for hexagonal shape visually
        ),
        child: CustomPaint(
          painter: HexagonPainter(const Color(0xFF2D2F7D)), // Custom painter for hexagon shape
          child: const Center(
            child: Icon(Icons.account_balance_wallet, color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }
}

// Custom Painter for Hexagon Shape (needs to be defined outside _RideStartedPageState)
class HexagonPainter extends CustomPainter {
  final Color color;

  HexagonPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Use ui.Path instead of Path
    var path = ui.Path();

    for (int i = 0; i < 6; i++) {
      final angle = 2 * pi / 6 * i + pi / 6; // Start from top flat side
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}