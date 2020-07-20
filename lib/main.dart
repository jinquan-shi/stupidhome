import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
  }

  //开锁控制
  Future<void> _unlock() async {
    final json = DefaultAssetBundle.of(context).loadString('assets/send.json');
    final data = JsonDecoder().convert(await json);
    Response response;
    Dio dio = Dio();
    try {
      //response = await dio.post("/test", data: data["unlock"]);
      response = await dio.get("http://www.baidu.com");
      print(response);
      showNotification("Unlocked!");
    } catch (e) {
      print("Fatal errors!!!");
    }
  }

  //上锁控制
  Future<void> _lock() async {
    final json = DefaultAssetBundle.of(context).loadString('assets/send.json');
    final data = JsonDecoder().convert(await json);
    Response response;
    Dio dio = Dio();
    try {
      //response = await dio.post("/test", data: data["lock"]);
      response = await dio.get("http://www.baidu.com");
      print(response);
    } catch (e) {
      print("Fatal errors!!!");
    }
  }

//发送通知
  showNotification(String preload) async {
    var android = new AndroidNotificationDetails(
        'channel id', 'channel NAME', 'CHANNEL DESCRIPTION',
        priority: Priority.High, importance: Importance.Max);
    var iOS = new IOSNotificationDetails();
    var platform = new NotificationDetails(android, iOS);
    await flutterLocalNotificationsPlugin.show(
      0,
      preload,
      'Flutter Local Notification',
      platform,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[],
        ),
      ),
      floatingActionButton: SpeedDial(child: Icon(Icons.menu), children: [
        SpeedDialChild(
            child: Icon(Icons.lock_outline),
            backgroundColor: Colors.red,
            label: '上锁',
            labelStyle: TextStyle(fontSize: 18.0),
            onTap: () => _lock()),
        SpeedDialChild(
          child: Icon(Icons.lock_open),
          backgroundColor: Colors.orange,
          label: '开锁',
          labelStyle: TextStyle(fontSize: 18.0),
          onTap: () => _unlock(),
        ),
      ]),
    );
  }
}
