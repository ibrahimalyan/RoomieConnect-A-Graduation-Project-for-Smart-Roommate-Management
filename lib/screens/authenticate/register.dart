import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/auth.dart';
import 'package:flutter_application_1/services/database.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/screens/wrapper.dart';

class Register extends StatefulWidget {
  final Function toggleView;
  Register({required this.toggleView});

  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  // User info
  String firstName = '';
  String lastName = '';
  String gender = 'Male';
  DateTime? birthday;
  bool isCreatingRoom = true; // true = Admin, false = Member
  String roomId = '';

  // Auth info
  String email = '';
  String password = '';
  String error = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
        actions: [
          TextButton.icon(
            icon: Icon(Icons.person),
            label: Text('Sign In'),
            onPressed: () {
              widget.toggleView();
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Are you creating a room?
              Row(
                children: [
                  Text('Create Room?'),
                  Switch(
                    value: isCreatingRoom,
                    onChanged: (val) {
                      setState(() => isCreatingRoom = val);
                    },
                  ),
                ],
              ),
              if (!isCreatingRoom)
                TextFormField(
                  decoration: InputDecoration(hintText: 'Room ID'),
                  validator: (val) => val!.isEmpty ? 'Enter Room ID' : null,
                  onChanged: (val) => setState(() => roomId = val),
                ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(hintText: 'First Name'),
                validator: (val) => val!.isEmpty ? 'Enter first name' : null,
                onChanged: (val) => setState(() => firstName = val),
              ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(hintText: 'Last Name'),
                validator: (val) => val!.isEmpty ? 'Enter last name' : null,
                onChanged: (val) => setState(() => lastName = val),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: gender,
                items: ['Male', 'Female', 'Other']
                    .map((label) =>
                        DropdownMenuItem(child: Text(label), value: label))
                    .toList(),
                onChanged: (val) {
                  setState(() => gender = val!);
                },
                decoration: InputDecoration(hintText: 'Gender'),
              ),
              SizedBox(height: 10),
              ListTile(
                title: Text(birthday == null
                    ? 'Select Birthday'
                    : DateFormat.yMMMd().format(birthday!)),
                trailing: Icon(Icons.calendar_today),
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
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(hintText: 'Email'),
                validator: (val) => val!.isEmpty ? 'Enter an email' : null,
                onChanged: (val) => setState(() => email = val),
              ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(hintText: 'Password'),
                obscureText: true,
                validator: (val) =>
                    val!.length < 6 ? 'Password must be 6+ chars' : null,
                onChanged: (val) => setState(() => password = val),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                child: Text('Register'),
                onPressed: () async {
                  if (_formKey.currentState!.validate() && birthday != null) {
                    var result = await _auth.registerWithEmailAndPassword(
                        email, password);
                    if (result != null) {
                      String newRoomId = roomId;
                      String role = 'member';

                      if (isCreatingRoom) {
                        // Create a new room
                        newRoomId =
                            await DatabaseService(uid: result.uid).createRoom();
                        role = 'admin';
                      } else {
                        // Join an existing room
                        await DatabaseService(uid: result.uid).joinRoom(roomId);
                      }

                      // Save user profile
                      await DatabaseService(uid: result.uid).updateUserData(
                        firstName: firstName,
                        lastName: lastName,
                        gender: gender,
                        birthday: birthday!,
                        role: role,
                        roomId: newRoomId,
                      );

                      // ✅ After all done, Navigate
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => Wrapper()),
                      );
                    } else {
                      setState(() => error = 'Please supply a valid email');
                    }
                  }
                },
              ),
              SizedBox(height: 12),
              Text(error, style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ),
    );
  }
}
