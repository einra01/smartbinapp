import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'super_admin_dashboard.dart';
import 'notification.dart'; // Use as needed
import 'landing.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AccountDeactPage(),
    );
  }
}
class UserData {
  final String name;
  final String role;

  UserData({required this.name, required this.role});

  factory UserData.fromMap(Map<dynamic, dynamic> map) {
    return UserData(
      name: map['name'] ?? 'Unknown',
      role: map['role'] ?? 'Unknown', // Assuming you have a 'role' field in your database
    );
  }
}
class AccountDeactPage extends StatefulWidget {
  @override
  _AccountManagementPageState createState() => _AccountManagementPageState();
}

class _AccountManagementPageState extends State<AccountDeactPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('users');
  late Stream<List<UserData>> _userStream;

  @override
  void initState() {
    super.initState();
    _userStream = _dbRef.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      print('Fetched data: $data'); // Debug print

      // Filter users by 'utility' role
      return data.entries
          .map((entry) {
        final user = entry.value as Map<dynamic, dynamic>;
        return UserData.fromMap(user);
      })
          .where((user) => user.role == 'utility')
          .toList();
    });}

  // Confirmation dialog for deactivating account
  Future<void> _showDeactivationDialog(BuildContext context,
      String name) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent dismissal when tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFD9D9D9), // Light gray background
          content: Column(
            mainAxisSize: MainAxisSize.min,
            // Ensures the content is properly sized
            children: [
              const Text(
                'DO YOU WANT TO DEACTIVATE',
                style: TextStyle(
                  fontSize: 10, // Font size 12
                ),
              ),
              Text(
                '$name ACCOUNT?',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center, // Center the buttons
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF6FB055), // Green background
                foregroundColor: Colors.white, // Text color
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      5), // Box shape with 5 radius
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                // Perform action for "Yes"
                print('Account deactivated');
              },
              child: const Text('Yes'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFD23C3C), // Red background
                foregroundColor: Colors.white, // Text color
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      5), // Box shape with 5 radius
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                // Perform action for "Cancel"
                print('Account deactivation cancelled');
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }


  // Confirmation dialog for reactivating account
  Future<void> _showReactivationDialog(BuildContext context,
      String name) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent dismissal when tapping outside
      builder: (BuildContext context)  {
        return AlertDialog(
          backgroundColor: const Color(0xFFD9D9D9), // Light gray background
          content: Column(
            mainAxisSize: MainAxisSize.min,
            // Ensures the content is properly sized
            children: [
              const Text(
                'DO YOU WANT TO REACTIVATE',
                style: TextStyle(
                  fontSize: 10, // Font size 12
                ),
              ),
              Text(
                '$name ACCOUNT?',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center, // Center the buttons
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF6FB055), // Green background
                foregroundColor: Colors.white, // Text color
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      2), // Box shape with 5 radius
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                // Perform action for "Yes"
                print('Account reactivated');
              },
              child: const Text('Yes'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFD23C3C), // Red background
                foregroundColor: Colors.white, // Text color
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      5), // Box shape with 5 radius
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                // Perform action for "Cancel"
                print('Account reactivation cancelled');
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      height: 15,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Text(
            'USERS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'STATUS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // User row with clickable add/remove icons
  Widget _buildUserRow(String name,
      String actionImagePath, {
        required Color backgroundColor,
        double fontSize = 12,
        required VoidCallback onActionTap,
      }) {
    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click, // Change cursor on hover
            child: GestureDetector(
              onTap: onActionTap,
              child: Image.asset(
                actionImagePath,
                width: 28,
                height: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NotificationScreen()),
                );
              },
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
                    'assets/notification.png',
                    color: Colors.white,
                    fit: BoxFit.cover,
                    width: 40,
                    height: 40,
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DashboardScreen()),
                );
              },
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
                    'assets/home.png',
                    color: Colors.white,
                    fit: BoxFit.cover,
                    width: 40,
                    height: 40,
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SuperAdminApp()),
                );
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.green[300],
                  ),
                  const CircleAvatar(
                    radius: 20,
                  ),
                  Image.asset(
                    'assets/profile picture.png',
                    fit: BoxFit.cover,
                    height: 40,
                    width: 40,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  @override

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow[700],
        title: Text('Account Creation'),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<List<UserData>>(
        stream: _userStream, // Ensure _userStream is properly defined
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching data'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No users found'));
          }

          final userDataList = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),
                _buildHeaderRow(),
                // Custom header row (ensure this is implemented)
                const Divider(thickness: 1),
                ListView.builder(
                  shrinkWrap: true,
                  // Ensures it takes the available space
                  physics: const NeverScrollableScrollPhysics(),
                  // Prevents inner scrolling
                  itemCount: userDataList.length,
                  itemBuilder: (context, index) {
                    final user = userDataList[index];
                    return _buildUserRow(
                      user.name,
                      user.role == 'Remove'
                          ? 'assets/remove.png'
                          : 'assets/add.png',
                      backgroundColor: index % 2 == 0
                          ? const Color(0xFFD9D9D9)
                          : const Color(0xFFF1F1F1),
                      onActionTap: () {
                        if (user.role == 'Remove') {
                          _showDeactivationDialog(context, user.name);
                        } else if (user.role == 'Add') {
                          _showReactivationDialog(context, user.name);
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Padding(
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
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/profile picture.png',
                      fit: BoxFit.cover,
                      height: 40,
                      width: 40,
                    ),
                  ),
                ),
              )


            ],
          ),
        ),
      ),
    );

  }

}
