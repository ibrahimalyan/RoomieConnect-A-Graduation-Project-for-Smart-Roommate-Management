import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final String uid;
  DatabaseService({required this.uid});

  final CollectionReference userCollection =
      FirebaseFirestore.instance.collection('users');
  final CollectionReference roomCollection =
      FirebaseFirestore.instance.collection('rooms');

  // Create or update user data
  Future updateUserData({
    required String firstName,
    required String lastName,
    required String gender,
    required DateTime birthday,
    required String role,
    required String roomId,
  }) async {
    return await userCollection.doc(uid).set({
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender,
      'birthday': birthday.toIso8601String(),
      'role': role,
      'roomId': roomId,
    });
  }

  // Create a new Room (only for Admin)
  Future<String> createRoom() async {
    DocumentReference roomDoc = await roomCollection.add({
      'adminId': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'members': [uid],
    });
    return roomDoc.id; // return the room ID
  }

  // Join an existing Room (for Members)
  Future joinRoom(String roomId) async {
    return await roomCollection.doc(roomId).update({
      'members': FieldValue.arrayUnion([uid]),
    });
  }
}
