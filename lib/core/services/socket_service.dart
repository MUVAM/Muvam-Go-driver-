import 'dart:convert';
import 'dart:io';
import 'package:muvam_rider/core/utils/app_logger.dart';

class SocketService {
  WebSocket? _socket;
  final String token;
  Function(Map<String, dynamic>)? onMessageReceived;

  SocketService(this.token);

  Future<void> connect() async {
    try {
      final uri = Uri.parse('ws://44.222.121.219/api/v1/ws');
      final headers = {
        'Authorization': 'Bearer $token',
        'Origin': 'http://44.222.121.219',
      };
      _socket = await WebSocket.connect(uri.toString(), headers: headers);
      _setupListeners();
      AppLogger.log('WebSocket connected!');
    } catch (e) {
      AppLogger.log('WebSocket connection error: $e');
      rethrow;
    }
  }

  void _setupListeners() {
    _socket?.listen(
      (event) {
        try {
          AppLogger.log('=== WEBSOCKET RAW MESSAGE ===');
          AppLogger.log('Raw event: $event');
          final data = jsonDecode(event) as Map<String, dynamic>;
          AppLogger.log('Parsed data: $data');
          AppLogger.log('Has callback: ${onMessageReceived != null}');
          if (onMessageReceived != null) {
            AppLogger.log('📨 Calling message callback');
            onMessageReceived!(data);
          } else {
            AppLogger.log('⚠️ No message callback set');
          }
          AppLogger.log('=== END WEBSOCKET MESSAGE ===\n');
        } catch (e) {
          AppLogger.log('❌ Error parsing message: $e');
        }
      },
      onDone: () {
        AppLogger.log('WebSocket connection closed');
      },
      onError: (error) {
        AppLogger.log('WebSocket error: $error');
      },
    );
  }

  void listenToMessages(Function(Map<String, dynamic>) callback) {
    onMessageReceived = callback;
  }

  void sendMessage(int rideId, String message) {
    AppLogger.log('=== SENDING CHAT MESSAGE ===');
    AppLogger.log('Ride ID: $rideId');
    AppLogger.log('Message: "$message"');
    AppLogger.log('Socket connected: ${_socket != null}');
    
    final payload = {
      'type': 'chat',
      'data': {'ride_id': rideId, 'message': message},
      'timestamp': DateTime.now().toIso8601String(),
    };

    AppLogger.log('Payload: $payload');
    final jsonMessage = jsonEncode(payload);
    AppLogger.log('JSON Message: $jsonMessage');
    
    try {
      _socket?.add(jsonMessage);
      AppLogger.log('✅ Message sent successfully');
    } catch (e) {
      AppLogger.log('❌ Failed to send message: $e');
    }
    AppLogger.log('=== END SENDING CHAT MESSAGE ===\n');
  }

  void disconnect() {
    _socket?.close();
    AppLogger.log('WebSocket disconnected');
  }

  void dispose() {
    _socket?.close();
    AppLogger.log('WebSocket closed');
  }
}
