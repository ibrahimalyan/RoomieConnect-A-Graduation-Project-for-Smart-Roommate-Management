import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/user.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/screens/authenticate/authinticate.dart';
import 'package:flutter_application_1/screens/home/home.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    // return either home or authenticate widget
    if (user == null) {
      return const Authinticate();
    } else {
      return const Home(); // Replace with your home widget
    }
  }
}
