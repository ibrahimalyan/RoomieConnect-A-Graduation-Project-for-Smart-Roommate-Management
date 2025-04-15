import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/authenticate/sign_in.dart';

class Authinticate extends StatefulWidget {
  const Authinticate({super.key});

  @override
  State<Authinticate> createState() => _AuthinticateState();
}

class _AuthinticateState extends State<Authinticate> {
  @override
  Widget build(BuildContext context) {
    return const SignIn(); // Return SignIn page
  }
}
