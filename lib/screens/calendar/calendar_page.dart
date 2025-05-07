import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<DateTime, List> _events = {};

  final CollectionReference eventsCollection =
      FirebaseFirestore.instance.collection('events');

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() async {
    eventsCollection.snapshots().listen((snapshot) {
      Map<DateTime, List> newEvents = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final Timestamp ts = data['date'];
        final DateTime day =
            DateTime.utc(ts.toDate().year, ts.toDate().month, ts.toDate().day);
        if (newEvents[day] == null) {
          newEvents[day] = [];
        }
        newEvents[day]!.add(data['event']);
      }
      setState(() {
        _events = newEvents;
      });
    });
  }

  void _addEvent(String event) {
    if (_selectedDay != null && event.isNotEmpty) {
      eventsCollection.add({
        'event': event,
        'date': Timestamp.fromDate(_selectedDay!),
        'uid': FirebaseAuth.instance.currentUser!.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  List getEventsForDay(DateTime day) {
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2000, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            onFormatChanged: (format) {
              setState(() => _calendarFormat = format);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: getEventsForDay, // 👈 VERY IMPORTANT
            calendarStyle: const CalendarStyle(
              markerDecoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_selectedDay != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(hintText: 'Add event'),
                      onSubmitted: (value) {
                        _addEvent(value.trim());
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.event),
                ],
              ),
            ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: getEventsForDay(_selectedDay ?? _focusedDay)
                  .map((event) => ListTile(title: Text(event)))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
