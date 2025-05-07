import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/authenticate/register.dart';
import 'package:flutter_application_1/screens/authenticate/sign_in.dart';

class Authentic extends StatefulWidget {
  final bool showSignInFirst;
  const Authentic({Key? key, required this.showSignInFirst}) : super(key: key);

  @override
  _AuthenticState createState() => _AuthenticState();
}

class _AuthenticState extends State<Authentic> {
  late bool showSignIn;

  @override
  void initState() {
    super.initState();
    showSignIn = widget.showSignInFirst;
  }

  void toggleView() {
    setState(() => showSignIn = !showSignIn);
  }

  @override
  Widget build(BuildContext context) {
    return showSignIn
        ? SignIn(toggleView: toggleView)
        : Register(toggleView: toggleView);
  }
}
