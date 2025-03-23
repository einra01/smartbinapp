import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'main.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

// Data from forgot.dart
class ConfirmationScreen extends StatefulWidget {
  final User? users;
  final String email;
  final String otp;
  final String userId;
  const ConfirmationScreen({
    Key? key,
    required this.users,
    required this.email,
    required this.otp,
    required this.userId,
  }) : super(key: key);

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  final List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

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

    final enteredOtp = _otpController.text.trim();

    // Validate OTP input
    if (enteredOtp.isEmpty || enteredOtp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit OTP.')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    if (enteredOtp == widget.otp) {
      final databaseRef = FirebaseDatabase.instance.ref('users');
      final user = widget.users;

      try {
        if (user != null) {
          // Store user data in Realtime Database
          final uid = user.uid;
          final userRef = databaseRef.child(uid);
          await userRef.set({
            'id': uid,
            'email': user.email,
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account verified and stored successfully!')),
          );
          // Navigate to LoginPage
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
          return;
        }
      }
      catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
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
