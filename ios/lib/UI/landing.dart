import 'dart:async'; // For Timer
import 'package:flutter/material.dart';
import 'dart:math' as m_a_t_h;

void main() {
  runApp(const LandingPage());
}

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: DashboardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Timer _timer;
  String currentTime = '';
  int _currentIndex = 0; // For tracking active navigation item
  double bioBinPercentage = 52; // Biodegradable Waste percentage
  double nonBioBinPercentage = 88; // Non-Biodegradable Waste percentage

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
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer.cancel(); // Cancel the timer to prevent memory leaks
    super.dispose();
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
          Center(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between time and date
                  children: [
                    // Time on the left side
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16), // Optional padding
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time, // Time icon
                              size: 16,
                              color: Colors.black,
                            ),
                            const SizedBox(width: 8), // Space between icon and text
                            Text(
                              currentTime,
                              style: const TextStyle(
                                fontSize: 12,  // Smaller font size
                                fontWeight: FontWeight.normal,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Date on the right side
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16), // Optional padding
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today, // Calendar icon
                              size: 16,
                              color: Colors.black,
                            ),
                            const SizedBox(width: 8), // Space between icon and text
                            Text(
                              "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                              style: const TextStyle(
                                fontSize: 12,  // Smaller font size for date
                                fontWeight: FontWeight.normal,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
                      decoration: const BoxDecoration(
                      gradient: LinearGradient(
                      colors: [
                      Color(0xFFF1C74B), // Lighter amber
                      Color(0xFFD19A29), // Lighter dark amber
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
                            child: const Text(
                              'HELLO [NAME MO TO]',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Gray section below amber
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
                              'WELCOME TO SMARTBIN!',
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
                    // Positioned logo
                    Positioned(
                      top: -70,
                      right: 1,
                      child: Image.asset(
                        'assets/trashlogo.png',
                        height: 250,
                        width: 180,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),

            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Biodegradable Waste Container
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16), // Left and right padding of 16
                  child: Container(
                    width: double.infinity,
                    height: 80,
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
                          fontSize: 10,
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16), // Left and right padding of 16
                  child: Container(
                    width: double.infinity,
                    height: 80,
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
                          fontSize: 10,
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
                    // Green circle (bottom)
                    CircleAvatar(
                      radius: 20,  // Inner circle radius (green)
                      backgroundColor: Colors.green[300],  // Green background
                    ),
                    // Black circle (middle)
                    const CircleAvatar(
                      radius: 20,  // Outer circle radius (black)
                      backgroundColor: Colors.black,  // Black background
                    ),
                    // Image on top (foreground)
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
                    // Green circle (bottom)
                    CircleAvatar(
                      radius: 20,  // Inner circle radius (green)
                      backgroundColor: Colors.green[300],  // Green background
                    ),
                    // Black circle (middle)
                    const CircleAvatar(
                      radius: 20,  // Outer circle radius (black)
                      backgroundColor: Colors.black,  // Black background
                    ),
                    // Image on top (foreground)
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
                    // Green circle (bottom)
                    CircleAvatar(
                      radius: 20,  // Inner circle radius (green)
                      backgroundColor: Colors.green[300],  // Green background
                    ),
                    // Black circle (middle)
                    const CircleAvatar(
                      radius: 20,  // Outer circle radius (black)
                    ),
                    // Image on top (foreground)
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
