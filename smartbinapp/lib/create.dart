import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../verification.dart';
import 'package:email_otp/email_otp.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:smartbin/main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Make sure Firebase is initialized
  runApp(const Create());
}

class Create extends StatefulWidget {
  const Create({Key? key}) : super(key: key);

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<Create> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _repasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureRePassword = true;
  bool _isLoading = false;
  String _selectedRole = 'utility'; // Default role is 'utility'

  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref('users');

  // Initialize EmailOTP instance
  final EmailOTP _emailOtp = EmailOTP();

  // Function to generate a 6-digit OTP
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
      ..from = Address('noreply@smartbin.com', 'Smart Bin')
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

  void _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _repasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    if (_selectedRole.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a role')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create user in Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Generate OTP and send it
      String otp = generateOTP();
      await sendOTP(_emailController.text.trim(), otp);

      // Store OTP in Firebase Realtime Database under the user's UID
      final otpRef = FirebaseDatabase.instance.ref('otp/${userCredential.user?.uid}');
      await otpRef.set({
        'otp': otp,
        'createdAt': DateTime.now().toString(),
      });

      // Navigate to ConfirmationScreen1 with the user's info
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConfirmationScreen1(
            users: userCredential.user,
            name: _nameController.text.trim(),
            password: _passwordController.text,
            role: _selectedRole,
            otp: otp, // Pass OTP to the confirmation screen
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Sign-up failed';
      if (e.code == 'email-already-in-use') {
        errorMessage = 'The email is already in use.';
      } else if (e.code == 'weak-password') {
        errorMessage = 'The password is too weak.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow[700],
        title: Text('Account Creation'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
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
                SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  validator: (value) => value!.isEmpty ? 'Please enter name' : null,
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) =>
                  value!.length < 6 ? 'Password too short' : null,
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _repasswordController,
                  obscureText: _obscureRePassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureRePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureRePassword = !_obscureRePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) =>
                  value!.isEmpty ? 'Please confirm password' : null,
                ),
                SizedBox(height: 20),

                // Role selection using radio buttons
                Row(
                  children: [
                    Text('Select Role: ', style: TextStyle(fontSize: 16)),
                    Radio<String>(
                      value: 'admin',
                      groupValue: _selectedRole,
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value!;
                        });
                      },
                    ),
                    Text('Admin'),
                    Radio<String>(
                      value: 'utility',
                      groupValue: _selectedRole,
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value!;
                        });
                      },
                    ),
                    Text('Utility'),
                  ],
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow[700],
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('Create'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
