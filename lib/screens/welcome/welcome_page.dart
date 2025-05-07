import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/authenticate/authinticate.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA), // Light blue background
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                child: Icon(Icons.home, size: 50, color: Colors.blueAccent),
              ),
              const SizedBox(height: 30),
              const Text(
                'Welcome to\nRoommate Management 🏡',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Find your perfect roommate.\nShare expenses.\nOrganize tasks.\nLive happily together!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const Authentic(showSignInFirst: true),
                    ),
                  );
                },
                child: const Text('Sign In', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const Authentic(showSignInFirst: false),
                    ),
                  );
                },
                child: const Text('Sign Up', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blueAccent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: const BorderSide(color: Colors.blueAccent),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
