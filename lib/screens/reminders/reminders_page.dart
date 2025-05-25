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

void initializeTimeZones() => tzData.initializeTimeZones();

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
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  final TextEditingController _taskCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _repeat = 'none';
  String _tone = 'friendly';
  bool _loadingGemini = false;

  final _remindersCol = FirebaseFirestore.instance.collection('reminders');
  final Gemini _gemini = Gemini.instance;

  /* ───────────────────────── helpers ───────────────────────── */

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
        context: context, initialTime: _selectedTime ?? TimeOfDay.now());
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _generateWithGemini() async {
    if (_taskCtrl.text.isEmpty || _nameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter both task & roommate name')),
      );
      return;
    }
    setState(() => _loadingGemini = true);
    final prompt =
        "Generate a $_tone reminder for ${_nameCtrl.text.trim()} about: '${_taskCtrl.text.trim()}', short and clear.";
    try {
      final res = await _gemini.text(prompt);
      final txt = res?.output?.trim();
      if (txt != null && txt.isNotEmpty) {
        _taskCtrl.text = txt;
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('AI returned nothing')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gemini error: $e')));
    } finally {
      setState(() => _loadingGemini = false);
    }
  }

  Future<void> _addReminder() async {
    if (_taskCtrl.text.isEmpty ||
        _selectedDate == null ||
        _selectedTime == null) return;
    final dateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    await _remindersCol.add({
      'text': _taskCtrl.text.trim(),
      'date': Timestamp.fromDate(dateTime),
      'repeat': _repeat,
      'uid': FirebaseAuth.instance.currentUser!.uid,
    });
    await scheduleReminderNotification(
      id: dateTime.hashCode,
      title: 'Reminder',
      body: _taskCtrl.text.trim(),
      scheduledTime: dateTime,
      repeatWeekly: _repeat == 'weekly',
    );
    _taskCtrl.clear();
    _nameCtrl.clear();
    setState(() {
      _selectedDate = null;
      _selectedTime = null;
      _repeat = 'none';
      _tone = 'friendly';
    });
  }

  void _deleteReminder(String id) => _remindersCol.doc(id).delete();

  /* ────────────────────────── UI ────────────────────────── */

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: Column(
        children: [
          /* --------------- input card --------------- */
          Card(
            elevation: 4,
            margin: const EdgeInsets.all(16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Roommate name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _taskCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Task / reminder text',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.edit_note),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _tone,
                          decoration: const InputDecoration(
                            labelText: 'Tone',
                            prefixIcon: Icon(Icons.mood),
                          ),
                          items: ['friendly', 'personal', 'less friendly']
                              .map((e) =>
                                  DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (v) => setState(() => _tone = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _loadingGemini
                          ? const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator()),
                            )
                          : ElevatedButton.icon(
                              onPressed: _generateWithGemini,
                              icon: const Icon(Icons.auto_awesome),
                              label: const Text('AI'),
                            ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.date_range),
                          label: Text(
                            _selectedDate == null
                                ? 'Pick date'
                                : DateFormat.yMMMd().format(_selectedDate!),
                          ),
                          onPressed: _pickDate,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.access_time),
                          label: Text(
                            _selectedTime == null
                                ? 'Pick time'
                                : _selectedTime!.format(context),
                          ),
                          onPressed: _pickTime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _repeat,
                    decoration: const InputDecoration(
                      labelText: 'Repeat',
                      prefixIcon: Icon(Icons.repeat),
                    ),
                    items: ['none', 'weekly']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _repeat = v!),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Add reminder'),
                      onPressed: _addReminder,
                    ),
                  ),
                ],
              ),
            ),
          ),

          /* ------------- reminder list -------------- */
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _remindersCol.orderBy('date').snapshots(),
              builder: (ctx, snap) {
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Center(child: Text('No reminders yet.'));
                }
                final docs = snap.data!.docs;
                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  itemBuilder: (ctx, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    final date = (d['date'] as Timestamp).toDate();
                    final repeat = d['repeat'] ?? 'none';

                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.alarm, size: 28),
                        title: Text(d['text'] ?? '', style: t.bodyLarge),
                        subtitle: Text(
                          '${DateFormat.yMMMd().add_jm().format(date)}'
                          '${repeat != 'none' ? ' • repeats $repeat' : ''}',
                          style: t.bodySmall?.copyWith(color: Colors.grey),
                        ),
                        trailing: IconButton(
                          tooltip: 'Delete',
                          icon: Icon(Icons.delete,
                              color: Theme.of(context).colorScheme.error),
                          onPressed: () => _deleteReminder(docs[i].id),
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
