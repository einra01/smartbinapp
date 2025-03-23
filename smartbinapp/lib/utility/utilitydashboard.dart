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
import 'utilitylanding.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const LandingPage());
}

class uDashboardScreen1 extends StatefulWidget {
  final String deviceId;
  final String deviceName;
  final String deviceStatus;
  const uDashboardScreen1({
    Key? key,
    required this.deviceId,
    required this.deviceName,
    required this.deviceStatus,
  }) : super(key: key);


  @override
  State<uDashboardScreen1> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<uDashboardScreen1> with SingleTickerProviderStateMixin {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref("users");
  final DatabaseReference devicesRef = FirebaseDatabase.instance.ref('devices');

  Map<String, String> assignedUsers = {};
  late AnimationController _controller;
  late Timer _timer;
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
  String shift = '';
  List<Map<String, String>> devicesList = []; // Move this to class state

  double wasteLevel = 0.0;
  double weight = 0.0;
  String esp32IP = "192.168.4.1";

  @override
  void initState() {
    super.initState();
    _checkUserLoggedIn();
    _fetchUser();
    _fetchUserData();
    fetchDeviceData();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }
  Future<String> _getShiftTime(String userId) async {
    try {
      final DatabaseReference userScheduleRef = FirebaseDatabase.instance.ref("schedule/$userId/shift");
      final DataSnapshot userShiftSnapshot = await userScheduleRef.get();

      if (!userShiftSnapshot.exists) {
        return "Unknown Shift"; // If the shift is missing
      }

      final String shiftKey = userShiftSnapshot.value as String;

      // Fetch shift time from "shift" table
      final DatabaseReference shiftRef = FirebaseDatabase.instance.ref("shift/$shiftKey");
      final DataSnapshot shiftSnapshot = await shiftRef.get();

      if (shiftSnapshot.exists) {
        return shiftSnapshot.value as String; // Return the fetched shift time
      } else {
        return "Unknown Shift Time"; // If the shift time is not found
      }
    } catch (e) {
      debugPrint("Error fetching shift for user $userId: $e");
      return "Error Loading Shift";
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



  @override
  void dispose() {
    _controller.dispose();
    _timer.cancel(); // Cancel the timer to prevent memory leaks
    super.dispose();
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Stack(
        children: [
          // Fixed Background (Covers entire screen, fixed size and position)
          Container(
            height: 198, // Fixed height for consistency
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
                            'Hello $_name,\nWelcome to SortMatic!',
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
                            'Make The Campus Cleaner!',
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
                        mainAxisAlignment: MainAxisAlignment.center, // Keeps both items closer together
                        crossAxisAlignment: CrossAxisAlignment.center, // Ensures vertical alignment
                        children: [
                          // Device Name (Center-Left)
                          Container(
                            width: 160, // Slightly wider
                            height: 55, // Increased height
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: const BorderRadius.all(Radius.circular(16)),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Center( // Ensures text is perfectly centered
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

                          const SizedBox(width: 20), // Adjust spacing as needed

                          // Shift Time (Center-Right)
                          Container(
                            width: 160,
                            height: 55,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: const BorderRadius.all(Radius.circular(16)),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Center(
                              child: StreamBuilder<DatabaseEvent>(
                                stream: FirebaseDatabase.instance.ref("users/$userId/schedule").onValue,
                                builder: (context, scheduleSnapshot) {
                                  if (!scheduleSnapshot.hasData || scheduleSnapshot.data?.snapshot.value == null) {
                                    return const Text("No Schedule", style: TextStyle(color: Colors.red));
                                  }

                                  var scheduleData = scheduleSnapshot.data!.snapshot.value as Map<dynamic, dynamic>?;
                                  if (scheduleData == null || scheduleData.isEmpty) {
                                    return const Text("No Assigned Devices", style: TextStyle(color: Colors.red));
                                  }

                                  String deviceKey = scheduleData.keys.first;

                                  return StreamBuilder<DatabaseEvent>(
                                    stream: FirebaseDatabase.instance.ref("users/$userId/schedule/$deviceKey/shift").onValue,
                                    builder: (context, shiftSnapshot) {
                                      if (!shiftSnapshot.hasData || shiftSnapshot.data?.snapshot.value == null) {
                                        return const Text("No Shift Assigned", style: TextStyle(color: Colors.red));
                                      }

                                      String shiftKey = shiftSnapshot.data!.snapshot.value.toString();

                                      return StreamBuilder<DatabaseEvent>(
                                        stream: FirebaseDatabase.instance.ref("shift/$shiftKey").onValue,
                                        builder: (context, shiftTimeSnapshot) {
                                          if (!shiftTimeSnapshot.hasData || shiftTimeSnapshot.data?.snapshot.value == null) {
                                            return const Text("Invalid Shift", style: TextStyle(color: Colors.red));
                                          }

                                          String shiftTime = shiftTimeSnapshot.data!.snapshot.value.toString();

                                          return Text(
                                            shiftTime,
                                            textAlign: TextAlign.center,
                                            softWrap: true,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
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
                                          double.tryParse('${wasteLevel.toStringAsFixed(1)}') ?? 0.0,
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
                                      '${wasteLevel.toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
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
                              'The bin is ${weight.toStringAsFixed(2)} kilograms',
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
                                          double.tryParse(nonbiowaste) ?? 0.0,
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
                                      '$nonbiowaste%',
                                      style: const TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
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
          borderRadius: BorderRadius.circular(20),
          child: BottomAppBar(
            color: Colors.transparent,
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