import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'history_page.dart';
import 'complain_page.dart';
import 'about_us_page.dart';
import 'help_support_page.dart';
import 'referral_page.dart';
import 'settings_page.dart';
import 'login.dart';
import 'heading_to_destination_page.dart';
import 'review_page.dart';
import 'driver_arrived_page.dart';
import 'services/user_service.dart';
import 'profile_edit_page.dart';
import 'wallet.dart';
import 'profile.dart';
import 'my_income_page.dart';
import 'rating_details_page.dart';
import 'driver_waiting_screen.dart';
import 'dart:async';
import 'package:latlong2/latlong.dart' as lt; // Alias latlong2

class PassengerHomeScreen extends StatefulWidget {
  final int? selectedIndex;
  const PassengerHomeScreen({super.key, this.selectedIndex});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  LatLng? _currentPosition;
  late final MapController _mapController;
  int _selectedIndex = 0;
  Map<String, dynamic>? _nearestFromStop;
  Map<String, dynamic>? _nearestToStop;
  Map<String, dynamic>? _selectedRoute;
  final UserService _userService = UserService();
  Map<String, dynamic>? _userProfile;
  bool _isLoadingProfile = true;
  bool _isConfirmEnabled = false;

  List<Map<String, dynamic>> _allRoutes = [];
  Map<String, dynamic>? _userSelectedRoute;
  Map<String, dynamic>? _userPickupStop;
  Map<String, dynamic>? _userDropoffStop;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _activeRideSubscription;
  DocumentSnapshot? _activeRideDoc;
  StreamSubscription? _positionStreamSubscription;
  List<String?> _seatGenders = [null, null, null, null];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    print('[PAX_HOME] initState: Requesting and listening to location.');
    _requestAndListenLocation();
    print('[PAX_HOME] initState: Loading user profile.');
    _loadUserProfile();
    print('[PAX_HOME] initState: Calling _fetchAllRoutes...');
    _fetchAllRoutes();
    if (widget.selectedIndex != null) {
      _selectedIndex = widget.selectedIndex!;
    }
    print('[PAX_HOME] initState: Listening for active ride.');
    _listenForActiveRide();
  }

  @override
  void dispose() {
    _activeRideSubscription?.cancel();
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchAllRoutes() async {
    print('Fetching all routes from Firestore...');
    final routesSnapshot = await FirebaseFirestore.instance.collection('routes').get();
    print('Routes fetched. Is empty: ${routesSnapshot.docs.isEmpty}');
    setState(() {
      _allRoutes = routesSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Temporarily simplified filtering to ensure all stops are included
        // This is for diagnostic purposes to see if routes populate at all.
        final stops = (data['stops'] as List<dynamic>?);
        return {
          ...data,
          'stops': stops?.where((stop) {
            if (stop == null) {
              print('Skipping null stop entry.');
              return false;
            }
            // Directly check for 'lat' and 'lng' keys in the stop map
            if (!(stop is Map<String, dynamic>)) {
              print('Skipping stop (not Map<String, dynamic>): ${stop['name'] ?? 'Unknown'}, Actual type: ${stop.runtimeType}');
              return false;
            }

            if (!stop.containsKey('lat') || !stop.containsKey('lng')) {
              print('Skipping stop (missing lat/lng keys): ${stop['name'] ?? 'Unknown'}, Stop Data: $stop');
              return false;
            }
            // Further check if lat/lng are numbers
            if (!(stop['lat'] is num) || !(stop['lng'] is num)) {
              print('Skipping stop (lat/lng not numbers): ${stop['name'] ?? 'Unknown'}, Lat Type: ${stop['lat'].runtimeType}, Lng Type: ${stop['lng'].runtimeType}');
              return false;
            }
            return true;
          }).toList() ?? [], // Ensure stops is always a list and filtered
        };
      }).toList();

      // Temporarily removed route filtering based on empty stops for diagnosis
      // _allRoutes.retainWhere((route) => (route['stops'] as List).isNotEmpty);

      // Diagnostic: Print the structure of _allRoutes to verify stop locations
      print('Fetched and filtered routes: ');
      for (var route in _allRoutes) {
        print('  Route Name: ${route['name']}');
        if (route['stops'] != null && (route['stops'] as List).isNotEmpty) {
          for (var stop in route['stops']) {
            print('    Stop Name: ${stop['name']}, Lat: ${stop['lat']}, Lng: ${stop['lng']}');
          }
        } else {
          print('    No valid stops for this route (after simplified check).');
        }
      }
      print('Total routes after simplified filtering: ${_allRoutes.length}');
    });
  }

  Future<void> _requestAndListenLocation() async {
    while (true) {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('[PAX_HOME] Location service not enabled.');
        break;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('[PAX_HOME] Location permission denied.');
          break;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        print('[PAX_HOME] Location permission denied forever.');
        break;
      }
      // Permission granted
      break;
    }
    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        if (_currentPosition != null) {
          _mapController.move(_currentPosition!, 15.0);
        }
      });
      // Only start one listener
      _positionStreamSubscription = Geolocator.getPositionStream().listen((Position position) {
        if (mounted) {
          setState(() {
            _currentPosition = LatLng(position.latitude, position.longitude);
            if (_currentPosition != null) {
              _mapController.move(_currentPosition!, 15.0);
            }
          });
        }
      });
    } catch (e) {
      print('[PAX_HOME] Error getting location: $e');
    }
  }

  void _listenForActiveRide() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('[PAX_HOME] _listenForActiveRide: User is null, returning.');
      return;
    }

    print('[PAX_HOME] _listenForActiveRide: Listening for active rides for PId: ${user.uid}');

    _activeRideSubscription = FirebaseFirestore.instance
        .collection('active_rides')
        .where('PId', isEqualTo: user.uid)
        .where('status', whereIn: ['pending', 'driver_arrived', 'in_progress'])
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      print('[PAX_HOME] _listenForActiveRide: Received snapshot. Is empty: ${snapshot.docs.isEmpty}');
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _activeRideDoc = snapshot.docs.first;
        });
        print('[PAX_HOME] _listenForActiveRide: Active ride found: ${_activeRideDoc!.id}, status: ${(_activeRideDoc!.data() as Map<String, dynamic>)['status']}');
        _handleActiveRideStatusChange(_activeRideDoc!);
      } else {
        print('[PAX_HOME] _listenForActiveRide: Snapshot docs is EMPTY.'); // Diagnostic print
        if (_activeRideDoc != null) {
          print('[PAX_HOME] _listenForActiveRide: Active ride cleared. Was: ${_activeRideDoc!.id}. Attempting navigation to PassengerHomeScreen.'); // Diagnostic print
          setState(() {
            _activeRideDoc = null;
          });
          // Handle transition back to home screen if ride was completed/cancelled externally
          if (mounted) {
            print('[PAX_HOME] _listenForActiveRide: Widget is mounted. Navigating to PassengerHomeScreen.'); // Diagnostic print
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const PassengerHomeScreen()),
                  (Route<dynamic> route) => false,
            );
          } else {
            print('[PAX_HOME] _listenForActiveRide: Widget is NOT mounted. Cannot navigate.'); // Diagnostic print
          }
        } else {
          print('[PAX_HOME] _listenForActiveRide: No active ride found and _activeRideDoc was already null. No navigation needed.');
        }
      }
    }, onError: (error) {
      print('[PAX_HOME] _listenForActiveRide: Error listening for active ride: $error');
    });
  }

  void _handleActiveRideStatusChange(DocumentSnapshot activeRideDoc) {
    print('[PAX_HOME] _handleActiveRideStatusChange: Called with ride ID: ${activeRideDoc.id}');
    final rideData = activeRideDoc.data() as Map<String, dynamic>?;

    if (rideData == null) {
      print('[PAX_HOME] _handleActiveRideStatusChange: rideData is null. Returning.');
      return;
    }

    final rideStatus = rideData['status'] as String?;
    final driverCurrentStopIndex = rideData['current_stop_index'] as int?;

    int? passengerPickupStopIndex;
    if (_userPickupStop != null && _userSelectedRoute != null && _userSelectedRoute!['stops'] is List) {
      final routeStops = List<Map<String, dynamic>>.from(_userSelectedRoute!['stops']);
      passengerPickupStopIndex = routeStops.indexWhere((stop) =>
      stop is Map<String, dynamic> && stop['name'] == _userPickupStop!['name']);
      if (passengerPickupStopIndex == -1) {
        passengerPickupStopIndex = null;
      }
    }

    print('[PAX_HOME] _handleActiveRideStatusChange: Ride status: $rideStatus, Driver Stop Index: $driverCurrentStopIndex, Passenger Pickup Index: $passengerPickupStopIndex');

    // Dismiss any existing dialogs/popups
    // Check if there's a current dialog and dismiss it before navigating
    if (Navigator.of(context).canPop()) {
      // Only pop if the current route is a dialog or a temporary route
      // Avoid popping the main content route prematurely
      if (ModalRoute.of(context)?.isCurrent == false) {
        print('[PAX_HOME] _handleActiveRideStatusChange: Dismissing current modal/route.');
        Navigator.of(context).pop();
      }
    }

    if (rideStatus == 'pending') {
      print('[PAX_HOME] _handleActiveRideStatusChange: Status: pending. Navigating to DriverWaitingScreen.');
      // Navigate to DriverWaitingScreen
      if (mounted) {
        // Ensure we don't push if already on DriverWaitingScreen
        if (!(ModalRoute.of(context)?.settings.name == '/DriverWaitingScreen')) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => DriverWaitingScreen(
                rideId: activeRideDoc.id,
                routeData: _userSelectedRoute!, // Pass the selected route data
                pickupStopIndex: passengerPickupStopIndex, // Pass the pickup stop index
              ),
            ),
          );
        } else {
          print('[PAX_HOME] _handleActiveRideStatusChange: Already on DriverWaitingScreen.');
        }
      }
    } else if (rideStatus == 'driver_arrived') {
      print('[PAX_HOME] _handleActiveRideStatusChange: Status: driver_arrived. Navigating to DriverArrivedPage.');
      // Navigate to DriverArrivedPage
      if (mounted) {
        if (!(ModalRoute.of(context)?.settings.name == '/DriverArrivedPage')) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => DriverArrivedPage(
                rideId: activeRideDoc.id,
                routeData: _userSelectedRoute!, // Pass the selected route data
                pickupStopIndex: passengerPickupStopIndex, // Pass the pickup stop index
              ),
            ),
          );
        } else {
          print('[PAX_HOME] _handleActiveRideStatusChange: Already on DriverArrivedPage.');
        }
      }
    } else if (rideStatus == 'in_progress') {
      print('[PAX_HOME] _handleActiveRideStatusChange: Status: in_progress. Navigating to HeadingToDestinationPage.');
      // Navigate to HeadingToDestinationPage
      if (mounted) {
        if (!(ModalRoute.of(context)?.settings.name == '/HeadingToDestinationPage')) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => HeadingToDestinationPage(
                rideId: activeRideDoc.id,
                fromStop: _userPickupStop!, // Pass the actual pickup stop data
                toStop: _userDropoffStop!, // Pass the actual dropoff stop data
              ),
            ),
          );
        } else {
          print('[PAX_HOME] _handleActiveRideStatusChange: Already on HeadingToDestinationPage.');
        }
      }
    } else if (rideStatus == 'completed') {
      print('[PAX_HOME] _handleActiveRideStatusChange: Status: completed. Navigating to ReviewPage or PassengerHomeScreen.');
      // Ride completed, navigate to ReviewPage, then back to home
      if (mounted) {
        // Ensure we are not already on ReviewPage to avoid pushing duplicate routes
        if (!(ModalRoute.of(context)?.settings.name == '/ReviewPage')) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) =>   ReviewPage(
                rideId: activeRideDoc.id,
                driverId: rideData['DId'],
              ),
            ),
          );
        } else {
          print('[PAX_HOME] _handleActiveRideStatusChange: Already on ReviewPage. Not navigating again.');
        }
      }
    } else if (rideStatus == 'cancelled') {
      print('[PAX_HOME] _handleActiveRideStatusChange: Status: cancelled. Returning to PassengerHomeScreen.');
      // Ride cancelled, navigate back to PassengerHomeScreen
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const PassengerHomeScreen()),
              (Route<dynamic> route) => false,
        );
      }
    } else {
      print('[PAX_HOME] _handleActiveRideStatusChange: Unknown status or ride completion. Popping to PassengerHomeScreen.');
      // Fallback for any other status, or if the ride document is removed
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const PassengerHomeScreen()),
              (Route<dynamic> route) => false,
        );
      }
    }
  }

  Future<void> _showFindingDriverDialog(String requestId) async {
    bool cancelled = false;
    final completer = Completer<void>();

    print('[PAX_HOME] _showFindingDriverDialog: Showing dialog for request ID: $requestId');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        // Store the BuildContext of the dialog for later dismissal
        _findingDriverDialogContext = context;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                const Expanded(child: Text('Finding your driver...')),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  cancelled = true;
                  print('[PAX_HOME] _showFindingDriverDialog: Cancel button pressed.');
                  await FirebaseFirestore.instance.collection('ride_requests').doc(requestId).delete();
                  if (completer.isCompleted == false) {
                    completer.complete();
                    print('[PAX_HOME] _showFindingDriverDialog: Completer completed by cancel.');
                  }
                  Navigator.of(context).pop();
                  _activeRideSubscription?.cancel();
                },
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );

    await completer.future;
    print('[PAX_HOME] _showFindingDriverDialog: Dialog future completed. Dialog should be dismissed.');
  }

  BuildContext? _findingDriverDialogContext;

  Future<void> _showDriverAndSeatSelectionModal() async {
    print('[PAX_HOME] _showDriverAndSeatSelectionModal: Called.');
    if (_userSelectedRoute == null || _userPickupStop == null || _userDropoffStop == null) {
      print('[PAX_HOME] _showDriverAndSeatSelectionModal: Route or stops are null, returning.');
      return;
    }

    if (_currentPosition == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please wait for your current location to be determined.')),
        );
      }
      return;
    }

    final onlineDriversSnapshot = await FirebaseFirestore.instance
        .collection('drivers_online')
        .where('RouteId', isEqualTo: _userSelectedRoute!['name'])
        .where('Status', isEqualTo: 'online')
        .get();

    List<Map<String, dynamic>> driversWithDetails = [];

    for (var driverDoc in onlineDriversSnapshot.docs) {
      final driverData = driverDoc.data() as Map<String, dynamic>;
      final driverId = driverData['DId'];

      if (driverId != null) {
        final userProfileDoc = await FirebaseFirestore.instance.collection('users').doc(driverId).get();
        if (userProfileDoc.exists) {
          final userProfileData = userProfileDoc.data() as Map<String, dynamic>;

          String driverCurrentStopName = 'Unknown';
          final driverCurrentStopIndex = driverData['current_stop_index'] as int?;
          if (driverCurrentStopIndex != null &&
              _userSelectedRoute != null &&
              _userSelectedRoute!['stops'] is List &&
              driverCurrentStopIndex >= 0 &&
              driverCurrentStopIndex < (_userSelectedRoute!['stops'] as List).length) {
            driverCurrentStopName = (_userSelectedRoute!['stops'][driverCurrentStopIndex] as Map<String, dynamic>)['name'] ?? 'Unknown';
          }

          driversWithDetails.add({
            'DId': driverId,
            'name': userProfileData['name'] ?? 'Driver',
            'averageRating': userProfileData['averageRating'] ?? 0.0,
            'totalReviews': userProfileData['totalReviews'] ?? 0,
            'vehicleModel': userProfileData['vehicleDetails']?['model'] ?? 'Car', // Assuming vehicleDetails field
            'vehicleImageUrl': userProfileData['vehicleDetails']?['imageUrl'] ?? 'assets/car_placeholder.png', // Placeholder
            'currentStopName': driverCurrentStopName, // Added current stop name
          });
        }
      }
    }

    print('[PAX_HOME] _showDriverAndSeatSelectionModal: Number of detailed drivers found: ${driversWithDetails.length}');

    if (driversWithDetails.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No available drivers for this route at the moment.')),
        );
      }
      print('[PAX_HOME] _showDriverAndSeatSelectionModal: No detailed drivers, returning.');
      return;
    }

    int? selectedDriverIndex; // Changed from selectedDriverIdx for consistency

    // Hardcode payment amount for now, actual calculation might be needed later.
    const String paymentAmount = 'Rs.30';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            print('[PAX_HOME] _showDriverAndSeatSelectionModal: StatefulBuilder rebuilt. Initial selectedDriverIndex: $selectedDriverIndex, _seatGenders: $_seatGenders');
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Select Driver', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: driversWithDetails.length,
                      itemBuilder: (context, i) {
                        final driver = driversWithDetails[i];
                        print('[PAX_HOME] Driver ${driver['name']} details: ${driver}'); // Diagnostic print for driver details
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          color: selectedDriverIndex == i ? Colors.indigo[50] : null,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                selectedDriverIndex = i;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Driver Avatar
                                  const CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Color(0xFF2D2F7D),
                                    child: Icon(Icons.person, color: Colors.white, size: 30),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          driver['name'],
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Current Stop: ${driver['currentStopName']}',
                                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.star, color: Colors.amber, size: 16),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${driver['averageRating'].toStringAsFixed(1)} (${driver['totalReviews']} reviews)',
                                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Vehicle Image (Placeholder for now)
                                  Image.asset(
                                    driver['vehicleImageUrl'], // Using placeholder image for now
                                    height: 60,
                                    width: 100,
                                    fit: BoxFit.contain,
                                  ),
                                  if (selectedDriverIndex == i)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8.0),
                                      child: Icon(Icons.check_circle, color: Colors.indigo, size: 24),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16), // Added spacing for seats
                  const Text('Select Seats', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), // Re-added Seats title
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (idx) {
                      Color color;
                      IconData icon = Icons.event_seat; // Default icon
                      if (_seatGenders[idx] == 'male') {
                        color = Colors.blue;
                        icon = Icons.male; // Male icon
                      } else if (_seatGenders[idx] == 'female') {
                        color = Colors.pink;
                        icon = Icons.female; // Female icon
                      } else {
                        color = Colors.grey[300]!;
                        icon = Icons.event_seat; // Unselected icon
                      }
                      return GestureDetector(
                        onTap: () {
                          print('[PAX_HOME] Seat ${idx} tapped. Before: ${_seatGenders[idx]}'); // Diagnostic print for seat tap
                          setState(() {
                            if (_seatGenders[idx] == null) {
                              _seatGenders[idx] = 'male';
                            } else if (_seatGenders[idx] == 'male') {
                              _seatGenders[idx] = 'female';
                            } else {
                              _seatGenders[idx] = null;
                            }
                            print('[PAX_HOME] Seat ${idx} tapped. After: ${_seatGenders[idx]}. All seats: $_seatGenders'); // Diagnostic print after seat state change
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: CircleAvatar(
                            backgroundColor: color,
                            child: Icon(icon, color: Colors.white),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Payment amount',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        paymentAmount,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: selectedDriverIndex != null && _seatGenders.any((g) => g != null) // Re-added seat selection check
                        ? () async {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('User not signed in. Please log in again.')),
                          );
                        }
                        return;
                      }

                      final driverDocData = driversWithDetails[selectedDriverIndex!];

                      // Determine pickup_stop_index
                      int? pickupStopIndex;
                      if (_userSelectedRoute != null && _userPickupStop != null) {
                        final routeStops = List<Map<String, dynamic>>.from(_userSelectedRoute!['stops'] ?? []);
                        pickupStopIndex = routeStops.indexWhere((stop) => stop['name'] == _userPickupStop!['name']);
                        if (pickupStopIndex == -1) pickupStopIndex = null; // Ensure it's null if not found
                      }

                      final request = {
                        'PId': user.uid,
                        'PName': _userProfile?['name'] ?? '',
                        'status': 'pending', // Pending (string, lowercase)
                        'BookingTime': FieldValue.serverTimestamp(),
                        'From': _userPickupStop,
                        'To': _userDropoffStop,
                        'RouteId': _userSelectedRoute!['name'],
                        'DId': driverDocData['DId'],
                        'Seats': _seatGenders, // Send the selected genders
                        'pickup_stop_index': pickupStopIndex,
                        'fare': double.parse(paymentAmount.replaceAll('Rs.', '')), // Add fare to request
                      };

                      print('[PAX_HOME] Requesting ride with data: $request');
                      final requestRef = await FirebaseFirestore.instance.collection('ride_requests').add(request);
                      print('[PAX_HOME] Ride request added with ID: ${requestRef.id}');
                      if (mounted) {
                        Navigator.pop(context); // Dismiss the modal
                      }
                      await _showFindingDriverDialog(requestRef.id);
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedDriverIndex != null && _seatGenders.any((g) => g != null) ? const Color(0xFF2D2F7D) : Colors.grey,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Confirm', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _requestRide() async {
    if (_userSelectedRoute == null || _userPickupStop == null || _userDropoffStop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select route and both stops.')),
      );
      return;
    }
    if (_userPickupStop == _userDropoffStop) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pickup and dropoff stops must be different.')),
      );
      return;
    }
    await _showDriverAndSeatSelectionModal();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoadingProfile = true);
    try {
      final profile = await _userService.getCurrentUserProfile();
      setState(() {
        _userProfile = profile;
        _isLoadingProfile = false;
      });
    } catch (e) {
      print('Error loading user profile: $e');
      setState(() => _isLoadingProfile = false);
    }
  }

  Widget _buildRideAcceptedView() {
    if (_activeRideDoc == null) return const SizedBox.shrink();

    final rideData = _activeRideDoc!.data() as Map<String, dynamic>;
    final String driverId = rideData['DId'];
    final Map<String, dynamic> pickupStop = rideData['pickup_stop'] ?? {};
    final Map<String, dynamic> dropStop = rideData['drop_stop'] ?? {};

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(driverId).get(),
      builder: (context, driverSnapshot) {
        if (driverSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (driverSnapshot.hasError) {
          return Center(child: Text('Error: ${driverSnapshot.error}'));
        }
        if (!driverSnapshot.hasData || !driverSnapshot.data!.exists) {
          return const Center(child: Text('Driver information not found.'));
        }

        final driverData = driverSnapshot.data!.data() as Map<String, dynamic>;
        final String driverName = driverData['name'] ?? 'Unknown Driver';
        final String vehicleMake = driverData['vehicleMake'] ?? 'N/A';
        final String vehicleModel = driverData['vehicleModel'] ?? 'N/A';
        final String vehicleColor = driverData['vehicleColor'] ?? 'N/A';
        final String licensePlate = driverData['licensePlate'] ?? 'N/A';

        return Container(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                const Text(
                  'Your ride has been accepted!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Driver: $driverName', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Vehicle: $vehicleColor $vehicleMake $vehicleModel', style: const TextStyle(fontSize: 16)),
                        Text('License Plate: $licensePlate', style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 16),
                        Text('Pickup Stop: ${pickupStop['name'] ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
                        Text('Drop-off Stop: ${dropStop['name'] ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 16),
                        Text('Status: ${rideData['status'] ?? 'pending'}', style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance.collection('active_rides').doc(_activeRideDoc!.id).update({
                      'status': 'cancelled_by_passenger',
                    });
                    if (mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Cancel Ride', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _editProfile() async {
    if (_userProfile == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileEditPage(currentProfile: _userProfile!),
      ),
    );

    if (result == true) {
      _loadUserProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    print('[PAX_HOME] build: Building PassengerHomeScreen. _activeRideDoc is ${_activeRideDoc != null ? 'not null' : 'null'}');

    if (_isLoadingProfile) {
      print('[PAX_HOME] build: Profile is loading, showing CircularProgressIndicator.');
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // If there's an active ride document, build the ride-related view
    if (_activeRideDoc != null) {
      print('[PAX_HOME] build: Active ride doc exists, calling _buildRideAcceptedView.');
      // This means the listener detected an active ride.
      // The _handleActiveRideStatusChange will handle the actual navigation,
      // but if we are *on* PassengerHomeScreen and an active ride is detected,
      // we might briefly show this or directly navigate.
      // For now, if activeRideDoc is present, we rely on _handleActiveRideStatusChange
      // to push the correct screen. We should not show the home screen if an active ride exists.
      // This branch should ideally not be reached if _handleActiveRideStatusChange works correctly,
      // as it should navigate away. If it is, it means the navigation didn't occur for some reason.
      return const Scaffold(body: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.green))));
    }

    Widget body;
    switch (_selectedIndex) {
      case 1:
        body = MyIncomePage();
        break;
      case 2:
        body = WalletPage();
        break;
      case 3:
        body = RatingDetailsPage();
        break;
      case 4:
        body = ProfilePage();
        break;
      default:
        body = Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(center: _currentPosition ?? LatLng(33.6844, 73.0479), zoom: 12),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                ),
                if (_currentPosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 40.0,
                        height: 40.0,
                        point: _currentPosition!,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (_activeRideDoc == null)
              Positioned(
                top: 40,
                left: 16,
                right: 16,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Map<String, dynamic>>(
                          hint: const Text('Select Route'),
                          value: _userSelectedRoute,
                          isExpanded: true,
                          items: _allRoutes.map((route) {
                            return DropdownMenuItem<Map<String, dynamic>>(
                              value: route,
                              child: Text(route['name']),
                            );
                          }).toList(),
                          onChanged: (route) {
                            setState(() {
                              _userSelectedRoute = route;
                              _userPickupStop = null;
                              _userDropoffStop = null;
                              _isConfirmEnabled = false;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_userSelectedRoute != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<Map<String, dynamic>>(
                            hint: const Text('F-10 Markaz'),
                            value: _userPickupStop,
                            isExpanded: true,
                            items: (
                                _userSelectedRoute!['stops'] as List<dynamic>
                            )
                                .whereType<Map<String, dynamic>>() // Ensure it's a list of maps
                                .where((stop) =>
                            stop.containsKey('lat') &&
                                stop['lat'] is num &&
                                stop.containsKey('lng') &&
                                stop['lng'] is num) // Filter for valid stops
                                .map((stop) {
                              return DropdownMenuItem<Map<String, dynamic>>(
                                value: stop,
                                child: Text(stop['name'] ?? 'Unknown Stop'),
                              );
                            }).toList(),
                            onChanged: (stop) {
                              setState(() {
                                _userPickupStop = stop;
                                // Reset dropoff stop if pickup changes to prevent invalid selection
                                _userDropoffStop = null;
                                _isConfirmEnabled = _userPickupStop != null && _userDropoffStop != null;
                              });
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    if (_userSelectedRoute != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<Map<String, dynamic>>(
                            hint: const Text('Drop-off Stop'),
                            value: _userDropoffStop,
                            isExpanded: true,
                            items: _userPickupStop == null
                                ? [] // No pickup stop selected, no dropoff stops available
                                : (
                                _userSelectedRoute!['stops'] as List<dynamic>
                            )
                                .whereType<Map<String, dynamic>>() // Ensure it's a list of maps
                                .skipWhile((stop) =>
                            stop['name'] != _userPickupStop!['name']) // Skip until pickup stop is found
                                .skip(1) // Then skip the pickup stop itself
                                .where((stop) =>
                            stop.containsKey('lat') &&
                                stop['lat'] is num &&
                                stop.containsKey('lng') &&
                                stop['lng'] is num) // Filter for valid stops
                                .map((stop) {
                              return DropdownMenuItem<Map<String, dynamic>>(
                                value: stop,
                                child: Text(stop['name'] ?? 'Unknown Stop'),
                              );
                            }).toList(),
                            onChanged: (stop) {
                              setState(() {
                                _userDropoffStop = stop;
                                _isConfirmEnabled = _userPickupStop != null && _userDropoffStop != null;
                              });
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            if (_activeRideDoc == null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 100,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isConfirmEnabled
                        ? () async {
                      // Call _requestRide to handle the full flow
                      await _requestRide();
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo[900],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Confirm Ride',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 40,
              left: 16,
              child: Builder(
                builder: (context) => Material(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 2,
                  child: IconButton(
                    icon: const Icon(Icons.menu, color: Color(0xFF2D2F7D)),
                    onPressed: () {
                      if (mounted) {
                        Scaffold.of(context).openDrawer();
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        );
        break;
    }

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF2D2F7D),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40, color: Color(0xFF2D2F7D)),
                  ),
                  const SizedBox(height: 10),
                  if (_isLoadingProfile)
                    const CircularProgressIndicator(color: Colors.white)
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userProfile?['name'] ?? 'User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _userProfile?['email'] ?? '',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Profile'),
              onTap: () {
                Navigator.pop(context);
                _editProfile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('History'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HistoryPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_problem_outlined),
              title: const Text('Complain'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ComplainPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.card_giftcard),
              title: const Text('Referral'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReferralPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About Us'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutUsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help and Support'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HelpSupportPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                      (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const WalletPage()),
            );
          } else if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfilePage()),
            );
          }
        },
        selectedItemColor: const Color(0xFF2D2F7D),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.monetization_on), label: 'My Income'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Rating'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
} 