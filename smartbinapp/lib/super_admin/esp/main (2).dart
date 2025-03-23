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
  String esp32IP = "192.168.4.1";

  @override
  void initState() {
    super.initState();
    scanNetworks();
  }

  Future<void> scanNetworks() async {
    List<WifiNetwork>? wifiList = await WiFiForIoTPlugin.loadWifiList();
    setState(() {
      networks = wifiList?.where((net) => net.ssid == "Sortmatic").toList() ?? [];
    });
  }

  Future<void> connectToESP32() async {
    bool success = await WiFiForIoTPlugin.connect("Sortmatic", security: NetworkSecurity.WPA, withInternet: false);
    if (success) {
      setState(() => isConnected = true);
      Navigator.push(context, MaterialPageRoute(builder: (context) => WasteMonitorScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Connection failed")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Connect to ESP32")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: scanNetworks,
              child: Text("Scan for ESP32"),
            ),
            networks.isNotEmpty
                ? ElevatedButton(
              onPressed: connectToESP32,
              child: Text("Connect to Sortmatic"),
            )
                : Text("ESP32 Not Found"),
          ],
        ),
      ),
    );
  }
}

class WasteMonitorScreen extends StatefulWidget {
  @override
  _WasteMonitorScreenState createState() => _WasteMonitorScreenState();
}

class _WasteMonitorScreenState extends State<WasteMonitorScreen> {
  double wasteLevel = 0.0;
  double weight = 0.0;
  Timer? _timer;
  String esp32IP = "192.168.4.1";

  @override
  void initState() {
    super.initState();
    fetchSensorData();
    _timer = Timer.periodic(Duration(seconds: 2), (timer) => fetchSensorData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchSensorData() async {
    try {
      var response = await http.get(Uri.parse("http://$esp32IP/data"));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        setState(() {
          wasteLevel = data["waste_level"];
          weight = data["weight"];
        });
      }
    } catch (e) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Waste Monitor")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Waste Level: ${wasteLevel.toStringAsFixed(1)}%"),
            Text("Weight: ${weight.toStringAsFixed(2)} kg"),
          ],
        ),
      ),
    );
  }
}
