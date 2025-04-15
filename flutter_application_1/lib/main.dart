import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_application_1/screens/wrapper.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/services/auth.dart';
import 'package:flutter_application_1/models/user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamProvider<User?>.value(
      // <-- Nullable User
      initialData: null, // <-- Provide initial data
      value: AuthsService().user, // <-- Your auth stream
      child: MaterialApp(
        home: const Wrapper(),
      ),
    );
  }
}
