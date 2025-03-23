import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_profile.dart';
import 'notification.dart'; // Use as needed
import 'landing.dart';
import 'package:intl/intl.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HistoryLogsScreen1(),
    );
  }
}

class HistoryLogsScreen1 extends StatefulWidget {
  const HistoryLogsScreen1({super.key});

  @override
  _HistoryLogsScreenState createState() => _HistoryLogsScreenState();
}
class _HistoryLogsScreenState extends State<HistoryLogsScreen1> {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref("notifications");
  String _name = 'Loading...'; // Initial loading state
  String _profileImageUrl = '';
  String userId = '';
  String time= '';
  DateTime? _startDate;
  DateTime? _endDate;



  @override
  void initState() {
    super.initState();
    _fetchUser();
    _setDefaultDate();
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
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade300, // Light Amber
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
      final snapshot = await _databaseRef.child(userId).get();
      final data = snapshot.value as Map<dynamic, dynamic>?;

      print("User data: $data");  // Add this to log the fetched data

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

  @override
  Widget build(BuildContext context) {
    String dateRangeText = _startDate != null && _endDate != null
        ? "${DateFormat('MMM dd').format(_startDate!)} - ${DateFormat('MMM dd').format(_endDate!)}"
        : "Select Date Range";

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          SizedBox(height: 80),
          Container(
            height: MediaQuery.of(context).size.height / 14,
            color: Colors.amber.withOpacity(0.99),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft, // Places the icon on the left
                    child: IconButton(
                      icon: Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center, // Ensures the text is always centered
                    child: Text(
                      "History",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),

            ),

          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SizedBox(
                  width: constraints.maxWidth, // Make sure it takes full width
                  height: 40, // Fixed height to prevent layout shifts
                  child: Stack(
                    clipBehavior: Clip.none, // Prevents cropping issues
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          dateRangeText,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: IconButton(
                          icon: Icon(Icons.calendar_today, color: Colors.black),
                          onPressed: () => _showDateRangePicker(context),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),


          Expanded(
            child: StreamBuilder(
              stream: _databaseRef.child("logged").onValue,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return Center(child: Text('No logs available.'));
                }

                final dynamic data = snapshot.data!.snapshot.value;
                List<Map<String, dynamic>> filteredLogs = [];

                if (data is Map) {
                  data.forEach((userId, userLogs) {
                    if (userLogs is Map) {
                      userLogs.forEach((logKey, logData) {
                        if (logData is Map && logData.containsKey('date')) {
                          DateTime logDate = DateFormat('yyyy-MM-dd').parse(logData['date']);
                          if (_startDate != null && _endDate != null &&
                              logDate.isAfter(_startDate!.subtract(Duration(days: 1))) &&
                              logDate.isBefore(_endDate!.add(Duration(days: 1)))) {
                            filteredLogs.add({
                              'userId': userId,
                              'status': logData['status'],
                              'time': logData['time'],
                              'date': logData['date'],
                            });
                          }
                        }
                      });
                    }
                  });
                }

                filteredLogs.sort((a, b) => (b['time'] ?? '').compareTo(a['time'] ?? ''));

                return filteredLogs.isEmpty
                    ? Center(child: Text('No logs for selected date range.'))
                    : ListView.builder(
                  itemCount: filteredLogs.length,
                  itemBuilder: (context, index) {
                    var log = filteredLogs[index];
                    return FutureBuilder(
                      future: FirebaseDatabase.instance.ref("users/${log['userId']}/name").get(),
                      builder: (context, nameSnapshot) {
                        String displayName = "Unknown User";
                        if (nameSnapshot.hasData && nameSnapshot.data!.value != null) {
                          displayName = nameSnapshot.data!.value.toString();
                        }

                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                          child: ListTile(
                            title: Text(displayName, style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("${log['status']} at ${log['time']}"),
                            trailing: Text(log['date']),
                          ),
                        );
                      },
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

