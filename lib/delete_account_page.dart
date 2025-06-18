import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:flutter_application_1/login.dart'; // Import your login page
import 'utils/validation_utils.dart';

class DeleteAccountPage extends StatefulWidget {
  @override
  _DeleteAccountPageState createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Prompt for reauthentication
        // For simplicity, we are assuming a direct password input. For a real app,
        // you might want a separate dialog or screen for reauthentication.
        // If the user has recently logged in, reauthentication might not be required.
        // However, for sensitive operations like account deletion, it's good practice.
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Reauthenticate'.tr()),
              content: Form(
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'password'.tr()),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel'.tr()),
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  },
                ),
                TextButton(
                  child: Text('Confirm'.tr()),
                  onPressed: () async {
                    // Validate password before proceeding
                    final form = Form.of(context);
                    if (form?.validate() == false) {
                      return;
                    }
                    
                    try {
                      AuthCredential credential = EmailAuthProvider.credential(
                        email: user.email!,
                        password: _passwordController.text,
                      );
                      await user.reauthenticateWithCredential(credential);
                      Navigator.of(context).pop(); // Close dialog
                      // Proceed with deletion after successful reauthentication
                      await user.delete();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Account deleted successfully.'.tr())),
                        );
                        // Navigate to login page after successful deletion
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => LoginScreen()),
                          (Route<dynamic> route) => false,
                        );
                      }
                    } on FirebaseAuthException catch (e) {
                      String errorMessage = 'Authentication failed.'.tr();
                      if (e.code == 'wrong-password') {
                        errorMessage = 'Incorrect password.'.tr();
                      } else if (e.code == 'user-not-found') {
                        errorMessage = 'User not found.'.tr();
                      } else {
                        errorMessage = '${'Error'.tr()}: ${e.message}'.tr();
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(errorMessage)),
                        );
                        Navigator.of(context).pop(); // Close dialog
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${'An error occurred'.tr()}: ${e.toString()}')),
                        );
                        Navigator.of(context).pop(); // Close dialog
                      }
                    } finally {
                      if (mounted) {
                        setState(() => _isLoading = false);
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User not signed in.'.tr())),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An unknown error occurred'.tr();
      if (e.code == 'requires-recent-login') {
        errorMessage = 'This operation is sensitive and requires recent authentication. Please log in again.'.tr();
      } else {
        errorMessage = '${'Error'.tr()}: ${e.message}'.tr();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'An error occurred'.tr()}: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('delete_account'.tr())),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  'delete_account_warning'.tr(), // Use a translatable string for the warning
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _deleteAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Delete'.tr(), style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 