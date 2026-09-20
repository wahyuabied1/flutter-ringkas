import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ✅ Logo Ringkas
            SizedBox(
              height: 180,
              child: Image.asset(
                'assets/images/Logo RingkasRM.png',
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              "Selamat Datang di RINGKAS",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),

            const Text(
              "Kelola uang jadi lebih mudah,\ndan bebas ribet setiap hari!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),

            const SizedBox(height: 40),

            // ✅ TOMBOL REGISTER
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D9E85),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pushNamed('/register');
                },
                child: const Text("Daftar", style: TextStyle(fontSize: 16)),
              ),
            ),

            const SizedBox(height: 12),

            // ✅ TOMBOL LOGIN
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF5D9E85), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pushNamed('/login');
                },
                child: const Text(
                  "Login",
                  style: TextStyle(fontSize: 16, color: Color(0xFF5D9E85)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
