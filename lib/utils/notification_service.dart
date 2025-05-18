import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzData;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void initializeTimeZones() {
  tzData.initializeTimeZones();
}

Future<void> showReminderNotification(String title, String body) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'reminder_channel_id',
    'Reminders',
    channelDescription: 'Test or scheduled reminders',
    importance: Importance.max,
    priority: Priority.high,
  );

  const NotificationDetails platformDetails = NotificationDetails(
    android: androidDetails,
  );

  await flutterLocalNotificationsPlugin.show(
    0, // Notification ID (you can make this dynamic)
    title,
    body,
    platformDetails,
  );
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
