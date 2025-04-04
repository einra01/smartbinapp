import 'dart:async'; // For Timer
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'dart:math' as m_a_t_h;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification.dart';
import 'admin_profile.dart';
import 'package:smartbin/main.dart';
import 'landing.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const LandingPage());
}

class DashboardScreens1 extends StatefulWidget {
  final String deviceId;
  final String deviceName;
  final String deviceStatus;

  const DashboardScreens1({
    Key? key,
    required this.deviceId,
    required this.deviceName,
    required this.deviceStatus,
  }) : super(key: key);


  @override
  State<DashboardScreens1> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreens1> with SingleTickerProviderStateMixin {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref("users");
  final DatabaseReference devicesRef = FirebaseDatabase.instance.ref('devices');
  final DatabaseReference _databases = FirebaseDatabase.instance.ref();

  Map<String, String> assignedUsers = {};
  late AnimationController _controller;
  //late Timer _timer;
  String currentTime = '';
  int _currentIndex = 0;
  String biowaste = '';
  String nonbiowaste = '';
  String biokg = '';
  String nonbiokg = '';
  String userId = '';
  String _profileImageUrl = '';
  String deviceKey = '';
  String deviceName = '';
  List<Map<String, String>> devicesList = []; // Move this to class state

  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _checkUserLoggedIn();
    _fetchUser();
    _fetchUserData();
    _fetchAssignedUsers();
    fetchDeviceData(); // ✅ Fetch only the selected device's data
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }


  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel(); // Cancel the timer to prevent memory leaks
    super.dispose();
  }

  Future<void> _fetchAssignedUsers() async {
    try {
      DatabaseReference assignRef = _databases.child('devices/${widget.deviceId}/shift');
      DataSnapshot assignSnapshot = await assignRef.get();

      if (assignSnapshot.exists && assignSnapshot.value is Map) {
        Map<String, dynamic> assignData = Map<String, dynamic>.from(assignSnapshot.value as Map);

        print("Fetched Assign Data: $assignData"); // Debugging line to check the data structure

        Map<String, String> tempUsers = {};

        for (var shift in ['AM', 'NN', 'PM']) {
          var shiftData = assignData[shift];

          // Check if shiftData is a Map (should be a map of userId -> user data)
          if (shiftData != null && shiftData is Map) {
            List<String> userNames = [];
            shiftData.forEach((userId, userData) {
              if (userData != null && userData is Map) {
                // Extract user name from the userData
                String userName = userData['name'] ?? 'Unknown';
                userNames.add(userName);
              }
            });

            // Join the user names or default to 'Unassigned' if no users
            tempUsers[shift] = userNames.isNotEmpty ? userNames.join(', ') : "Unassigned";
          } else {
            tempUsers[shift] = "Unassigned"; // If shift data is missing or not a Map
          }
        }

        setState(() {
          assignedUsers = tempUsers;
        });

        print("Assigned Users: $assignedUsers"); // Debugging to check final result
      }
    } catch (e) {
      print("Error fetching assigned users: $e");
    }
  }

  void _showDropdown(BuildContext context, TapDownDetails details) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy + 20,
        overlay.size.width - details.globalPosition.dx - 40,
        overlay.size.height - details.globalPosition.dy,
      ),
      items: [
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.person),
            title: Text("7-11AM: ${assignedUsers['AM'] ?? 'Unassigned'}"),
            onTap: () {
              Navigator.pop(context); // Close the menu
              _showUserDialog(context, "7-11 AM", assignedUsers['AM'] ?? "Unassigned");
            },
          ),
        ),
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.person),
            title: Text("12-4PM: ${assignedUsers['NN'] ?? 'Unassigned'}"),
            onTap: () {
              Navigator.pop(context);
              _showUserDialog(context, "12-4 PM", assignedUsers['NN'] ?? "Unassigned");
            },
          ),
        ),
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.person),
            title: Text("5-9PM: ${assignedUsers['PM'] ?? 'Unassigned'}"),
            onTap: () {
              Navigator.pop(context);
              _showUserDialog(context, "5-9 PM", assignedUsers['PM'] ?? "Unassigned");
            },
          ),
        ),
      ],
    );
  }
  void _showUserDialog(BuildContext context, String shift, String users) {
    List<String> userList = users.split(', ').where((user) => user.isNotEmpty).toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Rounded corners 🔥
          ),
          title: Row(
            children: [
              Icon(Icons.schedule, color: Colors.blueAccent), // Clock icon ⏰
              SizedBox(width: 10),
              Text(
                "Assigned Users",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Shift: $shift",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              SizedBox(height: 10),
              Divider(), // Line for separation
              SizedBox(height: 10),
              userList.isNotEmpty
                  ? Column(
                children: userList.map((user) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          user,
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () {
                            print("🗑️ Delete clicked for user: $user"); // Debugging
                            _removeUserFromFirebase(shift, user);
                            Navigator.pop(context); // Close dialog after removing
                          },
                        ),

                      ],
                    ),
                  );
                }).toList(),
              )
                  : Center(
                child: Text(
                  "Unassigned",
                  style: TextStyle(fontSize: 16, color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Close",
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
  Future<void> _removeUserFromFirebase(String shift, String userName) async {
    try {
      Map<String, String> shiftMapping = {
        "7-11 AM": "AM",
        "12-4 PM": "NN",
        "5-9 PM": "PM",
      };

      String correctShiftKey = shiftMapping[shift] ?? shift;
      DatabaseReference assignRef = _databases.child('devices/${widget.deviceId}/shift/$correctShiftKey');
      DatabaseReference usersRef = _databases.child('users');

      DataSnapshot snapshot = await assignRef.get();

      if (snapshot.exists && snapshot.value is Map) {
        Map<dynamic, dynamic> shiftData = Map<dynamic, dynamic>.from(snapshot.value as Map);
        String? userIdToRemove;
        String profileImageUrl = 'assets/profile picture.png'; // Default profile

        shiftData.forEach((userId, userData) {
          if (userData is Map) {
            String fetchedName = userData['name']?.toString().trim() ?? '';
            if (fetchedName.toLowerCase() == userName.toLowerCase().trim()) {
              userIdToRemove = userId.toString();
              profileImageUrl = userData['profileImageUrl'] ?? profileImageUrl;
            }
          }
        });

        if (userIdToRemove != null) {
          // Fetch user profile image from Firebase users collection
          DataSnapshot userSnapshot = await usersRef.child(userIdToRemove!).get();
          if (userSnapshot.exists && userSnapshot.value is Map) {
            Map<dynamic, dynamic> userData = userSnapshot.value as Map<dynamic, dynamic>;
            profileImageUrl = userData['profileImageUrl'] ?? profileImageUrl; // Get profile image URL
          }

          await assignRef.child(userIdToRemove!).remove();
          await usersRef.child('$userIdToRemove/schedule/${widget.deviceId}').remove();

          // Fetch device name
          DatabaseReference deviceRef = _databases.child('devices/${widget.deviceId}/deviceName');
          DataSnapshot deviceSnapshot = await deviceRef.get();
          String deviceName = deviceSnapshot.exists ? deviceSnapshot.value.toString() : "Unknown Device";

          final now = DateTime.now();
          final formattedDate = DateFormat('yyyy-MM-dd').format(now); // e.g., "2025-01-23"
          final formattedTime = DateFormat('HH:mm:ss').format(now);
          // **Now Store Notification**
          DatabaseReference notificationRef = _databases.child('notifications/assign/$userIdToRemove');
          String notificationKey = notificationRef.push().key!;

          await notificationRef.child(notificationKey).set({
            'name': userName,
            'userId': userIdToRemove,
            'msg': '$userName has been unassigned from $deviceName $shift',
            'status': '$userName has been unassigned from $deviceName $shift',
            'time': formattedTime,  // ✅ Using formatted time
            'date': formattedDate,  // ✅ Using formatted date
          });

          _fetchAssignedUsers(); // Refresh UI

          // Debugging
          print("✅ Unassigned User: $userName");
          print("✅ Profile Image URL: $profileImageUrl");
          print("✅ Device Name: $deviceName");
          print("✅ Unassigned at: $formattedTime on $formattedDate");

          // Show success dialog
          _showUnassignDialog(context, userName, profileImageUrl, deviceName, shift);
        } else {
          print("⚠️ User '$userName' not found in shift '$correctShiftKey'");
        }
      } else {
        print("⚠️ No data found for shift '$correctShiftKey'! Check Firebase.");
      }
    } catch (e) {
      print("❌ Error removing user: $e");
    }
  }

  void _showUnassignDialog(BuildContext context, String name, String? profileImageUrl, String deviceName, String shift) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Unassignment Successful",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                    ? NetworkImage(profileImageUrl) // Load network image
                    : AssetImage('assets/profile picture.png') as ImageProvider, // Fallback to asset image
                onBackgroundImageError: (_, __) {
                  print("❌ Error loading profile image: $profileImageUrl");
                },
              ),
              SizedBox(height: 10),
              Text(
                "$name has been successfully unassigned from $deviceName $shift shift.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "OK",
                style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
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
  void fetchDeviceKeys() {
    DatabaseReference devicesRef = FirebaseDatabase.instance.ref().child('devices');

    devicesRef.onValue.listen((DatabaseEvent event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) {
        print("No devices found.");
        return;
      }

      Map<dynamic, dynamic> devicesData = snapshot.value as Map<dynamic, dynamic>;
      List<String> deviceKeys = devicesData.keys.map((key) => key.toString()).toList();

      print("Device Keys: $deviceKeys");

      if (deviceKeys.isNotEmpty) {
        for (String key in deviceKeys) {
          fetchDeviceData(); // Fetch data for all devices
        }
      }
    }, onError: (error) {
      print("Error fetching device keys: $error");
    });
  }
  void fetchDeviceData() async {
    try {
      DatabaseReference deviceRef = FirebaseDatabase.instance.ref("devices/${widget.deviceId}");

      final snapshot = await deviceRef.get();
      if (snapshot.exists && snapshot.value != null) {
        Map<dynamic, dynamic> deviceData = snapshot.value as Map<dynamic, dynamic>;

        setState(() {
          deviceName = deviceData["deviceName"]?.toString() ?? "Unknown Device";
          biowaste = deviceData["bio"]?["biowaste"]?.toString() ?? "0";
          biokg = deviceData["bio"]?["biokg"]?.toString() ?? "0";
          nonbiowaste = deviceData["nonbio"]?["nonbiowaste"]?.toString() ?? "0";
          nonbiokg = deviceData["nonbio"]?["nonbiokg"]?.toString() ?? "0";
        });
      } else {
        print("Device not found.");
      }
    } catch (e) {
      print("Error fetching device data: $e");
    }
  }


  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      currentTime = "${now.hour.toString().padLeft(2, '0')}:"
          "${now.minute.toString().padLeft(2, '0')}:"
          "${now.second.toString().padLeft(2, '0')}  ";

    });

  }



  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

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
        DatabaseReference ref = _database.ref('users/${user.uid}');
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
  Future<String> _getProfileImageUrl(String userId) async {
    if (userId.isEmpty) return 'assets/profile picture.png'; // Return default if userId is empty

    try {
      final DatabaseReference userRef = FirebaseDatabase.instance.ref("users/$userId");
      final DataSnapshot snapshot = await userRef.get();

      if (snapshot.exists) {
        final userData = snapshot.value as Map<dynamic, dynamic>;
        return userData['profileImageUrl'] ?? 'assets/profile picture.png';
      }
    } catch (e) {
      debugPrint("Error fetching profile image for user $userId: $e");
    }
    return 'assets/profile picture.png'; // Default if an error occurs
  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Stack(
        children: [
          // Fixed Background
          Container(
            height: MediaQuery.of(context).size.height / 3.5,
            color: Colors.amber.withOpacity(0.57),
          ),

          // Content (Fixed Header + Scrollable Body)
          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.03),

              // Fixed Logo
              Image.asset(
                'assets/logo.png',
                width: 60,
                height: 50,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),

              // Fixed Current Time & Date
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

              // Fixed Welcome Banner
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(
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
                            'HELLO $_name\nWELCOME TO SORTMATIC!',
                            style: const TextStyle(
                              fontSize: 12,
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
                            'MAKE THE CAMPUS CLEANER!',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      top: -70, // Adjusted to make sure it stays visible
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
              ),

              //content (Make this scrollable)
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(), // Allows smooth scrolling
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center, // Center the entire row
                        mainAxisSize: MainAxisSize.min, // Prevents the row from expanding too much
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center, // Centers vertically
                            children: [
                              Align(
                                alignment: Alignment.centerLeft, // Aligns to the left
                                child: Container(
                                  width: 150,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200], // ✅ Fixed: No 'const' before BoxDecoration
                                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: Center(
                                    child: Text(
                                      '$deviceName',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 50), // Space between columns
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                width: 180, // Increased width to accommodate the icon
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12), // Adjust padding
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center, // Centers content horizontally
                                  crossAxisAlignment: CrossAxisAlignment.center, // Centers content vertically
                                  children: [
                                    const Text(
                                      'Assigned Utility Staff',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 6), // Adds a small space between text and icon
                                    GestureDetector(
                                      onTapDown: (details) => _showDropdown(context, details), // Capture tap position
                                      child: const Icon(
                                        Icons.arrow_drop_down,
                                        size: 35,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),


                        ],
                      ),

                      // Biodegradable Waste Container
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          width: double.infinity,
                          height: 120,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Positioned.fill(
                                  child: AnimatedBuilder(
                                    animation: _controller,
                                    builder: (context, child) {
                                      return CustomPaint(
                                        painter: WavePainter(
                                          _controller.value * 2 * m_a_t_h.pi,
                                          double.tryParse('$biowaste') ?? 0.0,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Biodegradable Waste Level',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    Text(
                                      'Waste Level: $biowaste cm',
                                      style: const TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Stack(
                                      alignment: Alignment.bottomCenter,
                                      children: [
                                        Container(width: 100, height: 200, color: Colors.grey.shade300),

                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          width: double.infinity,
                          height: 50,
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              'The bin is $biokg kilograms', // ✅ bioWeight is now a string
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      // Fixed Device Name


                      // Non-Biodegradable Waste Container
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          width: double.infinity,
                          height: 120,
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Positioned.fill(
                                  child: AnimatedBuilder(
                                    animation: _controller,
                                    builder: (context, child) {
                                      return CustomPaint(
                                        painter: WavePainter(
                                          _controller.value * 2 * m_a_t_h.pi,
                                          double.tryParse('$nonbiowaste') ?? 0.0,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Non-Biodegradable Waste Level',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    Text(
                                      '$nonbiowaste',
                                      style: const TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Stack(
                                      alignment: Alignment.bottomCenter,
                                      children: [
                                        Container(width: 100, height: 200, color: Colors.grey.shade300),

                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Weight Level
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          width: double.infinity,
                          height: 50,
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              'The bin is $nonbiokg kilograms',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),


                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),



      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 20.0), // Moves it up
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20), // ✅ Rounds all corners (top & bottom)
          child: BottomAppBar(
            color: Colors.transparent, // ✅ Make background transparent
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
                          MaterialPageRoute(builder: (context) => DashboardScreen()),
                        );
                      },
                    ),
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
class WavePainter extends CustomPainter {
  final double wavePhase;
  final double percentage;

  WavePainter(this.wavePhase, this.percentage);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.fill;

    final path = Path();

    // Set the base wave height based on the percentage
    double waveHeight = size.height * (1 - (percentage / 100));

    // Ensure wave height stays within the bounds of the container
    waveHeight = waveHeight.clamp(0.0, size.height);

    // Start the path from the bottom-left corner
    path.moveTo(0, size.height); // Bottom-left corner of the container
    path.lineTo(0, waveHeight);   // Start of wave based on percentage

    // Apply sinusoidal curve with controlled fluctuation
    path.quadraticBezierTo(
      size.width * 0.25,
      waveHeight - 5 * m_a_t_h.sin(wavePhase + 1),  // Controlled fluctuation amplitude
      size.width * 0.5,
      waveHeight,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      waveHeight + 5 * m_a_t_h.sin(wavePhase + 2),  // Controlled fluctuation amplitude
      size.width,
      waveHeight,
    );

    path.lineTo(size.width, size.height);  // Draw line to bottom-right corner
    path.close();  // Close the path

    canvas.drawPath(path, paint);  // Paint the wave onto the canvas
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;  // Repaint on animation cycle
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