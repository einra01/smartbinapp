import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'admin_profile.dart';
import 'notification.dart'; // Use as needed
import 'landing.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dashboard.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Ensure Firebase is initialized
  runApp(MaterialApp(
    home: Devicess(),
  ));
}

class Devicess extends StatefulWidget {

  @override
  _DevicessState createState() => _DevicessState();
}

class _DevicessState extends State<Devicess> {
  final DatabaseReference _devicesRef = FirebaseDatabase.instance.ref().child('devices');
  final DatabaseReference _locRefs = FirebaseDatabase.instance.ref().child('location');

  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref('users');
  String _name = 'Loading...'; // Initial loading state
  String _profileImageUrl = '';
  String userId = '';

  List<String> devices = [];

  @override
  void initState() {
    super.initState();
    _loadDevices();
    _fetchUser();
  }

  List<WifiNetwork> networks = [];



  void _loadDevices() async {
    try {
      DataSnapshot snapshot = await _devicesRef.get();
      if (snapshot.exists && snapshot.value != null) {
        var data = snapshot.value as Map<dynamic, dynamic>?;
        List<String> deviceList = [];
        data?.forEach((key, value) {
          if (value is Map && value.containsKey('deviceName')) {
            deviceList.add(value['deviceName'] ?? 'Unknown Device');
          }
        });
        setState(() {
          devices = deviceList;
        });
      } else {
        setState(() {
          devices = [];
        });
      }
    } catch (e) {
      print("Error loading devices: $e");
    }
  }

  void _scanWiFi() async {
    List<WifiNetwork>? wifiList = await WiFiForIoTPlugin.loadWifiList();
    setState(() {
      networks = wifiList ?? [];
    });
    _showWiFiDialog();
  }

  void _showWiFiDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Available WiFi Networks"),
        content: SizedBox(
          height: 300, // Adjust height as needed
          width: double.maxFinite, // Ensures it takes available width
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: networks.map((network) {
                return ListTile(
                  title: Text(network.ssid ?? "Unknown WiFi"),
                  onTap: () => _showPasswordDialog(network.ssid ?? ""),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showPasswordDialog(String ssid) {
    TextEditingController passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Connect to $ssid"),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(hintText: "Enter Password"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              _connectToWiFi(ssid, passwordController.text);
              Navigator.pop(context);
            },
            child: Text("Connect"),
          ),
        ],
      ),
    );
  }
  void _connectToWiFi(String ssid, String password) async {
    await WiFiForIoTPlugin.setWiFiAPEnabled(false); // Disable AP mode
    await WiFiForIoTPlugin.forceWifiUsage(true); // Force ESP32 WiFi for app

    bool success = await WiFiForIoTPlugin.connect(
      ssid,
      password: password,
      security: NetworkSecurity.WPA,
      joinOnce: true,
      withInternet: false, // Indicate ESP32 WiFi has no internet
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Connected to $ssid")),
      );

      // Allow mobile data to be used for internet after connecting
      Future.delayed(Duration(seconds: 5), () async {
        await WiFiForIoTPlugin.forceWifiUsage(false); // Re-enable mobile data for internet
      });

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DashboardScreen1(deviceId: '', deviceName: '', deviceStatus: '')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to connect to $ssid")),
      );
    }
  }

  Future<bool> hasInternetConnection() async {
    bool hasInternet = await InternetConnectionChecker().hasConnection;
    return hasInternet;
  }
  void _fetchUser() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        userId = user.uid; // Get the user ID
        print("Logged in user ID: $userId"); // Debugging: Print user ID
        await _fetchProfileImage(userId); // Fetch the profile image using the user ID
      } else {
        print("No user is currently logged in."); // Handle the case where no user is logged in
      }
    } catch (e) {
      print("Error fetching user: $e"); // Error handling
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
  Future<void> _listenToName(String userId) async {
    try {
      final snapshot = await _databaseRef.child(userId).get();
      final data = snapshot.value as Map<dynamic, dynamic>?;

      print("User data: $data");  // Add this to log the fetched data

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


  void _showAddDeviceDialog() {
    TextEditingController deviceNameController = TextEditingController();
    String validationGuide = "Format: [Building Name] Floor [1-7]\nExample: Academic Floor 1";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Add New Device"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: deviceNameController,
                decoration: InputDecoration(hintText: "Bin Location"),
              ),
              SizedBox(height: 8), // Adds spacing between input and guide
              Text(
                validationGuide,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                String input = deviceNameController.text.trim();
                print("User input: '$input'");

                // Auto-format user input
                RegExp autoFormat = RegExp(r"^([a-zA-Z]+)\s*(?:Floor)?\s*([1-7])$", caseSensitive: false);
                if (autoFormat.hasMatch(input)) {
                  Match match = autoFormat.firstMatch(input)!;
                  String buildingName = match.group(1)!.toLowerCase();
                  int floorNumber = int.parse(match.group(2)!);

                  // Accepted building names with correct capitalization
                  Map<String, String> validBuildings = {
                    "academic": "Academic",
                    "belmonte": "Belmonte",
                    "bautista": "Bautista",
                    "korphil": "KorPhil",
                    "techvoc": "TechVoc",
                  };

                  if (validBuildings.containsKey(buildingName)) {
                    // Auto-format to correct structure
                    input = "${validBuildings[buildingName]} Floor $floorNumber";
                  }
                }

                // Final validation
                RegExp regex = RegExp(r"^([A-Za-z]+) Floor ([1-7])$");
                if (regex.hasMatch(input)) {
                  print("Valid input: $input");
                  _addDevice(input);
                  Navigator.pop(context);
                } else {
                  _showErrorDialog("Invalid format. Example: Academic Floor 1");
                }
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }



// Error dialog function
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }



  // Add new device to Firebase
  void _addDevice(String deviceName) {
    String deviceId = DateTime.now().millisecondsSinceEpoch.toString();
    _locRefs.child(deviceName).update({
      'AM': 'Unassigned',
      'NN': 'Unassigned',
      'PM': 'Unassigned',
    });
    _devicesRef.child(deviceId).update({
      'deviceName': deviceName,
      'status': 'Running',
      'deviceId': deviceId,
      'shift': ['AM',
        'NN',
        'PM',
      ],
      'nonbio': {

        'nonbiowaste': 0,  // Initial value
        'nonbiokg': 0, // Initial value
         // Default status
      },
      'bio': {

        'biowaste': 0,  // Initial value
        'biokg': 0, // Initial value
         // Default status
      }
    }).then((_) {
      _loadDevices(); // Reload devices list after adding
    }).catchError((error) {
      print("Error adding device: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Stack(
        children: [
          Positioned(
            top: 80, // Adjusted to move it up
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).size.height / 14,
              color: Colors.amber.withOpacity(0.99),
              child: Stack(
                children: [
                  // Back button positioned to the left side of the header
                  Positioned(
                    left: 10,
                    top: MediaQuery.of(context).size.height / 75, // Centering vertically
                    child: IconButton(
                      icon: Icon(Icons.arrow_back),
                      onPressed: () {
                        Navigator.pop(context); // Navigate back to the previous screen
                      },
                    ),
                  ),

                  // Center the title "DEVICES"
                  Center(
                    child: Text(
                      "BIN/CONNECTION",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                    ),
                  ),

                  // Add button positioned to the right side of the header
                  Positioned(
                    right: 10,
                    top: MediaQuery.of(context).size.height / 75, // Centering vertically
                    child: IconButton(
                      icon: Icon(Icons.add),
                      onPressed: _showAddDeviceDialog,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Positioned the ListView under the header

          Positioned(
            top: MediaQuery.of(context).size.height * 0.15, // 30% from top
            left: 0,
            right: 0,
            bottom: 0, // Ensures it takes remaining space
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.7, // 70% of screen height
              child: ListView.builder(
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(devices[index]),
                    trailing: ElevatedButton(
                      onPressed: _scanWiFi,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: Text("Connect", style: TextStyle(color: Colors.white)),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 20.0), // Moves it up
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20), //  Rounds all corners
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
