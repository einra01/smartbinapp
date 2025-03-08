import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartbin/main.dart';
import 'package:smartbin/super_admin/admin_profile.dart';

class ConfirmationScreen1 extends StatefulWidget {
  final User? users;
  final String name;
  final String password;
  final String role;
  final String otp;
  final String userId;

  const ConfirmationScreen1({
    Key? key,
    required this.users,
    required this.name,
    required this.password,
    required this.role,
    required this.otp,
    required this.userId,
  }) : super(key: key);

  @override
  State<ConfirmationScreen1> createState() => _ConfirmationScreenState();
}
class _ConfirmationScreenState extends State<ConfirmationScreen1> {
  final List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;

  String getOtp() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  void _onOtpChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
    }
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _verifyOTP() async {
    setState(() {
      _isLoading = true;
    });

    final enteredOtp = getOtp();

    if (enteredOtp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit OTP.')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    if (enteredOtp == widget.otp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP Verified Successfully!')),
      );

      // Get a new UID for the new user (or create a reference for a new user)
      String newUid = FirebaseAuth.instance.currentUser?.uid ?? DateTime.now().toString();
      DatabaseReference userRef = FirebaseDatabase.instance.ref('users/$newUid');

      // Store the new user's data under the new UID in Realtime Database
      await userRef.set({
        'id': newUid,
        'name': widget.name,
        'email': widget.users?.email, // Use logged-in user's email
        'status': 'Active',
        'password': widget.password, // Consider hashing the password
        'role': widget.role,
      });

      // Retrieve email and password from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? email = prefs.getString('previousEmail');
      String? password = prefs.getString('previousPassword');

      if (email != null && password != null) {
        try {
          // Re-authenticate with Firebase using the stored credentials
          UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password,
          );

          // Ensure the user is logged in before navigating
          User? loggedInUser = userCredential.user;
          if (loggedInUser != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => SuperAdminApp(userId: widget.userId),
              ),
            );
          } else {
            throw FirebaseAuthException(
              code: 'reauthentication-failed',
              message: 'Failed to reauthenticate the user.',
            );
          }
        } on FirebaseAuthException catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Reauthentication failed: ${e.message}')),
          );
        }
      } else {
        // Handle case where credentials are not found in SharedPreferences
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credentials not found. Please login again.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP. Please try again.')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC107),
        title: const Center(child: Text('CONFIRMATION')),
      ),
      backgroundColor: const Color(0xFFE5E8E7),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16.0),
              const Text(
                'Please enter the 6-digit code sent to your email to verify your account.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 32.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  6,
                      (index) => Container(
                    width: 50,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    child: TextField(
                      controller: _otpControllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        counterText: "",
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => _onOtpChanged(index, value),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyOTP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC107),
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                  textStyle: const TextStyle(fontSize: 16.0),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Verify OTP'),
              ),
              const SizedBox(height: 16.0),
            ],
          ),
        ),
      ),
    );
  }
}
