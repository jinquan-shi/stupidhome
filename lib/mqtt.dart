import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class mqtt_app {
  MqttServerClient client;
  String msgIn;
  String msgOut;

  mqtt_app(String host, String identifier, int port) {
    this.client = MqttServerClient.withPort(host, identifier, port);
    connect();
  }
  Future<void> connect() async {
    client.logging(on: true);
    client.onConnected = _onConnected;
    client.onDisconnected = _onDisconnected;
    client.onUnsubscribed = _onUnsubscribed;

    client.onSubscribeFail = _onSubscribeFail;
    client.pongCallback = _pong;
    try {
      await client.connect();
      print("succeed");
    } catch (e) {
      print('Exception: $e');
      client.disconnect();
    }
  }

  void subscribe(String topic) {
    client.subscribe(topic, MqttQos.atMostOnce);
    client.onSubscribed(topic);
    client.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage message = c[0].payload;
      final payload =
          MqttPublishPayload.bytesToStringAsString(message.payload.message);
      msgIn = payload;
      print('Received message:$payload from topic: ${c[0].topic}>\n');
    });
  }

  void sendMsg(String msg, String pubTopic) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(msg);
    client.publishMessage(pubTopic, MqttQos.atLeastOnce, builder.payload);
  }

  void listen() {
    client.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage message = c[0].payload;

      final payload =
          MqttPublishPayload.bytesToStringAsString(message.payload.message);
      print(payload);
      print('Received message:$payload from topic: ${c[0].topic}>\n');
    });
  }

  // 连接成功
  void _onConnected() {
    print('Connected');
  }

  // 连接断开
  void _onDisconnected() {
    print('Disconnected');
  }

  // 订阅主题成功
  void _onSubscribed(String topic) {
    print('Subscribed topic: $topic');
  }

  // 订阅主题失败
  void _onSubscribeFail(String topic) {
    print('Failed to subscribe $topic');
  }

  // 成功取消订阅
  void _onUnsubscribed(String topic) {
    print('Unsubscribed topic: $topic');
  }

  // 收到 PING 响应
  void _pong() {
    print('Ping response client callback invoked');
  }
}
