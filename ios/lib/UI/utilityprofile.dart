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
      home: UtilityProfile(),
    );
  }
}

class UtilityProfile extends StatefulWidget {
  const UtilityProfile({super.key});

  @override
  _UtilityProfileState createState() => _UtilityProfileState();
}

class _UtilityProfileState extends State<UtilityProfile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          Stack(
            children: [
              // Top background amber container
              Container(
                height: MediaQuery.of(context).size.height / 3.2,
                color: Colors.amber.withOpacity(0.57),
              ),
              Column(
                children: [
                  const SizedBox(height: 40),
                  Image.asset(
                    'assets/logo.png',
                    width: 60,
                    height: 60,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            // Lighter Amber gradient header
                            Container(
                              width: double.infinity,
                              height: 60,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFF1C74B),
                                    Color(0xFFD19A29),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                              ),
                              padding: const EdgeInsets.all(16),
                            ),
                            // Gray section below amber
                            Container(
                              width: double.infinity,
                              height: 60,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Text(
                                    'SHARMAINE BANQUILES',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Utility Staff',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Profile icon above the container
                      Positioned(
                        top: -20,
                        left: MediaQuery.of(context).size.width / 2 - 30,
                        child: MouseRegion(
                          onEnter: (_) {
                            setState(() {
                              _isHovered = true;
                            });
                          },
                          onExit: (_) {
                            setState(() {
                              _isHovered = false;
                            });
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor:
                                Colors.grey.withOpacity(_isHovered ? 0.6 : 0),
                                backgroundImage:
                                const AssetImage('assets/profile picture.png'),
                              ),
                              if (_isHovered)
                                const Icon(
                                  Icons.edit,
                                  size: 30,
                                  color: Colors.black,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40), // Adjusted vertical spacing
          // ACCOUNT MANAGEMENT text with left icon and right arrow
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Left Icon
                    const Icon(
                      Icons.account_circle, // Icon for account management
                      size: 30,
                      color: Colors.black,
                    ),
                    const SizedBox(width: 10), // Space between icon and text
                    const Text(
                      'ACCOUNT MANAGEMENT',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                // Right Arrow Icon
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.black,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20), // Additional spacing for alignment
        ],
      ),
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
              InkWell(
                onTap: () {
                  // Handle notification tap
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 20, // Inner circle radius (green)
                      backgroundColor: Colors.green[300], // Green background
                    ),
                    const CircleAvatar(
                      radius: 20, // Outer circle radius (black)
                      backgroundColor: Colors.black, // Black background
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
                      radius: 20, // Inner circle radius (green)
                      backgroundColor: Colors.green[300], // Green background
                    ),
                    const CircleAvatar(
                      radius: 20, // Outer circle radius (black)
                      backgroundColor: Colors.black, // Black background
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
                      radius: 20, // Inner circle radius (green)
                      backgroundColor: Colors.green[300], // Green background
                    ),
                    const CircleAvatar(
                      radius: 20, // Outer circle radius (black)
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
      ),
    );
  }
}
