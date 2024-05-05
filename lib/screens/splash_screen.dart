import 'dart:developer';

import 'package:chatie/api/apis.dart';
import 'package:chatie/screens/auth/login_screen.dart';
import 'package:chatie/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Splash Screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  late MediaQueryData mq;

  @override
  void initState() {
    super.initState();
    checkAuthentication();
  }

  Future<void> checkAuthentication() async {
    await Future.delayed(const Duration(seconds: 2),() {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.white,
          statusBarColor: Colors.white));

      if (APIs.auth.currentUser != null) {
        log('User is already signed in.');
        // Navigate to HomeScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        log('User is not signed in.');
        // Navigate to LoginScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }

    );
    // Simulating a delay


  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context); // Initialize mq here

    return Scaffold(
      // App Bar
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Welcome To My Chat App"),
      ),
      body: Stack(
        children: [
          // App logo
          Positioned(
            top: mq.size.height * .15,
            right: mq.size.width * .25,
            width: mq.size.width * .5,
            child: Image.asset("assets/icon.png"),
          ),
          Positioned(
            bottom: mq.size.height * .15,
            width: mq.size.width,
            child: const Text(
              "Made In Pakistan With Love ❤️",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.black87,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}