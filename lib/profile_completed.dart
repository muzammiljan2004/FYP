import 'package:flutter/material.dart';

class ProfileCompleted extends StatelessWidget {
  const ProfileCompleted({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Completed', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 24),
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
              SizedBox(height: 24),
              Text(
                'Your driver profile has been successfully completed and is currently under verification.\n\nWe will notify you as soon as the review is complete.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Color(0xFF34495E)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
