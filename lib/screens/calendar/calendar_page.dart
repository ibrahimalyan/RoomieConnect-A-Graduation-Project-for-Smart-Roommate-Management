import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<DateTime, List<Map<String, dynamic>>> _events = {};

  final Map<String, Color> _categoryColors = {
    'Rent': Colors.red,
    'Chores': Colors.blue,
    'Meeting': Colors.green,
    'Other': Colors.orange,
    'Payment': Colors.purple,
    'Shopping': Colors.teal,
    'Task': Colors.brown,
  };

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final Map<DateTime, List<Map<String, dynamic>>> newEvents = {};

    FirebaseFirestore.instance.collection('events').snapshots().listen((snap) {
      for (var doc in snap.docs) {
        final data = doc.data();
        final ts = (data['date'] as Timestamp).toDate();
        final day = DateTime(ts.year, ts.month, ts.day);

        newEvents.putIfAbsent(day, () => []).add({
          'id': doc.id,
          'title': data['title'],
          'category': data['category'],
          'doc': doc.reference,
          'source': 'event',
        });
      }

      FirebaseFirestore.instance
          .collection('bills')
          .where('uid', isEqualTo: uid)
          .snapshots()
          .listen((snap) {
        for (var doc in snap.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final dueDate = (data['dueDate'] as Timestamp?)?.toDate();
          if (dueDate != null) {
            final day = DateTime(dueDate.year, dueDate.month, dueDate.day);
            newEvents.putIfAbsent(day, () => []).add({
              'title': 'Bill: ${data['title']}',
              'category': 'Payment',
              'doc': doc.reference,
              'source': 'bill',
            });
          }
        }

        FirebaseFirestore.instance
            .collection('shopping')
            .where('assignedTo', isEqualTo: uid)
            .snapshots()
            .listen((snap) {
          for (var doc in snap.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
            if (timestamp != null) {
              final day =
                  DateTime(timestamp.year, timestamp.month, timestamp.day);
              newEvents.putIfAbsent(day, () => []).add({
                'title': 'Shopping: ${data['item']}',
                'category': 'Shopping',
                'doc': doc.reference,
                'source': 'shopping',
              });
            }
          }

          FirebaseFirestore.instance
              .collection('tasks')
              .where('assignedTo', isEqualTo: uid)
              .snapshots()
              .listen((snap) {
            for (var doc in snap.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
              if (timestamp != null) {
                final day =
                    DateTime(timestamp.year, timestamp.month, timestamp.day);
                newEvents.putIfAbsent(day, () => []).add({
                  'title': 'Task: ${data['task']}',
                  'category': 'Task',
                  'doc': doc.reference,
                  'source': 'task',
                });
              }
            }

            setState(() {
              _events = newEvents;
            });
          });
        });
      });
    });
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
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
                    color: hasEvents
                        ? Colors.red
                        : null, // 🔴 Highlight marked dates
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      color: hasEvents ? Colors.white : null,
                      fontWeight:
                          hasEvents ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
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
                      final color =
                          _categoryColors[ev['category']] ?? Colors.grey;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(backgroundColor: color),
                          title: Text(ev['title'] ?? 'No Title'),
                          subtitle: Text(ev['category'] ?? 'Unknown'),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
