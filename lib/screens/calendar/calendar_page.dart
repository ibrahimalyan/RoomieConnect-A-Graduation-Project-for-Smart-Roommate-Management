import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Roommate Calendar',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.indigo,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const CalendarPage(),
    );
  }
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Map date -> list of event docs
  Map<DateTime, List<Map<String, dynamic>>> _events = {};

  final _eventsColl = FirebaseFirestore.instance.collection('events');

  // Predefined categories and their colors
  final Map<String, Color> _categoryColors = {
    'Rent': Colors.red,
    'Chores': Colors.blue,
    'Meeting': Colors.green,
    'Other': Colors.orange,
  };

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    _eventsColl.snapshots().listen((snap) {
      final Map<DateTime, List<Map<String, dynamic>>> newEvents = {};
      for (var doc in snap.docs) {
        final data = doc.data();
        final ts = (data['date'] as Timestamp).toDate();
        final day = DateTime(ts.year, ts.month, ts.day);
        final ev = {
          'id': doc.id,
          'title': data['title'],
          'category': data['category'],
          'doc': doc.reference,
        };
        newEvents.putIfAbsent(day, () => []).add(ev);
      }
      setState(() => _events = newEvents);
    });
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  Future<void> _showAddOrEditDialog({
    Map<String, dynamic>? existing,
    required DateTime day,
  }) async {
    final isEdit = existing != null;
    final ctrl = TextEditingController(text: existing?['title'] ?? '');
    String category = existing?['category'] ?? _categoryColors.keys.first;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEdit ? 'Edit Event' : 'Add Event'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: category,
              items: _categoryColors.keys
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c),
                      ))
                  .toList(),
              onChanged: (v) => category = v!,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
          ],
        ),
        actions: [
          if (isEdit)
            TextButton(
              onPressed: () async {
                await existing!['doc'].delete();
                Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = ctrl.text.trim();
              if (title.isEmpty) return;
              final data = {
                'title': title,
                'category': category,
                'date': Timestamp.fromDate(day),
                'uid': FirebaseAuth.instance.currentUser?.uid,
                'timestamp': FieldValue.serverTimestamp(),
              };
              if (isEdit) {
                await existing!['doc'].update(data);
              } else {
                await _eventsColl.add(data);
              }
              Navigator.pop(context);
            },
            child: Text(isEdit ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Responsive spacing
    final mq = MediaQuery.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Roommate Calendar')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2000, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
            calendarFormat: _calendarFormat,
            onFormatChanged: (f) => setState(() => _calendarFormat = f),
            onDaySelected: (sel, foc) {
              setState(() {
                _selectedDay = sel;
                _focusedDay = foc;
              });
            },
            eventLoader: _getEventsForDay,
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (ctx, day, _) {
                final hasEvents = _getEventsForDay(day).isNotEmpty;
                return Container(
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: hasEvents ? Colors.indigo.shade100 : null,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text('${day.day}'),
                );
              },
              todayBuilder: (ctx, day, _) => Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.indigo, width: 2),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text('${day.day}'),
              ),
              selectedBuilder: (ctx, day, _) => Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.indigo,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${day.day}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _selectedDay == null
                ? const Center(child: Text('Select a day to see events'))
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: _getEventsForDay(_selectedDay!).map((ev) {
                      final color = _categoryColors[ev['category']]!;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(backgroundColor: color),
                          title: Text(ev['title']),
                          subtitle: Text(ev['category']),
                          onTap: () => _showAddOrEditDialog(
                              existing: ev, day: _selectedDay!),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
      floatingActionButton: _selectedDay == null
          ? null
          : FloatingActionButton(
              onPressed: () => _showAddOrEditDialog(day: _selectedDay!),
              child: const Icon(Icons.add),
            ),
    );
  }
}
