import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class BillsPage extends StatefulWidget {
  const BillsPage({Key? key}) : super(key: key);

  @override
  _BillsPageState createState() => _BillsPageState();
}

class _BillsPageState extends State<BillsPage> {
  final TextEditingController _billTitleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  DateTime? _selectedDueDate;

  final CollectionReference billsCollection =
      FirebaseFirestore.instance.collection('bills');

  void _addBill() {
    if (_billTitleController.text.isNotEmpty &&
        _amountController.text.isNotEmpty &&
        _selectedDueDate != null) {
      billsCollection.add({
        'title': _billTitleController.text.trim(),
        'amount': double.parse(_amountController.text),
        'dueDate': Timestamp.fromDate(_selectedDueDate!),
        'paid': false,
        'timestamp': FieldValue.serverTimestamp(),
        'uid': FirebaseAuth.instance.currentUser!.uid,
      });
      _billTitleController.clear();
      _amountController.clear();
      setState(() => _selectedDueDate = null);
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

  Future<void> _pickDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (picked != null) {
      setState(() => _selectedDueDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  child: Column(
                    children: [
                      TextField(
                        controller: _billTitleController,
                        decoration: const InputDecoration(
                          labelText: 'Bill Title',
                          prefixIcon: Icon(Icons.edit),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedDueDate == null
                                  ? 'No due date selected'
                                  : 'Due: ${DateFormat.yMMMd().format(_selectedDueDate!)}',
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.date_range),
                            onPressed: () => _pickDueDate(context),
                          )
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton.extended(
                  onPressed: _addBill,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Bill'),
                )
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
                      final dueDate = (data['dueDate'] as Timestamp?)?.toDate();
                      final paid = data['paid'] as bool? ?? false;
                      final color = paid
                          ? Colors.green
                          : (dueDate != null &&
                                  dueDate.isBefore(DateTime.now()))
                              ? Colors.red
                              : Colors.orange;

                      return Card(
                        color: color.withOpacity(0.1),
                        child: ListTile(
                          leading: Icon(
                            paid ? Icons.check_circle : Icons.pending_actions,
                            color: color,
                          ),
                          title: Text(
                            data['title'] ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration:
                                  paid ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Amount: \$${data['amount'] ?? 0}'),
                              if (dueDate != null)
                                Text(
                                    'Due: ${DateFormat.yMMMd().format(dueDate)}'),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteBill(doc.id),
                          ),
                          onTap: () => _toggleBill(doc),
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
