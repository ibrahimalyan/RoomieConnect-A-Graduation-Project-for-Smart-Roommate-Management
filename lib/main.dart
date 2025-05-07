import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart'; // Import your Firebase options
import 'package:flutter_application_1/theme/theme.dart'; // Import the theme
import 'package:flutter_gemini/flutter_gemini.dart'; // Import Gemini
import 'package:flutter_application_1/config/api_keys.dart'; // Import API Key

import 'package:flutter_application_1/services/auth.dart';
import 'package:flutter_application_1/screens/wrapper.dart';
import 'package:flutter_application_1/screens/profile/profile_screen.dart'; // Import your profile screen
import 'package:flutter_application_1/screens/roommates/roommates_screen.dart'; // Import your roommates screen
import 'package:flutter_application_1/screens/shopping/shopping_list.dart'; // Import your shopping list screen
import 'package:flutter_application_1/screens/tasks/tasks_page.dart'; // Import your tasks page
import 'package:flutter_application_1/screens/chat/chat_page.dart'; // Import your chat page
import 'package:flutter_application_1/screens/calendar/calendar_page.dart'; // Import your calendar page
import 'package:flutter_application_1/screens/bills/bills_page.dart'; // Import your bills page
import 'package:flutter_application_1/screens/reminders/reminders_page.dart'; // Import your reminders page

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Initialize Gemini with the API key
  Gemini.init(apiKey: geminiApiKey);

  runApp(const FlutterApplication1());
}

class FlutterApplication1 extends StatelessWidget {
  const FlutterApplication1({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamProvider<User?>.value(
      value: AuthService().user,
      initialData: null,
      child: MaterialApp(
        theme: buildAppTheme(), // Apply the custom theme
        debugShowCheckedModeBanner: false,
        initialRoute: '/', // Start at Wrapper
        routes: {
          '/': (context) => Wrapper(), // 👈 Wrapper is initial
          '/profile': (context) => ProfileScreen(),
          '/roommates': (context) => RoommatesScreen(),
          '/shopping': (context) => ShoppingListPage(),
          '/tasks': (context) => const TasksPage(), // ✅ Add this
          '/chat': (context) => const ChatPage(), // ✅ Add this
          '/calendar': (context) => const CalendarPage(),
          '/bills': (context) => const BillsPage(), // ✅ Add this\
          '/reminders': (context) => const RemindersPage(), // ✅ Add this
        },
      ),
    );
  }
}
