import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/auth.dart'; // Import your Auth Service

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthsService _auth =
        AuthsService(); // Create instance of Auth Service

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Colors.brown[400],
        elevation: 0.0,
        actions: [
          TextButton.icon(
            onPressed: () async {
              await _auth.signOut(); // Call sign out function
            },
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
            ),
            label: const Text(
              'Logout',
              style: TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
      body: const Center(
        child: Text('Home Page'),
      ),
    );
  }
}
