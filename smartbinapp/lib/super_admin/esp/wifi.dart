import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wifi_iot/wifi_iot.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WiFiConnectScreen(),
    );
  }
}

class WiFiConnectScreen extends StatefulWidget {
  @override
  _WiFiConnectScreenState createState() => _WiFiConnectScreenState();
}

class _WiFiConnectScreenState extends State<WiFiConnectScreen> {
  List<WifiNetwork> networks = [];
  bool isConnected = false;
  String esp32IP = "192.168.4.1"; // Default ESP32 IP in AP mode

  @override
  void initState() {
    super.initState();
    requestPermissions();
    scanNetworks();
  }

  /// Request necessary permissions (for Android 10+)
  Future<void> requestPermissions() async {
    await WiFiForIoTPlugin.forceWifiUsage(false);
  }

  /// Scan available WiFi networks
  Future<void> scanNetworks() async {
    List<WifiNetwork>? wifiList = await WiFiForIoTPlugin.loadWifiList();
    setState(() {
      networks = wifiList ?? [];
    });
  }

  /// Connect to a WiFi network
  Future<void> connectToWiFi(String ssid, String password) async {
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
      setState(() {
        isConnected = true;
      });
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => WasteLevelScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to connect to $ssid")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Connect to WiFi")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: scanNetworks,
            child: Text("Scan WiFi Networks"),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: networks.length,
              itemBuilder: (context, index) {
                String ssid = networks[index].ssid ?? "Unknown WiFi";
                return ListTile(
                  title: Text(ssid),
                  onTap: () {
                    TextEditingController passwordController =
                    TextEditingController();
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("Connect to $ssid"),
                        content: TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration:
                          InputDecoration(hintText: "Enter Password"),
                        ),
                        actions: [
                          ElevatedButton(
                            onPressed: () {
                              connectToWiFi(ssid, passwordController.text);
                              Navigator.pop(context);
                            },
                            child: Text("Connect"),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
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
  double weight = 0.0;

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
    String url = "http://$esp32IP/data"; // ESP32 endpoint

    try {
      var response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        setState(() {
          wasteLevel = (data["waste_level"] ?? 0).toDouble();
          weight = (data["weight"] ?? 0).toDouble();
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
