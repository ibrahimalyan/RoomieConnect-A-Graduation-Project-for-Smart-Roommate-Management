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
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  void _addItem() {
    if (_controller.text.isNotEmpty) {
      shoppingCollection.add({
        'item': _controller.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'uid': FirebaseAuth.instance.currentUser!.uid,
        'status': 'pending', // pending, in-progress, done
        'assignedTo': null, // UID of the roommate it's assigned to
      });
      _controller.clear();
    }
  }

  void _removeItem(String docId) async {
    final confirmed = await _showConfirmationDialog(context, 'Delete Item',
        'Are you sure you want to delete this item? This action cannot be undone.');
    if (confirmed) {
      shoppingCollection.doc(docId).delete();
    }
  }

  void _takeOn(String docId) {
    shoppingCollection.doc(docId).update({
      'assignedTo': FirebaseAuth.instance.currentUser!.uid,
      'status': 'in-progress',
    });
  }

  void _markDone(String docId) async {
    final confirmed = await _showConfirmationDialog(
        context, 'Mark as Done', 'Are you sure this item is purchased?');
    if (confirmed) {
      shoppingCollection.doc(docId).update({'status': 'done'});
    }
  }

  Future<void> _assignToRoommate(BuildContext context, String docId) async {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;

    final roommatesSnapshot = await usersCollection.get();
    final roommates = roommatesSnapshot.docs
        .where((doc) => doc.id != FirebaseAuth.instance.currentUser!.uid)
        .toList(); // Exclude current user

    if (roommates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No other roommates available to assign.')),
      );
      return;
    }

    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Assign to Roommate', style: textTheme.titleLarge),
        children: roommates.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, doc.id),
            child: Text(data['firstName'] ?? 'Unnamed User',
                style: textTheme.bodyLarge),
          );
        }).toList(),
      ),
    );

    if (selected != null) {
      shoppingCollection.doc(docId).update({
        'assignedTo': selected,
        'status': 'in-progress',
      });
    }
  }

  Future<bool> _showConfirmationDialog(
      BuildContext context, String title, String content) async {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: textTheme.titleLarge),
        content: Text(content, style: textTheme.bodyMedium),
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

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status) {
      case 'pending':
        return Colors.orange.shade700;
      case 'in-progress':
        return theme.colorScheme.secondary; // Teal accent
      case 'done':
        return Colors.green.shade700;
      default:
        return theme.textTheme.bodySmall!.color!;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending_actions_outlined;
      case 'in-progress':
        return Icons.shopping_cart_checkout_outlined;
      case 'done':
        return Icons.check_circle_outline;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Shopping List')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _controller,
                    decoration:
                        const InputDecoration(hintText: 'Add new item...'),
                    style: textTheme.bodyLarge,
                    onFieldSubmitted: (_) => _addItem(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_shopping_cart_outlined),
                  label: const Text('Add'),
                  onPressed: _addItem,
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: shoppingCollection
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Something went wrong.',
                          style: textTheme.bodyMedium));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = snapshot.data!.docs;

                if (items.isEmpty) {
                  return Center(
                      child: Text('No items on the shopping list yet!',
                          style: textTheme.headlineSmall
                              ?.copyWith(color: theme.colorScheme.secondary)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(
                      bottom: 80.0), // Space for FAB if any or general padding
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final doc = items[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final String itemText = data['item'] ?? 'No item name';
                    final String status = data['status'] ?? 'pending';
                    final String? assignedToUid = data['assignedTo'];
                    final bool isDone = status == 'done';

                    return Card(
                      // Using CardTheme from main theme
                      child: ListTile(
                        leading: Icon(
                          _getStatusIcon(status),
                          color: _getStatusColor(status, theme),
                          size: 28,
                        ),
                        title: Text(
                          itemText,
                          style: textTheme.titleMedium?.copyWith(
                            decoration:
                                isDone ? TextDecoration.lineThrough : null,
                            color: isDone
                                ? Colors.grey
                                : textTheme.titleMedium?.color,
                          ),
                        ),
                        subtitle: FutureBuilder<String>(
                          future: _getAssignedUserName(assignedToUid),
                          builder: (context, assignedSnapshot) {
                            final assignedToName =
                                assignedSnapshot.data ?? 'Loading...';
                            return Text(
                                'Status: ${status.toUpperCase()}\nAssigned to: $assignedToName',
                                style: textTheme.bodySmall?.copyWith(
                                    color: _getStatusColor(status, theme)));
                          },
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert,
                              color: theme.iconTheme.color),
                          onSelected: (value) {
                            if (value == 'mark_done') _markDone(doc.id);
                            if (value == 'assign')
                              _assignToRoommate(context, doc.id);
                            if (value == 'take_on') _takeOn(doc.id);
                            if (value == 'delete') _removeItem(doc.id);
                          },
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<String>>[
                            if (!isDone) ...[
                              const PopupMenuItem<String>(
                                value: 'mark_done',
                                child: ListTile(
                                    leading: Icon(Icons.check_circle_outline),
                                    title: Text('Mark as Done')),
                              ),
                              const PopupMenuItem<String>(
                                value: 'assign',
                                child: ListTile(
                                    leading:
                                        Icon(Icons.person_add_alt_1_outlined),
                                    title: Text('Assign to Roommate')),
                              ),
                              if (assignedToUid !=
                                  FirebaseAuth.instance.currentUser!.uid)
                                const PopupMenuItem<String>(
                                  value: 'take_on',
                                  child: ListTile(
                                      leading: Icon(Icons.person_outline),
                                      title: Text('Take On Myself')),
                                ),
                            ],
                            const PopupMenuDivider(),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: ListTile(
                                  leading: Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  title: Text('Delete Item',
                                      style: TextStyle(color: Colors.red))),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
