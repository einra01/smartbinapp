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
import 'dashboards.dart';
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
  String deviceId = '';
  String deviceName= '';
  String deviceStatus='';
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: networks.map((network) {
            return ListTile(
              title: Text(network.ssid ?? "Unknown WiFi"),
              onTap: () => _showPasswordDialog(network.ssid ?? ""),
            );
          }).toList(),
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
    await WiFiForIoTPlugin.forceWifiUsage(true); // Ensure ESP32 WiFi usage

    bool success = await WiFiForIoTPlugin.connect(
      ssid,
      password: password,
      security: NetworkSecurity.WPA,
      joinOnce: true,
      withInternet: false,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Connected to $ssid")),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DashboardScreens1(deviceId: deviceId, deviceName: deviceName, deviceStatus: deviceStatus,)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to connect to $ssid")),
      );
    }
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
                      "BIN/DEVICES",
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
            top: MediaQuery.of(context).size.height * 0.3, // 30% from top
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

/// Waste Level Monitoring Screen
class WasteLevelScreen extends StatefulWidget {
  @override
  _WasteLevelScreenState createState() => _WasteLevelScreenState();
}

class _WasteLevelScreenState extends State<WasteLevelScreen> {
  double wasteLevel = 0.0;
  double binHeight = 40.0;
  String statusMessage = "Connecting...";
  Timer? _timer;
  String esp32IP = "192.168.4.1"; // Update ESP32 IP address

  @override
  void initState() {
    super.initState();
    fetchWasteLevel();
    _timer = Timer.periodic(Duration(seconds: 2), (timer) {
      fetchWasteLevel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Fetch waste level data from ESP32
  Future<void> fetchWasteLevel() async {
    String url = "http://$esp32IP/waste_level"; // ESP32 endpoint

    try {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        setState(() {
          wasteLevel = data["wasteLevel"].toDouble();
          statusMessage = "Connected ✅";
        });
      } else {
        setState(() {
          statusMessage = "ESP32 Error: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        statusMessage = "No Connection ❌";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double percentage = (wasteLevel / binHeight) * 100;

    return Scaffold(
      appBar: AppBar(title: Text("Waste Level Monitor")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Status: $statusMessage",
              style: TextStyle(fontSize: 16, color: Colors.blue),
            ),
            SizedBox(height: 10),
            Text(
              "Waste Level: ${wasteLevel.toStringAsFixed(1)} cm",
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(width: 100, height: 200, color: Colors.grey.shade300),
                Container(
                  width: 100,
                  height: 200 * (percentage / 100),
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
