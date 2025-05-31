import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({Key? key}) : super(key: key);

  @override
  _TasksPageState createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final TextEditingController _taskController = TextEditingController();
  final CollectionReference tasksCollection =
      FirebaseFirestore.instance.collection('tasks');
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  final Gemini _gemini = Gemini.instance;
  bool _loadingAI = false;

  String _statusFilter = 'open';
  String _assignmentFilter = 'all';

  void _addTask() {
    if (_taskController.text.isNotEmpty) {
      tasksCollection.add({
        'task': _taskController.text.trim(),
        'status': 'pending',
        'assignedTo': null,
        'timestamp': FieldValue.serverTimestamp(),
        'uid': FirebaseAuth.instance.currentUser!.uid,
      });
      _taskController.clear();
    }
  }

  Future<void> _generateTaskWithAI() async {
    final input = _taskController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please type something first.')),
      );
      return;
    }

    setState(() => _loadingAI = true);
    final prompt = """
Refine this input into a short, clear task that a roommate might add to a shared to-do list. Keep the original intent but make it sound friendly and helpful:

"$input"
""";

    try {
      final result = await _gemini.text(prompt);
      final suggestion = result?.output?.trim();
      if (suggestion != null && suggestion.isNotEmpty) {
        _taskController.text = suggestion;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI didn’t return anything useful.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gemini error: $e')),
      );
    } finally {
      setState(() => _loadingAI = false);
    }
  }

  void _takeOn(String docId) {
    tasksCollection.doc(docId).update({
      'assignedTo': FirebaseAuth.instance.currentUser!.uid,
      'status': 'in-progress',
    });
  }

  Future<void> _assignToRoommate(BuildContext context, String docId) async {
    final roommatesSnapshot = await usersCollection.get();
    final roommates = roommatesSnapshot.docs
        .where((doc) => doc.id != FirebaseAuth.instance.currentUser!.uid)
        .toList();

    if (roommates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No roommates available to assign.')),
      );
      return;
    }

    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Assign to Roommate'),
        children: roommates.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, doc.id),
            child: Text(data['firstName'] ?? 'Unnamed User'),
          );
        }).toList(),
      ),
    );

    if (selected != null) {
      tasksCollection.doc(docId).update({
        'assignedTo': selected,
        'status': 'in-progress',
      });
    }
  }

  Future<void> _markDone(String docId) async {
    final confirmed = await _showConfirmationDialog(
        context, 'Mark as Done', 'Are you sure this task is complete?');
    if (confirmed) {
      tasksCollection.doc(docId).update({'status': 'done'});
    }
  }

  Future<void> _deleteTask(String docId) async {
    final confirmed = await _showConfirmationDialog(
        context, 'Delete Task', 'Are you sure you want to delete this task?');
    if (confirmed) {
      tasksCollection.doc(docId).delete();
    }
  }

  Future<bool> _showConfirmationDialog(
      BuildContext context, String title, String content) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm')),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<String> _getAssignedUserName(String? uid) async {
    if (uid == null) return 'Unassigned';
    if (uid == FirebaseAuth.instance.currentUser!.uid) return 'You';
    final doc = await usersCollection.doc(uid).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      return data['firstName'] ?? 'Unnamed Roommate';
    }
    return 'Unknown';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'done':
        return Colors.green;
      case 'in-progress':
        return Colors.orange;
      case 'pending':
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'done':
        return Icons.check_circle_outline;
      case 'in-progress':
        return Icons.autorenew_outlined;
      case 'pending':
      default:
        return Icons.pending_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks List'),
        backgroundColor: theme.colorScheme.primary,
      ),
      body: Container(
        color: Colors.grey[100],
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(blurRadius: 5, color: Colors.black12)
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _taskController,
                      decoration: const InputDecoration(
                        hintText: 'Add a new task...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_loadingAI)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _generateTaskWithAI,
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('AI'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ElevatedButton.icon(
                    onPressed: _addTask,
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                DropdownButton<String>(
                  value: _statusFilter,
                  onChanged: (value) => setState(() => _statusFilter = value!),
                  items: const [
                    DropdownMenuItem(value: 'open', child: Text('Open')),
                    DropdownMenuItem(value: 'closed', child: Text('Closed')),
                  ],
                ),
                const SizedBox(width: 20),
                DropdownButton<String>(
                  value: _assignmentFilter,
                  onChanged: (value) =>
                      setState(() => _assignmentFilter = value!),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Tasks')),
                    DropdownMenuItem(
                        value: 'personal', child: Text('My Tasks')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: tasksCollection
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError)
                    return const Center(child: Text('Error loading tasks.'));
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final tasks = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status'] ?? 'pending';
                    final assignedTo = data['assignedTo'];
                    final statusMatch = _statusFilter == 'open'
                        ? status != 'done'
                        : status == 'done';
                    final assignmentMatch =
                        _assignmentFilter == 'all' ? true : assignedTo == uid;
                    return statusMatch && assignmentMatch;
                  }).toList();

                  if (tasks.isEmpty)
                    return const Center(child: Text('No tasks found.'));

                  return ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final doc = tasks[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final status = data['status'] ?? 'pending';
                      final assignedTo = data['assignedTo'];
                      final color = _statusColor(status);

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(blurRadius: 4, color: Colors.black12)
                          ],
                        ),
                        child: ListTile(
                          leading: Icon(
                            _statusIcon(status),
                            color: color,
                            size: 28,
                          ),
                          title: Text(
                            data['task'] ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                              decoration: status == 'done'
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          subtitle: FutureBuilder<String>(
                            future: _getAssignedUserName(assignedTo),
                            builder: (context, snapshot) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Status: ${status.toUpperCase()}',
                                  style: TextStyle(color: color),
                                ),
                                Text(
                                  'Assigned to: ${snapshot.data ?? 'Loading...'}',
                                  style: TextStyle(color: color),
                                ),
                              ],
                            ),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'take_on') _takeOn(doc.id);
                              if (value == 'assign')
                                _assignToRoommate(context, doc.id);
                              if (value == 'done') _markDone(doc.id);
                              if (value == 'delete') _deleteTask(doc.id);
                            },
                            itemBuilder: (context) => [
                              if (status != 'done') ...[
                                const PopupMenuItem(
                                  value: 'done',
                                  child: ListTile(
                                    leading: Icon(Icons.check),
                                    title: Text('Mark Done'),
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'assign',
                                  child: ListTile(
                                    leading: Icon(Icons.person_add),
                                    title: Text('Assign'),
                                  ),
                                ),
                                if (assignedTo != uid)
                                  const PopupMenuItem(
                                    value: 'take_on',
                                    child: ListTile(
                                      leading: Icon(Icons.person),
                                      title: Text('Take On'),
                                    ),
                                  ),
                              ],
                              const PopupMenuDivider(),
                              const PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading:
                                      Icon(Icons.delete, color: Colors.red),
                                  title: Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
