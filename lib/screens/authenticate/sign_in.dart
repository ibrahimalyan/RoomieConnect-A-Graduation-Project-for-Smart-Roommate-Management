import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/auth.dart';
import 'package:flutter_application_1/screens/wrapper.dart';

class SignIn extends StatefulWidget {
  final Function toggleView;
  const SignIn({Key? key, required this.toggleView}) : super(key: key);

  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  // Text field state
  String email = '';
  String password = '';
  String error = '';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;

    return Scaffold(
      // AppBar styling is inherited from theme
      appBar: AppBar(
        title: const Text('Sign In'),
        actions: [
          TextButton.icon(
            // Use theme colors for consistency
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            icon: const Icon(Icons.person),
            label: const Text('Register'),
            onPressed: () {
              widget.toggleView();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50.0, vertical: 20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 20),
              TextFormField(
                // InputDecoration is styled by theme
                decoration: const InputDecoration(labelText: 'Email'), // Use labelText for better UX
                validator: (val) => val!.isEmpty ? 'Enter an email' : null,
                onChanged: (val) {
                  setState(() => email = val);
                },
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              TextFormField(
                // InputDecoration is styled by theme
                decoration: const InputDecoration(labelText: 'Password'), // Use labelText
                obscureText: true,
                validator: (val) =>
                    val!.length < 6 ? 'Enter a password 6+ chars long' : null,
                onChanged: (val) {
                  setState(() => password = val);
                },
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () async {
                    await _showPasswordResetDialog(context, theme, textTheme);
                  },
                  child: Text(
                    'Forgot Password?',
                    style: textTheme.bodyMedium?.copyWith(color: theme.primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                // Style is inherited from theme
                child: const Text('Sign In'), // Text style from theme
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    dynamic result = await _auth.signInWithEmailAndPassword(
                        email.trim(), password.trim());
                    if (result == null) {
                      setState(() =>
                          error = 'Could not sign in with those credentials');
                    } else {
                      // Navigate to Wrapper on success
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => Wrapper()),
                      );
                    }
                  }
                },
                // Remove specific style if theme is sufficient
                // style: ElevatedButton.styleFrom(...)
              ),
              const SizedBox(height: 12),
              if (error.isNotEmpty)
                Text(
                  error,
                  // Use theme color and style for errors
                  style: textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPasswordResetDialog(BuildContext context, ThemeData theme, TextTheme textTheme) async {
    TextEditingController resetEmailController = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          // Use theme styles for AlertDialog
          backgroundColor: theme.dialogBackgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          title: Text('Reset Password', style: textTheme.titleLarge),
          content: TextField(
            controller: resetEmailController,
            // InputDecoration styled by theme
            decoration: const InputDecoration(labelText: 'Enter your email'),
            keyboardType: TextInputType.emailAddress,
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              },
              // Style using theme
              style: TextButton.styleFrom(foregroundColor: theme.primaryColor),
            ),
            ElevatedButton(
              // Style inherited from theme
              child: const Text('Send Email'),
              onPressed: () async {
                if (resetEmailController.text.trim().isEmpty) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text('Please enter your email.', style: TextStyle(color: theme.colorScheme.onError)), backgroundColor: theme.colorScheme.error),
                   );
                   return; // Don't proceed if email is empty
                }
                try {
                  await _auth.sendPasswordResetEmail(resetEmailController.text.trim());
                  Navigator.pop(context); // Close dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Reset email sent! Check your inbox.', style: TextStyle(color: theme.colorScheme.onSecondary)),
                      backgroundColor: theme.colorScheme.secondary,
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context); // Close dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}', style: TextStyle(color: theme.colorScheme.onError)),
                      backgroundColor: theme.colorScheme.error,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}

