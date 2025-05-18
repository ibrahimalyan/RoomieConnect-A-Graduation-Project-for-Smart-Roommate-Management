import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzData;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void initializeTimeZones() {
  tzData.initializeTimeZones();
}

Future<void> scheduleReminderNotification({
  required int id,
  required String title,
  required String body,
  required DateTime scheduledTime,
  bool repeatWeekly = false,
}) async {
  final tz.TZDateTime tzScheduledTime =
      tz.TZDateTime.from(scheduledTime, tz.local);

  await flutterLocalNotificationsPlugin.zonedSchedule(
    id,
    title,
    body,
    tzScheduledTime,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'reminder_channel_id',
        'Reminders',
        channelDescription: 'Scheduled reminders',
        importance: Importance.max,
        priority: Priority.high,
      ),
    ),
    androidAllowWhileIdle: true,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents:
        repeatWeekly ? DateTimeComponents.dayOfWeekAndTime : null,
  );
}

class RemindersPage extends StatefulWidget {
  const RemindersPage({Key? key}) : super(key: key);

  @override
  _RemindersPageState createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  final TextEditingController _reminderController = TextEditingController();
  final TextEditingController _roommateNameController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _repeatFrequency = 'none';
  String _selectedTone = 'friendly';
  bool _isLoadingAi = false;

  final CollectionReference remindersCollection =
      FirebaseFirestore.instance.collection('reminders');
  final Gemini gemini = Gemini.instance;

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

  Future<void> _pickTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _deleteReminder(String docId) {
    remindersCollection.doc(docId).delete();
  }

  Future<void> _generateReminder() async {
    if (_reminderController.text.isEmpty ||
        _roommateNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter both task and roommate name.')),
      );
      return;
    }

    setState(() => _isLoadingAi = true);

    String prompt =
        "Generate a reminder message for my roommate, ${_roommateNameController.text.trim()}, about the task: '${_reminderController.text.trim()}'. The tone should be $_selectedTone. Keep it concise.";

    try {
      final response = await gemini.text(prompt);
      String? generatedText = response?.output?.trim();
      if (generatedText != null && generatedText.isNotEmpty) {
        _reminderController.text = generatedText;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('AI could not generate a reminder. Please try again.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() => _isLoadingAi = false);
    }
  }

  Future<void> _addReminder() async {
    if (_reminderController.text.isNotEmpty &&
        _selectedDate != null &&
        _selectedTime != null) {
      final DateTime fullDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      remindersCollection.add({
        'text': _reminderController.text.trim(),
        'date': Timestamp.fromDate(fullDateTime),
        'repeat': _repeatFrequency,
        'uid': FirebaseAuth.instance.currentUser!.uid,
      });

      await scheduleReminderNotification(
        id: fullDateTime.hashCode,
        title: 'Reminder',
        body: _reminderController.text.trim(),
        scheduledTime: fullDateTime,
        repeatWeekly: _repeatFrequency == 'weekly',
      );

      _reminderController.clear();
      _roommateNameController.clear();
      _selectedDate = null;
      _selectedTime = null;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _roommateNameController,
              decoration: const InputDecoration(hintText: 'Roommate Name...'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _reminderController,
              decoration:
                  const InputDecoration(hintText: 'Task description...'),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  value: _selectedTone,
                  items: ['friendly', 'personal', 'less friendly']
                      .map((tone) =>
                          DropdownMenuItem(value: tone, child: Text(tone)))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedTone = value!),
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDate == null
                        ? 'Select Date'
                        : 'Date: ${DateFormat.yMMMd().format(_selectedDate!)}',
                    style: textTheme.bodyMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.date_range),
                  onPressed: () => _pickDate(context),
                ),
                IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: () => _pickTime(context),
                ),
              ],
            ),
            DropdownButton<String>(
              value: _repeatFrequency,
              items: ['none', 'weekly']
                  .map((freq) =>
                      DropdownMenuItem(value: freq, child: Text(freq)))
                  .toList(),
              onChanged: (value) => setState(() => _repeatFrequency = value!),
            ),
            IconButton(
              icon: Icon(Icons.add_circle, size: 30, color: theme.primaryColor),
              onPressed: _addReminder,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: remindersCollection.orderBy('date').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No reminders yet.'));
                  }

                  final reminders = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: reminders.length,
                    itemBuilder: (context, index) {
                      final doc = reminders[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final repeat = data['repeat'] ?? 'none';
                      final date = (data['date'] as Timestamp).toDate();

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        child: ListTile(
                          title: Text(data['text'] ?? '',
                              style: textTheme.bodyLarge),
                          subtitle: Text(
                            '${DateFormat.yMMMd().add_jm().format(date)}' +
                                (repeat != 'none' ? ' • repeats $repeat' : ''),
                            style: textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete,
                                color: theme.colorScheme.error),
                            onPressed: () => _deleteReminder(doc.id),
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
