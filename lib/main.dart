import 'dart:convert';

import 'package:dio/dio.dart';
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
  var _appId;
  var _deviceList = ['test1'];

  //初始化连接及通知服务
  @override
  void initState() {
    super.initState();
    _appId = 'app';
    player.setDataSource("rtmp://52.184.15.163:666/videotest/test",
        autoPlay: false);
    var android = new AndroidInitializationSettings('@mipmap/ic_launcher');
    var iOS = new IOSInitializationSettings();
    var initSetttings = new InitializationSettings(android, iOS);
    flutterLocalNotificationsPlugin.initialize(initSetttings,
        onSelectNotification: onSelectNotification);
    readJSON();
  }

  //通知初始化
  // ignore: missing_return
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

  //串流控制
  void _stream() {
    player.setDataSource(
        "https://sample-videos.com/video123/flv/240/big_buck_bunny_240p_10mb.flv",
        autoPlay: false);
    showDialog<Null>(
        context: context,
        builder: (BuildContext context) {
          return Scaffold(
            body: FijkView(
              player: player,
            ),
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
  Future<void> _listAdd() async {
    List tmp = [];
    List _listAvailableWifi = [];
    _listAvailableWifi = await WifiConfiguration.getWifiList();
    //仅供测试
    for (var item in _listAvailableWifi) {
      if (item.toString().split("-")[0] == "MicroPython") tmp.add(item);
    }
    _listAvailableWifi = tmp;
    showDialog<Null>(
      context: context,
      builder: (BuildContext context) {
        return new SimpleDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
          title: new Text('设备列表'),
          children: [
            for (var item in _listAvailableWifi)
              Card(
                elevation: 0.0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.0)),
                child: ListTile(
                  leading: Icon(Icons.wifi),
                  title: Text(item.toString()),
                  onTap: () async {
                    var connection = await WifiConfiguration.connectToWifi(
                        item.toString(),
                        'sl172919',
                        'stupidmembers.stupidhome');
                    if (!(connection == WifiConnectionStatus.alreadyConnected ||
                        connection == WifiConnectionStatus.connected)) {
                      Fluttertoast.showToast(
                        msg: "连接失败！",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.CENTER,
                        timeInSecForIosWeb: 1,
                        backgroundColor: Colors.grey[200],
                        textColor: Colors.black,
                      );
                      return;
                    }
                    var dio = Dio();
                    //TODO: need to set the home wifi
                    var request =
                        '{"magic_number":"123"，"app_id":"app"，"wifi":"wifi_name"，"password":"password"}';
                    var result = dio
                        .request('http://192.168.0.1:8989/',
                            data: jsonEncode(request))
                        .toString();
                    var _devideId = jsonDecode(result)["device_id"];
                    _client.sendMsg(
                        'add_app' +
                            _devideId +
                            _appId +
                            DateTime.fromMillisecondsSinceEpoch(
                                    DateTime.now().millisecondsSinceEpoch)
                                .toString(),
                        'toServer');
                    for (int i = 0; i < 10; i++) {
                      Future.delayed(Duration(milliseconds: 500), () {
                        try {
                          if (jsonDecode(_client.msgIn)["state"] == '0') {
                            Fluttertoast.showToast(
                              msg: "连接成功！",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.CENTER,
                              timeInSecForIosWeb: 1,
                              backgroundColor: Colors.grey[200],
                              textColor: Colors.black,
                            );
                            return;
                          }
                        } catch (e) {
                          if (i == 9) {
                            Fluttertoast.showToast(
                              msg: "连接失败！",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.CENTER,
                              timeInSecForIosWeb: 1,
                              backgroundColor: Colors.grey[200],
                              textColor: Colors.black,
                            );
                          }
                        }
                      });
                    }
                    _deviceList.add(_devideId);
                  },
                ),
              )
          ],
        );
      },
    );
  }

  //列表删除
  void _listDelete() {
    showDialog<Null>(
      context: context,
      builder: (BuildContext context) {
        return new SimpleDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
          title: new Text('设备列表'),
          children: [
            for (var item in _deviceList)
              Card(
                elevation: 0.0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.0)),
                child: ListTile(
                  leading: Icon(Icons.lock),
                  title: Text(item.toString()),
                  onTap: () {
                    setState(() {
                      _deviceList.remove(item);
                    });
                  },
                ),
              )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    _client = MqttApp('52.184.15.163', 'flutter_client', 1883);
    _client.connect().then((value) => _client.subscribe("get"));
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          for (var item in _deviceList)
            Card(
              elevation: 0.0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.0)),
              child: ListTile(
                leading: Icon(Icons.lock),
                title: Text(item.toString()),
                onTap: () {
                  showDialog<Null>(
                      context: context,
                      builder: (BuildContext context) {
                        return SimpleDialog(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.0)),
                          children: [
                            Card(
                              elevation: 0.0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14.0)),
                              child: ListTile(
                                leading: Icon(
                                  Icons.lock_outline,
                                  color: Colors.redAccent,
                                ),
                                title: Text('上锁'),
                                onTap: () {
                                  _lock();
                                },
                              ),
                            ),
                            Card(
                              elevation: 0.0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14.0)),
                              child: ListTile(
                                leading: Icon(
                                  Icons.lock_outline,
                                  color: Colors.orangeAccent,
                                ),
                                title: Text('开锁'),
                                onTap: () {
                                  _unlock();
                                },
                              ),
                            ),
                            Card(
                              elevation: 0.0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14.0)),
                              child: ListTile(
                                leading: Icon(
                                  Icons.camera,
                                  color: Colors.yellow,
                                ),
                                title: Text('串流'),
                                onTap: () {
                                  _stream();
                                },
                              ),
                            ),
                          ],
                        );
                      });
                },
              ),
            )
        ],
      ),
      floatingActionButton: SpeedDial(child: Icon(Icons.menu), children: [
        SpeedDialChild(
            child: Icon(Icons.add),
            backgroundColor: Colors.red,
            label: '添加设备',
            labelStyle: TextStyle(fontSize: 18.0),
            onTap: () => _listAdd()),
        SpeedDialChild(
          child: Icon(Icons.delete),
          backgroundColor: Colors.orange,
          label: '删除设备',
          labelStyle: TextStyle(fontSize: 18.0),
          onTap: () => _listDelete(),
        ),
      ]),
    );
  }
}
