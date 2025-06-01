// RoommatesScreen with card-based UI and profile image support
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoommatesScreen extends StatefulWidget {
  @override
  _RoommatesScreenState createState() => _RoommatesScreenState();
}

class _RoommatesScreenState extends State<RoommatesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> members = [];
  String? roomId;
  String? adminId;

  @override
  void initState() {
    super.initState();
    loadMembers();
  }

  Future<void> loadMembers() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      roomId = userDoc.get('roomId');
      if (roomId != null) {
        DocumentSnapshot roomDoc =
            await _firestore.collection('rooms').doc(roomId).get();
        adminId = roomDoc.get('adminId');
        List memberIds = roomDoc.get('members');

        List<Map<String, dynamic>> loadedMembers = [];
        for (String uid in memberIds) {
          DocumentSnapshot memberDoc =
              await _firestore.collection('users').doc(uid).get();
          loadedMembers.add({
            'uid': uid,
            'firstName': memberDoc.get('firstName'),
            'lastName': memberDoc.get('lastName'),
            'role': memberDoc.get('role'),
            'photoUrl': memberDoc.data().toString().contains('photoUrl')
                ? memberDoc.get('photoUrl')
                : null,
          });
        }

        setState(() {
          members = loadedMembers;
        });
      }
    }
  }

  Future<void> removeMember(String uid) async {
    if (roomId != null) {
      await _firestore.collection('rooms').doc(roomId).update({
        'members': FieldValue.arrayRemove([uid])
      });

      await _firestore.collection('users').doc(uid).update({
        'roomId': '',
        'role': 'member',
      });

      loadMembers();
    }
  }

  @override
  Widget build(BuildContext context) {
    User? currentUser = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Roommates'),
      ),
      body: members.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundImage: member['photoUrl'] != null
                          ? NetworkImage(member['photoUrl'])
                          : const AssetImage('assets/logo.png')
                              as ImageProvider,
                    ),
                    title: Text(
                      '${member['firstName']} ${member['lastName']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Role: ${member['role']}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    trailing: (currentUser?.uid == adminId &&
                            member['uid'] != adminId)
                        ? IconButton(
                            icon: const Icon(Icons.remove_circle,
                                color: Colors.red),
                            onPressed: () {
                              removeMember(member['uid']);
                            },
                          )
                        : null,
                  ),
                );
              },
            ),
    );
  }
}
