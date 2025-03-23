import 'dart:async'; // For Timer
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'dart:math' as m_a_t_h;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utilitynotifpage.dart';
import 'utilityprofile.dart';
import 'package:smartbin/main.dart';
import 'utilitydashboard.dart';
void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const LandingPage());
}

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: uDashboardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class uDashboardScreen extends StatefulWidget {
  const uDashboardScreen({super.key});

  @override
  State<uDashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<uDashboardScreen> with SingleTickerProviderStateMixin {

  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref("users");

  late AnimationController _controller;
  late Timer _timer;
  String currentTime = '';
  int _currentIndex = 0;

  String userId = '';
  String _profileImageUrl = '';

  final DatabaseReference _devicesRef = FirebaseDatabase.instance.ref().child('devices');


  @override
  void initState() {
    super.initState();
    _checkUserLoggedIn();
    _fetchUser();
    _loadDevices();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  List<Map<String, dynamic>> devices = [];

  void _loadDevices() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("User not logged in.");
        return;
      }

      String userId = user.uid;
      print("Fetching schedule for User ID: $userId");

      // 🔹 Step 1: Get User's Device Keys from Schedule
      DatabaseReference scheduleRef = FirebaseDatabase.instance.ref("users/$userId/schedule");
      DataSnapshot scheduleSnapshot = await scheduleRef.get();
      print("Raw schedule snapshot: ${scheduleSnapshot.value}");

      if (!scheduleSnapshot.exists || scheduleSnapshot.value == null) {
        print("No assigned devices for user.");
        setState(() => devices = []);
        return;
      }

      var scheduleData = scheduleSnapshot.value as Map<dynamic, dynamic>?;
      if (scheduleData == null || scheduleData.isEmpty) {
        print("ERROR: Schedule is empty!");
        setState(() => devices = []);
        return;
      }

      List<Map<String, dynamic>> tempDevices = [];

      for (var entry in scheduleData.entries) {
        String deviceKey = entry.key.toString();
        print("Fetching details for DeviceKey: $deviceKey");

        DatabaseReference deviceRef = FirebaseDatabase.instance.ref("devices/$deviceKey");
        DataSnapshot deviceSnapshot = await deviceRef.get();

        if (!deviceSnapshot.exists || deviceSnapshot.value == null) {
          print("No device found for key: $deviceKey");
          continue;
        }

        var deviceData = deviceSnapshot.value as Map<dynamic, dynamic>?;
        if (deviceData != null) {
          tempDevices.add({
            "id": deviceKey,
            "name": deviceData['deviceName'] ?? 'Unknown Device',
            "status": deviceData['status'] ?? 'Unknown'
          });
        }
      }

      setState(() {
        devices = tempDevices;
      });

      print("Loaded Devices: $devices");
    } catch (e) {
      print("Error loading devices: $e");
    }
  }




  void _checkUserLoggedIn() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()), // Redirect to LoginPage
        );
      });
    }
  }


  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      currentTime = "${now.hour.toString().padLeft(2, '0')}:"
          "${now.minute.toString().padLeft(2, '0')}:"
          "${now.second.toString().padLeft(2, '0')}  ";

    });
    _fetchUserData();
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer.cancel(); // Cancel the timer to prevent memory leaks
    super.dispose();
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _databaseR = FirebaseDatabase.instance;

  String _name = '';

  void _fetchUser() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        userId = user.uid; // Get the user ID
        print("Logged in user ID: $userId"); // Debugging: Print user ID
        await _fetchProfileImage(userId); // Fetch the profile image using the user ID
      }
    } catch (e) {
      setState(() {
        _name = "Error fetching user: ${e.toString()}";
      });
    }
  }

  Future<void> _fetchProfileImage(String userId) async {
    try {
      final snapshot = await FirebaseDatabase.instance.ref("users/$userId").get();
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

  Future<void> _fetchUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        setState(() {
          userId = user.uid; // Set the user ID here
        });
        DatabaseReference ref = _databaseR.ref('users/${user.uid}');
        DataSnapshot snapshot = await ref.get();

        if (snapshot.exists && snapshot.value is Map) {
          setState(() {
            _name = (snapshot.child('name').value ?? '').toString();
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile data')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Stack(
        children: [
          // Fixed-size Top Amber Background
          Container(
            height: 198, // Fixed height for consistency
            color: Colors.amber.withOpacity(0.57),
          ),

          // Main Content with Scrollable View
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20), // Keep spacing consistent

                Image.asset(
                  'assets/logo.png',
                  width: 60,
                  height: 50,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),

                // Current Time & Date Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: Colors.black),
                          const SizedBox(width: 8),
                          Text(
                            currentTime,
                            style: const TextStyle(fontSize: 12, color: Colors.black),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: Colors.black),
                          const SizedBox(width: 8),
                          Text(
                            "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                            style: const TextStyle(fontSize: 12, color: Colors.black),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Welcome Banner
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFF1C74B), Color(0xFFD19A29)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Hello $_name,\nWelcome to SortMatic!',
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            height: 60,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Make the campus cleaner!',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: -70,
                      right: 1,
                      child: Image.asset(
                        'assets/landinglogo.png',
                        height: 250,
                        width: 180,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Devices List (Sorted Alphabetically)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: devices.map((deviceData) {
                      String id = deviceData["id"] ?? "Unknown";
                      String name = deviceData["name"] ?? "Unknown";
                      String status = deviceData["status"] ?? "Unknown";

                      // Define tile color based on status
                      Color tileColor;
                      switch (status.toLowerCase()) {
                        case "error":
                          tileColor = Colors.red[300]!;
                          break;
                        case "full":
                          tileColor = Colors.redAccent[100]!;
                          break;
                        default:
                          tileColor = Colors.grey[300]!;
                          break;
                      }

                      return Column(
                        children: [
                          Material(
                            color: tileColor,
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => uDashboardScreen1(
                                      deviceId: id,
                                      deviceName: name,
                                      deviceStatus: status,
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Image.asset(
                                      'assets/binlogo.png',
                                      width: 24,
                                      height: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      name,
                                      style: TextStyle(
                                        color: status.toLowerCase() == "error" || status.toLowerCase() == "full"
                                            ? Colors.white
                                            : Colors.black,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      'Status: $status',
                                      style: TextStyle(
                                        color: status.toLowerCase() == "error" || status.toLowerCase() == "full"
                                            ? Colors.white
                                            : Colors.black,
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 20.0), // Moves it up
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20), // Rounds all corners
          child: BottomAppBar(
            color: Colors.transparent, // Transparent background
            shape: const CircularNotchedRectangle(),
            notchMargin: 8.0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[300], // Background color
                borderRadius: BorderRadius.circular(20),
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
                        MaterialPageRoute(builder: (context) => NotificationScreenn()),
                      );
                    },
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.home, color: Colors.black),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => uDashboardScreen()),
                        );
                      },
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => UtilityProfile()),
                      );
                    },
                    child: ClipOval(
                      child: _profileImageUrl.isNotEmpty
                          ? Image.network(_profileImageUrl, fit: BoxFit.cover, height: 40, width: 40)
                          : Image.asset('assets/profile picture.png', fit: BoxFit.cover, height: 40, width: 40),
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
class DeviceDetailsPage extends StatelessWidget {
  final String deviceId;
  final String deviceName;

  DeviceDetailsPage({required this.deviceId, required this.deviceName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(deviceName)),
      body: Center(
        child: Text("Details for $deviceName (ID: $deviceId)"),
      ),
    );
  }
}
