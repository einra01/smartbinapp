import 'package:flutter/material.dart';

void main() {
  runApp(const AccountManagementApp());
}

class AccountManagementApp extends StatelessWidget {
  const AccountManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AccountManagementScreen(),
    );
  }
}

class AccountManagementScreen extends StatelessWidget {
  const AccountManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // Logo and Header Title
            Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.all(16.0),
              child: const Column(
                children: [
                  Text(
                    'LOGO',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
            // Header Section with "Account Management" Title
            Container(
              color: Colors.amber[700],
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: const Center(
                child: Text(
                  'ACCOUNT MANAGEMENT',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            // Navigation Items for Account Management Options
            Expanded(
              child: Container(
                color: Colors.grey[200],
                child: const Column(
                  children: [
                    SizedBox(height: 16),
                    // Change Name
                    NavigationItem(
                      icon: Icons.edit,
                      label: 'CHANGE NAME',
                    ),
                    // Change Password
                    NavigationItem(
                      icon: Icons.lock_outline,
                      label: 'CHANGE PASSWORD',
                    ),
                    // Change Email
                    NavigationItem(
                      icon: Icons.email_outlined,
                      label: 'CHANGE EMAIL',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.grey[300],
        selectedItemColor: Colors.amber[700],
        unselectedItemColor: Colors.black54,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: '',
          ),
        ],
      ),
    );
  }
}

class NavigationItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const NavigationItem({required this.icon, required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.black54, size: 16),
      onTap: () {
        // Handle navigation here
      },
    );
  }
}
