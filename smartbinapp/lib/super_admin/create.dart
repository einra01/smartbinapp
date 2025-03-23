import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_profile.dart';
import 'landing.dart';
import 'notification.dart';
import 'package:email_otp/email_otp.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'verification.dart';

import 'package:smartbin/main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();  // Make sure Firebase is initialized
  runApp(const Create(userId: ''));
}


class Create extends StatefulWidget {
  final String userId;

  const Create({Key? key, required this.userId}) : super(key: key);

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<Create> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _Create1 = false;
  String _profileImageUrl = '';
  String _selectedRole = 'utility';
  String userId = '';
  String _name = '';

  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref('users');
  final EmailOTP _emailOtp = EmailOTP();
  String _uid = 'userId';

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  void _fetchUser() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        userId = user.uid; // Get the user ID
        print("Logged in user ID: $userId");
        await _listenToName(userId);
        await _fetchProfileImage(userId);
      } else {
        setState(() {
          _name = "User not logged in";
        });
      }
    } catch (e) {
      setState(() {
        _name = "Error fetching user: ${e.toString()}";
      });
    }
  }

  Future<void> _listenToName(String userId) async {
    try {
      final snapshot = await _databaseRef.child(userId).get();
      final data = snapshot.value as Map<dynamic, dynamic>?;

      if (data != null && data.containsKey('name')) {
        setState(() {
          _name = data['name'] ?? "No name found";
        });
      } else {
        setState(() {
          _name = "User not found";
        });
      }
    } catch (e) {
      setState(() {
        _name = "Error fetching name: ${e.toString()}";
      });
    }
  }

  Future<void> _fetchProfileImage(String userId) async {
    try {
      final snapshot = await _databaseRef.child(userId).get();
      final data = snapshot.value as Map<dynamic, dynamic>?;

      if (data != null && data['profileImageUrl'] != null) {
        setState(() {
          _profileImageUrl = data['profileImageUrl'];
        });
      } else {
        setState(() {
          _profileImageUrl = '';
        });
      }
    } catch (e) {
      print("Error fetching profile image: $e");
      setState(() {
        _profileImageUrl = '';
      });
    }
  }

  // Function to generate a secure password
  String generatePassword() {
    const String upperCaseLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const String lowerCaseLetters = 'abcdefghijklmnopqrstuvwxyz';
    const String numbers = '0123456789';
    const String symbols = '!@#\$%^&*()_-+=<>?/';

    final random = Random();

    // Ensure at least one character from each category
    String generatedPassword =
        upperCaseLetters[random.nextInt(upperCaseLetters.length)] +
            numbers[random.nextInt(numbers.length)] +
            symbols[random.nextInt(symbols.length)];

    // Fill the rest of the password with random characters from all categories
    String allChars = upperCaseLetters + lowerCaseLetters + numbers + symbols;
    for (int i = 0; i < 5; i++) {
      generatedPassword += allChars[random.nextInt(allChars.length)];
    }

    // Shuffle the password to avoid predictable patterns
    return String.fromCharCodes(generatedPassword.runes.toList()..shuffle(random));
  }

  String generateOTP() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

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

  Future<void> saveUserCredentials(String userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', _uid);
  }

  void _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRole.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a role')),
      );
      return;
    }

    setState(() {
      _Create1 = true;
    });

    try {
      // Generate OTP
      String otp = generateOTP();
      print("Generated OTP: $otp");

      // Send OTP via email
      await sendOTP(_emailController.text.trim(), otp);
      print("OTP sent successfully to ${_emailController.text.trim()}");

      // Generate a secure password
      String password = generatePassword();
      print("Generated Password: $password");

      String sanitizedEmail = _emailController.text.trim().replaceAll('.', '_');

      final otpRef = FirebaseDatabase.instance.ref('otp/$sanitizedEmail');

      await otpRef.set({
        'otp': otp,
        'createdAt': DateTime.now().toString(),
      });
      print("OTP stored in Firebase");

      // Navigate to ConfirmationScreen1
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConfirmationScreen1(
            users: null,
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: password,
            role: _selectedRole,
            otp: otp,
            userId: DateTime.now().toString(),
          ),
        ),
      );
      print("Navigated to ConfirmationScreen1");
    } catch (e) {
      print("Error during signup: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send OTP: $e')),
      );
    } finally {
      setState(() {
        _Create1 = false;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Stack(
        children: [
        // Move the "ACCOUNT DEACTIVATION" section up
        Positioned(
        top: 80, // Adjusted to move it up
        left: 0,
        right: 0,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.06,
          color: Colors.amber.withOpacity(0.99),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              Center(
                child: Text(
                  "ACCOUNT CREATION",
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.06,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

    Positioned(
    top: 150, // Start content below the logo and banner
    left: 0,
    right: 0,
    bottom: 0, // Extend to bottom of screen
    child: SingleChildScrollView(
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

                // Role selection using radio buttons
                Row(
                  children: [
                    Text('Select Role: ', style: TextStyle(fontSize: 16)),
                    Radio<String>(
                      value: 'Admin',
                      groupValue: _selectedRole,
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value!;
                        });
                      },
                    ),
                    Text('Admin'),
                    Radio<String>(
                      value: 'Utility',
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
                    onPressed: _Create1 ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow[700],
                    ),
                    child: _Create1
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('Creatse'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

  ),



  ],
  ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 20.0), // Moves it up
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20), // Rounds all corners
          child: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 8.0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[300], //  Apply color here
                borderRadius: BorderRadius.circular(20), //  Ensure all corners are rounded
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.black),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => NotificationScreen()),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.home, color: Colors.black),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => DashboardScreen()),
                      );
                    },
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SuperAdminApp()),
                      );
                    },
                    child: ClipOval(
                      child: _profileImageUrl.isNotEmpty
                          ? Image.network(
                        _profileImageUrl,
                        fit: BoxFit.cover,
                        height: 40,
                        width: 40,
                      )
                          : Image.asset(
                        'assets/profile picture.png',
                        fit: BoxFit.cover,
                        height: 40,
                        width: 40,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

