import 'dart:convert';
import 'dart:io';
import 'package:muvam_rider/core/utils/app_logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/url_constants.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  bool _isConnecting = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  // Callback for ride requests
  Function(Map<String, dynamic>)? onRideRequest;

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    AppLogger.log('🚀 WEBSOCKET CONNECT METHOD CALLED');

    if (_isConnected) {
      AppLogger.log('⚠️ WebSocket already connected, skipping...');
      return;
    }

    if (_isConnecting) {
      AppLogger.log('⚠️ Connection already in progress, skipping...');
      return;
    }

    _isConnecting = true;

    try {
      final token = await _getToken();
      AppLogger.log(
        '🔍 Token check result: ${token != null ? 'Found' : 'Not found'}',
      );
      if (token == null) {
        AppLogger.log('❌ No auth token found for WebSocket');
        return;
      }

      AppLogger.log('=== WEBSOCKET CONNECTION START ===');
      AppLogger.log('🔗 Connecting to: ${UrlConstants.webSocketUrl}');
      AppLogger.log('🔑 Using token: ${token.substring(0, 20)}...');
      AppLogger.log('⏰ Connection time: ${DateTime.now()}');
      AppLogger.log('🌐 Attempting WebSocket.connect...');

      final webSocket = await WebSocket.connect(
        UrlConstants.webSocketUrl,
        headers: {'Authorization': 'Bearer $token'},
      );

      AppLogger.log('🔌 WebSocket.connect completed');
      _channel = IOWebSocketChannel(webSocket);
      _isConnected = true;
      AppLogger.log('✅ WebSocket connected successfully!');
      AppLogger.log('🎯 Ready to receive messages...');
      AppLogger.log('📊 Connection state: $_isConnected');
      AppLogger.log('📡 Channel created: ${_channel != null}');

      _channel!.stream.listen(
        (message) {
          AppLogger.log('📥 WebSocket message received at ${DateTime.now()}');
          _handleMessage(message);
        },
        onError: (error) {
          AppLogger.log('❌ WebSocket error: $error');
          _isConnected = false;
          _isConnecting = false;
          _reconnectAttempts++;
          if (_reconnectAttempts <= _maxReconnectAttempts) {
            _reconnect();
          }
        },
        onDone: () {
          AppLogger.log('🔌 WebSocket connection closed at ${DateTime.now()}');
          AppLogger.log('🔍 Close reason: Server closed connection');
          _isConnected = false;
          _isConnecting = false;
          _reconnectAttempts++;
          if (_reconnectAttempts <= _maxReconnectAttempts) {
            _reconnect();
          }
        },
      );

      AppLogger.log('✅ WebSocket listener setup complete');
      _reconnectAttempts = 0; // Reset on successful connection
      _isConnecting = false;

      AppLogger.log('🎯 WebSocket ready - no automatic test message sent');
    } catch (e) {
      AppLogger.log('❌ Failed to connect WebSocket: $e');
      _isConnected = false;
      _isConnecting = false;
      _reconnectAttempts++;

      if (_reconnectAttempts <= _maxReconnectAttempts) {
        final delay = _getReconnectDelay();
        AppLogger.log(
          '🔄 Will attempt reconnection #$_reconnectAttempts in ${delay}s...',
        );
        _reconnect();
      } else {
        AppLogger.log(
          '❌ Max reconnection attempts reached. Stopping reconnection.',
        );
      }
    }
    AppLogger.log('=== WEBSOCKET CONNECTION END ===\n');
  }

  void _reconnect() async {
    final delay = _getReconnectDelay();
    await Future.delayed(Duration(seconds: delay));
    if (!_isConnected && !_isConnecting) {
      connect();
    }
  }

  int _getReconnectDelay() {
    // Exponential backoff: 3, 6, 12, 24, 60 seconds
    switch (_reconnectAttempts) {
      case 1:
        return 3;
      case 2:
        return 6;
      case 3:
        return 12;
      case 4:
        return 24;
      default:
        return 60;
    }
  }

  void _handleMessage(dynamic message) {
    AppLogger.log('=== WEBSOCKET MESSAGE RECEIVED ===');
    AppLogger.log('🚨🚨🚨 ACTUAL RAW WEBSOCKET MESSAGE START 🚨🚨🚨');
    AppLogger.log('📨 RAW MESSAGE: $message');
    AppLogger.log('📋 Message type: ${message.runtimeType}');
    AppLogger.log('📏 Message length: ${message.toString().length}');
    AppLogger.log('📄 FULL RAW MESSAGE CONTENT: ${message.toString()}');
    AppLogger.log('🔍 RAW MESSAGE AS STRING: "${message.toString()}"');
    AppLogger.log('🔍 RAW MESSAGE BYTES: ${message.toString().codeUnits}');
    AppLogger.log('🚨🚨🚨 ACTUAL RAW WEBSOCKET MESSAGE END 🚨🚨🚨');

    if (message == null) {
      AppLogger.log('⚠️ Message is NULL');
    } else if (message.toString().isEmpty) {
      AppLogger.log('⚠️ Message is EMPTY STRING');
    } else {
      AppLogger.log('✅ Message has content: "${message.toString()}"');
    }

    try {
      AppLogger.log('🔄 Attempting to parse JSON from raw message...');
      final data = jsonDecode(message);
      AppLogger.log('🔍 Parsed JSON: $data');
      AppLogger.log('🔍 JSON keys: ${data.keys.toList()}');
      final type = data['type'];
      AppLogger.log('🏷️ Message type from JSON: $type');
      AppLogger.log('🏷️ All data fields: ${data.toString()}');

      switch (type) {
        case 'ride_request':
        case 'new_ride':
          _handleRideRequest(data);
          break;
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
          AppLogger.log('Unknown message type: $type');
          AppLogger.log('Full message data: $data');
      }
    } catch (e) {
      AppLogger.log('Error parsing WebSocket message: $e');
      AppLogger.log('Raw message that failed: $message');
    }
    AppLogger.log('=== END WEBSOCKET MESSAGE ===\n');
  }

  void _handleRideRequest(Map<String, dynamic> data) {
    AppLogger.log('🚗 NEW RIDE REQUEST RECEIVED:');
    AppLogger.log('   Data: $data');

    // Transform WebSocket data to expected format
    final rideData = data['data'] ?? {};
    final passengerName =
        rideData['passenger_name']?.toString() ?? 'Unknown Passenger';
    final nameParts = passengerName.split(' ');

    final transformedRide = {
      'ID': rideData['ride_id'],
      'Price': rideData['price']?.toString() ?? '0',
      'PickupAddress':
          rideData['pickup_address']?.toString() ?? 'Unknown pickup',
      'DestAddress':
          rideData['dest_address']?.toString() ?? 'Unknown destination',
      'Note': rideData['note']?.toString() ?? '',
      'PaymentMethod': 'in_car',
      'pickup_location': rideData['pickup_location']?.toString() ?? '',
      'dest_location': rideData['dest_location']?.toString() ?? '',
      'Passenger': {
        'first_name': nameParts.isNotEmpty ? nameParts.first : 'Unknown',
        'last_name': nameParts.length > 1
            ? nameParts.skip(1).join(' ')
            : 'Passenger',
      },
      'Status': 'pending',
    };

    AppLogger.log('🔄 Transformed ride data: $transformedRide');

    if (onRideRequest != null) {
      onRideRequest!(transformedRide);
    }
  }

  void _handleRideAccepted(Map<String, dynamic> data) {
    AppLogger.log('🚗 RIDE ACCEPTED MESSAGE:');
    AppLogger.log('   Data: $data');
  }

  void _handleRideUpdate(Map<String, dynamic> data) {
    AppLogger.log('📱 RIDE UPDATE MESSAGE:');
    AppLogger.log('   Data: $data');
  }

  void _handleChatMessage(Map<String, dynamic> data) {
    AppLogger.log('💬 CHAT MESSAGE:');
    AppLogger.log('   Data: $data');
  }

  void _handleDriverLocation(Map<String, dynamic> data) {
    AppLogger.log('📍 DRIVER LOCATION MESSAGE:');
    AppLogger.log('   Data: $data');
  }

  void sendMessage(Map<String, dynamic> message) {
    AppLogger.log('=== WEBSOCKET SEND DEBUG ===');
    AppLogger.log('Connected: $_isConnected');
    AppLogger.log('Channel exists: ${_channel != null}');
    AppLogger.log('Raw message: $message');

    if (!_isConnected || _channel == null) {
      AppLogger.log('❌ WebSocket not ready - forcing reconnect');
      _forceReconnectAndSend(message);
      return;
    }

    try {
      final jsonMessage = jsonEncode(message);
      AppLogger.log('📤 Sending exact JSON: $jsonMessage');
      AppLogger.log('📤 Message length: ${jsonMessage.length} chars');

      _channel!.sink.add(jsonMessage);
      AppLogger.log('✅ Message added to sink successfully');

      // Force flush
      if (_channel!.sink is IOSink) {
        (_channel!.sink as IOSink).flush();
        AppLogger.log('✅ Sink flushed');
      }
    } catch (e, stackTrace) {
      AppLogger.log('❌ Send failed: $e');
      AppLogger.log('❌ Stack: $stackTrace');
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
      AppLogger.log('✅ Message sent after forced reconnection');
    } else {
      AppLogger.log('❌ Forced reconnection failed');
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
      _isConnecting = false;
      _reconnectAttempts = 0;
      AppLogger.log('WebSocket disconnected');
    }
  }

  void resetConnection() {
    AppLogger.log('🔄 Resetting WebSocket connection...');
    disconnect();
    _reconnectAttempts = 0;
    connect();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  void testConnection() {
    AppLogger.log('=== CONNECTION TEST ===');
    AppLogger.log('_isConnected: $_isConnected');
    AppLogger.log('_channel != null: ${_channel != null}');
    if (_channel != null) {
      AppLogger.log('Channel type: ${_channel.runtimeType}');
      AppLogger.log('Sink type: ${_channel!.sink.runtimeType}');
    }

    AppLogger.log('Use sendTestMessage() to manually test connection');
  }

  void sendTestMessage() {
    AppLogger.log('🧪 Sending manual test message...');
    sendMessage({
      'type': 'ping',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void sendHeartbeat() {
    if (_isConnected) {
      sendMessage({
        'type': 'heartbeat',
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }
}
