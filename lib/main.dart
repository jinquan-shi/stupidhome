import 'dart:convert';

import 'package:fijkplayer/fijkplayer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:wifi_configuration/wifi_configuration.dart';
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
  final FijkPlayer player = FijkPlayer();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      new FlutterLocalNotificationsPlugin();
  var _client;
  var _json;
  var _data;
  List _listAvailableWifi;
  //初始化连接及通知服务
  @override
  void initState() {
    super.initState();
    player.setDataSource("rtmp://52.184.15.163:666/videotest/test",
        autoPlay: false);
    var android = new AndroidInitializationSettings('@mipmap/ic_launcher');
    var iOS = new IOSInitializationSettings();
    var initSetttings = new InitializationSettings(android, iOS);
    flutterLocalNotificationsPlugin.initialize(initSetttings,
        onSelectNotification: onSelectNotification);
    _client = MqttApp('52.184.15.163', 'flutter_client', 1883);
    readJSON();
  }

  //通知初始化
  Future onSelectNotification(String payload) {
    debugPrint("payload : $payload");
    showDialog(
      context: context,
      builder: (_) => new AlertDialog(
        title: new Text('Notification'),
        content: new Text('$payload'),
      ),
    );
  }

  //读取JSON
  Future<void> readJSON() async {
    _json = DefaultAssetBundle.of(context).loadString('assets/send.json');
    _data = JsonDecoder().convert(await _json);
  }

  //开锁控制
  void _unlock() {
    _client.sendMsg("print_msg3 hello world!", "test");
    Future.delayed(Duration(milliseconds: 5000), () {
      if (_client.msgIn == 'OK') {
        Fluttertoast.showToast(
          msg: "开锁成功",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
        print("ok");
        _showNotification();
      } else {
        Fluttertoast.showToast(
          msg: "开锁失败",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
        print("no");
        _showNotification();
      }
    });
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
  Future _showNotification() async {
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
        0, 'title', 'content', platformChannelSpecifics,
        payload: 'complete');
  }

  //列表添加
  Future<void> _list_add() async {
    List tmp = [];
    _listAvailableWifi = await WifiConfiguration.getWifiList();
    //仅供测试
    for (var item in _listAvailableWifi) {
      if (item.toString().split(" ")[0] == "LY") tmp.add(item);
    }
    _listAvailableWifi = tmp;
    showDialog<Null>(
      context: context,
      builder: (BuildContext context) {
        return new AlertDialog(
          useMaterialBorderRadius: true,
          title: new Text('设备列表'),
          content: Container(
            width: 70,
            height: 80,
            child: ListView.builder(
              itemCount: _listAvailableWifi.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_listAvailableWifi[index].toString()),
                  onTap: () {
                    var status = WifiConfiguration.connectToWifi(
                        _listAvailableWifi[index].toString(),
                        '',
                        "stupidmembers.stupidhome");
                    if (status ==0 ||
                        status ==1) {
                      print('succeed');
                    } else {
                      print('error');
                    }
                  },
                );
              },
            ),
          ),
        );
      },
    ).then((val) {
      print(val);
    });
  }

  //列表删除
  void _list_delete() {}
  @override
  Widget build(BuildContext context) {
    _client.connect().then((value) => _client.subscribe("get"));
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(),
      floatingActionButton: SpeedDial(child: Icon(Icons.menu), children: [
        SpeedDialChild(
            child: Icon(Icons.add),
            backgroundColor: Colors.red,
            label: '添加设备',
            labelStyle: TextStyle(fontSize: 18.0),
            onTap: () => _list_add()),
        SpeedDialChild(
          child: Icon(Icons.delete),
          backgroundColor: Colors.orange,
          label: '删除设备',
          labelStyle: TextStyle(fontSize: 18.0),
          onTap: () => _list_delete(),
        ),
      ]),
    );
  }
}
