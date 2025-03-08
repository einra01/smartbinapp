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
      home: AccountDeactivate(),
    );
  }
}

class AccountDeactivate extends StatelessWidget {
  const AccountDeactivate({super.key});

  // Header row with reduced vertical space
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
            'ACTION',
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
  Widget _buildUserRow(
      String name,
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

  Widget _buildBottomNavigationBar() {
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
                // Handle notification tap
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
                // Handle home tap
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
                // Handle profile tap
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

  // Confirmation dialog for deactivating account
  Future<void> _showDeactivationDialog(BuildContext context, String name) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent dismissal when tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFD9D9D9), // Light gray background
          content: Column(
            mainAxisSize: MainAxisSize.min, // Ensures the content is properly sized
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5), // Box shape with 5 radius
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5), // Box shape with 5 radius
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
  Future<void> _showReactivationDialog(BuildContext context, String name) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent dismissal when tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFD9D9D9), // Light gray background
          content: Column(
            mainAxisSize: MainAxisSize.min, // Ensures the content is properly sized
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2), // Box shape with 5 radius
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5), // Box shape with 5 radius
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


  @override
  Widget build(BuildContext context) {
    // Sample list of users
    final userList = [
      {'name': 'SHARMAINE BANQUILES', 'actionImagePath': 'assets/remove.png'},
      {'name': 'ALVIN GALIT', 'actionImagePath': 'assets/remove.png'},
      {'name': 'ALBERT CABRAL', 'actionImagePath': 'assets/add.png'},
      {'name': 'LESTER MANALON', 'actionImagePath': 'assets/add.png'},
      {'name': 'JOHN ELOI OLIVAR', 'actionImagePath': 'assets/remove.png'},
      {'name': 'LAWRENCE RAMOS', 'actionImagePath': 'assets/remove.png'},

      // Add more users here...
    ];

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Column(
          children: [
            Container(
              color: Colors.grey[200],
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Image.asset(
                'assets/logo.png',
                height: 50,
              ),
            ),
            Container(
              color: Colors.amber,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: const Text(
                'USERS',
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildHeaderRow(),
            const Divider(thickness: 1),
            ListView.builder(
              shrinkWrap: true, // Ensures it takes the available space
              physics: NeverScrollableScrollPhysics(), // Prevents inner scrolling
              itemCount: userList.length,
              itemBuilder: (context, index) {
                final user = userList[index];
                return _buildUserRow(
                  user['name']!,
                  user['actionImagePath']!,
                  backgroundColor: index % 2 == 0 ? const Color(0xFFD9D9D9) : const Color(0xFFF1F1F1),
                  onActionTap: () {
                    if (user['actionImagePath'] == 'assets/remove.png') {
                      _showDeactivationDialog(context, user['name']!);
                    } else if (user['actionImagePath'] == 'assets/add.png') {
                      _showReactivationDialog(context, user['name']!);
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
}
