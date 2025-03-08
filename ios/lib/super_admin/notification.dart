import 'package:flutter/material.dart';
import 'super_admin_dashboard.dart';
import 'notification.dart';
import 'landing.dart'; // Use correct import path

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: NotificationScreen(),
    );
  }
}

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Column(
          children: [
            Container(
              color: Colors.grey[200],
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Image.asset(
                'assets/logo.png',
                height: 50,
              ),
            ),
            Container(
              color: Colors.amber,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const Text(
                'NOTIFICATIONS',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
      body: const SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(title: "New"),
              NotificationItem(
                iconPath: 'assets/profile picture.png',
                message: "User Sharmaine has cleared the trash from SmartBin.",
                trailingIconPath: 'assets/binlogo.png',
              ),
              NotificationItem(
                iconPath: 'assets/profile picture.png',
                message: "User Albert has cleared the trash from SmartBin.",
                trailingIconPath: 'assets/binlogo.png',
              ),
              SizedBox(height: 16),
              SectionTitle(title: "Old"),
              NotificationItem(
                iconPath: 'assets/notification.png',
                message: "SmartBin is halfway full. Please monitor for timely disposal.",
              ),
              NotificationItem(
                iconPath: 'assets/profile picture.png',
                message: "User Alvin has cleared the trash from SmartBin.",
                trailingIconPath: 'assets/binlogo.png',
              ),
              NotificationItem(
                iconPath: 'assets/notification.png',
                message: "SmartBin hits 50% capacity. Check-in soon to prevent overflow.",
              ),
              NotificationItem(
                iconPath: 'assets/notification.png',
                message: "SmartBin hits 83% capacity. Remove the trash to prevent overflow.",
              ),
              NotificationItem(
                iconPath: 'assets/profile picture.png',
                message: "User Jenny has just disposed of the trash from SmartBin.",
                trailingIconPath: 'assets/binlogo.png',
              ),
            ],
          ),
        ),
      ),
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.black),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => NotificationScreen()),
                      );
                    },
                  ),
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
                  child: Image.asset(
                    'assets/profile picture.png',
                    fit: BoxFit.cover,
                    height: 40,
                    width: 40,
                  ),
                ),

              ],
            ),
          ),
        ),
    );
  }


  Widget _buildNavIcon(BuildContext context, String assetPath, Widget page) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => page),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.green[300],
          ),
          const CircleAvatar(
            radius: 20,
            backgroundColor: Colors.black,
          ),
          Image.asset(
            assetPath,
            color: Colors.white,
            fit: BoxFit.cover,
            width: 40,
            height: 40,
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class NotificationItem extends StatelessWidget {
  final String iconPath;
  final String message;
  final String? trailingIconPath;

  const NotificationItem({
    super.key,
    required this.iconPath,
    required this.message,
    this.trailingIconPath,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () {},
        hoverColor: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            leading: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey[300],
              child: Image.asset(
                iconPath,
                width: 40,
                height: 40,
                fit: BoxFit.contain,
              ),
            ),
            title: Text(
              message,
              style: const TextStyle(fontSize: 14),
            ),
            trailing: trailingIconPath != null
                ? Container(
              alignment: Alignment.centerRight,
              width: 40,
              height: 40,
              child: Image.asset(
                trailingIconPath!,
                fit: BoxFit.contain,
              ),
            )
                : null,
          ),
        ),
      ),
    );
  }
}
