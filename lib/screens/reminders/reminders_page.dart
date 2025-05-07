import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gemini/flutter_gemini.dart'; // Import Gemini

class RemindersPage extends StatefulWidget {
  const RemindersPage({Key? key}) : super(key: key);

  @override
  _RemindersPageState createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  final TextEditingController _reminderController = TextEditingController();
  final TextEditingController _roommateNameController =
      TextEditingController(); // Added for roommate name
  DateTime? _selectedDate;
  String _selectedTone = 'friendly'; // Default tone
  bool _isLoadingAi = false; // To show loading indicator

  final CollectionReference remindersCollection =
      FirebaseFirestore.instance.collection('reminders');
  final Gemini gemini = Gemini.instance; // Gemini instance

  void _addReminder() {
    if (_reminderController.text.isNotEmpty && _selectedDate != null) {
      remindersCollection.add({
        'text': _reminderController.text.trim(),
        'date': Timestamp.fromDate(_selectedDate!),
        'timestamp': FieldValue.serverTimestamp(),
        'uid': FirebaseAuth.instance.currentUser!.uid,
        // Consider adding roommate name and tone if needed for display
      });
      _reminderController.clear();
      _roommateNameController.clear();
      _selectedDate = null;
      setState(() {}); // Update UI
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _deleteReminder(String docId) {
    remindersCollection.doc(docId).delete();
  }

  // Function to generate reminder using Gemini
  Future<void> _generateReminder() async {
    if (_reminderController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter the task description first.')),
      );
      return;
    }
    if (_roommateNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the roommate\'s name.')),
      );
      return;
    }

    setState(() => _isLoadingAi = true);

    String task = _reminderController.text.trim();
    String roommateName = _roommateNameController.text.trim();

    // Construct the prompt
    String prompt =
        "Generate a reminder message for my roommate, $roommateName, about the task: '$task'. "
        "The tone should be $_selectedTone. Keep it concise.";

    try {
      final response = await gemini.text(prompt); // ✅ Fixed here

      String? generatedText = response?.output?.trim();

      if (generatedText != null && generatedText.isNotEmpty) {
        // Update the reminder text field with the generated text
        _reminderController.text = generatedText;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('AI could not generate a reminder. Please try again.')),
        );
      }
    } catch (e) {
      print('Error generating reminder: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating reminder: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoadingAi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Roommate Name Input
            TextField(
              controller: _roommateNameController,
              decoration: const InputDecoration(hintText: 'Roommate Name...'),
            ),
            const SizedBox(height: 10),
            // Reminder Text Input
            TextField(
              controller: _reminderController,
              decoration:
                  const InputDecoration(hintText: 'Task description...'),
              maxLines: 3, // Allow more space for potentially longer AI text
            ),
            const SizedBox(height: 10),
            // Tone Selection and AI Generation Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  value: _selectedTone,
                  items: ['friendly', 'personal', 'less friendly']
                      .map((tone) => DropdownMenuItem(
                            value: tone,
                            child: Text(tone[0].toUpperCase() +
                                tone.substring(1)), // Capitalize
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedTone = value);
                    }
                  },
                ),
                _isLoadingAi
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Generate'),
                        onPressed: _generateReminder,
                      ),
              ],
            ),
            const SizedBox(height: 10),
            // Date Picker and Add Button
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDate == null
                        ? 'Select Date'
                        : 'Date: ${DateFormat.yMMMd().format(_selectedDate!)}',
                    style: textTheme.bodyMedium?.copyWith(
                        color: _selectedDate == null
                            ? Colors.grey
                            : theme.primaryColor),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.date_range, color: theme.primaryColor),
                  onPressed: () => _pickDate(context),
                ),
                IconButton(
                  icon: Icon(Icons.add_circle,
                      color: theme.primaryColor, size: 30),
                  onPressed: _addReminder,
                  tooltip: 'Add Reminder',
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Reminder List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: remindersCollection.orderBy('date').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No reminders yet.'));
                  }

                  final reminders = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: reminders.length,
                    itemBuilder: (context, index) {
                      final doc = reminders[index];
                      final data = doc.data() as Map<String, dynamic>;

                      return Card(
                        // Use Card for better UI
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        child: ListTile(
                          title: Text(data['text'] ?? '',
                              style: textTheme.bodyLarge),
                          subtitle: Text(
                            DateFormat.yMMMd()
                                .format((data['date'] as Timestamp).toDate()),
                            style: textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete,
                                color: theme.colorScheme.error),
                            onPressed: () => _deleteReminder(doc.id),
                            tooltip: 'Delete Reminder',
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
      ),
    );
  }
}
