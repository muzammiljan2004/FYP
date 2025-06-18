import 'package:flutter/material.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({Key? key}) : super(key: key);

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
        title: const Text('Help and Support', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Text(
            'Lorem ipsum dolor sit amet consectetur. Sit pulvinar montes malesuada ac nibh tempor euismod. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Quis dictumst sagittis nibh euismod pharetra odio at feugiat nisi. Orci varius dictumst interdum. Lorem sit egestas dictum nullam pellentesque id. Habitant orci arcu et nunc euismod mattis facilisis sollicitudin.',
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ),
      ),
    );
  }
} 