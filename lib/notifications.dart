import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final plugin=FlutterLocalNotificationsPlugin();
  bool ready=false;

  Future<void> init() async {
    if(ready||!(Platform.isAndroid||Platform.isIOS||Platform.isMacOS)) return;
    tzdata.initializeTimeZones();
    try {
      final zone=await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.name));
    } catch (_) {}
    const ios=DarwinInitializationSettings();
    await plugin.initialize(const InitializationSettings(android:AndroidInitializationSettings('@mipmap/ic_launcher'),iOS:ios,macOS:ios));
    ready=true;
  }

  Future<void> permission() async {
    await init();
    if(Platform.isAndroid) {
      await plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    } else if(Platform.isIOS||Platform.isMacOS) {
      await plugin.resolvePlatformSpecificImplementation<DarwinFlutterLocalNotificationsPlugin>()?.requestPermissions(alert:true,badge:true,sound:true);
    }
  }

  Future<void> test() async {
    await init(); if(!ready)return;
    const details=NotificationDetails(
      android:AndroidNotificationDetails('life_os','Life OS',channelDescription:'Life OS reminders',importance:Importance.high,priority:Priority.high),
      iOS:DarwinNotificationDetails(),macOS:DarwinNotificationDetails());
    await plugin.show(999,'LIFE OS','Notifications are working.',details);
  }

  Future<void> schedule(int id,String title,String body,DateTime when) async {
    await init(); if(!ready||when.isBefore(DateTime.now()))return;
    const details=NotificationDetails(
      android:AndroidNotificationDetails('life_os_reminders','Life OS Reminders',channelDescription:'Task and habit reminders',importance:Importance.high,priority:Priority.high),
      iOS:DarwinNotificationDetails(),macOS:DarwinNotificationDetails());
    await plugin.zonedSchedule(id,title,body,tz.TZDateTime.from(when,tz.local),details,androidScheduleMode:AndroidScheduleMode.inexactAllowWhileIdle);
  }
}
