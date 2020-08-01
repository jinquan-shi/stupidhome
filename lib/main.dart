import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fijkplayer/fijkplayer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stupidhome/notify.dart';
import 'package:wifi/wifi.dart';
import 'package:wifi_configuration/wifi_configuration.dart';
import 'mqtt.dart';

var deviceList = ['test1'];
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
  var _appId = 'app';

  var _dio = Dio();
  var _appTopic = 'toapp';
  NotificationManager notifier = NotificationManager();

  //初始化连接及通知服务
  @override
  void initState() {
    super.initState();
    player.setDataSource("rtmp://52.184.15.163:666/videotest/test",
        autoPlay: false);
    var android = new AndroidInitializationSettings('@mipmap/ic_launcher');
    var iOS = new IOSInitializationSettings();
    var initSetttings = new InitializationSettings(android, iOS);
    notifier.flutterLocalNotificationsPlugin
        .initialize(initSetttings, onSelectNotification: selectNotification);
  }

  //设置点击事件
  // ignore: missing_return
  Future<void> selectNotification(String payload) async {
    showDialog(
      context: context,
      builder: (_) => new SimpleDialog(
        children: [
          Container(
              child: Image(
                  image: NetworkImage("http://192.168.43.103:5000/get_pic"))),
          RaisedButton(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6.0)),
            child: Text('保存'),
            onPressed: () async {
              if (await Permission.storage.request().isDenied) {
                Permission.storage.request();
              }
              await Dio().download(
                'http://192.168.43.103:5000/get_pic',
                '/storage/emulated/0/DCIM/TEST.jpg',
              );
            },
          ),
        ],
      ),
    );
  }

  //开锁控制
  Future<void> _unlock() async {
    _client.sendMsg(
        "unlock device app " +
            DateTime.fromMillisecondsSinceEpoch(
                    DateTime.now().millisecondsSinceEpoch)
                .toString(),
        "toserver");
    //TODO:可能需要更改地址
    Response response = await _dio.post(
      'http://192.168.43.103:5000/test',
      data: {
        "name": "unlock",
        "topic": "device",
        "topic2": "app",
        "time": DateTime.fromMillisecondsSinceEpoch(
                DateTime.now().millisecondsSinceEpoch)
            .toString()
      },
    );
    print(response);
    if (response.data == '1') {
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
    var _flag = true;
    for (int i = 0; i < 10; i++) {
      if (_client.msgIn.split(' ')[0] == 'unlock_response')
        Future.delayed(Duration(milliseconds: 500), () {
          try {
            if (_client.msgIn.split(' ')[1] == '1') {
              Fluttertoast.showToast(
                msg: "开锁成功",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
              );
            } else if (_client.msgIn.split(' ')[1] == '0') {
              Fluttertoast.showToast(
                msg: "开锁失败",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
              );
            } else {
              Fluttertoast.showToast(
                msg: "设备故障",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
              );
              _flag = false;
            }
          } catch (e) {
            if (i == 9) {
              Fluttertoast.showToast(
                msg: "无法连接到设备！",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                timeInSecForIosWeb: 1,
                backgroundColor: Colors.grey[200],
                textColor: Colors.black,
              );
            }
          }
        });
      else
        continue;
      if (!_flag) break;
    }
  }

  //上锁控制
  Future<void> _lock() async {
    _client.sendMsg(
        "lock device app " +
            DateTime.fromMillisecondsSinceEpoch(
                    DateTime.now().millisecondsSinceEpoch)
                .toString(),
        "toserver");
    //TODO:可能需要更改地址
    Response response =
        await _dio.post('http://192.168.43.103:5000/test', data: {
      "name": "lock",
      "topic": "device",
      "topic2": "app",
      "time": DateTime.fromMillisecondsSinceEpoch(
              DateTime.now().millisecondsSinceEpoch)
          .toString()
    });
    if (response.data == '1') {
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
    var _flag = true;
    for (int i = 0; i < 10; i++) {
      if (_client.msgIn.split(' ')[0] == 'lock_response')
        Future.delayed(Duration(milliseconds: 500), () {
          try {
            if (_client.msgIn.split(' ')[1] == '1') {
              Fluttertoast.showToast(
                msg: "上锁成功",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
              );
            } else if (_client.msgIn.split(' ')[1] == '0') {
              Fluttertoast.showToast(
                msg: "上锁失败",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
              );
            } else {
              Fluttertoast.showToast(
                msg: "设备故障",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
              );
              _flag = false;
            }
          } catch (e) {
            if (i == 9) {
              Fluttertoast.showToast(
                msg: "无法连接到设备！",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                timeInSecForIosWeb: 1,
                backgroundColor: Colors.grey[200],
                textColor: Colors.black,
              );
            }
          }
        });
      else
        continue;
      if (_flag == false) break;
    }
  }

  //串流控制
  void _stream() {
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

  //图片下载
  Future<void> capture() async {
    //TODO:可能需要改地址
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: Text("Picture"),
            ),
            body: Column(
              children: [
                Container(
                    child: Image(
                        image: NetworkImage(
                            "http://192.168.43.103:5000/get_pic"))),
                RaisedButton(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6.0)),
                    child: Text('保存'),
                    onPressed: () async {
                      if (await Permission.storage.request().isDenied) {
                        Permission.storage.request();
                      }
                      await _dio.download(
                        'http://192.168.43.103:5000/get_pic',
                        '/storage/emulated/0/DCIM/TEST.jpg',
                      );
                    })
              ],
            ),
          );
        },
      ),
    );
  }

  //列表添加
  Future<void> _listAdd() async {
    if (await Permission.location.request().isDenied) {
      Permission.location.request();
    }
    List tmp = [];
    List _listAvailableWifi = [];
    List _listAvailableDevice = [];
    tmp = await WifiConfiguration.getWifiList();
    var tmp2 = tmp.toSet();
    var tmp3 = tmp2.toList();
    print('wifilist:' + tmp.toString());
    for (var item in tmp3) {
      if (item.toString().split("_")[0] == "ESP")
        _listAvailableDevice.add(item);
      else
        _listAvailableWifi.add(item);
    }
    print(_listAvailableWifi.toString());
    var title = '设备列表';
    var ssid, passsword;
    var controller = TextEditingController();
    showDialog<Null>(
        context: context,
        builder: (BuildContext context) {
          return new SimpleDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.0)),
              children: [
                Container(
                  height: 333,
                  child: Scaffold(
                    appBar: AppBar(
                      title: Text(title),
                    ),
                    body: Navigator(
                        // Navigator
                        initialRoute: '/abc',
                        onGenerateRoute: (val) {
                          RoutePageBuilder builder;
                          switch (val.name) {
                            case '/abc':
                              builder = (BuildContext nContext,
                                      Animation<double> animation,
                                      Animation<double> secondaryAnimation) =>
                                  Column(
                                    // 并没有在 MaterialApp 中设定 /efg 路由
                                    // 因为Navigator的特性 使用nContext 可以跳转 /efg
                                    children: <Widget>[
                                      for (var item in _listAvailableDevice)
                                        Card(
                                          elevation: 0.0,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14.0)),
                                          child: ListTile(
                                            leading: Icon(Icons.wifi),
                                            title: Text(item.toString()),
                                            onTap: () async {
                                              var connection =
                                                  await WifiConfiguration
                                                      .connectToWifi(
                                                          item.toString(),
                                                          '12345678',
                                                          'stupidmembers.stupidhome');
                                              setState(() {
                                                title = '选择WiFI';
                                              });
                                              Navigator.pushNamed(
                                                  nContext, title);
                                            },
                                          ),
                                        ),
                                    ],
                                  );
                              break;
                            case '选择WiFI':
                              builder = (BuildContext nContext,
                                      Animation<double> animation,
                                      Animation<double> secondaryAnimation) =>
                                  SingleChildScrollView(
                                    child: Column(
                                      children: <Widget>[
                                        for (var item in _listAvailableWifi)
                                          Card(
                                            elevation: 0.0,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        14.0)),
                                            child: ListTile(
                                              leading: Icon(Icons.wifi),
                                              title: Text(item.toString()),
                                              onTap: () async {
                                                ssid = item;
                                                setState(() {
                                                  title = '输入密码';
                                                });
                                                Navigator.pushNamed(
                                                    nContext, title);
                                              },
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                              break;
                            default:
                              builder = (BuildContext nContext,
                                      Animation<double> animation,
                                      Animation<double> secondaryAnimation) =>
                                  Column(
                                    children: [
                                      TextField(
                                        controller: controller,
                                      ),
                                      RaisedButton(
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(6.0)),
                                        child: Text('确认'),
                                        onPressed: () async {
                                          passsword = controller.text;
                                          var request = {
                                            "magic_number": "123",
                                            "app_topic": 'app',
                                            "app_id": "app",
                                            "wifi": ssid,
                                            "password": passsword
                                          };
                                          Response result;

                                          result = await _dio.post(
                                              'http://192.168.0.2:8989',
                                              data: request);

                                          var _deviceId = jsonDecode(
                                                  result.data)["device_id"]
                                              .toString();
                                          var _flag = true;
                                          var _deviceTopic = jsonDecode(
                                                  result.data)["device_topic"]
                                              .toString();
                                          await WifiConfiguration.connectToWifi(
                                              ssid,
                                              passsword,
                                              'stupidmembers.stupidhome')
                                              .then((value) =>
                                                  _client.mqttdisconnect());
                                          print('wifi connected');
//                                          Future.delayed(
//                                              Duration(milliseconds: 1000),
//                                              () async {
//                                            await _client.connect();
//                                          });
                                                _client.subscribe(_appTopic);

                                          Future.delayed(
                                              Duration(milliseconds: 1000),
                                              () async {
                                            await _client.sendMsg(
                                                'add_app ' +
                                                    _deviceId +
                                                    ' ' +
                                                    _deviceTopic +
                                                    ' ' +
                                                    _appId +
                                                    ' ' +
                                                    _appTopic +
                                                    ' ' +
                                                    DateTime.fromMillisecondsSinceEpoch(
                                                            DateTime.now()
                                                                .millisecondsSinceEpoch)
                                                        .toString(),
                                                'toserver');
                                          }).then((val) => () {
                                                for (int i = 0; i < 10; i++) {
                                                  try {
                                                    if (_client.msgIn[
                                                            "action_name"] ==
                                                        'hand_shake')
                                                      Future.delayed(
                                                          Duration(
                                                              milliseconds:
                                                                  500), () {
                                                        try {
                                                          if (_client.msgIn[
                                                                  'state'] ==
                                                              0) {
                                                            Fluttertoast
                                                                .showToast(
                                                              msg: "连接成功！",
                                                              toastLength: Toast
                                                                  .LENGTH_SHORT,
                                                              gravity:
                                                                  ToastGravity
                                                                      .BOTTOM,
                                                              timeInSecForIosWeb:
                                                                  1,
                                                              backgroundColor:
                                                                  Colors.grey[
                                                                      200],
                                                              textColor:
                                                                  Colors.black,
                                                            );
                                                            setState(() {
                                                              deviceList.add(
                                                                  _deviceId);
                                                            });
                                                            _client.msgIn = {};
                                                          }
                                                        } catch (e) {
                                                          if (i == 9) {
                                                            Fluttertoast
                                                                .showToast(
                                                              msg: "连接失败！",
                                                              toastLength: Toast
                                                                  .LENGTH_SHORT,
                                                              gravity:
                                                                  ToastGravity
                                                                      .BOTTOM,
                                                              timeInSecForIosWeb:
                                                                  1,
                                                              backgroundColor:
                                                                  Colors.grey[
                                                                      200],
                                                              textColor:
                                                                  Colors.black,
                                                            );
                                                          }
                                                        }
                                                      });
                                                    else
                                                      continue;
                                                    if (!_flag) break;
                                                  } catch (e) {
                                                    if (i == 9)
                                                      Fluttertoast.showToast(
                                                        msg: "连接失败！",
                                                        toastLength:
                                                            Toast.LENGTH_SHORT,
                                                        gravity:
                                                            ToastGravity.BOTTOM,
                                                        timeInSecForIosWeb: 1,
                                                        backgroundColor:
                                                            Colors.grey[200],
                                                        textColor: Colors.black,
                                                      );
                                                  }
                                                }
                                              });

                                          setState(() {
                                            _listAvailableWifi = [];
                                            _listAvailableDevice = [];
                                          });
                                        },
                                      )
                                    ],
                                  );
                          }
                          return PageRouteBuilder(
                            pageBuilder: builder,
                            // transitionDuration: const Duration(milliseconds: 0),
                          );
                        },
                        observers: <NavigatorObserver>[]),
                  ),
                )
              ]);
        });
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
            for (var item in deviceList)
              Card(
                elevation: 0.0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.0)),
                child: ListTile(
                  leading: Icon(Icons.lock),
                  title: Text(item.toString()),
                  onTap: () {
                    setState(() {
                      deviceList.remove(item);
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
    _client = MqttApp('52.184.15.163', 'flutter_client', 1883, notifier);
    _client.connect().then((value) => _client.subscribe(_appTopic));
    final timer = Timer.periodic(Duration(milliseconds: 600000), (timer) {
      _client.msgIn = '';
    });
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          for (var item in deviceList)
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
