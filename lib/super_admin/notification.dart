import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'admin_profile.dart';
import 'landing.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref("notifications");
  String _profileImageUrl = '';
  String userId = '';
  String selectedTimeFrame = 'Week'; // Default to 'Week'
  List<MapEntry<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  void _fetchUser() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        userId = user.uid; // Get the user ID
        await _fetchProfileImage(userId);
      }
    } catch (e) {
      print("Error fetching user: $e");
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
      }
    } catch (e) {
      print("Error fetching profile image: $e");
    }
  }

  Future<List<MapEntry<String, dynamic>>> _fetchNotifications() async {
    try {
      DatabaseReference databaseRef = FirebaseDatabase.instance.ref().child("notifications");

      // Paths to fetch
      List<String> paths = ["logged", "acct_deact", "acct_update", "assign"];
      List<MapEntry<String, dynamic>> allNotifications = [];

      for (String path in paths) {
        DataSnapshot snapshot = await databaseRef.child(path).get();
        if (snapshot.value != null && snapshot.value is Map<dynamic, dynamic>) {
          Map<dynamic, dynamic> userMap = snapshot.value as Map<dynamic, dynamic>;

          // Iterate over userIds inside each category
          userMap.forEach((userId, userNotifications) {
            if (userNotifications is Map<dynamic, dynamic>) {
              userNotifications.forEach((notifKey, notifData) {
                allNotifications.add(MapEntry(notifKey, notifData));
              });
            }
          });
        }
      }

      // **Sorting notifications based on Date & Time (Latest first)**
      allNotifications.sort((a, b) {
        try {
          final aDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').parse("${a.value['date']} ${a.value['time']}");
          final bDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').parse("${b.value['date']} ${b.value['time']}");
          return bDateTime.compareTo(aDateTime); // Latest first
        } catch (e) {
          return 0; // Ignore errors and keep order unchanged
        }
      });

      return allNotifications;
    } catch (e) {
      print("Error fetching notifications: $e");
      return [];
    }
  }


  List<MapEntry<String, dynamic>> _filterNotifications(List<MapEntry<String, dynamic>> allNotifications) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    final newNotifications = allNotifications.where((entry) {
      try {
        DateTime notificationDate = DateFormat('yyyy-MM-dd').parse(entry.value['date']);
        return notificationDate.isAtSameMomentAs(todayStart) || notificationDate.isAfter(todayStart);
      } catch (e) {
        return false;
      }
    }).toList();

    final oldNotifications = allNotifications.where((entry) {
      try {
        DateTime notificationDate = DateFormat('yyyy-MM-dd').parse(entry.value['date']);
        return notificationDate.isBefore(todayStart);
      } catch (e) {
        return false;
      }
    }).toList();

    return [...newNotifications, ...oldNotifications];
  }



@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Column(
          children: [
            Container(
              height: MediaQuery.of(context).size.height / 10,

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
      body: StreamBuilder(
        stream: _databaseRef.onValue, // Listen for real-time changes
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Failed to load notifications.'));
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text('No notifications available.'));
          }

          // Use FutureBuilder to fetch additional data asynchronously
          return FutureBuilder<List<MapEntry<String, dynamic>>>(
            future: _fetchNotifications(),
            builder: (context, futureSnapshot) {
              if (futureSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (futureSnapshot.hasError) {
                return const Center(child: Text('Error loading notifications.'));
              }

              final allNotifications = futureSnapshot.data ?? [];
// 🔥 Sort by time (Newest First)
              allNotifications.sort((a, b) {
                try {
                  // Parse `time` field assuming it's in 24-hour format like "14:30:15"
                  DateTime timeA = DateFormat('HH:mm:ss').parse(a.value['time']);
                  DateTime timeB = DateFormat('HH:mm:ss').parse(b.value['time']);

                  return timeB.compareTo(timeA); // Newest first
                } catch (e) {
                  print("⚠️ Error parsing time: $e");
                  return 0; // If there's an error, keep the original order
                }
              });

              final today = DateTime.now();
              final todayStart = DateTime(today.year, today.month, today.day);

              final newNotifications = allNotifications.where((entry) {
                try {
                  DateTime notificationDate = DateFormat('yyyy-MM-dd').parse(entry.value['date']);
                  return notificationDate.isAtSameMomentAs(todayStart) || notificationDate.isAfter(todayStart);
                } catch (e) {
                  return false;
                }
              }).toList();

              final oldNotifications = allNotifications.where((entry) {
                try {
                  DateTime notificationDate = DateFormat('yyyy-MM-dd').parse(entry.value['date']);
                  return notificationDate.isBefore(todayStart);
                } catch (e) {
                  return false;
                }
              }).toList();


              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("New Notifications", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          DropdownButton<String>(
                            value: selectedTimeFrame,
                            onChanged: (newValue) {
                              setState(() {
                                selectedTimeFrame = newValue!;
                              });
                            },
                            items: <String>['Week', 'Month', 'Year']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      if (newNotifications.isEmpty) const Text("No new notifications available."),
                      ...newNotifications.map((entry) {
                        final data = entry.value as Map<dynamic, dynamic>? ?? {};
                        final userId = data['userId'] ?? 'Unknown User';
                        final name = data['name'] ?? 'Unknown Name';
                        final status = data['status'] ?? 'Unknown Status';
                        final time = data['time'] ?? 'Unknown Time';
                        final message = data['msg'] ?? '';

                        if (message.isNotEmpty) {
                          return NotificationItem(
                            userId: userId,
                            message: "$name $status",
                            time: time, // ✅ Pass time separately to align it properly
                          );
                        }
                        return const SizedBox();
                      }),


                      const Text("Old Notifications", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      if (oldNotifications.isEmpty) const Text("No old notifications available."),
                      ...oldNotifications.map((entry) {
                        final data = entry.value as Map<dynamic, dynamic>? ?? {};
                        final userId = data['userId'] ?? 'Unknown User';
                        final name = data['name'] ?? 'Unknown Name';
                        final status = data['status'] ?? 'Unknown Status';
                        final time = data['time'] ?? 'Unknown Time';
                        final message = data['msg'] ?? '';

                        if (message.isNotEmpty) {
                          return NotificationItem(
                            userId: userId,
                            message: "$name $status",
                            time: time, // ✅ Pass time separately to align it properly
                          );
                        }
                        return const SizedBox();
                      }),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 20.0), // Moves it up
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20), // ✅ Rounds all corners (top & bottom)
          child: BottomAppBar(
            color: Colors.transparent, // ✅ Make background transparent
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
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child:
                    IconButton(
                      icon: const Icon(Icons.notifications, color: Colors.black),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => NotificationScreen()),
                        );
                      },
                    ),
                  ), IconButton(
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
  final String userId;
  final String message;
  final String time; // ✅ Make sure we use this!

  const NotificationItem({
    super.key,
    required this.userId,
    required this.message,
    required this.time,
  });

  Future<String> _getProfileImageUrl(String userId) async {
    try {
      final DatabaseReference userRef = FirebaseDatabase.instance.ref("users/$userId");
      final DataSnapshot snapshot = await userRef.get();

      if (snapshot.exists) {
        final userData = snapshot.value as Map<dynamic, dynamic>;
        return userData['profileImageUrl'] ?? 'assets/profile picture.png'; // Default if no URL
      }
    } catch (e) {
      debugPrint("Error fetching profile image for user $userId: $e");
    }
    return 'assets/profile picture.png'; // Default if an error occurs
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getProfileImageUrl(userId),
      builder: (context, snapshot) {
        String imageUrl = 'assets/profile picture.png'; // Default image
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          imageUrl = snapshot.data!;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey[300],
                backgroundImage: imageUrl.startsWith('http') // Use URL if valid
                    ? NetworkImage(imageUrl)
                    : AssetImage(imageUrl) as ImageProvider,
              ),
              title: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
              // ✅ Adding Time to the Right
              trailing: Text(
                time,
                style: const TextStyle(fontSize: 12, color: Colors.black),
              ),
            ),
          ),
        );
      },
    );
  }
}

