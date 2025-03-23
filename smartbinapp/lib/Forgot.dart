import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:smartbin/main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(
    home: Forgot(),
  ));
}

class Forgot extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<Forgot> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String generatedOTP = '';

  // 6 digit generated code
  String generateOTP() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString(); // Generates 6 digits
  }

  // Function to send OTP via email
  Future<void> sendOTP(String email, String otp) async {
    final String smtpEmail = 'my.smartbin.2025@gmail.com';
    final String smtpPassword = 'ybph wluh gqxe oslb';

    final smtpServer = gmail(smtpEmail, smtpPassword);

    final message = Message()
      ..from = Address('noreply@smartbin.com', 'SortMatic')
      ..recipients.add(email)
      ..subject = 'Your OTP Code'
      ..text = 'Your OTP code is: $otp';

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: $sendReport');
    } catch (e) {
      print('Error sending OTP: $e');
    }
  }

  // Function to handle password reset request
  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        String email = _emailController.text.trim();
        DatabaseReference usersRef = FirebaseDatabase.instance.ref().child('users');
        DataSnapshot snapshot = await usersRef.orderByChild('email').equalTo(email).get();

        if (snapshot.exists) {
          // Email exists, get userId
          Map<dynamic, dynamic> users = snapshot.value as Map<dynamic, dynamic>;
          String userId = users.keys.first;

          // Generate and send OTP
          generatedOTP = generateOTP();
          await sendOTP(email, generatedOTP);

          // Navigate to OTP screen for verification
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OTPScreen(
                email: email,
                OTP: generatedOTP,
                userId: userId,
              ),
            ),
          );
        } else {
          // Email not found
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Email not found in the database.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Stack(
        children: [
          // Top amber container
          Container(
            margin: EdgeInsets.only(top: 110),
            height: MediaQuery.of(context).size.height / 13.5,
            color: Colors.amber.withOpacity(0.99),
            child: Center(
              child: Text(
                'Forgot Password',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          // Main content
          SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 250),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Text(
                          'Please enter your email to reset your password',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                            ),
                            validator: (value) => value!.isEmpty ? 'Please enter email' : null,
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(
                                context,
                                MaterialPageRoute(builder: (context) => LoginPage()),
                              );
                            },
                            child: Text(
                              'Back to Login',
                              style: TextStyle(
                                color: Colors.black12,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: 200,
                            height: 45,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _resetPassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.yellow[700],
                                minimumSize: Size(200, 45),
                              ),
                              child: _isLoading
                                  ? CircularProgressIndicator(color: Colors.white)
                                  : Text('Reset'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}

class OTPScreen extends StatefulWidget {
  final String email;
  final String OTP;
  final String userId;
  OTPScreen({required this.email, required this.OTP, required this.userId});

  @override
  _OTPScreenState createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final _otpController = TextEditingController();
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
    String enteredOTP = getOtp(); // Collect OTP from input fields

    print('Entered OTP: $enteredOTP');
    print('Generated OTP: ${widget.OTP}');

    if (enteredOTP == widget.OTP) {
      try {
        // Send password reset email
        await FirebaseAuth.instance
            .sendPasswordResetEmail(email: widget.email)
            .then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Password reset link sent to ${widget.email}')),
          );

          // Update the user's profile in Realtime Database
          DatabaseReference userRef = FirebaseDatabase.instance.ref().child('users/${widget.userId}');
          userRef.update({
            'lastPasswordResetTimestamp': DateTime.now().toIso8601String(),
          });
        });

        // Navigate to login screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid OTP. Please try again.')),
      );
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


