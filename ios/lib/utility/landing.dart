import 'dart:async'; // For Timer
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'dart:math' as m_a_t_h;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification.dart';
import 'utilityprofile.dart';
import 'package:smartbin/main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(uDashboardScreen());
}

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: uDashboardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class uDashboardScreen extends StatefulWidget {
  const uDashboardScreen({super.key});

  @override
  State<uDashboardScreen> createState() => _uDashboardScreenState();
}

class _uDashboardScreenState extends State<uDashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Timer _timer;
  String currentTime = '';
  int _currentIndex = 0; // For tracking active navigation item
  double bioBinPercentage = 67; // Biodegradable Waste percentage
  double nonBioBinPercentage = 37; // Non-Biodegradable Waste percentage

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(); // Loop the animation

    // Start timer to update the time
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      currentTime = "${now.hour.toString().padLeft(2, '0')}:"
          "${now.minute.toString().padLeft(2, '0')}:"
          "${now.second.toString().padLeft(2, '0')}  ";

    });
    _checkUserLogin();  // Corrected method name
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer.cancel(); // Cancel the timer to prevent memory leaks
    super.dispose();
  }

  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref().child('users');
  String _name = '';
  String userId = '';



  Future<void> _checkUserLogin() async {  // Corrected method name and removed 'late'
    User? user = FirebaseAuth.instance.currentUser; // Check if user is logged in

    if (user != null) {
      userId = user.uid; // Get the logged-in user's UID
      await _fetchName(userId);
    }
  }

  Future<void> _fetchName(String userId) async {
    final snapshot = await _usersRef.child(userId).get();
    final data = snapshot.value as Map<dynamic, dynamic>?;

    setState(() {
      _name = data!['name']; // Directly access the name since we assume it always exists
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Stack(
        children: [
          // Top background amber container
          Container(
            height: MediaQuery.of(context).size.height / 3.2,
            color: Colors.amber.withOpacity(0.57),
          ),
          SingleChildScrollView( // Added to make the content scrollable
            child: Column(
              children: [
                const SizedBox(height: 40),
                Image.asset(
                  'assets/logo.png',
                  width: 60,
                  height: 50,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
                // Display current time and date
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.black,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            currentTime,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.black,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 65),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
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
                            child: Text(
                              'HELLO $_name\nWELCOME TO SMARTBIN!',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            height: 60,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'MAKE THE CAMPUS CLEANER!',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: -70,
                      right: 1,
                      child: Image.asset(
                        'assets/landinglogo.png',
                        height: 250,
                        width: 180,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Biodegradable Waste Container
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16), // Left and right padding of 16
                      child: Container(
                        width: double.infinity,
                        height: 120,
                        margin: const EdgeInsets.symmetric(vertical: 10), // Spacing between containers
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned.fill(
                                child: AnimatedBuilder(
                                  animation: _controller,
                                  builder: (context, child) {
                                    return CustomPaint(
                                      painter: WavePainter(
                                        _controller.value * 2 * m_a_t_h.pi,
                                        bioBinPercentage,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Biodegradable Waste Level',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  Text(
                                    '${bioBinPercentage.toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Add other components here, with the same pattern for padding if needed
// 5kg Container
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16), // Left and right padding of 16
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            'The bin has reached 5 kilograms',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),

                    // Non-Biodegradable Waste Container
                    // Non-Biodegradable Waste Container
                    SizedBox(height: 50),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16), // Left and right padding of 16
                      child: Container(
                        width: double.infinity,
                        height: 120,
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned.fill(
                                child: AnimatedBuilder(
                                  animation: _controller,
                                  builder: (context, child) {
                                    return CustomPaint(
                                      painter: WavePainter(
                                        _controller.value * 2 * m_a_t_h.pi,
                                        nonBioBinPercentage,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Non-Biodegradable Waste Level',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  Text(
                                    '${nonBioBinPercentage.toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),



// 5kg Container

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16), // Left and right padding of 16
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            'The bin has reached 5 kilograms',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),

                  ],
                ),

              ],
            ),
          ),
        ],
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
                    MaterialPageRoute(builder: (context) => NotificationScreenn()),
                  );
                },
              ),
              Container(
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.home, color: Colors.black),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => uDashboardScreen()),
                    );
                  },
                ),
              ),


              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => UtilityProfile()),
                  );
                },
                child: Image.asset(
                  'assets/profile picture.png',
                  fit: BoxFit.cover,
                  height: 40,
                  width: 40,
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}



class WavePainter extends CustomPainter {
  final double wavePhase;
  final double percentage;

  WavePainter(this.wavePhase, this.percentage);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.fill;

    final path = Path();

    // Set the base wave height based on the percentage
    double waveHeight = size.height * (1 - (percentage / 100));

    // Ensure wave height stays within the bounds of the container
    waveHeight = waveHeight.clamp(0.0, size.height);

    // Start the path from the bottom-left corner
    path.moveTo(0, size.height); // Bottom-left corner of the container
    path.lineTo(0, waveHeight);   // Start of wave based on percentage

    // Apply sinusoidal curve with controlled fluctuation
    path.quadraticBezierTo(
      size.width * 0.25,
      waveHeight - 5 * m_a_t_h.sin(wavePhase + 1),  // Controlled fluctuation amplitude
      size.width * 0.5,
      waveHeight,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      waveHeight + 5 * m_a_t_h.sin(wavePhase + 2),  // Controlled fluctuation amplitude
      size.width,
      waveHeight,
    );

    path.lineTo(size.width, size.height);  // Draw line to bottom-right corner
    path.close();  // Close the path

    canvas.drawPath(path, paint);  // Paint the wave onto the canvas
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;  // Repaint on animation cycle
  }
}
