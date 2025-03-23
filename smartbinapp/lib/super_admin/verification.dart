import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartbin/main.dart';
import 'package:smartbin/super_admin/admin_profile.dart';

class ConfirmationScreen1 extends StatefulWidget {
  final User? users;
  final String name;
  final String password;
  final String role;
  final String otp;
  final String email;
  final String userId;

  const ConfirmationScreen1({
    Key? key,
    required this.users,
    required this.name,
    required this.password,
    required this.role,
    required this.otp,
    required this.email,
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

      try {
        // Save the currently logged-in user’s credentials
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? prevEmail = prefs.getString('previousEmail');
        String? prevPassword = prefs.getString('previousPassword');

        User? previousUser = FirebaseAuth.instance.currentUser; // Save previous user before signup

        // Create new user in Firebase Auth
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: widget.email,
          password: widget.password,
        );

        // Get new user's UID
        String newUid = userCredential.user?.uid ?? DateTime.now().toString();

        // Store new user details in Realtime Database
        DatabaseReference userRef = FirebaseDatabase.instance.ref('users/$newUid');
        await userRef.set({
          'id': newUid,
          'name': widget.name,
          'email': widget.email,
          'status': 'Active',
          'password': widget.password, // Consider hashing the password
          'role': widget.role,
        });
        await sendPasswordEmail(widget.email, widget.password);

        // Restore the previous user session
        if (prevEmail != null && prevPassword != null && previousUser != null) {
          await FirebaseAuth.instance.signOut(); // Sign out the new user

          // Sign back in the previous user
          UserCredential prevUserCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: prevEmail,
            password: prevPassword,
          );

          if (prevUserCredential.user != null) {
            // Navigate to SuperAdminApp after restoring the previous session
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
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Previous session not found. Please log in again.')),
          );
        }
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
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

  Future<void> sendPasswordEmail(String email, String password) async {
    final String smtpEmail = 'my.smartbin.2025@gmail.com';
    final String smtpPassword = 'ybph wluh gqxe oslb';

    final smtpServer = gmail(smtpEmail, smtpPassword);

    final message = Message()
      ..from = Address('noreply@smartbin.com', 'SortMatic')
      ..recipients.add(email)
      ..subject = 'Your Account Password'
      ..text = 'Your account has been created successfully. Your password is: $password';

    try {
      final sendReport = await send(message, smtpServer);
      print('Password email sent: $sendReport');
    } catch (e) {
      print('Error sending password email: $e');
    }
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
