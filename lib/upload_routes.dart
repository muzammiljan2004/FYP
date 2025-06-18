import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // <-- Add this line

Future<void> main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // <-- Use this!
  );

  final firestore = FirebaseFirestore.instance;

  // Route 1
  final route1 = [
    {'name': 'Air University', 'lat': 33.6667, 'lng': 72.9908},
    {'name': 'F-10 Markaz', 'lat': 33.6938, 'lng': 73.0117},
    {'name': 'G-10 Markaz', 'lat': 33.6844, 'lng': 73.0250},
    {'name': 'G-11 Markaz', 'lat': 33.6986, 'lng': 73.0186},
  ];
  await firestore.collection('routes').add({
    'name': 'Air Uni to G-11 (Route 1)',
    'stops': route1,
  });
  await firestore.collection('routes').add({
    'name': 'G-11 to Air Uni (Route 1)',
    'stops': List.from(route1.reversed),
  });

  // Route 2
  final route2 = [
    {'name': 'Air University', 'lat': 33.6667, 'lng': 72.9908},
    {'name': 'Ibn-e-Sina Metro Station', 'lat': 33.6841, 'lng': 73.0445},
    {'name': 'G-9 Markaz', 'lat': 33.6931, 'lng': 73.0479},
    {'name': 'G-10 Markaz', 'lat': 33.6844, 'lng': 73.0250},
    {'name': 'G-11 Markaz', 'lat': 33.6986, 'lng': 73.0186},
  ];
  await firestore.collection('routes').add({
    'name': 'Air Uni to G-11 (Route 2)',
    'stops': route2,
  });
  await firestore.collection('routes').add({
    'name': 'G-11 to Air Uni (Route 2)',
    'stops': List.from(route2.reversed),
  });

  print('Routes (including reverse) uploaded!');
}