import 'package:flutter/material.dart';
import 'passenger_profile_page.dart';
import 'driver_profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'utils/validation_utils.dart';

class SetPasswordPage extends StatefulWidget {
  final String role;
  final String name;
  final String email;
  final String phone;
  final String gender;
  const SetPasswordPage({Key? key, required this.role, required this.name, required this.email, required this.phone, required this.gender}) : super(key: key);

  @override
  _SetPasswordPageState createState() => _SetPasswordPageState();
}

class _SetPasswordPageState extends State<SetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorText;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  Future<void> createUserAccount() async {
    try {
      print('Starting user account creation for email: ${widget.email}');
      
      // Create Firebase Auth user
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: widget.email,
        password: _passwordController.text,
      );

      print('Firebase Auth user created successfully. User ID: ${userCredential.user?.uid}');

      final user = userCredential.user;
      if (user == null) {
        print('User is null after account creation');
        return;
      }

      // Store user data in Firestore
      final userData = {
        'name': widget.name,
        'email': widget.email,
        'phone': widget.phone,
        'gender': widget.gender,
        'role': widget.role,
        'createdAt': FieldValue.serverTimestamp(),
      };

      print('Storing user data in Firestore: $userData');

      // Store in users collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(userData);

      print('User data stored in users collection');

      // Store in role-specific collection
      final roleCollection = widget.role == 'driver' ? 'drivers' : 'passengers';
      await FirebaseFirestore.instance
          .collection(roleCollection)
          .doc(user.uid)
          .set(userData);

      print('User data stored in $roleCollection collection');

    } catch (e) {
      print('Error during account creation: $e');
      if (e is FirebaseAuthException) {
        print('Firebase Auth Exception: ${e.code} - ${e.message}');
        setState(() => _errorText = e.message ?? 'An error occurred.');
      } else {
        print('General error: $e');
        setState(() => _errorText = e.toString());
      }
      rethrow;
    }
  }

  void _onRegister() async {
    setState(() {
      _errorText = null;
      _isLoading = true;
    });

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorText = 'Passwords do not match';
        _isLoading = false;
      });
      return;
    }

    try {
      await createUserAccount();
      
      if (!mounted) return;

      if (widget.role == 'passenger') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PassengerProfilePage()),
        );
      } else if (widget.role == 'driver') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DriverProfilePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Set Password',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create a strong password for your account',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Password',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: ValidationUtils.validatePassword,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  hintText: 'Confirm Password',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                validator: (value) => ValidationUtils.validateConfirmPassword(value, _passwordController.text),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorText!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () {
                    if (_formKey.currentState!.validate()) {
                      _onRegister();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D2F7D),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Create Account',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
} 