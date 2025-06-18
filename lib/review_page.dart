import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen_passenger.dart';
import 'utils/validation_utils.dart';

class ReviewPage extends StatefulWidget {
  final String rideId;
  final String driverId;

  const ReviewPage({
    Key? key,
    required this.rideId,
    required this.driverId,
  }) : super(key: key);

  @override
  _ReviewPageState createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic>? _driverProfile;
  bool _isLoading = true;
  double _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadDriverProfile();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadDriverProfile() async {
    try {
      final driverDoc = await _firestore.collection('users').doc(widget.driverId).get();
      if (!driverDoc.exists) return;

      setState(() {
        _driverProfile = driverDoc.data();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading driver profile: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Add review to reviews collection
      await _firestore.collection('reviews').add({
        'rideId': widget.rideId,
        'driverId': widget.driverId,
        'passengerId': user.uid,
        'rating': _rating,
        'comment': _commentController.text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update driver's average rating
      final driverReviews = await _firestore
          .collection('reviews')
          .where('driverId', isEqualTo: widget.driverId)
          .get();

      double totalRating = 0;
      for (var review in driverReviews.docs) {
        totalRating += review.data()['rating'] as double;
      }
      double averageRating = totalRating / driverReviews.docs.length;

      await _firestore.collection('users').doc(widget.driverId).update({
        'averageRating': averageRating,
        'totalReviews': driverReviews.docs.length,
      });

      // Navigate back to home screen
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const PassengerHomeScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting review: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Your Ride'),
        backgroundColor: const Color(0xFF2D2F7D),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    // Driver Info Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const CircleAvatar(
                              radius: 40,
                              backgroundColor: Color(0xFF2D2F7D),
                              child: Icon(Icons.person, size: 50, color: Colors.white),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _driverProfile?['name'] ?? 'Driver',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.star, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  '${_driverProfile?['averageRating']?.toStringAsFixed(1) ?? '0.0'} (${_driverProfile?['totalReviews'] ?? 0} reviews)',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Rating Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text(
                              'How was your ride?',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (index) {
                                return IconButton(
                                  icon: Icon(
                                    index < _rating ? Icons.star : Icons.star_border,
                                    color: Colors.amber,
                                    size: 40,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _rating = index + 1;
                                    });
                                  },
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Comment Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Additional Comments',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _commentController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                hintText: 'Share your experience...',
                                border: OutlineInputBorder(),
                              ),
                              validator: ValidationUtils.validateMessage,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Submit Button
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D2F7D),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Submit Review',
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 