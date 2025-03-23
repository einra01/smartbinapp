import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'utilitylanding.dart';
import 'utilityprofile.dart';

class NotificationScreenn extends StatefulWidget {
  const NotificationScreenn({super.key});

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreenn> {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref("notifications");

  String _name = 'Loading...'; // Initial loading state
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
    _fetchNotifications(userId);
  }

  // Fetch the current user
  void _fetchUser() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        userId = user.uid; // Get the user ID
        print("Logged in user ID: $userId"); // Debugging: Print user ID
        await _fetchProfileImage(userId); // Fetch the profile image using the user ID
      }
    } catch (e) {
      setState(() {
        _name = "Error fetching user: ${e.toString()}";
      });
    }
  }

  // Fetch the profile image URL
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
// Method to filter notifications based on selected time frame
  Future<List<MapEntry<String, dynamic>>> _fetchNotifications(String userId) async {
    List<MapEntry<String, dynamic>> allNotifications = [];

    try {
      DatabaseEvent acctUpdateSnapshot = await _databaseRef.child('acct_update/$userId').once();
      DatabaseEvent loggedSnapshot = await _databaseRef.child('logged/$userId').once();
      DatabaseEvent photoSnapshot = await _databaseRef.child('photo/$userId').once();
      DatabaseEvent assignSnapshot = await _databaseRef.child('assign/$userId').once();

      if (acctUpdateSnapshot.snapshot.value != null) {
        allNotifications.addAll(Map<String, dynamic>.from(acctUpdateSnapshot.snapshot.value as Map).entries);
      }
      if (assignSnapshot.snapshot.value != null) {
        allNotifications.addAll(Map<String, dynamic>.from(assignSnapshot.snapshot.value as Map).entries);
      }
      if (loggedSnapshot.snapshot.value != null) {
        allNotifications.addAll(Map<String, dynamic>.from(loggedSnapshot.snapshot.value as Map).entries);
      }
      if (photoSnapshot.snapshot.value != null) {
        allNotifications.addAll(Map<String, dynamic>.from(photoSnapshot.snapshot.value as Map).entries);
      }

      allNotifications = _filterNotifications(allNotifications);
    } catch (e) {
      print(" Error fetching notifications: $e");
    }

    return allNotifications;
  }

  List<MapEntry<String, dynamic>> _filterNotifications(List<MapEntry<String, dynamic>> allNotifications) {
    try {
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
      print(" Error filtering notifications: $e");
      return [];
    }
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
                    _fetchNotifications(userId);
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
            child: StreamBuilder(
              stream: _databaseRef.onValue,
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

                return FutureBuilder<List<MapEntry<String, dynamic>>>(
                  future: _fetchNotifications(userId),
                  builder: (context, futureSnapshot) {
                    if (futureSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (futureSnapshot.hasError) {
                      return const Center(child: Text('Error loading notifications.'));
                    }

                    // Get all notifications
                    final allNotifications = futureSnapshot.data ?? [];

                    allNotifications.sort((a, b) {
                      try {
                        DateTime timeA = DateFormat('HH:mm:ss').parse(a.value['time']);
                        DateTime timeB = DateFormat('HH:mm:ss').parse(b.value['time']);
                        return timeB.compareTo(timeA);
                      } catch (e) {
                        print(" Error parsing time: $e");
                        return 0;
                      }
                    });

                    final filteredNotifications = allNotifications.where((entry) {
                      try {
                        DateTime notificationDate = DateFormat('yyyy-MM-dd').parse(entry.value['date']);
                        if (_startDate != null && _endDate != null) {
                          return notificationDate.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
                              notificationDate.isBefore(_endDate!.add(const Duration(days: 1)));
                        }
                        return true; // If no date range is selected, show all notifications
                      } catch (e) {
                        return false;
                      }
                    }).toList();

                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      children: [
                        // ✅ Header for Notifications
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            "Notifications",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),

                        // ✅ Show "No Notifications" message if no results match the selected date
                        if (filteredNotifications.isEmpty)
                          const Text("No notifications available for the selected date range."),

                        // ✅ Display filtered notifications
                        ...filteredNotifications.map((entry) {
                          final data = entry.value as Map<dynamic, dynamic>? ?? {};
                          final userId = data['userId'] ?? 'Unknown User';
                          final name = data['name'] ?? 'Unknown Name';
                          final status = data['status'] ?? 'Unknown Status';
                          final time = data['time'] ?? 'Unknown Time';
                          final message = data['msg'] ?? '';
                          final date = data['date'] ?? '';

                          if (message.isNotEmpty) {
                            return NotificationItem(
                              userId: userId,
                              message: "$name $status $time",
                              date: date,
                            );
                          }
                          return const SizedBox();
                        }),
                      ],
                    );
                  },
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
            color: Colors.transparent,
            shape: const CircularNotchedRectangle(),
            notchMargin: 8.0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
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
                          MaterialPageRoute(builder: (context) => NotificationScreenn()),
                        );
                      },
                    ),
                  ), IconButton(
                    icon: const Icon(Icons.home, color: Colors.black),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => uDashboardScreen()),
                      );
                    },
                  ),

                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => UtilityProfile()),
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

