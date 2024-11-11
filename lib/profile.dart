import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Profile Page',
      theme: ThemeData(
        primarySwatch: Colors.yellow,
      ),
      home: const ProfilePage(),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow[700],
        elevation: 0,
        toolbarHeight: 0, // Hides the AppBar since the design has no visible AppBar
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Top Icon
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Icon(
                Icons.build, // Change to a relevant icon if needed
                size: 60,
                color: Colors.yellow[800],
              ),
            ),
            const SizedBox(height: 20),

            // Profile Picture
            const CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(
                'https://via.placeholder.com/150', // Replace with actual profile picture URL
              ),
            ),
            const SizedBox(height: 20),

            // Display Name
            const Text(
              'SHARMAINE BANQUILES', // Replace with actual display name
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Utility Staff', // Replace with actual position title
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),

            // Other Navigation Section Header
            const Text(
              'OTHER NAVIGATION',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Account Management Button
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Account Management'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Add your account management functionality here
              },
            ),
            Divider(color: Colors.grey[300]),

            // Notifications/Alert Button
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Notification / Alert'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Add your notifications/alert functionality here
              },
            ),

            const Spacer(),

            // Logout Button at the bottom-center
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: ElevatedButton(
                onPressed: () {
                  // Add your logout functionality here
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.yellow[700],
                  minimumSize: const Size(200, 50),
                ),
                child: const Text('LOGOUT'),
              ),
            ),
          ],
        ),
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBar: BottomAppBar(
        color: Colors.grey[200],
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.black),
                onPressed: () {
                  // Add notification functionality here
                },
              ),
              IconButton(
                icon: const Icon(Icons.home, color: Colors.black),
                onPressed: () {
                  // Add home functionality here
                },
              ),
              IconButton(
                icon: CircleAvatar(
                  backgroundColor: Colors.green[400],
                  radius: 15,
                  child: const Icon(Icons.person, color: Colors.white, size: 18),
                ),
                onPressed: () {
                  // Add profile functionality here
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
