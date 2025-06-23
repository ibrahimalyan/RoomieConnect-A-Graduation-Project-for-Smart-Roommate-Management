import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? userData;
  Map<String, dynamic>? roomData;
  bool isEditing = false;

  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController genderController = TextEditingController();
  TextEditingController apartmentNameController = TextEditingController();
  TextEditingController roomPasswordController = TextEditingController();
  DateTime? birthday;

  File? _selectedImage;
  String? _profileImageUrl;
  bool isAssetAvatar = false;
  final ImagePicker _picker = ImagePicker();

  final List<String> avatarList = List.generate(
    10,
    (index) => 'assets/avatar${index + 1}.jpg',
  );

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
        _profileImageUrl = userData?['photoUrl'];
        isAssetAvatar = userData?['isAssetAvatar'] ?? false;
      });

      if (userData != null && userData!['role'] == 'admin') {
        final roomId = userData!['roomId'];
        final roomDoc = await _firestore.collection('rooms').doc(roomId).get();
        if (roomDoc.exists) {
          setState(() {
            roomData = roomDoc.data() as Map<String, dynamic>;
            apartmentNameController.text = roomData?['apartmentName'] ?? '';
            roomPasswordController.text = roomData?['roomPassword'] ?? '';
          });
        }
      }
    }
  }

  Future<void> uploadProfileImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final uid = _auth.currentUser!.uid;

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('$uid.jpg');

      await storageRef.putFile(file);
      final downloadUrl = await storageRef.getDownloadURL();

      await _firestore.collection('users').doc(uid).update({
        'photoUrl': downloadUrl,
        'isAssetAvatar': false,
      });

      setState(() {
        _profileImageUrl = downloadUrl;
        isAssetAvatar = false;
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
        'photoUrl': _profileImageUrl,
        'isAssetAvatar': isAssetAvatar,
      });

      if (userData != null && userData!['role'] == 'admin') {
        await _firestore.collection('rooms').doc(userData!['roomId']).update({
          'apartmentName': apartmentNameController.text,
          'roomPassword': roomPasswordController.text,
        });
      }

      setState(() => isEditing = false);
      loadUserData();
    }
  }

  Widget buildCard(
      {required IconData icon, required String label, required Widget child}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28, color: Colors.teal),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  child
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.check : Icons.edit),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: isEditing ? uploadProfileImage : null,
              child: CircleAvatar(
                radius: 48,
                backgroundImage: _profileImageUrl != null
                    ? (isAssetAvatar
                        ? AssetImage(_profileImageUrl!)
                        : NetworkImage(_profileImageUrl!)) as ImageProvider
                    : const AssetImage('assets/logo.png'),
                child: isEditing
                    ? Align(
                        alignment: Alignment.bottomRight,
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 14,
                          child: Icon(Icons.camera_alt,
                              size: 18, color: Colors.teal),
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            if (isEditing)
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: avatarList.map((path) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _profileImageUrl = path;
                        isAssetAvatar = true;
                      });
                    },
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor:
                          _profileImageUrl == path ? Colors.teal : null,
                      child: CircleAvatar(
                        radius: 24,
                        backgroundImage: AssetImage(path),
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 10),
            buildCard(
              icon: Icons.person,
              label: 'First Name',
              child: TextFormField(
                controller: firstNameController,
                decoration: const InputDecoration(border: InputBorder.none),
                enabled: isEditing,
              ),
            ),
            buildCard(
              icon: Icons.person_outline,
              label: 'Last Name',
              child: TextFormField(
                controller: lastNameController,
                decoration: const InputDecoration(border: InputBorder.none),
                enabled: isEditing,
              ),
            ),
            buildCard(
              icon: Icons.wc,
              label: 'Gender',
              child: TextFormField(
                controller: genderController,
                decoration: const InputDecoration(border: InputBorder.none),
                enabled: isEditing,
              ),
            ),
            buildCard(
              icon: Icons.cake,
              label: 'Birthday',
              child: InkWell(
                onTap: isEditing
                    ? () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: birthday ?? DateTime(2000),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => birthday = picked);
                        }
                      }
                    : null,
                child: Text(
                  birthday == null
                      ? 'Not set'
                      : DateFormat.yMMMd().format(birthday!),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            buildCard(
              icon: Icons.verified_user,
              label: 'Role',
              child: Text(userData?['role'] ?? 'N/A'),
            ),
            buildCard(
              icon: Icons.meeting_room,
              label: 'Room ID',
              child: Text(userData?['roomId'] ?? 'N/A'),
            ),
            if (userData?['role'] == 'admin') ...[
              buildCard(
                icon: Icons.apartment,
                label: 'Apartment Name',
                child: TextFormField(
                  controller: apartmentNameController,
                  decoration: const InputDecoration(border: InputBorder.none),
                  enabled: isEditing,
                ),
              ),
              buildCard(
                icon: Icons.lock,
                label: 'Room Password',
                child: TextFormField(
                  controller: roomPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(border: InputBorder.none),
                  enabled: isEditing,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
