import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('About Us', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Text(
            '''Professional RideShare Platform. Here we will provide you only interesting content, which you will like very much. We're dedicated to providing you the best of RideSharing, with a focus on dependability and safety. We're working to turn our passion for RideSharing into a booming online platform. We hope you enjoy our RideSharing Platform as much as we enjoy offering them to you. If you have any questions or comments, please don't hesitate to contact us.

Our platform offers everything from easy ride booking, transparent pricing, and professional drivers. Whether you're heading to work, the airport, or a night out, we're here to get you there safely and comfortably. Thank you for choosing our service and being a part of our community.

For more important posts and updates, please visit our website regularly. Thank you for your support and love.''',
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ),
      ),
    );
  }
} 