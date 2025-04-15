import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/auth.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final AuthsService _auth = AuthsService();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[100],
      appBar: AppBar(
        title: const Text('Sign In'),
        backgroundColor: Colors.brown[400],
        elevation: 0.0,
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 50),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pink[400], // Button color
          ),
          child: const Text('Sign In Anonymously'),
          onPressed: () async {
            dynamic result = await _auth.signInAnonymously();
            if (result == null) {
              print('Error signing in');
            } else {
              print('Signed in: ');
              print(result.uid);
            }
          },
        ),
      ),
    );
  }
}
