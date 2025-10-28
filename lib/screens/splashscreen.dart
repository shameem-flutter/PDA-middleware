import 'package:flutter/material.dart';
import 'package:pda/constants/color_constants.dart';
import 'package:pda/services/authwrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    final navigator = Navigator.of(context);
    Future.delayed(Duration(seconds: 2), () {
      navigator.pushReplacement(
        MaterialPageRoute(builder: (context) => AuthWrapper()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          height: 105,
          child: Text(
            "Welcome to\n InventoryPro ;)",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
