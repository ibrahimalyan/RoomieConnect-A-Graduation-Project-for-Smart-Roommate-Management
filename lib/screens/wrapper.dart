import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_application_1/screens/home/home.dart';
import 'package:flutter_application_1/screens/welcome/welcome_page.dart';

class Wrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    // return either Home or Authenticate
    if (user == null) {
      return WelcomePage(); // Not logged in
    } else {
      return HomePage(); // Logged in
    }
  }
}
