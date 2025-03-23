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
  List<MapEntry<String, dynamic>> _notifications = [];
  DateTime? _startDate;
  DateTime? _endDate;


  @override
  void initState() {
    super.initState();
    _fetchUser();
    _setDefaultDate();
    _fetchNotifications();
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
      List<String> paths = ["logged", "acct_deact", "acct_update", "assign", "photo"];
      List<MapEntry<String, dynamic>> allNotifications = [];

      for (String path in paths) {
        DataSnapshot snapshot = await databaseRef.child(path).get();
        if (snapshot.value != null && snapshot.value is Map<dynamic, dynamic>) {
          Map<dynamic, dynamic> userMap = snapshot.value as Map<dynamic, dynamic>;

          userMap.forEach((userId, userNotifications) {
            if (userNotifications is Map<dynamic, dynamic>) {
              userNotifications.forEach((notifKey, notifData) {
                allNotifications.add(MapEntry(notifKey, notifData));
              });
            }
          });
        }
      }

      if (_startDate != null && _endDate != null) {
        allNotifications = allNotifications.where((entry) {
          try {
            DateTime notificationDate = DateFormat('yyyy-MM-dd').parse(entry.value['date']);
            return notificationDate.isAfter(_startDate!.subtract(Duration(days: 1))) &&
                notificationDate.isBefore(_endDate!.add(Duration(days: 1)));
          } catch (e) {
            return false;
          }
        }).toList();
      }

      allNotifications.sort((a, b) {
        try {
          final aDate = DateFormat('yyyy-MM-dd').parse(a.value['date']);
          final bDate = DateFormat('yyyy-MM-dd').parse(b.value['date']);

          // Sort by date first (newest to oldest)
          int dateComparison = bDate.compareTo(aDate);
          if (dateComparison != 0) return dateComparison;

          // If dates are the same, sort by time (newest to oldest)
          final aTime = DateFormat('HH:mm:ss').parse(a.value['time']);
          final bTime = DateFormat('HH:mm:ss').parse(b.value['time']);
          return bTime.compareTo(aTime);
        } catch (e) {
          return 0;
        }
      });

      return allNotifications;
    } catch (e) {
      print("Error fetching notifications: $e");
      return [];
    }
  }

  void _sortNotificationsByTime() {
    setState(() {
      _notifications.sort((a, b) {
        try {
          final aDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').parse("${a.value['date']} ${a.value['time']}");
          final bDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').parse("${b.value['date']} ${b.value['time']}");
          return bDateTime.compareTo(aDateTime);
        } catch (e) {
          return 0;
        }
      });
    });
  }

  void _setDefaultDate() {
    DateTime today = DateTime.now();
    setState(() {
      _startDate = today;
      _endDate = today;
    });
  }

  void _showDateRangePicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        DateTime selectedStart = _startDate!;
        DateTime selectedEnd = _endDate!;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text(
                "Select Date Range",
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text("Start Date: ${DateFormat('MMM dd, yyyy').format(selectedStart)}"),
                    trailing: Icon(Icons.calendar_today),
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedStart,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (picked != null) {
                        setModalState(() => selectedStart = picked);
                      }
                    },
                  ),
                  ListTile(
                    title: Text("End Date: ${DateFormat('MMM dd, yyyy').format(selectedEnd)}"),
                    trailing: Icon(Icons.calendar_today),
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedEnd,
                        firstDate: selectedStart,
                        lastDate: DateTime(2101),
                      );
                      if (picked != null) {
                        setModalState(() => selectedEnd = picked);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _startDate = selectedStart;
                      _endDate = selectedEnd;
                    });
                    _fetchNotifications();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade300,
                  ),
                  child: const Text("Apply Date Range"),
                ),


              ],
            );
          },
        );
      },
    );
  }

  @override

  Widget build(BuildContext context) {
    String dateRangeText = _startDate != null && _endDate != null
        ? "${DateFormat('MMM dd').format(_startDate!)} - ${DateFormat('MMM dd').format(_endDate!)}"
        : "Select Date Range";

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Column(
          children: [
            Container(height: MediaQuery.of(context).size.height / 10),
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
                      "NOTIFICATIONS",
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.06,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).size.height * 0.005,
              bottom: 10,
              left: 16,
              right: 16,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    dateRangeText,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Positioned(
                  right: 0,
                  top: MediaQuery.of(context).size.height * -0.005,
                  bottom: 0,
                  child: IconButton(
                    icon: const Icon(Icons.calendar_today, color: Colors.black),
                    onPressed: () => _showDateRangePicker(context),
                  ),
                ),
              ],
            ),
          ),


          Expanded(
            child: FutureBuilder<List<MapEntry<String, dynamic>>>(
              future: _fetchNotifications(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Failed to load notifications.'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No notifications available.'));
                }

                final notifications = snapshot.data!;

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: notifications.map((entry) {
                      final data = entry.value as Map<dynamic, dynamic>? ?? {};
                      final userId = data['userId'] ?? 'Unknown User';
                      final name = data['name'] ?? 'Unknown Name';
                      final status = data['status'] ?? 'Unknown Status';
                      final time = data['time'] ?? 'Unknown Time';
                      final message = data['msg'] ?? '';
                      final date = data['date'] ?? 'Unknown date';

                      if (message.isNotEmpty) {
                        return NotificationItem(
                          userId: userId,
                          message: "$name $status $time",
                          date: date,
                        );
                      }
                      return const SizedBox();
                    }).toList(),

                  ),
                );
              },
            ),
          ),
        ],
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 20.0), // Moves it up
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BottomAppBar(
            color: Colors.transparent, //  Make background transparent
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
  final String date;
  const NotificationItem({
    super.key,
    required this.userId,
    required this.message,
    required this.date,
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
              trailing: Text(
                date,
                style: const TextStyle(fontSize: 12, color: Colors.black),
              ),
            ),
          ),
        );
      },
    );
  }
}

