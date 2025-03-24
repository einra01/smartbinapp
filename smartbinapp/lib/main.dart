import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartbin/utility/utilitylanding.dart';
import 'super_admin/landing.dart';
import 'Forgot.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SortMatic App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AppInitializer(),
    );
  }
}
// starting loading screen
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});
  @override
  AppInitializerState createState() => AppInitializerState();
}
class AppInitializerState extends State<AppInitializer> {
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

// users saved credential
  Future<void> _initializeApp() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedEmail = prefs.getString('previousEmail');
    String? savedPassword = prefs.getString('previousPassword');

    FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    if (user != null) {
      // User already logged in
      _navigateBasedOnRole(user.uid);
    } else if (savedEmail != null && savedPassword != null) {
      // Try logging in with saved credentials
      try {
        UserCredential userCredential = await auth.signInWithEmailAndPassword(
          email: savedEmail,
          password: savedPassword,
        );
        print('Auto login successful: ${userCredential.user?.uid}');
        _navigateBasedOnRole(userCredential.user!.uid);
      } on FirebaseAuthException catch (e) {
        print('Auto login failed: ${e.message}');
        _navigateToLogin();
      }
    } else {
      // No user logged in and no saved credentials
      _navigateToLogin();
    }
  }
  // Function to navigate based on user role
  Future<void> _navigateBasedOnRole(String userId) async {
    final userRef = FirebaseDatabase.instance.ref('users/$userId');
    final userSnapshot = await userRef.get();

    if (!userSnapshot.exists) {
      _showSnackbar('User not found.');
      _navigateToLogin();
      return;
    }
    final user = Map<String, dynamic>.from(userSnapshot.value as Map);
    final role = user['role'];
    final userName = user['name'] ?? 'Unknown User';
    // Record login event
    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd').format(now);
    final formattedTime = DateFormat('HH:mm:ss').format(now);
    final notificationsRef = FirebaseDatabase.instance.ref('notifications/logged/$userId').push();
    await notificationsRef.set({
      'name': userName.toString(),
      'userId': userId,
      'status': 'Logged In',
      'date': formattedDate,
      'time': formattedTime,
      'msg': '$userName Logged In',
    });

    // Navigate based on role
    if (role == 'Admin') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } else if (role == 'Excellent') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const uDashboardScreen()),
      );
    } else {
      _showSnackbar('Invalid role. Access denied.');
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading ? const LoadingScreen() : const LoginPage();
  }
}

// starting loading display when opening the app
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              height: 80,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: Colors.blue),
          ],
        ),
      ),
    );
  }
}


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    final email = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackbar('Please enter both email and password.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      String userId = userCredential.user!.uid;
      //users data credential save
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('previousEmail', email);
      await prefs.setString('previousPassword', password); // Store securely

      final now = DateTime.now();
      final formattedDate = DateFormat('yyyy-MM-dd').format(now);
      final formattedTime = DateFormat('HH:mm:ss').format(now);

      final userRef = FirebaseDatabase.instance.ref('users/$userId');
      final userSnapshot = await userRef.get();

      if (userSnapshot.exists) {
        final user = Map<String, dynamic>.from(userSnapshot.value as Map);
        final role = user['role'];
        final userName = user['name'] ?? 'Unknown User';
        final status = user['status'] ?? 'active';

        if (status == 'Inactive') {
          _showDeactivatedPopup();
          return;
        }

        final notificationsRef =
        FirebaseDatabase.instance.ref('notifications/logged/$userId');
        final newLoginRef = notificationsRef.push();
        await newLoginRef.set({
          'name': userName.toString(),
          'userId': userId,
          'status': 'Logged In',
          'date': formattedDate,
          'time': formattedTime,
          'msg': '$userName Logged In',
        });

        if (role == 'Admin') {
          _showSnackbar('Welcome, Admin $userName!');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        } else if (role == 'Excellent') {
          _showSnackbar('Welcome, $userName!');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const uDashboardScreen()),
          );
        } else {
          _showSnackbar('Invalid role. Access denied.');
        }
        return;
      }

      _showSnackbar('Invalid username or password.');
    } on FirebaseAuthException catch (e) {
      _handleFirebaseAuthError(e);
    } catch (e) {
      _showSnackbar('Unexpected error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  // modal pop up when users status is deactivated
  void _showDeactivatedPopup() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing by tapping outside
      builder: (context) {
        return AlertDialog(
          title: const Text('Account Deactivated'),
          content: const Text(
            'Your account has been deactivated. Please contact support for assistance.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                FirebaseAuth.instance.signOut(); // Sign out the user
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
  // error message
  void _handleFirebaseAuthError(FirebaseAuthException e) {
    String errorMessage;
    switch (e.code) {
      case 'user-not-found':
        errorMessage = 'No user found for that email.';
        break;
      case 'wrong-password':
        errorMessage = 'Incorrect password.';
        break;
      case 'network-request-failed':
        errorMessage = 'Network error. Please try again.';
        break;
      default:
        errorMessage = 'An error occurred: ${e.message ?? e.code}';
    }
    _showSnackbar(errorMessage);
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _navigateToForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => Forgot()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/logo.png',
          height: 40,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Image.asset('assets/img.png', height: 250),
              const SizedBox(height: 20),
              const Text(
                'Welcome to SortMatic!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Opacity(
                opacity: 0.5,
                child: Text(
                  'Make the world cleaner',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20.0),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(68)),
                  ),
                ),
              ),
              const SizedBox(height: 15.0),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(68)),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: _navigateToForgotPassword,
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login, // Disable button when loading
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5AF0F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(68),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14), // Adjust padding
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text('LOGIN'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
