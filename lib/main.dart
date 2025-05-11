import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzData;

import 'firebase_options.dart';
import 'package:flutter_application_1/config/api_keys.dart';
import 'package:flutter_application_1/services/auth.dart';
import 'package:flutter_application_1/theme/theme.dart';

// Screens
import 'package:flutter_application_1/screens/wrapper.dart';
import 'package:flutter_application_1/screens/profile/profile_screen.dart';
import 'package:flutter_application_1/screens/roommates/roommates_screen.dart';
import 'package:flutter_application_1/screens/shopping/shopping_list.dart';
import 'package:flutter_application_1/screens/tasks/tasks_page.dart';
import 'package:flutter_application_1/screens/chat/chat_page.dart';
import 'package:flutter_application_1/screens/calendar/calendar_page.dart';
import 'package:flutter_application_1/screens/bills/bills_page.dart';
import 'package:flutter_application_1/screens/reminders/reminders_page.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase init
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Gemini AI init
  Gemini.init(apiKey: geminiApiKey);

  // Timezone init for scheduling notifications
  tzData.initializeTimeZones();

  // Local notification setup
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

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
        theme: buildAppTheme(),
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => Wrapper(),
          '/profile': (context) => ProfileScreen(),
          '/roommates': (context) => RoommatesScreen(),
          '/shopping': (context) => ShoppingListPage(),
          '/tasks': (context) => TasksPage(),
          '/chat': (context) => ChatPage(),
          '/calendar': (context) => CalendarPage(),
          '/bills': (context) => BillsPage(),
          '/reminders': (context) => RemindersPage(),
        },
      ),
    );
  }
}
