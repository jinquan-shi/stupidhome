import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'mqtt.dart';

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
  var _client;
  var _json;
  var _data;
  @override
  void initState() {
    super.initState();
    flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
    readJSON();
  }

  //读取JSON
  Future<void> readJSON() async {
    _json = DefaultAssetBundle.of(context).loadString('assets/send.json');
    _data = JsonDecoder().convert(await _json);
  }

  //开锁控制
  void _unlock() {
    _client.sendMsg(_data["unlock"].toString(), "out");
    if (_client.msgIn == 'OK') {
      Fluttertoast.showToast(
        msg: "开锁成功",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      print("ok");
    } else {
      Fluttertoast.showToast(
        msg: "开锁失败",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      print("no");
    }
  }

  //上锁控制
  Future<void> _lock() async {
    _client.sendMsg(_data["lock"].toString(), "out");
    Future.delayed(Duration(milliseconds: 1000), () {
      if (_client.msgIn == 'OK')
        Fluttertoast.showToast(
          msg: "上锁成功",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      else
        Fluttertoast.showToast(
          msg: "上锁失败",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
    });
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
    Future(() {
      _client = mqtt_app('broker.emqx.io', 'flutter_client', 1883);
    }).then((value) => _client.subscribe("get"));

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
