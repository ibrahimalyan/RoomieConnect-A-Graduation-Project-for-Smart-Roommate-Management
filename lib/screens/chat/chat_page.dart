import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final CollectionReference chatCollection =
      FirebaseFirestore.instance.collection('chats');

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      chatCollection.add({
        'text': _messageController.text.trim(),
        'sender': FirebaseAuth.instance.currentUser!.email,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Roommates'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: chatCollection.orderBy('timestamp').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong.'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true, // Newest message at bottom
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final doc = messages[messages.length - 1 - index];
                    final data = doc.data() as Map<String, dynamic>;

                    return ListTile(
                      title: Text(
                        data['text'] ?? '',
                        style: const TextStyle(fontSize: 16),
                      ),
                      subtitle: Text(
                        data['sender'] ?? '',
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration:
                        const InputDecoration(hintText: 'Type a message...'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
