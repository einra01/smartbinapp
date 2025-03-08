import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'landing.dart';
import 'notification.dart';
import 'account_management.dart';
import 'create.dart';
import 'package:smartbin/main.dart';
import 'history.dart';
import 'acct_deact.dart'; // Ensure this is correctly defined

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
  const SuperAdminApp({super.key});

  @override
  _SuperAdminAppState createState() => _SuperAdminAppState();
}

class _SuperAdminAppState extends State<SuperAdminApp> {
  bool _isHovered = false;
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref("users");
  String _name = 'Loading...'; // Initial loading state
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
        await _fetchName(userId); // Fetch the name using the user ID
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

  Future<void> _fetchName(String userId) async {
    try {
      final snapshot = await _databaseRef.child(userId).once();
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null && data.containsKey('name')) {
        setState(() {
          _name = data['name'] ?? "No name found";
        });
      } else {
        setState(() {
          _name = "User not found";
        });
      }
    } catch (error) {
      setState(() {
        _name = "Error fetching data: $error";
      });
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut(); // Sign out the user
    setState(() {
      _name = "User not logged in"; // Update UI after logout
    });

    // Clear the entire navigation stack and navigate to the LoginPage
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginPage()),
          (Route<dynamic> route) => false, // This predicate removes all previous routes
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          Stack(
            children: [
              // Top background amber container
              Container(
                height: MediaQuery.of(context).size.height / 3.2,
                color: Colors.amber.withOpacity(0.57),
              ),
              Column(
                children: [
                  const SizedBox(height: 10),
                  Image.asset(
                    'assets/logo.png',
                    width: 60,
                    height: 60,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 60),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            // Lighter Amber gradient header
                            Container(
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFF1C74B), // Lighter amber
                                    Color(0xFFD19A29), // Lighter dark amber
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Center( // Wrap the Text widget with Center
                                child: Text(
                                  '$_name',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            // Gray section below amber
                            Container(
                              width: double.infinity,
                              height: 60,
                              alignment: Alignment.center, // Center the text
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'ADMIN STAFF',
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
                      // Profile icon above the container
                      Positioned(
                        top: -40,  // Adjusted this value to move the profile picture higher
                        left: MediaQuery.of(context).size.width / 2 - 30,
                        child: MouseRegion(
                          onEnter: (_) {
                            setState(() {
                              _isHovered = true;
                            });
                          },
                          onExit: (_) {
                            setState(() {
                              _isHovered = false;
                            });
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.grey.withOpacity(_isHovered ? 0.6 : 0),
                                backgroundImage: const AssetImage('assets/profile picture.png'), // Default image
                              ),
                              if (_isHovered)
                                const Icon(
                                  Icons.edit,
                                  size: 30,
                                  color: Colors.black,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )

            ],
          ),
          const SizedBox(height: 40), // Adjusted vertical spacing
          // ACCOUNT MANAGEMENT text with left icon and right arrow
          Expanded(
            child: Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  // Navigation Items

                  // Navigation Items
                  NavigationItem(
                    icon: Icons.account_circle_outlined,
                    label: 'ACCOUNT MANAGEMENT',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AccountManagementPage(),
                        ),
                      );
                    },
                  ),
                  NavigationItem(
                    icon: Icons.add_circle_outline,
                    label: 'ACCOUNT CREATION',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Create(),
                        ),
                      );
                    },
                  ),
                  NavigationItem(
                    icon: Icons.remove_circle_outline,
                    label: 'USER LIST',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AccountDeactPage(),
                        ),
                      );
                    },
                  ),
                  NavigationItem(
                    icon: Icons.history,
                    label: 'HISTORY LOGS',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HistoryLogsScreen1(),
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  // Centered Logout Button
                  Center(
                    child: GestureDetector(
                      onTap: _logout,
                      child: Container(
                        width: 192,
                        height: 48,
                        color: const Color(0xFFE5AF0F),
                        child: const Center(
                          child: Text(
                            'LOGOUT',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.black,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20), // Additional spacing for alignment
        ],
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