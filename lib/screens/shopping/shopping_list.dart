import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShoppingListPage extends StatefulWidget {
  const ShoppingListPage({Key? key}) : super(key: key);

  @override
  _ShoppingListPageState createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  final TextEditingController _controller = TextEditingController();
  final CollectionReference shoppingCollection =
      FirebaseFirestore.instance.collection('shopping');

  void _addItem() {
    if (_controller.text.isNotEmpty) {
      shoppingCollection.add({
        'item': _controller.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'uid': FirebaseAuth.instance.currentUser!.uid,
      });
      _controller.clear();
    }
  }

  void _removeItem(String docId) {
    shoppingCollection.doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Add new item...',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addItem,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: shoppingCollection.orderBy('timestamp').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Something went wrong.'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final items = snapshot.data!.docs;

                  if (items.isEmpty) {
                    return const Center(child: Text('No items yet.'));
                  }

                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final doc = items[index];
                      final data = doc.data() as Map<String, dynamic>;

                      return ListTile(
                        title: Text(data['item'] ?? ''),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _removeItem(doc.id),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
