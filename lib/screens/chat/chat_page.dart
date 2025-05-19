import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:intl/intl.dart'; // For formatting timestamps

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showEmojiPicker = false;

  final CollectionReference chatCollection =
      FirebaseFirestore.instance.collection('chats');

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      await chatCollection.add({
        'text': text,
        'sender': FirebaseAuth.instance.currentUser!.email,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildMessageBubble(Map<String, dynamic> data, bool isMe) {
    final Timestamp? ts = data['timestamp'];
    String time =
        ts != null ? DateFormat('hh:mm a').format(ts.toDate()) : 'Sending...';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.all(10.0),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue[200] : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                data['sender'] ?? '',
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 4),
            Text(
              data['text'] ?? '',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(fontSize: 10, color: Colors.grey[700]),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
    );
  }

  void _onEmojiSelected(Emoji emoji) {
    _messageController
      ..text += emoji.emoji
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: _messageController.text.length),
      );
  }

  void _toggleEmojiPicker() {
    FocusScope.of(context).unfocus(); // Hide keyboard
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser?.email;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat with Roommates'),
        centerTitle: true,
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
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    final isMe = data['sender'] == currentUser;
                    return _buildMessageBubble(data, isMe);
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.emoji_emotions_outlined),
                  onPressed: _toggleEmojiPicker,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onTap: () {
                      setState(() {
                        _showEmojiPicker = false;
                      });
                    },
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
          Offstage(
            offstage: !_showEmojiPicker,
            child: SizedBox(
              height: 250,
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) => _onEmojiSelected(emoji),
                config: const Config(
                  emojiSizeMax: 32,
                  bgColor: Color(0xFFF2F2F2),
                  indicatorColor: Colors.blue,
                  iconColorSelected: Colors.blue,
                  backspaceColor: Colors.red,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
