import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter/foundation.dart';
import 'package:work_hub/core/constants/api_constants.dart';

class SocketService {
  io.Socket? _socket;

  static String get serverUrl => ApiConstants.socketUrl;

  void connect(String userId) {
    if (_socket?.connected == true) return;

    debugPrint('[SocketService] Connecting to $serverUrl for userId: $userId');

    _socket = io.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket!.connect();

    _socket!.onConnect((_) {
      debugPrint('[SocketService] Connected');
      _socket!.emit('register', userId);
    });

    _socket!.onDisconnect((_) {
      debugPrint('[SocketService] Disconnected');
    });

    _socket!.onConnectError((err) {
      debugPrint('[SocketService] Connect Error: $err');
    });
  }

  void onResumeDone(Function(Map<String, dynamic>) callback) {
    _socket?.on('resume:done', (data) {
      debugPrint('[SocketService] Received resume:done');
      if (data != null && data['success'] == true) {
        callback(data['data']);
      }
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}



