import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

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
  final MqttClient client = MqttClient('test.mosquitto.org', '');

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

  //Mqtt 模块
  Future<MqttServerClient> connect() async {
    MqttServerClient client =
    MqttServerClient.withPort('broker.emqx.io', 'flutter_client', 1883);
    client.logging(on: true);
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;
    client.onUnsubscribed = onUnsubscribed;
    client.onSubscribed = onSubscribed;
    client.onSubscribeFail = onSubscribeFail;
    client.pongCallback = pong;

    final connMessage = MqttConnectMessage()
        .authenticateAs('username', 'password')
        .keepAliveFor(60)
        .withWillTopic('willtopic')
        .withWillMessage('Will message')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMessage;
    try {
      await client.connect();
    } catch (e) {
      print('Exception: $e');
      client.disconnect();
    }

    client.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage message = c[0].payload;
      final payload =
      MqttPublishPayload.bytesToStringAsString(message.payload.message);

      print('Received message:$payload from topic: ${c[0].topic}>');
    });

    return client;
  }
  // 连接成功
  void onConnected() {
    print('Connected');
  }

// 连接断开
  void onDisconnected() {
    print('Disconnected');
  }

// 订阅主题成功
  void onSubscribed(String topic) {
    print('Subscribed topic: $topic');
  }

// 订阅主题失败
  void onSubscribeFail(String topic) {
    print('Failed to subscribe $topic');
  }

// 成功取消订阅
  void onUnsubscribed(String topic) {
    print('Unsubscribed topic: $topic');
  }

// 收到 PING 响应
  void pong() {
    print('Ping response client callback invoked');
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
    var client=connect();
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
