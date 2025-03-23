import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartbin/super_admin/schedule.dart';
import 'devices.dart';

import 'landing.dart';
import 'notification.dart';
import 'account_management.dart';
import 'create.dart';
import 'package:smartbin/main.dart';
import 'history.dart';
import 'acct_deact.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SuperAdminApp(),
    );
  }
}

class SuperAdminApp extends StatefulWidget {
  final String? userId;
  const SuperAdminApp({Key? key, this.userId}) : super(key: key);

  @override
  _SuperAdminAppState createState() => _SuperAdminAppState();
}

class _SuperAdminAppState extends State<SuperAdminApp> {
  bool _isHovered = false;
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref("users");

  String _name = 'Loading...'; // Initial loading state
  String _profileImageUrl = '';
  final ImagePicker _picker = ImagePicker();
  String userId = '';

  @override
  void initState() {
    super.initState();
    _fetchUser(); // Fetch user data when the widget is initialized
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


  Future<void> _pickAndUploadImage() async {
    try {
      // Let the user pick an image from the gallery
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        File file = File(pickedFile.path);

        // Check file size (e.g., max 5MB)
        final fileSize = await file.length();
        if (fileSize > 5 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("File size exceeds 5MB limit.")),
          );
          return;
        }

        // Convert the image file to Base64
        List<int> imageBytes = await file.readAsBytes();
        String base64Image = base64Encode(imageBytes);

        // Upload the image to Imgur
        String clientId = 'd7f3e9585ae12f5'; // Replace with your Imgur Client ID
        final response = await http.post(
          Uri.parse('https://api.imgur.com/3/image'),
          headers: {'Authorization': 'Client-ID $clientId'},
          body: {'image': base64Image, 'type': 'base64'},
        );

        if (response.statusCode == 200) {
          var data = json.decode(response.body);
          String imageUrl = data['data']['link'];
          String imageFileName = pickedFile.name; // Get the picked file's name

          // Save the image URL and file name to Firebase
          await _databaseRef.child(userId).update({
            'profileImageUrl': imageUrl,
            'profileImageFileName': imageFileName, // Save the file name
          });

          // Update the profile image URL in the UI
          setState(() {
            _profileImageUrl = imageUrl;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Profile image updated successfully!")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to upload image: ${response.body}")),
          );
        }
      } else {
        print("Image picking was cancelled.");
      }
    } catch (e) {
      print("Error during image upload: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred during image upload.")),
      );
    }
  }
  void _showImagePreview(BuildContext context, String profileImageUrl, Function onUpload) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: profileImageUrl.isNotEmpty
                  ? NetworkImage(profileImageUrl)
                  : AssetImage('assets/profile picture.png') as ImageProvider,
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    onUpload(); // Call upload function
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent),
                  child: Text('Upload Photo', style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context), // Close dialog
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text('Cancel', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  void _logout() async {
    try {
      final now = DateTime.now();
      final formattedDate = DateFormat('yyyy-MM-dd').format(now);
      final formattedTime = DateFormat('HH:mm:ss').format(now);

      print('Attempting logout...');

      // Fetch stored user info
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String userId = prefs.getString('userId') ?? '';
      String name = prefs.getString('name') ?? 'Unknown User';

      print('Current user ID: $userId');
      print('Current user name: $name');

      if (userId.isNotEmpty) {
        final notificationsRef = FirebaseDatabase.instance.ref('notifications/logged/$userId');
        final newLogoutRef = notificationsRef.push();

        await newLogoutRef.set({
          'name': name,
          'userId': userId,
          'status': 'Logged Out',
          'date': formattedDate,
          'time': formattedTime,
          'msg': '$name Logged Out'
        });

        print('Logout notification added successfully.');
      }

      // Sign out user from FirebaseAuth
      await FirebaseAuth.instance.signOut();
      print('User signed out.');

      // ❗ Clear stored login data
      await prefs.clear();
      print('SharedPreferences cleared.');

      if (!mounted) return;

      setState(() {
        _name = "User not logged in";
        _profileImageUrl = '';
      });

      // Navigate to LoginPage & clear navigation stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginPage()),
            (Route<dynamic> route) => false,
      );

      print('Navigated to LoginPage.');
    } catch (e) {
      print('Error during logout: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed. Please try again.')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          // Fixed Header Section
          Stack(
            children: [
              SizedBox(
                height: 198,
                width: double.infinity,
                child: Container(
                  color: Colors.amber.withOpacity(0.57),
                ),
              ),
              Column(
                children: [
                  const SizedBox(height: 124),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 75,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFF1C74B),
                                    Color(0xFFD19A29),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                              ),
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Text(
                                  _name,
                                  style: const TextStyle(
                                    fontSize: 17.5,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              height: 55,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'ADMIN',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: -30,
                        left: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _showImagePreview(
                            context,
                            _profileImageUrl,
                            _pickAndUploadImage,
                          ),
                          child: Center(
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundImage: _profileImageUrl.isNotEmpty
                                      ? NetworkImage(_profileImageUrl)
                                      : AssetImage('assets/profile picture.png')
                                  as ImageProvider,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.amber,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.edit, size: 16, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    color: Colors.grey[200],
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        NavigationItem(
                          icon: Icons.account_circle_outlined,
                          label: 'ACCOUNT MANAGEMENT',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => AccountManagementPage()),
                          ),
                        ),
                        NavigationItem(
                          icon: Icons.add_circle_outline,
                          label: 'ACCOUNT CREATION',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => Create(userId: '',)),
                          ),
                        ),
                        NavigationItem(
                          icon: Icons.remove_circle_outline,
                          label: 'USER LIST',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => AccountDeactPage()),
                          ),
                        ),
                        NavigationItem(
                          icon: Icons.history,
                          label: 'HISTORY LOGS',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => HistoryLogsScreen1()),
                          ),
                        ),

                        NavigationItem(
                          icon: Icons.wifi,
                          label: 'BIN/CONNECTION',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => Devicess()),
                          ),
                        ),
                        NavigationItem(
                          icon: Icons.assignment_turned_in,
                          label: 'SCHEDULE',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => Schedule()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Fixed Logout Button
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: _logout,
              child: Container(
                width: 160,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5AF0F),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text(
                    'LOGOUT',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 8.0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.black),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => NotificationScreen()),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.home, color: Colors.black),
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => DashboardScreen()),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SuperAdminApp()),
                    ),
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
class NavigationItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap; // Correct type for a callback

  const NavigationItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
  }) : super(key: key);



  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.black54, size: 16),
      onTap: onTap, // Use the callback passed to the widget
    );
  }
}