import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationManager {
  BuildContext context;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  NotificationManager();

  //发送通知
  Future showNotification(String title, String content) async {
    //安卓的通知配置，必填参数是渠道id, 名称, 和描述, 可选填通知的图标，重要度等等。
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        '1', 'your channel name', 'your channel description',
        importance: Importance.Max, priority: Priority.High);
    //IOS的通知配置
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    var platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    //显示通知，其中 0 代表通知的 id，用于区分通知。
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      content,
      platformChannelSpecifics,
      payload: 'complete',
    );
  }
}
