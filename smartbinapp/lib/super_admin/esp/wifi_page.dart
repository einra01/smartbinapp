import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WiFiPage extends StatefulWidget {
  @override
  _WiFiPageState createState() => _WiFiPageState();
}

class _WiFiPageState extends State<WiFiPage> {
  List<String> wifiNetworks = ["VINNY", "HOME_WIFI", "ESP32_Network"];

  void _showWiFiDialog(String ssid) {
    TextEditingController ssidController = TextEditingController(text: ssid);
    TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Connect to $ssid"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ssidController,
                decoration: InputDecoration(labelText: "SSID"),
                readOnly: true,
              ),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(labelText: "Password"),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                _connectToWiFi(ssidController.text, passwordController.text);
                Navigator.pop(context);
              },
              child: Text("Connect"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _connectToWiFi(String ssid, String password) async {
    String url = "http://192.168.4.1/connect";
    try {
      var response = await http.post(
        Uri.parse(url),
        body: {"ssid": ssid, "password": password},
      );

      if (response.statusCode == 200) {
        _showSuccessDialog("Connected successfully!");
      } else {
        _showSuccessDialog("Failed to connect.");
      }
    } catch (e) {
      _showSuccessDialog("Error: $e");
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Connection Status"), // ✅ FIXED ERROR
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("WiFi Networks")),
      body: ListView.builder(
        itemCount: wifiNetworks.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(wifiNetworks[index]),
            trailing: ElevatedButton(
              onPressed: () => _showWiFiDialog(wifiNetworks[index]),
              child: Text("Connect"),
            ),
          );
        },
      ),
    );
  }
}
