import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BillsPage extends StatefulWidget {
  const BillsPage({Key? key}) : super(key: key);

  @override
  _BillsPageState createState() => _BillsPageState();
}

class _BillsPageState extends State<BillsPage> {
  final TextEditingController _billController = TextEditingController();
  final CollectionReference billsCollection =
      FirebaseFirestore.instance.collection('bills');

  void _addBill() {
    if (_billController.text.isNotEmpty) {
      billsCollection.add({
        'title': _billController.text.trim(),
        'paid': false,
        'timestamp': FieldValue.serverTimestamp(),
        'uid': FirebaseAuth.instance.currentUser!.uid,
      });
      _billController.clear();
    }
  }

  void _toggleBill(DocumentSnapshot doc) {
    billsCollection.doc(doc.id).update({
      'paid': !(doc['paid'] as bool),
    });
  }

  void _deleteBill(String docId) {
    billsCollection.doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bills & Payments'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _billController,
                    decoration: const InputDecoration(
                      hintText: 'Add a new bill...',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addBill,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: billsCollection.orderBy('timestamp').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Something went wrong.'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final bills = snapshot.data!.docs;

                  if (bills.isEmpty) {
                    return const Center(child: Text('No bills yet.'));
                  }

                  return ListView.builder(
                    itemCount: bills.length,
                    itemBuilder: (context, index) {
                      final doc = bills[index];
                      final data = doc.data() as Map<String, dynamic>;

                      return ListTile(
                        title: Text(
                          data['title'] ?? '',
                          style: TextStyle(
                            decoration: data['paid']
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        leading: Checkbox(
                          value: data['paid'] ?? false,
                          onChanged: (val) => _toggleBill(doc),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteBill(doc.id),
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
