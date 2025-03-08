import 'package:flutter/material.dart';
import 'super_admin_dashboard.dart';
import 'notification.dart'; // Use as needed
import 'landing.dart';

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
  String selectedFilter = 'Sort by Date';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow[700],
        title: const Text('History Logs'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Icon with Popup Menu
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.filter_alt, color: Colors.black),
                    onSelected: (String value) {
                      setState(() {
                        selectedFilter = value;
                      });
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'Sort by Date',
                        child: Text('Sort by Date'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'Sort by Time',
                        child: Text('Sort by Time'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'Sort by Name',
                        child: Text('Sort by Name'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'Newest',
                        child: Text('Newest'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'Oldest',
                        child: Text('Oldest'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // History Logs
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: historyLogs.length,
              itemBuilder: (context, index) {
                final log = historyLogs[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          log['message']!,
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          log['time']!,
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
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

const historyLogs = [
  {'message': 'Trash bin has been collected', 'time': '5:21 PM'},
  {'message': 'Sharmaine logged out', 'time': '4:56 PM'},
  {'message': 'Dellomes logged in', 'time': '4:29 PM'},
  {'message': 'Trash bin has been collected', 'time': '4:20 PM'},
  {'message': 'Eloi logged out', 'time': '4:13 PM'},
];