import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartBin App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _displayedEmail;

  void _login() {
    final email = _emailController.text;
    final password = _passwordController.text;

    // Simple validation
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both email and password.')),
      );
      return;
    }

    // Optionally, validate email format
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }

    // Set the displayed email and clear the input fields
    setState(() {
      _displayedEmail = email; // Store the email
    });

    // Simulate a successful login
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Login successful!')),
    );

    // Clear the text fields
    _emailController.clear();
    _passwordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/Group 2.png',
          height: 40, // Set the desired height
          fit: BoxFit.contain, // Adjusts the image to maintain aspect ratio
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                alignment: Alignment.topCenter, // Align the image to the top center
                child: Image.asset(
                  'assets/binlogo.png',
                  height: 300, // Adjust height as needed
                  fit: BoxFit.contain, // Maintains aspect ratio
                ),
              ),
              const SizedBox(height: 1.0), // Add space below the image
              // Text below the image
              const Text(
                'Welcome to SmartBin!', // Replace with your desired text
                style: TextStyle(
                  fontSize: 20, // Adjust font size as needed
                  fontWeight: FontWeight.bold, // Makes the text bold
                ),
              ),
              const SizedBox(height: 5.0), // Add space below the image
              // Text below the image
              const Opacity(
                opacity: 0.5, // Set the desired opacity between 0.0 and 1.0
                child: Text(
                  'Make the world cleaner', // Replace with your desired text
                  style: TextStyle(
                    fontSize: 15, // Adjust font size as needed
                    fontWeight: FontWeight.bold, // Makes the text bold
                  ),
                ),
              ),
              const SizedBox(height: 10.0),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(68)),
                  ),
                ),

                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 16.0),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(68)),
                  ),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // Sets the button's background color to green
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(68), // Adjust the radius as needed
                  ),
                ),
                child: const Text('Login'),
              ),
              const SizedBox(height: 24.0),
              // Display the email if login is successful
              if (_displayedEmail != null)
                Text(
                  'Email: $_displayedEmail',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


