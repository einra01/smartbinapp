import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_profile.dart';
import 'notification.dart'; // Use as needed
import 'landing.dart';
import 'package:intl/intl.dart';

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
  final String id;
  final String name;
  final String role;
  final String status;

  UserData({
    required this.id,
    required this.name,
    required this.role,
    required this.status,
  });
  factory UserData.fromMap(String key, Map<dynamic, dynamic> value) {
    return UserData(
      id: key,
      name: value['name']?.toString() ?? 'Unknown', // Default to 'Unknown' if null
      role: value['role']?.toString() ?? 'Unknown',
      status: value['status']?.toString() ?? 'Unknown',
    );
  }

}


class AccountDeactPage extends StatefulWidget {
  @override
  _AccountManagementPageState createState() => _AccountManagementPageState();
}

class _AccountManagementPageState extends State<AccountDeactPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('users');
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _name = ''; // Initial loading state
  String userId = '';
  String _profileImageUrl= '';
  List<UserData> userDataList = [];
  String? adminName; // Store the logged-in admin's name
  TextEditingController _searchController = TextEditingController();
  List<UserData> allUsers = []; // Stores all users from Firebase
  List<UserData> filteredUsers = []; // Stores users matching search query

  @override
  void initState() {
    super.initState();
    _fetchUser(); // Fetch the admin's name on init
    _listenToUserUpdates();
    _fetchUsers(); // Fetch users from Firebase
    _searchController.addListener(_filterUsers);
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
      final snapshot = await _dbRef.child(userId).get(); // Fetch data once
      final data = snapshot.value as Map<dynamic, dynamic>?;

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
  void _listenToUserUpdates() {
    _dbRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data is Map<dynamic, dynamic>) { // Check if data is a Map
        final List<UserData> users = [];
        data.forEach((key, value) {
          if (value is Map) { // Ensure value is a Map before using it
            users.add(UserData.fromMap(key, value));
          }
        });
        setState(() {
          userDataList = users; // Update the state with new data
        });
      } else {
        print("Unexpected data format: $data");
      }
    });
  }


// Helper to show a Snackbar
  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

// Update status and create a notification
  // Update status and create a notification
  void _updateNotification(String userId, String status, String userName, String action) async {
    try {
      // Update the user's status
      await _dbRef.child('$userId').update({'status': status});

      // Add a notification with a unique key
      final notificationsRef = FirebaseDatabase.instance.ref('notifications/acct_deact/$userId/');
      final now = DateTime.now();
      final formattedDate = DateFormat('yyyy-MM-dd').format(now); // e.g., "2025-01-23"
      final formattedTime = DateFormat('HH:mm:ss').format(now); // e.g., "14:35:12"

      // Use push() to generate a unique key
      final newNotificationRef = notificationsRef.push();

      // Determine the message based on the action
      String message = '';
      if (action == 'reactivate') {
        message = 'has been Activated by ${_name ?? ''} on $formattedDate';
      } else if (action == 'deactivate') {
        message = 'has been Deactivated by ${_name ?? ''} on $formattedDate';
      }

      // Check if the message is formed correctly
      print("Notification message: $message");

      await newNotificationRef.set({
        'msg': message,
        'userId': userId,
        'name': '$userName',
        'status': message,
        'date': formattedDate,
        'time': formattedTime,
        'by': (_name ?? '').toString(),
      });

      print("Status and notification updated successfully.");
    } catch (e) {
      print("Error updating status and notification: $e");
    }
  }


  void _showReactivationDialog(BuildContext context, String userId, String userName) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('DO YOU WANT TO REACTIVATE'),
              Text(
                "$userName's ACCOUNT?",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    try {
                      await _dbRef.child('$userId/status').set('Active');
                      _updateNotification(userId, 'Active', userName, 'reactivate');

                      String profileImageUrl = await _fetchUserProfileImage(userId);
                      if (context.mounted) {
                        _showReactivationSuccessDialog(context, userName, profileImageUrl);
                      }
                    } catch (error) {
                      if (context.mounted) {
                        _showSnackBar(context, 'Failed to reactivate account: $error');
                      }
                    }
                  },
                  child: const Text('YES', style: TextStyle(color: Colors.green)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('CANCEL', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showReactivationSuccessDialog(BuildContext context, String userName, String profileImageUrl) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext successContext) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipOval(
                child: profileImageUrl.isNotEmpty
                    ? Image.network(
                  profileImageUrl,
                  fit: BoxFit.cover,
                  height: 60,
                  width: 60,
                )
                    : Image.asset(
                  'assets/profile picture.png',
                  fit: BoxFit.cover,
                  height: 60,
                  width: 60,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'ACCOUNT REACTIVATED',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(successContext).pop(),
              child: const Text('CONFIRM', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  Future<String> _fetchUserProfileImage(String userId) async {
    try {
      // Ensure we're querying the correct path: "users/{userId}/profileImageUrl"
      DatabaseEvent event = await _dbRef.child('$userId/profileImageUrl').once();

      // Convert to string, handle null values
      String profileImageUrl = event.snapshot.value?.toString() ?? '';

      debugPrint("Profile Image URL fetched: $profileImageUrl");
      return profileImageUrl;
    } catch (error) {
      debugPrint("Error fetching profile image: $error");
      return ''; // Return an empty string if there's an error
    }
  }
  void _showDeactivationDialog(BuildContext context, String userId, String userName) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('DO YOU WANT TO DEACTIVATE'),
              Text(
                "$userName's ACCOUNT?",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center, // Center the buttons horizontally
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Ensures spacing
              children: [
                TextButton(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop(); // Close the first dialog
                    try {
                      // 1️⃣ Update status in Firebase
                      await _dbRef.child('$userId/status').set('Inactive');
                      _updateNotification(userId, 'Inactive', userName, 'deactivate');

                      debugPrint("Fetching profile image for userId: $userId");

                      // 2️⃣ Fetch profile image URL from Firebase
                      String profileImageUrl = await _fetchUserProfileImage(userId);

                      // 3️⃣ Ensure the context is still valid before showing the success dialog
                      if (context.mounted) {
                        _showDeactivationSuccessDialog(context, userName, profileImageUrl);
                      }
                    } catch (error) {
                      if (context.mounted) {
                        _showSnackBar(context, 'Failed to deactivate account: $error');
                      }
                    }
                  },
                  child: const Text('YES', style: TextStyle(color: Colors.green)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('CANCEL', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showDeactivationSuccessDialog(BuildContext context, String userName, String profileImageUrl) {
    if (!context.mounted) return; // Ensure context is still valid

    showDialog(
      context: context,
      builder: (BuildContext successContext) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Show Profile Image (If available) or Default Image
              ClipOval(
                child: profileImageUrl.isNotEmpty
                    ? Image.network(
                  profileImageUrl,
                  fit: BoxFit.cover,
                  height: 60,
                  width: 60,
                )
                    : Image.asset(
                  'assets/profile picture.png',
                  fit: BoxFit.cover,
                  height: 60,
                  width: 60,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'ACCOUNT DEACTIVATED',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center, // Center the button
          actions: [
            TextButton(
              onPressed: () => Navigator.of(successContext).pop(),
              child: const Text('CONFIRM', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8).copyWith(top: 12), // Moves it down
      height: 25, // Adjust height if needed
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Text(
            'USERS',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Text(
            'ROLE',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Text(
            'STATUS',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
  void _fetchUsers() async {
    DatabaseReference usersRef = FirebaseDatabase.instance.ref('users');
    usersRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        List<UserData> users = [];
        for (var child in event.snapshot.children) {
          var data = child.value as Map<dynamic, dynamic>;
          users.add(UserData(
            id: child.key!,
            name: data['name'] ?? '',
            role: data['role'] ?? '',
            status: data['status'] ?? '',
          ));
        }

        // Sorting: Admins first, then alphabetically
        users.sort((a, b) {
          if (a.role == 'Admin' && b.role != 'Admin') return -1;
          if (a.role != 'Admin' && b.role == 'Admin') return 1;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });

        setState(() {
          allUsers = users;
          filteredUsers = users; // Initialize list
        });
      }
    });
  }


  void _filterUsers() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredUsers = allUsers
          .where((user) => user.name.toLowerCase().contains(query))
          .toList();
    });
  }

  Widget _buildUserRow(String name, String role, String status, String actionImagePath,
      {required Color backgroundColor, required VoidCallback onActionTap}) {
    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // Ensures vertical alignment
        children: [
          // Name Column
          Container(
            width: 150,
            child: Text(
              name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),

          // Role Column
          Container(
            width: 100,
            alignment: Alignment.center,
            child: Text(
              role,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),

          const Spacer(),

          // Status Text
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Text(
              status,
              style: const TextStyle(fontSize: 12),
            ),
          ),

          // Action Image (Disable if role is Admin)
          GestureDetector(
            onTap: role == 'Admin' ? null : onActionTap, // Disable tap for Admin
            child: Opacity(
              opacity: role == 'Admin' ? 0.5 : 1.0, // Make icon faded for Admin
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




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Column(
          children: [
            // 🔹 Adds Space to Move Header Down
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),

            // 🔹 ACCOUNT DEACTIVATION Header (Moved Down)
            Container(
              height: MediaQuery.of(context).size.height * 0.06,
              color: Colors.amber.withOpacity(0.99),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      "USER LIST",
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.06,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 🔹 Search Bar (Fixed Position)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.04,
                vertical: MediaQuery.of(context).size.height * 0.02,
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search user...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),

            // 🔹 Fixed Header Row
            Container(
              padding: EdgeInsets.symmetric(
                vertical: MediaQuery.of(context).size.height * 0.01,
              ),
              child: _buildHeaderRow(),
            ),

            // 🔹 Scrollable User List (Takes Remaining Space)
            Expanded(
              child: Container(
                color: Colors.grey[200],
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(top: 5),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];

                    String actionImagePath = user.status == 'Active'
                        ? 'assets/add.png'
                        : 'assets/remove.png';

                    return _buildUserRow(
                      user.name,
                      user.role,
                      user.status,
                      actionImagePath,
                      backgroundColor: Colors.white,
                      onActionTap: () {
                        if (user.status == 'Inactive') {
                          _showReactivationDialog(context, user.id, user.name);
                        } else {
                          _showDeactivationDialog(context, user.id, user.name);
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
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
