import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? userData;
  bool isEditing = false;

  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController genderController = TextEditingController();
  DateTime? birthday;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        userData = doc.data() as Map<String, dynamic>?;
        firstNameController.text = userData?['firstName'] ?? '';
        lastNameController.text = userData?['lastName'] ?? '';
        genderController.text = userData?['gender'] ?? '';
        birthday = DateTime.tryParse(userData?['birthday'] ?? '');
      });
    }
  }

  Future<void> saveProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'firstName': firstNameController.text,
        'lastName': lastNameController.text,
        'gender': genderController.text,
        'birthday': birthday?.toIso8601String(),
      });
      setState(() {
        isEditing = false;
      });
      loadUserData(); // Refresh
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Profile')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile'),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (isEditing) {
                saveProfile();
              } else {
                setState(() => isEditing = true);
              }
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            TextFormField(
              controller: firstNameController,
              decoration: InputDecoration(labelText: 'First Name'),
              enabled: isEditing,
            ),
            TextFormField(
              controller: lastNameController,
              decoration: InputDecoration(labelText: 'Last Name'),
              enabled: isEditing,
            ),
            TextFormField(
              controller: genderController,
              decoration: InputDecoration(labelText: 'Gender'),
              enabled: isEditing,
            ),
            ListTile(
              title: Text(
                  'Birthday: ${birthday == null ? '' : DateFormat.yMMMd().format(birthday!)}'),
              trailing: isEditing ? Icon(Icons.calendar_today) : null,
              onTap: isEditing
                  ? () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: birthday ?? DateTime(2000),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          birthday = picked;
                        });
                      }
                    }
                  : null,
            ),
            SizedBox(height: 20),
            Text('Role: ${userData?['role']}'),
            Text('Room ID: ${userData?['roomId']}'),
          ],
        ),
      ),
    );
  }
}
