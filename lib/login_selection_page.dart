import 'package:flutter/material.dart';
import 'dart:math';
import 'doctor_login_page.dart';
import 'staff_login_page.dart';
import 'glassmorphism.dart';
import 'responsive_helper.dart';

class LoginSelectionPage extends StatelessWidget {
  const LoginSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A237E), // Deep blue
              Color(0xFF3949AB), // Purple-blue
              Color(0xFF3F51B5), // Indigo
              Color(0xFF2196F3), // Blue
              Color(0xFF00BCD4), // Cyan
              Color(0xFF4CAF50), // Green
            ],
          ),
        ),
        child: Stack(
          children: [
            const _MolecularPolyhedrons(),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Medical App',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Select Login Type',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 60),
                      GlassMorphism(
                        blur: 20,
                        opacity: 0.1,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.8,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const DoctorLoginPage()),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                    backgroundColor: Colors.white.withAlpha(51),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'Doctor Login',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const StaffLoginPage()),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                    backgroundColor: Colors.white.withAlpha(51),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'Staff Login',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MolecularPolyhedrons extends StatelessWidget {
  const _MolecularPolyhedrons();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(8, (index) {
        final random = Random(index + 100);
        return Positioned(
          left: 50 + random.nextDouble() * 200,
          top: 150 + random.nextDouble() * 400,
          child: Transform.rotate(
            angle: random.nextDouble() * 2 * pi,
            child: Container(
              width: 20 + random.nextDouble() * 30,
              height: 20 + random.nextDouble() * 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.lightBlue.withAlpha(26),
                border: Border.all(
                  color: Colors.lightBlueAccent.withAlpha(77),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.lightBlueAccent.withAlpha(51),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(204),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withAlpha(128),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
