import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HistoryLogsScreen(),
    );
  }
}

class HistoryLogsScreen extends StatefulWidget {
  const HistoryLogsScreen({super.key});

  @override
  _HistoryLogsScreenState createState() => _HistoryLogsScreenState();
}

class _HistoryLogsScreenState extends State<HistoryLogsScreen> {
  String selectedFilter = 'Sort by Date';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Column(
          children: [
            Container(
              color: Colors.amber,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const Text(
                'HISTORY LOGS',
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
          Expanded(
            child: ListView.builder(
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
                          style:
                              const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: Padding(
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
                  child:
                      const Icon(Icons.person, color: Colors.white, size: 18),
                ),
                onPressed: () {
                  // Add profile functionality here
                },
              ),
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
