import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/services/auth.dart';
import 'package:flutter_application_1/utils/notification_service.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

/// HomePage widget that serves as the main screen of the app.

class _HomePageState extends State<HomePage> {
  final AuthService _auth = AuthService();
  String? firstName;

  @override
  void initState() {
    super.initState();
    _loadUserFirstName();
  }

  Future<void> _loadUserFirstName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        setState(() {
          firstName = doc['firstNam'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Roommate Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () async {
              if (kIsWeb) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('🔔 This would show a notification on mobile!'),
                  ),
                );
              } else {
                await showReminderNotification(
                  '🔔 Test Notification',
                  'This is a test local notification from Roommate App.',
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.group),
            onPressed: () => Navigator.pushNamed(context, '/roommates'),
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/profile'),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.onPrimary.withOpacity(0.8),
                child: Icon(Icons.person, color: theme.colorScheme.primary),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/', (route) => false);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              firstName != null ? 'Hello, $firstName! ✨' : 'Hello! ✨',
              style: textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'What would you like to do today?',
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.0,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              children: [
                _buildFeatureCard(context, Icons.shopping_cart, 'Shopping', () {
                  Navigator.pushNamed(context, '/shopping');
                }),
                _buildFeatureCard(context, Icons.task_alt, 'Tasks', () {
                  Navigator.pushNamed(context, '/tasks');
                }),
                _buildFeatureCard(context, Icons.payments, 'Bills & Payments',
                    () {
                  Navigator.pushNamed(context, '/bills');
                }),
                _buildFeatureCard(context, Icons.calendar_today, 'Calendar',
                    () {
                  Navigator.pushNamed(context, '/calendar');
                }),
                _buildFeatureCard(context, Icons.chat, 'Chat', () {
                  Navigator.pushNamed(context, '/chat');
                }),
                _buildFeatureCard(
                    context, Icons.notifications_active, 'Reminders', () {
                  Navigator.pushNamed(context, '/reminders');
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: theme.colorScheme.primary),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
