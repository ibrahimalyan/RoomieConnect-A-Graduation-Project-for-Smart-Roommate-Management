// Updated DatabaseService with room password and apartment name
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final String uid;
  DatabaseService({required this.uid});

  final CollectionReference userCollection =
      FirebaseFirestore.instance.collection('users');
  final CollectionReference roomCollection =
      FirebaseFirestore.instance.collection('rooms');

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

  Future<String> createRoom({
    required String roomPassword,
    required String apartmentName,
  }) async {
    DocumentReference roomDoc = await roomCollection.add({
      'adminId': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'members': [uid],
      'roomPassword': roomPassword,
      'apartmentName': apartmentName,
    });
    return roomDoc.id;
  }

  Future<bool> joinRoom({
    required String roomId,
    required String enteredPassword,
  }) async {
    DocumentSnapshot roomSnapshot = await roomCollection.doc(roomId).get();

    if (roomSnapshot.exists) {
      String correctPassword = roomSnapshot['roomPassword'];
      if (correctPassword == enteredPassword) {
        await roomCollection.doc(roomId).update({
          'members': FieldValue.arrayUnion([uid]),
        });
        return true;
      } else {
        return false;
      }
    }
    return false;
  }

  Future updateRoomPassword(String roomId, String newPassword) async {
    DocumentSnapshot roomSnapshot = await roomCollection.doc(roomId).get();
    if (roomSnapshot['adminId'] == uid) {
      await roomCollection.doc(roomId).update({
        'roomPassword': newPassword,
      });
    } else {
      throw Exception("Only admin can change the password.");
    }
  }
}
