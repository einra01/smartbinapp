import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Account Management',
      theme: ThemeData(
        primarySwatch: Colors.yellow,
      ),
      home: AccountManagementPage(),
    );
  }
}

class AccountManagementPage extends StatefulWidget {
  const AccountManagementPage({super.key});

  @override
  _AccountManagementPageState createState() => _AccountManagementPageState();
}

class _AccountManagementPageState extends State<AccountManagementPage> {
  bool _isChangeNameVisible = false;
  bool _isChangePasswordVisible = false;
  bool _isChangeEmailVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow[700],
        elevation: 0,
        toolbarHeight: 0, // Hides the AppBar
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Icon and Title
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Column(
                children: [
                  Icon(
                    Icons.build, // Adjust icon to match the top logo if needed
                    size: 60,
                    color: Colors.yellow[800],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    color: Colors.yellow[700],
                    width: double.infinity,
                    padding: const EdgeInsets.all(15.0),
                    child: const Center(
                      child: Text(
                        'ACCOUNT MANAGEMENT',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Account Options
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.black),
              title: const Text('Change Name'),
              trailing: Icon(
                _isChangeNameVisible ? Icons.expand_less : Icons.expand_more,
                color: Colors.black,
              ),
              onTap: () {
                setState(() {
                  _isChangeNameVisible = !_isChangeNameVisible;
                });
              },
            ),

            // Dropdown content for changing name
            Visibility(
              visible: _isChangeNameVisible,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        // Add save functionality here
                      },
                      child: const Text('Save'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: Colors.yellow[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(color: Colors.grey[300]),

            ListTile(
              leading: const Icon(Icons.lock_outline, color: Colors.black),
              title: const Text('Change Password'),
              trailing: Icon(
                _isChangePasswordVisible ? Icons.expand_less : Icons.expand_more,
                color: Colors.black,
              ),
              onTap: () {
                setState(() {
                  _isChangePasswordVisible = !_isChangePasswordVisible;
                });
              },
            ),

            // Dropdown content for changing password
            Visibility(
              visible: _isChangePasswordVisible,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        // Add save functionality here
                      },
                      child: const Text('Save'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: Colors.yellow[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(color: Colors.grey[300]),

            ListTile(
              leading: const Icon(Icons.email_outlined, color: Colors.black),
              title: const Text('Change Email'),
              trailing: Icon(
                _isChangeEmailVisible ? Icons.expand_less : Icons.expand_more,
                color: Colors.black,
              ),
              onTap: () {
                setState(() {
                  _isChangeEmailVisible = !_isChangeEmailVisible;
                });
              },
            ),

            // Dropdown content for changing email
            Visibility(
              visible: _isChangeEmailVisible,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'New Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        // Add save functionality here
                      },
                      child: const Text('Save'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: Colors.yellow[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),

            // Bottom Navigation Bar
            BottomAppBar(
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
                        child: Icon(Icons.person, color: Colors.white, size: 18),
                      ),
                      onPressed: () {
                        // Add profile functionality here
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
