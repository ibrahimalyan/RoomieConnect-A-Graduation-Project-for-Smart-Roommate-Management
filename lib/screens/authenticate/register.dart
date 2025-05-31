// Updated Register widget with room password and apartment name
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/services/auth.dart';
import 'package:flutter_application_1/services/database.dart';
import 'package:flutter_application_1/screens/wrapper.dart';

class Register extends StatefulWidget {
  final Function toggleView;
  const Register({Key? key, required this.toggleView}) : super(key: key);

  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  String firstName = '';
  String lastName = '';
  String gender = 'Male';
  DateTime? birthday;
  bool isCreatingRoom = true;
  String roomId = '';
  String roomPassword = '';
  String apartmentName = '';
  String email = '';
  String password = '';
  String error = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF73C8A9), Color(0xFF373B44)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Register Roomie',
                            style: textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Text('Create Room?',
                                  style: textTheme.bodyMedium
                                      ?.copyWith(color: Colors.white)),
                            ),
                            Switch(
                              value: isCreatingRoom,
                              onChanged: (val) =>
                                  setState(() => isCreatingRoom = val),
                            ),
                          ],
                        ),
                        if (!isCreatingRoom)
                          TextFormField(
                            decoration: _inputDecoration('Room ID'),
                            validator: (val) =>
                                val!.isEmpty ? 'Enter Room ID' : null,
                            onChanged: (val) => setState(() => roomId = val),
                          ),
                        const SizedBox(height: 10),
                        if (isCreatingRoom)
                          TextFormField(
                            decoration: _inputDecoration('Apartment Name'),
                            validator: (val) =>
                                val!.isEmpty ? 'Enter apartment name' : null,
                            onChanged: (val) =>
                                setState(() => apartmentName = val),
                          ),
                        const SizedBox(height: 10),
                        TextFormField(
                          decoration: _inputDecoration('First Name'),
                          validator: (val) =>
                              val!.isEmpty ? 'Enter first name' : null,
                          onChanged: (val) => setState(() => firstName = val),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          decoration: _inputDecoration('Last Name'),
                          validator: (val) =>
                              val!.isEmpty ? 'Enter last name' : null,
                          onChanged: (val) => setState(() => lastName = val),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: gender,
                          dropdownColor: Colors.white.withOpacity(0.9),
                          items: ['Male', 'Female', 'Other']
                              .map((label) => DropdownMenuItem(
                                    child: Text(label),
                                    value: label,
                                  ))
                              .toList(),
                          onChanged: (val) => setState(() => gender = val!),
                          decoration: _inputDecoration('Gender'),
                        ),
                        const SizedBox(height: 10),
                        ListTile(
                          title: Text(
                            birthday == null
                                ? 'Select Birthday'
                                : DateFormat.yMMMd().format(birthday!),
                            style: textTheme.bodyMedium
                                ?.copyWith(color: Colors.white),
                          ),
                          trailing: const Icon(Icons.calendar_today,
                              color: Colors.white),
                          onTap: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime(2000),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() => birthday = picked);
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          decoration: _inputDecoration('Email'),
                          validator: (val) =>
                              val!.isEmpty ? 'Enter an email' : null,
                          onChanged: (val) => setState(() => email = val),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          decoration: _inputDecoration('Password'),
                          obscureText: true,
                          validator: (val) => val!.length < 6
                              ? 'Password must be 6+ characters'
                              : null,
                          onChanged: (val) => setState(() => password = val),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          decoration: _inputDecoration(isCreatingRoom
                              ? 'Set Room Password'
                              : 'Room Password'),
                          obscureText: true,
                          validator: (val) =>
                              val!.isEmpty ? 'Enter room password' : null,
                          onChanged: (val) =>
                              setState(() => roomPassword = val),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: theme.primaryColor,
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Register'),
                          onPressed: () async {
                            if (_formKey.currentState!.validate() &&
                                birthday != null) {
                              var result =
                                  await _auth.registerWithEmailAndPassword(
                                      email, password);
                              if (result != null) {
                                String newRoomId = roomId;
                                String role = 'member';

                                if (isCreatingRoom) {
                                  newRoomId =
                                      await DatabaseService(uid: result.uid)
                                          .createRoom(
                                    roomPassword: roomPassword,
                                    apartmentName: apartmentName,
                                  );
                                  role = 'admin';
                                } else {
                                  bool joined =
                                      await DatabaseService(uid: result.uid)
                                          .joinRoom(
                                              roomId: roomId,
                                              enteredPassword: roomPassword);
                                  if (!joined) {
                                    setState(() =>
                                        error = 'Incorrect room password');
                                    return;
                                  }
                                }

                                await DatabaseService(uid: result.uid)
                                    .updateUserData(
                                  firstName: firstName,
                                  lastName: lastName,
                                  gender: gender,
                                  birthday: birthday!,
                                  role: role,
                                  roomId: newRoomId,
                                );

                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                      builder: (context) => Wrapper()),
                                );
                              } else {
                                setState(() =>
                                    error = 'Please supply a valid email');
                              }
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        if (error.isNotEmpty)
                          Text(
                            error,
                            style: textTheme.bodyMedium
                                ?.copyWith(color: theme.colorScheme.error),
                            textAlign: TextAlign.center,
                          ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => widget.toggleView(),
                          child: const Text(
                            "Already have an account? Sign In",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white.withOpacity(0.3),
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
