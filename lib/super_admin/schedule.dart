import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_profile.dart';
import 'notification.dart';
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
      home: Schedule(),
    );
  }
}class UserData {
  final String id;
  final String name;
  final String role;
  final String status;
  final String? profileImageUrl;
  String deviceName;
  String shift; // Ensure shift is non-nullable

  UserData({
    required this.id,
    required this.name,
    required this.role,
    required this.status,
    this.profileImageUrl,
    this.deviceName = "Unknown Device",
    this.shift = "", // Default value to avoid null issues
  });

  factory UserData.fromMap(String key, Map<dynamic, dynamic> value) {
    return UserData(
      id: key,
      name: value['name']?.toString() ?? 'Unknown',
      role: value['role']?.toString() ?? 'Unknown',
      status: value['status']?.toString() ?? 'Unknown',
      profileImageUrl: value['profileImageUrl']?.toString(),
      shift: value['shift']?.toString() ?? "", // Ensure shift is never null
    );
  }
}





class Schedule extends StatefulWidget {
  @override
  _ScheduleState createState() => _ScheduleState();
}

class _ScheduleState extends State<Schedule> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('users');
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<UserData> userDataList = [];
  List<UserData> filteredUserDataList = [];
  String searchQuery = '';
  String _profileImageUrl = '';
  String deviceName= '';
  String userId = '';

  List<Map<String, dynamic>> displayedUsers = [];

  @override
  void initState() {
    super.initState();
    _fetchUser();
    _listenToUserUpdates();
  }

  void _fetchUser() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        userId = user.uid;
        await _fetchProfileImage(userId);
      }
    } catch (e) {
      print("Error fetching user: $e");
    }
  }

  Future<void> _fetchProfileImage(String userId) async {
    try {
      final snapshot = await _dbRef.child(userId).get();
      final data = (snapshot.value as Map<dynamic, dynamic>?)
          ?.map((key, value) => MapEntry(key.toString(), value));

      if (data != null && data['profileImageUrl'] != null) {
        setState(() {
          _profileImageUrl = data['profileImageUrl'];
        });
      }
    } catch (e) {
      print("Error fetching profile image: $e");
    }
  }
  void _listenToUserUpdates() {
    _dbRef.onValue.listen((event) async {
      final data = event.snapshot.value;
      if (data is Map) {
        List<UserData> users = [];

        for (var entry in data.entries) {
          String userId = entry.key.toString();
          Map<dynamic, dynamic> userData = entry.value as Map<dynamic, dynamic>;

          UserData user = UserData.fromMap(userId, userData);

          // Fetch schedule (check if user is assigned)
          final scheduleSnapshot = await _dbRef.child("$userId/schedule").get();
          bool isAssigned = scheduleSnapshot.exists;

          if (isAssigned) {
            Map<dynamic, dynamic> scheduleData = scheduleSnapshot.value as Map<dynamic, dynamic>;
            String? firstDeviceKey = scheduleData.keys.first;

            // Fetch deviceName
            final deviceSnapshot = await FirebaseDatabase.instance.ref("devices/$firstDeviceKey/deviceName").get();
            if (deviceSnapshot.exists) {
              user.deviceName = deviceSnapshot.value.toString();
            }

            // Fetch shift
            final shiftSnapshot = await FirebaseDatabase.instance.ref("users/$userId/schedule/$firstDeviceKey/shift").get();
            if (shiftSnapshot.exists) {
              user.shift = shiftSnapshot.value.toString();
            }
          } else {
            user.deviceName = "Unassigned"; // Mark unassigned users
            user.shift = "";
          }

          users.add(user);
        }

        // Sort users: unassigned first, then by deviceName, then by shift
        users.sort((a, b) {
          // Unassigned users should be first
          if (a.deviceName == "Unassigned" && b.deviceName != "Unassigned") return -1;
          if (a.deviceName != "Unassigned" && b.deviceName == "Unassigned") return 1;

          // Sort alphabetically by deviceName
          int deviceComparison = a.deviceName.compareTo(b.deviceName);
          if (deviceComparison != 0) return deviceComparison;

          // Sort by shift order: AM → NN → PM
          List<String> shiftOrder = ["AM", "NN", "PM"];
          int shiftA = shiftOrder.indexOf(a.shift);
          int shiftB = shiftOrder.indexOf(b.shift);
          return shiftA.compareTo(shiftB);
        });

        setState(() {
          userDataList = users;
          _filterUsers(); // Apply filtering after sorting
        });
      }
    });
  }

  void _showAssignmentSuccessDialog(BuildContext context, UserData user, String deviceName, String shiftTime) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                      ? NetworkImage(user.profileImageUrl!)
                      : const AssetImage('assets/profile picture.png') as ImageProvider,
                ),
                const SizedBox(height: 10),
                Text(
                  user.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 10),
                Text(
                  "Assigned to $deviceName",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Text(
                  "Shift: $shiftTime",
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Close"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserTile(UserData user) {
    return FutureBuilder<DataSnapshot>(
      future: FirebaseDatabase.instance.ref('users/${user.id}/schedule').get(),
      builder: (context, scheduleSnapshot) {
        bool isAssigned = scheduleSnapshot.hasData && scheduleSnapshot.data?.value != null;

        if (!isAssigned) {
          return _buildUserCard(user, isAssigned, "", "Unknown Shift", "Unknown Device");
        }

        Map<dynamic, dynamic>? scheduleData = scheduleSnapshot.data!.value as Map<dynamic, dynamic>?;
        String profileImageUrl = scheduleData?['profileImageUrl']?.toString() ?? '';
        List<String> deviceKeys = scheduleData != null ? scheduleData.keys.map((key) => key.toString()).toList() : [];

        if (deviceKeys.isEmpty) {
          return _buildUserCard(user, isAssigned, profileImageUrl, "Unknown Shift", "Unknown Device");
        }

        // Fetch the first assigned device (modify as needed to support multiple devices)
        String deviceKey = deviceKeys.first;
        return FutureBuilder<DataSnapshot>(
          future: FirebaseDatabase.instance.ref('users/${user.id}/schedule/$deviceKey/shift').get(),
          builder: (context, shiftSnapshot) {
            String shift = "Unknown Shift";
            if (shiftSnapshot.hasData && shiftSnapshot.data?.value != null) {
              shift = shiftSnapshot.data!.value.toString();
            }

            return FutureBuilder<DataSnapshot>(
              future: FirebaseDatabase.instance.ref('devices/$deviceKey').get(),
              builder: (context, deviceSnapshot) {
                String deviceName = "Unknown Device";

                if (deviceSnapshot.hasData && deviceSnapshot.data?.value != null) {
                  var deviceData = deviceSnapshot.data!.value;
                  if (deviceData is Map<dynamic, dynamic>) {
                    deviceName = deviceData['deviceName']?.toString() ?? "Unknown Device";
                  }
                }

                return _buildUserCard(user, isAssigned, profileImageUrl, shift, deviceName);
              },
            );
          },
        );
      },
    );
  }


  /// Helper method to build the user card UI

  Widget _buildUserCard(UserData user, bool isAssigned, String profileImageUrl, String shift, String deviceName) {
    Color cardColor = isAssigned ? Color(0xFFE9DAAF) : Color(0xFFA89F84);
    return Card(
      color: cardColor,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            /// Profile Image (Directly Used)
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.grey[300],
              backgroundImage: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                  ? NetworkImage(user.profileImageUrl!)
                  : const AssetImage('assets/profile picture.png') as ImageProvider,
            ),
            const SizedBox(width: 12),

            /// Name & Shift/Device Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      if (!isAssigned)
                        const Text(
                          "Unassigned",
                          style: TextStyle(fontSize: 14),
                        ),
                    ],
                  ),

                  isAssigned
                      ? FutureBuilder<DataSnapshot>(
                    future: FirebaseDatabase.instance.ref('shift/$shift').get(),
                    builder: (context, shiftSnapshot) {
                      String shiftTime = shiftSnapshot.hasData && shiftSnapshot.data?.value != null
                          ? shiftSnapshot.data!.value.toString()
                          : shift;

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            shiftTime,
                            style: TextStyle(fontSize: 13),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                deviceName,
                                style: TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  )
                      : const SizedBox.shrink(),
                ],
              ),
            ),
            const SizedBox(width: 8),

            /// Edit Button
            Container(
              decoration: const BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.edit, color: Colors.black, size: 20),
                onPressed: () => _showEditDialog(user),
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _filterUsers() {
    setState(() {
      filteredUserDataList = userDataList.where((user) {
        String query = searchQuery.toLowerCase();
        return (user.name.toLowerCase().contains(query) ||
            user.deviceName.toLowerCase().contains(query)) &&
            user.role == 'Utility' &&
            user.status == 'Active';
      }).toList();
    });
  }


  void _showEditDialog(UserData user) {
    String? selectedDevice;
    String? selectedShift;
    Map<String, String> shiftTimes = {
      'AM': '7:00AM-11:00AM',
      'NN': '12:00PM-4:00PM',
      'PM': '5:00PM-9:00PM',
    };

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: FutureBuilder<DatabaseEvent>(
              future: FirebaseDatabase.instance.ref('devices').once(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                Map<dynamic, dynamic> devices = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                List<DropdownMenuItem<String>> deviceItems = devices.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value['deviceName']),
                  );
                }).toList();

                return Stack(
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 10),
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                                ? NetworkImage(user.profileImageUrl!)
                                : const AssetImage('assets/profile picture.png') as ImageProvider,
                          ),
                          const SizedBox(height: 10),
                          Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          const Text("Utility Staff", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 10),

                          DropdownButton<String>(
                            value: selectedDevice,
                            hint: const Text("Select Device"),
                            items: deviceItems,
                            onChanged: (newValue) {
                              setState(() {
                                selectedDevice = newValue;
                              });
                            },
                            isExpanded: true,
                          ),
                          const SizedBox(height: 10),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: ['AM', 'NN', 'PM'].map((shift) {
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    bool isValid = await _validateShift(user.id, shift);
                                    if (isValid) {
                                      setState(() {
                                        selectedShift = shift;
                                      });
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("User is already assigned to another shift.")),
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    decoration: BoxDecoration(
                                      color: selectedShift == shift ? Colors.amber : Colors.grey[300],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      shift,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: selectedShift == shift ? Colors.white : Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),
                ElevatedButton(
                onPressed: (selectedDevice != null && selectedShift != null)
                ? () async {
                DatabaseReference deviceRef =
                FirebaseDatabase.instance.ref('devices/$selectedDevice/deviceName');
                DatabaseReference scheduleRef =
                FirebaseDatabase.instance.ref('users/${user.id}/schedule/$selectedDevice');
                DatabaseReference devii = FirebaseDatabase.instance
                    .ref('devices/$selectedDevice/shift/$selectedShift/${user.id}');
                DatabaseReference notificationRef =
                FirebaseDatabase.instance.ref('notifications/assign/${user.id}');
                DatabaseReference shiftRef =
                FirebaseDatabase.instance.ref('shift/$selectedShift');

                // Fetch deviceName
                DatabaseEvent deviceSnapshot = await deviceRef.once();
                String deviceName =
                deviceSnapshot.snapshot.value?.toString() ?? "Unknown Device";

                // Fetch shift time (real shift time instead of AM, NN, PM)
                DatabaseEvent shiftSnapshot = await shiftRef.once();
                String shiftTime =
                shiftSnapshot.snapshot.value?.toString() ?? shiftTimes[selectedShift]!;

                // Get formatted timestamp
                final now = DateTime.now();
                final formattedDate = DateFormat('yyyy-MM-dd').format(now);
                final formattedTime = DateFormat('HH:mm:ss').format(now);

                // Update schedule & device shift
                await scheduleRef.update({'shift': selectedShift});
                await devii.set({'userId': user.id, 'name': user.name});

                // Push notification with correct shift time
                String assignedKey = notificationRef.push().key!;
                await notificationRef.child(assignedKey).set({
                'name': user.name,
                'status': "has been assigned to $deviceName at $shiftTime shift",
                'date': formattedDate,
                'time': formattedTime,
                  'msg': "${user.name} has been assigned to $deviceName at $shiftTime shift",
                'userId': user.id,
                });

                // Close the assignment dialog
                Navigator.pop(context);

                // Show confirmation modal
                _showAssignmentSuccessDialog(context, user, deviceName, shiftTime);
                }
                    : null,
                style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
                ),
                child: const Text("Assign"),
                ),

                        ],
                      ),
                    ),

                    // Close Button at Top-Right
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[300],
                          ),
                          child: const Icon(Icons.close, size: 20, color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }



  Future<bool> _validateShift(String userId, String newShift) async {
    DataSnapshot snapshot = await FirebaseDatabase.instance.ref('users/$userId/schedule').get();
    if (snapshot.value != null) {
      Map<dynamic, dynamic> schedule = snapshot.value as Map<dynamic, dynamic>;
      for (var device in schedule.values) {
        if (device['shift'] != newShift) {
          return false;
        }
      }
    }
    return true;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Stack(
        children: [
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).size.height / 14,
              color: Colors.amber.withOpacity(0.99),
              child: Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const Center(
                    child: Text(
                      "SCHEDULE",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 160,
            left: 16,
            right: 16,
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search user...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                  _filterUsers();
                });
              },
            ),
          ),
          Positioned.fill(
            top: 200, // Adjusted to move the list slightly lower
            child: Column(
              children: [
                Expanded(
                  child: filteredUserDataList.isEmpty
                      ? const Center(child: Text("No users found"))
                      : ListView(
                    padding: EdgeInsets.only(top: 20),
                    children: filteredUserDataList.map((user) => _buildUserTile(user)).toList(),
                  ),

                ),
              ],
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

