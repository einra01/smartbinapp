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
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _repasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureRePassword = true;
  bool _Create1 = false;
  String _profileImageUrl='';
  String _selectedRole = 'utility';
  String userId = '';
  String _name = '';
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
        print("Logged in user ID: $userId"); // Debugging: Print user ID
        await _listenToName(userId); // Fetch the name using the user ID
        await _fetchProfileImage(userId); // Fetch the profile image using the user ID
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
      final snapshot = await _databaseRef.child(userId).get(); // Fetch data once
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

  // Updated Fetch Profile Image
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
          _profileImageUrl = ''; // Default to empty if not found
        });
      }
    } catch (e) {
      print("Error fetching profile image: $e");
      setState(() {
        _profileImageUrl = ''; // Default to empty if there's an error
      });
    }
  }

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


  String _uid = 'userId';





  Future<void> saveUserCredentials(String userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', _uid);

  }

  void _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    // Password validation regex for at least one uppercase letter, one digit, and at least 8 characters
    RegExp passwordRegExp = RegExp(r'^(?=.*[A-Z])(?=.*\d).{8,}$');
    if (!passwordRegExp.hasMatch(_passwordController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password must have at least one uppercase letter, one number, and be at least 8 characters long')),
      );
      return;
    }

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
      _Create1 = true;
    });

    try {
      // Create user in Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Save user data to SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', userCredential.user!.uid);

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
            otp: otp,
            userId: _uid,
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
              height: MediaQuery.of(context).size.height / 14,
              color: Colors.amber.withOpacity(0.99),
              child: Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () {
                      Navigator.pop(context); // Navigate back to the previous screen
                    },
                  ),
                  const Center(
                    child: Text(
                      "CREATE ACCOUNT",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
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
                        : Text('Create'),

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
          borderRadius: BorderRadius.circular(20), // ✅ Rounds all corners
          child: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 8.0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[300], // ✅ Apply color here
                borderRadius: BorderRadius.circular(20), // ✅ Ensure all corners are rounded
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

