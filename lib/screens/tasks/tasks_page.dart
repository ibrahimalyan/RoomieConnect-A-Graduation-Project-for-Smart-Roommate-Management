import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({Key? key}) : super(key: key);

  @override
  _TasksPageState createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final TextEditingController _taskController = TextEditingController();
  final CollectionReference tasksCollection =
      FirebaseFirestore.instance.collection('tasks');

  void _addTask() {
    if (_taskController.text.isNotEmpty) {
      tasksCollection.add({
        'task': _taskController.text.trim(),
        'completed': false,
        'timestamp': FieldValue.serverTimestamp(),
        'uid': FirebaseAuth.instance.currentUser!.uid,
      });
      _taskController.clear();
    }
  }

  void _toggleTask(DocumentSnapshot doc) {
    tasksCollection.doc(doc.id).update({
      'completed': !(doc['completed'] as bool),
    });
  }

  void _deleteTask(String docId) {
    tasksCollection.doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks List'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextFormField(
                        controller: _taskController,
                        decoration: const InputDecoration(
                          hintText: 'Add a new task...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.extended(
                  onPressed: _addTask,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Task'),
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: tasksCollection
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Something went wrong.'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final tasks = snapshot.data!.docs;

                  if (tasks.isEmpty) {
                    return const Center(child: Text('No tasks yet.'));
                  }

                  return ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final doc = tasks[index];
                      final data = doc.data() as Map<String, dynamic>;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          leading: Icon(
                            data['completed']
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: data['completed']
                                ? Colors.green
                                : theme.colorScheme.primary,
                          ),
                          title: Text(
                            data['task'] ?? '',
                            style: TextStyle(
                              fontSize: 16,
                              decoration: data['completed']
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteTask(doc.id),
                          ),
                          onTap: () => _toggleTask(doc),
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
