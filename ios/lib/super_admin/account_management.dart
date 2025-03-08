import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'super_admin_dashboard.dart';
import 'notification.dart'; // Use as needed
import 'landing.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AccountManagementPage(),
    );
  }
}

class AccountManagementPage extends StatefulWidget {
  @override
  _AccountManagementPageState createState() => _AccountManagementPageState();
}

class _AccountManagementPageState extends State<AccountManagementPage> {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String? _expandedSection;
  bool _isCurrentPasswordObscured = true;
  bool _isNewPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
  void _updateName() async {
    final newName = _nameController.text.trim();

    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    User? user = _auth.currentUser;
    if (user != null) {
      try {
        // Update Firebase Realtime Database
        await _database.ref('users/${user.uid}').update({
          'name': newName,
        });

        // Update Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'name': newName,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name updated successfully!')),
        );

        _nameController.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
    }
  }
  void _toggleCurrentPasswordVisibility() {
    setState(() {
      _isCurrentPasswordObscured = !_isCurrentPasswordObscured;
    });
  }

  void _toggleNewPasswordVisibility() {
    setState(() {
      _isNewPasswordObscured = !_isNewPasswordObscured;
    });
  }
  void _updatePassword() async {
    if (_newPasswordController.text == _confirmPasswordController.text) {
      User? user = _auth.currentUser;
      if (user != null) {
        try {
          AuthCredential credential = EmailAuthProvider.credential(
            email: user.email!,
            password: _currentPasswordController.text,
          );
          await user.reauthenticateWithCredential(credential);
          await user.updatePassword(_newPasswordController.text);

          // Update Firestore with a password change timestamp or flag
          await _firestore.collection('users').doc(user.uid).update({
            'passwordUpdatedAt': FieldValue.serverTimestamp(), // Storing when the password was changed
          });

          // Update Firebase Realtime Database
          await _database.ref('users/${user.uid}').update({
            'passwordUpdatedAt': ServerValue.timestamp, // Storing timestamp
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password updated successfully!')),
          );

          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        } on FirebaseAuthException catch (e) {
          String errorMessage;
          switch (e.code) {
            case 'wrong-password':
              errorMessage = 'The current password is incorrect.';
              break;
            case 'weak-password':
              errorMessage = 'The new password is too weak.';
              break;
            case 'requires-recent-login':
              errorMessage = 'Please log in again to change your password.';
              break;
            default:
              errorMessage = 'An error occurred: ${e.message}';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
    }
  }

  void _toggleSection(String section) {
    setState(() {
      _expandedSection = _expandedSection == section ? null : section;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow[700],
        title: const Text('Account Management'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(color: Colors.grey[300]),
                _buildExpandableSection(
                  section: 'name',
                  icon: Icons.person,
                  title: 'Name',
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'New Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: BorderSide(color: Colors.yellow[700]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _updateName,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow[700],
                        ),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ),
                Divider(color: Colors.grey[300]),
                _buildExpandableSection(
                  section: 'password',
                  icon: Icons.lock,
                  title: 'Change Password',
                  child: Column(
                    children: [
                      TextField(
                        controller: _currentPasswordController,
                        obscureText: _isCurrentPasswordObscured,
                        decoration: InputDecoration(
                          labelText: 'Current Password',
                          suffixIcon: IconButton(
                            icon: Icon(_isCurrentPasswordObscured
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: _toggleCurrentPasswordVisibility,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: BorderSide(color: Colors.yellow[700]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _newPasswordController,
                        obscureText: _isNewPasswordObscured,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          suffixIcon: IconButton(
                            icon: Icon(_isNewPasswordObscured
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: _toggleNewPasswordVisibility,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: BorderSide(color: Colors.yellow[700]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _newPasswordController,
                        obscureText: _isNewPasswordObscured,
                        decoration: InputDecoration(
                          labelText: 'Confirm New Password',
                          suffixIcon: IconButton(
                            icon: Icon(_isNewPasswordObscured
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: _toggleNewPasswordVisibility,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: BorderSide(color: Colors.yellow[700]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _updatePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow[700],
                        ),
                        child: const Text('Save'),
                      ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Padding(
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
                  Navigator.push(
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
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/profile picture.png',
                      fit: BoxFit.cover,
                      height: 40,
                      width: 40,
                    ),
                  ),
                ),
              )


            ],
          ),
        ),
      ),
    );


  }

  Widget _buildNavIcon(String assetPath, Widget Function() page) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => page()),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.green[300],
          ),
          const CircleAvatar(
            radius: 20,
            backgroundColor: Colors.black,
          ),
          Image.asset(
            assetPath,
            color: Colors.white,
            fit: BoxFit.cover,
            width: 40,
            height: 40,
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableSection({
    required String section,
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      color: _expandedSection == section ? Colors.transparent : Colors.grey[200 ],
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon, color: Colors.black),
            title: Text(title),
            trailing: Icon(
              _expandedSection == section ? Icons.expand_less : Icons.expand_more,
              color: Colors.black,
            ),
            onTap: () => _toggleSection(section),
          ),
          if (_expandedSection == section) child,
        ],
      ),
    );
  }
}