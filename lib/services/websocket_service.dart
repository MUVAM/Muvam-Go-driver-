import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/url_constants.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  
  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected) return;
    
    try {
      final token = await _getToken();
      if (token == null) {
        print('No auth token found');
        return;
      }
      
      print('=== WEBSOCKET CONNECTION ===');
      print('Connecting to: ${UrlConstants.wsUrl}');
      
      final webSocket = await WebSocket.connect(
        UrlConstants.wsUrl,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      _channel = IOWebSocketChannel(webSocket);
      _isConnected = true;
      print('WebSocket connected successfully');
      
      _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
          print('WebSocket error: $error');
          _isConnected = false;
          _reconnect();
        },
        onDone: () {
          print('WebSocket connection closed');
          _isConnected = false;
          _reconnect();
        },
      );
    } catch (e) {
      print('Failed to connect WebSocket: $e');
      _isConnected = false;
      _reconnect();
    }
  }

  void _reconnect() async {
    await Future.delayed(Duration(seconds: 3));
    if (!_isConnected) {
      print('Attempting to reconnect WebSocket...');
      connect();
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      final type = data['type'];
      
      switch (type) {
        case 'ride_accepted':
          _handleRideAccepted(data);
          break;
        case 'ride_update':
          _handleRideUpdate(data);
          break;
        case 'chat_message':
          _handleChatMessage(data);
          break;
        case 'driver_location':
          _handleDriverLocation(data);
          break;
        default:
          print('Unknown message type: $type');
      }
    } catch (e) {
      print('Error parsing WebSocket message: $e');
    }
  }

  void _handleRideAccepted(Map<String, dynamic> data) {
    print('Ride accepted: $data');
  }

  void _handleRideUpdate(Map<String, dynamic> data) {
    print('Ride update: $data');
  }

  void _handleChatMessage(Map<String, dynamic> data) {
    print('Chat message: $data');
  }

  void _handleDriverLocation(Map<String, dynamic> data) {
    print('Driver location: $data');
  }

  void sendMessage(Map<String, dynamic> message) {
    if (!_isConnected || _channel == null) {
      print('WebSocket not ready - forcing reconnect');
      _forceReconnectAndSend(message);
      return;
    }
    
    try {
      final jsonMessage = jsonEncode(message);
      _channel!.sink.add(jsonMessage);
    } catch (e) {
      print('Send failed: $e');
      _isConnected = false;
    }
  }
  
  void _forceReconnectAndSend(Map<String, dynamic> message) async {
    _isConnected = false;
    _channel = null;
    
    await connect();
    
    if (_isConnected && _channel != null) {
      final jsonMessage = jsonEncode(message);
      _channel!.sink.add(jsonMessage);
    }
  }

  void sendChatMessage(String message, String rideId) {
    sendMessage({
      'type': 'chat_message',
      'message': message,
      'ride_id': rideId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void sendRideRequest(Map<String, dynamic> rideData) {
    sendMessage({
      'type': 'ride_request',
      'data': rideData,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void disconnect() {
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
      _isConnected = false;
      print('WebSocket disconnected');
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}