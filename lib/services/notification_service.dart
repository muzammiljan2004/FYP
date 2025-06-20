import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initialize() async {
    // Request permission for notifications
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else {
      print('User declined or has not accepted permission');
    }

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _saveTokenToDatabase(token);
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToDatabase);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle notification taps when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  Future<void> _saveTokenToDatabase(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print('FCM token saved to database');
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
      _showLocalNotification(message);
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.data}');
    // Handle navigation based on notification data
    if (message.data['type'] == 'driver_arrived') {
      // Navigate to driver arrived page or show alert
      print('Driver arrived notification tapped');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('Local notification tapped: ${response.payload}');
    // Handle local notification tap
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'driver_arrival',
      'Driver Arrival Notifications',
      channelDescription: 'Notifications when driver arrives at pickup location',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Driver Arrived',
      message.notification?.body ?? 'Your driver is waiting for you',
      platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }

  Future<void> sendDriverArrivalNotification({
    required String passengerId,
    required String driverName,
    required String pickupLocation,
  }) async {
    try {
      // Get passenger's FCM token
      final passengerDoc = await _firestore.collection('users').doc(passengerId).get();
      final fcmToken = passengerDoc.data()?['fcmToken'];

      if (fcmToken != null) {
        // This is a placeholder for sending a notification.
        // In a real app, this should be handled by a backend/cloud function
        // to securely send the notification using the FCM API.
        // For this example, we'll write to a "notifications" collection
        // which a cloud function could listen to.
        await _firestore.collection('notifications').add({
          'recipientId': passengerId,
          'fcmToken': fcmToken, // For the cloud function to use
          'type': 'driver_arrived',
          'title': 'Driver Arrived!',
          'body': '$driverName is waiting for you at $pickupLocation.',
          'createdAt': FieldValue.serverTimestamp(),
        });
        print('Notification request created for passenger: $passengerId');
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }
}

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  // await Firebase.initializeApp(); // You might need this if you add more logic here.

  print("Handling a background message: ${message.messageId}");
} 