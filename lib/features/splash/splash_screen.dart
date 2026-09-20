import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _logoOpacity = 0.0;
  double _textOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _startAnimation();
    _checkLoginStatus();
  }

  void _startAnimation() {
    Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _logoOpacity = 1.0;
        });
      }
    });

    Timer(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _textOpacity = 1.0;
        });
      }
    });
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('authToken');

    if (token != null && token.isNotEmpty) {
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    } else {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/onboarding', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedOpacity(
              opacity: _logoOpacity,
              duration: const Duration(milliseconds: 1000),
              child: Image.asset(
                'assets/images/logo_ringkas.webp',
                width: 250,
                height: 250,
              ),
            ),
            AnimatedOpacity(
              opacity: _textOpacity,
              duration: const Duration(milliseconds: 800),
              child: Transform.translate(
                offset: const Offset(0, -50),
                child: const Text(
                  "RINGKAS",
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
