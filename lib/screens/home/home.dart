import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/auth.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AuthService _auth = AuthService(); // Initialize auth service
    final ThemeData theme = Theme.of(context); // Get the current theme
    final TextTheme textTheme = theme.textTheme; // Get text theme

    return Scaffold(
      appBar: AppBar(
        // Title uses AppBarTheme's titleTextStyle
        title: const Text('Roommate Management'),
        // centerTitle is set in AppBarTheme
        // backgroundColor and foregroundColor are set in AppBarTheme
        actions: [
          IconButton(
            // Icon color inherits from AppBarTheme's foregroundColor
            icon: const Icon(Icons.group),
            onPressed: () {
              Navigator.pushNamed(
                  context, '/roommates'); // Navigate to Roommates
            },
          ),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/profile'); // Navigate to Profile
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: CircleAvatar(
                radius: 18,
                // Use theme colors
                backgroundColor: theme.colorScheme.onPrimary.withOpacity(0.8),
                child: Icon(Icons.person, color: theme.colorScheme.primary),
              ),
            ),
          ),
          IconButton(
            // Icon color inherits from AppBarTheme's foregroundColor
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/', (route) => false);
            },
          ),
        ],
      ),
      // scaffoldBackgroundColor is set in the theme
      body: Padding(
        padding: const EdgeInsets.all(12.0), // Reduced padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, Ibrahim! ✨', // TODO: Replace with dynamic user name
              // Use text theme style
              style: textTheme.headlineMedium,
            ),
            const SizedBox(height: 8), // Reduced spacing
            Text(
              'What would you like to do today?',
              // Use text theme style
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 16), // Reduced spacing
            Expanded(
              child: GridView.count(
                crossAxisCount: 3, // Changed from 2 to 3
                mainAxisSpacing: 12, // Reduced spacing
                crossAxisSpacing: 12, // Reduced spacing
                childAspectRatio: 1.0, // Adjust aspect ratio if needed (width / height)
                physics: const NeverScrollableScrollPhysics(), // Disable scrolling if we expect it to fit
                children: [
                  _buildFeatureCard(
                    context,
                    Icons.shopping_cart,
                    'Shopping',
                    () {
                      Navigator.pushNamed(
                          context, '/shopping'); // ✅ Navigate to Shopping page
                    },
                  ),
                  _buildFeatureCard(
                    context,
                    Icons.task_alt,
                    'Tasks',
                    () {
                      Navigator.pushNamed(context, '/tasks');
                    },
                  ),
                  _buildFeatureCard(
                    context,
                    Icons.payments,
                    'Bills & Payments',
                    () {
                      Navigator.pushNamed(context, '/bills');
                    },
                  ),
                  _buildFeatureCard(
                    context,
                    Icons.calendar_today,
                    'Calendar',
                    () {
                      Navigator.pushNamed(context, '/calendar');
                    },
                  ),
                  _buildFeatureCard(
                    context,
                    Icons.chat,
                    'Chat',
                    () {
                      Navigator.pushNamed(context, '/chat');
                    },
                  ),
                  _buildFeatureCard(
                    context,
                    Icons.notifications_active,
                    'Reminders',
                    () {
                      Navigator.pushNamed(context, '/reminders');
                    },
                  ),
                ],
              ),
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
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;

    return GestureDetector(
      onTap: onTap,
      // Card styling (elevation, shape, color, margin) is inherited from CardTheme
      child: Card(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 40, // Reduced icon size from 50
                // Use theme color
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 8), // Reduced spacing
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0), // Add padding for text wrapping
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  // Use text theme style, maybe slightly smaller
                  style: textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary, // Or onSurfaceColor
                  ),
                  maxLines: 2, // Allow text wrapping
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

