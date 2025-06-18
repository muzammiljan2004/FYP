import 'package:flutter/material.dart';
import 'utils/validation_utils.dart';

class ReferralPage extends StatefulWidget {
  const ReferralPage({Key? key}) : super(key: key);

  @override
  State<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends State<ReferralPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _referralController = TextEditingController();

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
        title: const Text('Referral', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _referralController,
                decoration: InputDecoration(
                  hintText: 'Referral Code',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a referral code';
                  }
                  if (value.trim().length < 3) {
                    return 'Referral code must be at least 3 characters';
                  }
                  if (value.trim().length > 20) {
                    return 'Referral code is too long';
                  }
                  // Allow alphanumeric characters and hyphens
                  final referralRegex = RegExp(r'^[A-Za-z0-9\-]+$');
                  if (!referralRegex.hasMatch(value.trim())) {
                    return 'Referral code can only contain letters, numbers, and hyphens';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Handle referral code submission
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Referral code submitted successfully!')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D2F7D),
                    foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Invite'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 