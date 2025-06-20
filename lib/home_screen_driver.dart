    import 'package:flutter/material.dart';
    import 'package:flutter_map/flutter_map.dart';
    import 'package:latlong2/latlong.dart';
    import 'package:geolocator/geolocator.dart';
    import 'history_page.dart';
    import 'complain_page.dart';
    import 'about_us_page.dart';
    import 'help_support_page.dart';
    import 'referral_page.dart';
    import 'settings_page.dart';
    import 'login.dart';
    import 'select_address.dart';
    import 'select_route_sheet.dart';
    import 'ride_started.dart';
    import 'rating_details_page.dart';
    import 'my_income_page.dart';
    import 'wallet.dart';
    import 'profile.dart';
    import 'driver_profile_page.dart';
    import 'package:cloud_firestore/cloud_firestore.dart';
    import 'package:firebase_auth/firebase_auth.dart';
    import 'services/user_service.dart';
    import 'profile_edit_page.dart';

    final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

    class DriverHomeScreen extends StatefulWidget {
      const DriverHomeScreen({super.key});

      @override
      State<DriverHomeScreen> createState() => _DriverHomeScreenState();
    }

    class _DriverHomeScreenState extends State<DriverHomeScreen> {
      LatLng? _currentPosition;
      late final MapController _mapController;
      bool _isOnline = false;
      int _selectedIndex = 2;
      bool _routeConfirmed = false;
      Map<String, dynamic>? _selectedRoute;
      Stream<QuerySnapshot>? _requestsStream;
      final UserService _userService = UserService();
      Map<String, dynamic>? _userProfile;
      bool _isLoadingProfile = true;

      @override
      void initState() {
        super.initState();
        _mapController = MapController();
        _requestAndListenLocation();
        _loadUserProfile();
        _restoreOnlineStatus();
      }

      Future<void> _requestAndListenLocation() async {
        while (true) {
          bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (!serviceEnabled) {
            await Geolocator.openLocationSettings();
            await Future.delayed(const Duration(seconds: 1));
            continue;
          }
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
            if (permission == LocationPermission.denied) {
              await _showPermissionDialog('Location permission is required to use this app. Please enable location to continue.');
              continue;
            }
          }
          if (permission == LocationPermission.deniedForever) {
            await _showPermissionDialog('Location permission is permanently denied. Please enable it from app settings to use this app.');
            await Geolocator.openAppSettings();
            await Future.delayed(const Duration(seconds: 1));
            continue;
          }
          // Permission granted
          break;
        }
        try {
          Position position = await Geolocator.getCurrentPosition();
          setState(() {
            _currentPosition = LatLng(position.latitude, position.longitude);
          });
          print('Initial Current Position: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');
          // Only start one listener
          Geolocator.getPositionStream().listen((Position position) {
            setState(() {
              _currentPosition = LatLng(position.latitude, position.longitude);
              _mapController.move(_currentPosition!, 15.0);
            });
            print('Stream Updated Position: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');
          });
        } catch (e) {
          await _showPermissionDialog('Failed to get location. Please try again.');
          Future.delayed(const Duration(seconds: 1), _requestAndListenLocation);
        }
      }

      Future<void> _showPermissionDialog(String message) async {
        return showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Location Required'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }

      Future<void> _restoreOnlineStatus() async {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final doc = await FirebaseFirestore.instance.collection('drivers_online').doc(user.uid).get();
          setState(() {
            _isOnline = doc.exists && doc.data()?['Status'] == 'online';
          });
        }
      }

      void _handleOnlineToggle() async {
        if (!_isOnline) {
          // Ensure current position is available before going online
          if (_currentPosition == null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Waiting for your current location. Please try again.')),
              );
            }
            return;
          }

          // Going online - show route selection
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            isDismissible: false,
            enableDrag: false,
            builder: (context) => FractionallySizedBox(
              heightFactor: 0.5,
              child: SelectRouteSheet(
                onRouteSelected: (route) async {
                  if (route == null) {
                    // User cancelled
                    setState(() {
                      _isOnline = false;
                      _routeConfirmed = false;
                      _selectedRoute = null;
                      _requestsStream = null;
                    });
                    if (mounted) Navigator.pop(context);
                    return;
                  }
                  try {
                    setState(() {
                      _selectedRoute = route;
                      _routeConfirmed = true;
                      _isOnline = true;
                      _requestsStream = FirebaseFirestore.instance
                        .collection('ride_requests')
                        .where('RouteId', isEqualTo: route['name'])
                        .where('status', isEqualTo: 'pending')
                        .snapshots();
                    });
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      // Only go offline if user is signed out
                      setState(() {
                        _isOnline = false;
                        _routeConfirmed = false;
                        _selectedRoute = null;
                        _requestsStream = null;
                      });
                      if (mounted) Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('You have been signed out. Please log in again.')),
                      );
                      return;
                    }
                    Map<String, dynamic> driverOnlineData = {
                      'DId': user.uid,
                      'RouteId': route['name'],
                      'Status': 'online',
                      'LastUpdated': FieldValue.serverTimestamp(),
                      'CurrentLocation': _currentPosition != null ? {
                        'lat': _currentPosition?.latitude,
                        'lng': _currentPosition?.longitude,
                      } : null,
                    };

                    await FirebaseFirestore.instance
                        .collection('drivers_online')
                        .doc(user.uid)
                        .set(driverOnlineData);
                    if (mounted) {
                      Navigator.pop(context);
                      await _showPassengerRequestsPopup();
                    }
                  } catch (e) {
                    if (mounted) {
                      // Use the GlobalKey to show the SnackBar
                      scaffoldMessengerKey.currentState?.showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    }
                  }
                },
                showCancelButton: true,
              ),
            ),
          );
        } else {
          // Going offline
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            try {
              await FirebaseFirestore.instance
                  .collection('drivers_online')
                  .doc(user.uid)
                  .delete();
            } catch (e) {
              print('Error updating offline status: $e');
            }
          }
          setState(() {
            _isOnline = false;
            _routeConfirmed = false;
            _selectedRoute = null;
            _requestsStream = null;
          });
        }
      }

      Future<void> _showPassengerRequestsPopup() async {
        if (_requestsStream == null) return;
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          isDismissible: false,
          enableDrag: false,
          builder: (context) => StreamBuilder<QuerySnapshot>(
            stream: _requestsStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final requests = snapshot.data!.docs;
              if (requests.isEmpty) {
                // Show waiting message and allow manual cancel
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('No ride requests at the moment.'),
                      const SizedBox(height: 16),
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () async {
                          // Set offline in Firestore and update state
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            await FirebaseFirestore.instance
                                .collection('drivers_online')
                                .doc(user.uid)
                                .delete();
                          }
                          setState(() {
                            _isOnline = false;
                            _routeConfirmed = false;
                            _selectedRoute = null;
                            _requestsStream = null;
                          });
                          if (mounted) {
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('Cancel / Go Offline'),
                      ),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: requests.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, idx) {
                  final req = requests[idx].data() as Map<String, dynamic>;
                  final passengerId = req['PId'];

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(passengerId).get(),
                    builder: (context, passengerSnapshot) {
                      String passengerName = 'Unknown Passenger';
                      if (passengerSnapshot.hasData && passengerSnapshot.data!.exists) {
                        passengerName = passengerSnapshot.data!['name'] ?? 'Unknown Passenger';
                        print('[DRIVER_HOME] Fetched Passenger Name: $passengerName for PId: $passengerId');
                      } else {
                        print('[DRIVER_HOME] Passenger data not found or does not exist for PId: $passengerId');
                      }

                      return Card(
                        child: ListTile(
                          title: Text('From:  ${req['From']['name']} → To: ${req['To']['name']}'),
                          subtitle: Text('Passenger: $passengerName'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FutureBuilder<QuerySnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('active_rides')
                                    .where('DId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                                    .get(),
                                builder: (context, activeRidesSnapshot) {
                                  if (!activeRidesSnapshot.hasData) {
                                    print('[DRIVER_HOME] Active rides snapshot has no data.');
                                    return const CircularProgressIndicator();
                                  }
                                  final activeRidesCount = activeRidesSnapshot.data!.docs.length;
                                  final canAccept = activeRidesCount < 4;
                                  print('[DRIVER_HOME] Active Rides Count: $activeRidesCount, Can Accept: $canAccept');

                                  return ElevatedButton(
                                    onPressed: canAccept
                                        ? () async {
                                            await _acceptRequest(requests[idx]);
                                          }
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: canAccept ? Theme.of(context).primaryColor : Colors.grey,
                                    ),
                                    child: Text(canAccept ? 'Accept' : 'Full (${activeRidesCount}/4)'),
                                  );
                                },
                              ),
                              const SizedBox(width: 8), // Spacing between buttons
                              ElevatedButton(
                                onPressed: () async {
                                  await _rejectRequest(requests[idx].id); // Pass request ID to reject
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Reject', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      }

      Future<void> _acceptRequest(DocumentSnapshot requestDoc) async {
        final data = requestDoc.data() as Map<String, dynamic>;
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        final batch = FirebaseFirestore.instance.batch();

        // Generate a new document ID for the active ride once
        final newRideDocRef = FirebaseFirestore.instance.collection('active_rides').doc();

        // Remove from ride_requests
        batch.delete(requestDoc.reference);

        // Add to active_rides using the generated document reference
        batch.set(
          newRideDocRef,
          {
            'PId': data['PId'],
            'DId': user.uid,
            'AcceptanceTime': FieldValue.serverTimestamp(),
            'From': data['From'],
            'To': data['To'],
            'status': 'pending',
            'RouteId': data['RouteId'],
            'pickup_stop': data['From'],
            'drop_stop': data['To'],
            'pickup_stop_index': data['pickup_stop_index'],
            'dropoff_stop_index': data['dropoff_stop_index'],
            'CurrentLocation': _currentPosition != null ? {
              'lat': _currentPosition?.latitude,
              'lng': _currentPosition?.longitude,
            } : null,
          },
        );

        await batch.commit();

        // Navigate to ride started page
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RideStartedPage(
              driverId: user.uid,
              rideId: newRideDocRef.id, // Pass the actual document ID
              routeData: _selectedRoute!, // Pass the selected route data
            ),
          ),
        );
      }

      Future<void> _rejectRequest(String requestId) async {
        try {
          await FirebaseFirestore.instance.collection('ride_requests').doc(requestId).delete();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ride request rejected.')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error rejecting request: $e')),
            );
          }
        }
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
        if (_currentPosition == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        Widget body;
        switch (_selectedIndex) {
          case 1:
            body = MyIncomePage();
            break;
          case 3:
            body = RatingDetailsPage();
            break;
          default:
            body = Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(center: _currentPosition!, zoom: 15),
                  children: [
                    TileLayer(
                      urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                    ),
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
                // Online/Offline flowable toggle button
                Positioned(
                  top: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _handleOnlineToggle,
                      child: Container(
                        width: 180,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Stack(
                          children: [
                            AnimatedAlign(
                              alignment: _isOnline ? Alignment.centerRight : Alignment.centerLeft,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              child: Container(
                                width: 90,
                                height: 36,
                                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _isOnline ? Colors.green[100] : Colors.red[100],
                                  borderRadius: BorderRadius.circular(32),
                                  border: Border.all(
                                    color: _isOnline ? Colors.green : Colors.red,
                                    width: 2,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _isOnline ? 'Online' : 'Offline',
                                  style: TextStyle(
                                    color: _isOnline ? Colors.green[900] : Colors.red[900],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Menu button (top left)
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
                if (_routeConfirmed)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 40,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_isOnline) {
                            await _showPassengerRequestsPopup();
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please go online first.')),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo[900],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Start Ride',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
              ],
            );
            break;
        }

        return Scaffold(
          key: scaffoldMessengerKey,
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
                    if (mounted) {
                      Navigator.pop(context);
                    }
                    _editProfile();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('History'),
                  onTap: () {
                    if (mounted) {
                      Navigator.pop(context);
                    }
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
                    if (mounted) {
                      Navigator.pop(context);
                    }
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
                    if (mounted) {
                      Navigator.pop(context);
                    }
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
                    if (mounted) {
                      Navigator.pop(context);
                    }
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
                    if (mounted) {
                      Navigator.pop(context);
                    }
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
                    if (mounted) {
                      Navigator.pop(context);
                    }
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
                    if (mounted) {
                      Navigator.pop(context);
                    }
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                      (route) => false,
                    );
                  },
                ),
                const SizedBox(height: 16),
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
              }
              else if (index == 4) {
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