import 'dart:convert';
import 'dart:io';
import 'package:muvam_rider/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/url_constants.dart';

class WebSocketService {
  static WebSocketService? _instance;
  WebSocket? _socket;
  final String? token;
  bool _isConnected = false;
  bool _isConnecting = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  // Callbacks for different message types
  Function(dynamic)? onMessageReceived;
  Function(Map<String, dynamic>)? onRideAccepted;
  Function(Map<String, dynamic>)? onRideUpdate;
  Function(Map<String, dynamic>)? onChatMessage;
  Function(Map<String, dynamic>)? onDriverLocation;
Function(Map<String, dynamic>)? onRideCancelled;
  // List of listeners for incoming calls instead of single callback
  final List<Function(Map<String, dynamic>)> _incomingCallListeners = [];

  // Deprecated: use addIncomingCallListener
  set onIncomingCall(Function(Map<String, dynamic>)? callback) {
    if (callback != null) {
      addIncomingCallListener(callback);
    }
  }

  // Helper to maintain compatibility but it's not a true getter anymore
  Function(Map<String, dynamic>)? get onIncomingCall =>
      _incomingCallListeners.isNotEmpty ? _incomingCallListeners.last : null;

  void addIncomingCallListener(Function(Map<String, dynamic>) listener) {
    if (!_incomingCallListeners.contains(listener)) {
      _incomingCallListeners.add(listener);
      AppLogger.log(
        'Added incoming call listener. Total listeners: ${_incomingCallListeners.length}',
      );
    }
  }

  void removeIncomingCallListener(Function(Map<String, dynamic>) listener) {
    _incomingCallListeners.remove(listener);
    AppLogger.log(
      'Removed incoming call listener. Remaining listeners: ${_incomingCallListeners.length}',
    );
  }

  Function(Map<String, dynamic>)?
  onRideCompleted; // Callback for ride completion
  Function(Map<String, dynamic>)? onRideRequest;

  bool get isConnected => _isConnected;

  // Singleton pattern
  static WebSocketService get instance {
    _instance ??= WebSocketService._internal();
    return _instance!;
  }

  WebSocketService._internal() : token = null;
  Function(Map<String, dynamic>)? onChatNotification;

  Future<void> connect() async {
    //NATIVE WEBSOCKET CONNECT');

    if (_isConnected) {
      //Already connected');
      return;
    }

    if (_isConnecting) {
      //Connection in progress');
      return;
    }

    _isConnecting = true;

    try {
      // Get token from storage
      final authToken = await _getToken();
      if (authToken == null) {
        //No auth token found');
        _isConnecting = false;
        return;
      }

      //═══════════════════════════════════════');
      //NATIVE WEBSOCKET CONNECTION');
      //═══════════════════════════════════════');
      //URL: ${UrlConstants.wsUrl}');
      //Token: ${authToken.substring(0, 20)}...');
      //Time: ${DateTime.now()}');
      //═══════════════════════════════════════');
      String url = UrlConstants.wsUrl;
      if (url.startsWith('https://')) {
        url = url.replaceFirst('https://', 'wss://');
      } else if (url.startsWith('http://')) {
        url = url.replaceFirst('http://', 'ws://');
      }
      // Parse URL
      final uri = Uri.parse(url);

      // Headers - Try lowercase 'authorization' to match Postman exactly
      final headers = {'authorization': 'Bearer $authToken'};

      //Headers:');
      headers.forEach((key, value) {
        AppLogger.log(
          ' headerss  $key: ${value.length > 50 ? "${value.substring(0, 50)}..." : value}',
        );
      });

      // Connect using native WebSocket
      //Connecting...');
      _socket = await WebSocket.connect(uri.toString(), headers: headers);

      //WebSocket connected!');
      //   ReadyState: ${_socket!.readyState}');
      //');

      // CRITICAL: Setup listeners IMMEDIATELY and SYNCHRONOUSLY
      //Setting up listeners NOW...');
      _setupListenersSync();
      //Listeners attached');
      //');

      // Small delay to let the connection stabilize
      //Stabilizing connection...');
      await Future.delayed(Duration(milliseconds: 200));
      //Connection stabilized');
      //');

      // NOW it's safe to mark as connected
      _reconnectAttempts = 0;
      _isConnecting = false;
      _isConnected = true;

      //Native WebSocket FULLY ready');
      //═══════════════════════════════════════');
      //');
    } catch (e, stack) {
      //Connection error: $e');
      //Stack: $stack');
      _isConnected = false;
      _isConnecting = false;
      _socket = null;
      _reconnectAttempts++;

      if (_reconnectAttempts <= _maxReconnectAttempts) {
        _reconnect();
      }
    }
  }

  // CRITICAL: Synchronous listener setup - no async gaps
  void _setupListenersSync() {
    if (_socket == null) {
      //Cannot setup listeners - socket is null');
      return;
    }

    //   Attaching onData handler...');
    //   Attaching onDone handler...');
    //   Attaching onError handler...');

    _socket!.listen(
      (event) {
        //');
        //═══════════════════════════════════════');
        //MESSAGE RECEIVED');
        //═══════════════════════════════════════');
        //Time: ${DateTime.now()}');
        //Event type: ${event.runtimeType}');
        //Raw event: $event');

        try {
          // Handle both String and List<int> responses
          String messageStr;
          if (event is String) {
            messageStr = event;
          } else if (event is List<int>) {
            messageStr = utf8.decode(event);
          } else {
            messageStr = event.toString();
          }

          //Decoded message: $messageStr');

          final data = jsonDecode(messageStr);
          //Parsed JSON: $data');
          //Message type: ${data['type']}');
          //═══════════════════════════════════════');
          //');

          // Call general message callback
          if (onMessageReceived != null) {
            onMessageReceived!(data);
          }

          // Route to specific handlers
          _handleMessage(data);
        } catch (e, stack) {
          //Message parse error: $e');
          //Stack: $stack');
          //═══════════════════════════════════════');
          //');
        }
      },
      onDone: () {
        //');
        //═══════════════════════════════════════');
        //WebSocket connection CLOSED');
        //═══════════════════════════════════════');
        //Time: ${DateTime.now()}');
        //Close code: ${_socket?.closeCode}');
        //Close reason: ${_socket?.closeReason}');
        //Was Connected: $_isConnected');
        //Is Connecting: $_isConnecting');
        //═══════════════════════════════════════');
        //');

        bool wasConnected = _isConnected;
        _isConnected = false;
        _isConnecting = false;

        // Only reconnect if we were actually connected (not during initial setup)
        if (wasConnected) {
          _reconnectAttempts++;
          if (_reconnectAttempts <= _maxReconnectAttempts) {
            _reconnect();
          }
        }
      },
      onError: (error) {
        //');
        //═══════════════════════════════════════');
        //WebSocket ERROR');
        //═══════════════════════════════════════');
        //Time: ${DateTime.now()}');
        //Error: $error');
        //Error type: ${error.runtimeType}');
        //═══════════════════════════════════════');
        //');

        _isConnected = false;
        _isConnecting = false;
      },
      cancelOnError: false,
    );

    //   All handlers attached successfully');
  }

  void _handleMessage(Map<String, dynamic> data) async {
    final type = data['type'];
    //Routing message type: $type');
AppLogger.log('📨 RAW MESSAGE TYPE from driver: "$type" | Full data: $data');
    switch (type) {
      case 'ride_cancelled':
      case 'ride_cancel':
      case 'cancel_ride':
        AppLogger.log('🚫 Ride cancelled message received: $data');
        if (onRideCancelled != null) {
          onRideCancelled!(data);
        }
        break;
      case 'ride_accepted':
        //   ride_accepted handler');
        if (onRideAccepted != null) onRideAccepted!(data);
        break;
      case 'ride_update':
        //   ride_update handler');
        if (onRideUpdate != null) onRideUpdate!(data);
        break;
      case 'chat':
      case 'chat_message':
        //   chat handler');
        if (onChatMessage != null) {
          onChatMessage!(data);
        } else {
          //   No chat handler registered!');
        }
        break;
      case 'driver_location':
        //   driver_location handler');
        if (onDriverLocation != null) onDriverLocation!(data);
        break;
      case 'call_initiate':
      case 'call_answer':
      case 'call_reject':
      case 'call_end':
      case 'call_offer':
      case 'call_answer_sdp':
      case 'call_ice_candidate':
        //   call handler');
        // CRITICAL FIX: Filter call messages based on recipient
        await _handleCallMessage(data, type);
        break;
      case 'ride_completed':
        //Ride completed message received: $data');
        if (onRideCompleted != null) {
          onRideCompleted!(data);
        } else {
          //No ride completed handler registered!');
        }
        break;
      case 'ride_request':
      case 'new_ride':
        //   ride_request handler');
        if (onRideRequest != null) onRideRequest!(data);
        break;
      default:
      //   Unknown message type: $type');
    }
  }

  // CRITICAL FIX: Filter call messages to ensure they go to the right recipient
  Future<void> _handleCallMessage(
    Map<String, dynamic> data,
    String type,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('user_id');

      //═══════════════════════════════════════');
      //CALL MESSAGE FILTERING');
      //═══════════════════════════════════════');
      //Message type: $type');
      //Current user ID: $currentUserId');

      final messageData = data['data'];
      if (messageData != null) {
        final callerId = messageData['caller_id']?.toString();
        final recipientId = messageData['recipient_id']?.toString();

        //Caller ID: $callerId');
        //Recipient ID: $recipientId');

        // For call_initiate: only show to recipient (not the caller)
        if (type == 'call_initiate') {
          if (recipientId != null && recipientId == currentUserId) {
            //This user IS the recipient - showing incoming call');
            AppLogger.log(
              'onIncomingCall listeners count: ${_incomingCallListeners.length}',
            );
            if (_incomingCallListeners.isNotEmpty) {
              AppLogger.log(
                'Notify all ${_incomingCallListeners.length} incoming call listeners...',
              );
              try {
                for (var listener in List.from(_incomingCallListeners)) {
                  try {
                    listener(data);
                  } catch (e) {
                    //Error in listener: $e');
                  }
                }
                //All listeners notified successfully');
              } catch (e, stack) {
                //Error calling listeners: $e');
                //Stack: $stack');
              }
            } else {
              //No incoming call listeners registered!');
            }
          } else if (callerId == currentUserId) {
            //This user is the CALLER - ignoring call_initiate');
          } else {
            //This call is for someone else - ignoring');
          }
        }
        // For other call messages: route to the appropriate party
        else {
          // call_answer, call_reject, call_end should go to the caller
          if (type == 'call_answer' ||
              type == 'call_reject' ||
              type == 'call_end') {
            if (callerId == currentUserId) {
              //Routing $type to caller');
              for (var listener in List.from(_incomingCallListeners)) {
                try {
                  listener(data);
                } catch (e) {
                  //Error in listener: $e');
                }
              }
            } else {
              //This message is not for this user');
            }
          }
          // WebRTC signaling messages (offer, answer, ICE) should go to both parties
          else if (type == 'call_offer' ||
              type == 'call_answer_sdp' ||
              type == 'call_ice_candidate') {
            if (recipientId == currentUserId) {
              //Routing WebRTC message to recipient');
              for (var listener in List.from(_incomingCallListeners)) {
                try {
                  listener(data);
                } catch (e) {
                  //Error in listener: $e');
                }
              }
            } else {
              //WebRTC message not for this user');
            }
          }
        }
      } else {
        //No data field in call message');
        // Fallback: route to handler anyway
        //No data field in call message');
        // Fallback: route to listeners anyway
        for (var listener in List.from(_incomingCallListeners)) {
          try {
            listener(data);
          } catch (e) {
            //Error in listener: $e');
          }
        }
      }

      //═══════════════════════════════════════');
    } catch (e) {
      //Error filtering call message: $e');
      // Fallback: route to handler anyway
      //Error filtering call message: $e');
      // Fallback: route to listeners anyway
      for (var listener in List.from(_incomingCallListeners)) {
        listener(data);
      }
    }
  }

  void _reconnect() async {
    final delay = _getReconnectDelay();
    AppLogger.log(
      'Reconnecting in ${delay}s... (attempt $_reconnectAttempts/$_maxReconnectAttempts)',
    );
    await Future.delayed(Duration(seconds: delay));

    if (!_isConnected && !_isConnecting) {
      connect();
    }
  }

  int _getReconnectDelay() {
    switch (_reconnectAttempts) {
      case 1:
        return 2;
      case 2:
        return 4;
      case 3:
        return 8;
      default:
        return 15;
    }
  }

  // Send JSON with extensive logging
  void _sendJson(Map<String, dynamic> message) {
    //');
    //═══════════════════════════════════════');
    //ATTEMPTING TO SEND MESSAGE');
    //═══════════════════════════════════════');
    //Time: ${DateTime.now()}');

    // Pre-flight checks
    //PRE-FLIGHT CHECKS:');
    //   _isConnected: $_isConnected');
    //   _isConnecting: $_isConnecting');
    //   _socket != null: ${_socket != null}');

    if (_socket != null) {
      //   _socket.readyState: ${_socket!.readyState}');
      //   WebSocket.open: ${WebSocket.open}');
      AppLogger.log(
        '   States match: ${_socket!.readyState == WebSocket.open}',
      );
      //   _socket.closeCode: ${_socket!.closeCode}');
      //   _socket.closeReason: ${_socket!.closeReason}');
    }

    //');
    //MESSAGE PAYLOAD:');
    //   $message');
    //');

    // Check 1: Socket exists
    if (_socket == null) {
      //SEND BLOCKED: Socket is null');
      //═══════════════════════════════════════');
      //');
      return;
    }

    // Check 2: Marked as connected
    if (!_isConnected) {
      //SEND BLOCKED: Not marked as connected');
      //   Hint: Connection may still be initializing');
      //═══════════════════════════════════════');
      //');
      return;
    }

    // Check 3: Socket is open
    if (_socket!.readyState != WebSocket.open) {
      //SEND BLOCKED: Socket not in OPEN state');
      //   Current state: ${_socket!.readyState}');
      //   Expected state: ${WebSocket.open}');
      //═══════════════════════════════════════');
      //');

      // Try to reconnect if socket is closed
      _isConnected = false;
      _reconnect();
      return;
    }

    // All checks passed, send the message
    try {
      final jsonMessage = jsonEncode(message);
      //SENDING:');
      //   JSON string: $jsonMessage');
      //   Length: ${jsonMessage.length} bytes');
      //');

      _socket!.add(jsonMessage);

      //MESSAGE SENT SUCCESSFULLY');
      //   Message added to socket send buffer');
      //   Socket state after send: ${_socket!.readyState}');
      //   Waiting for server response...');
      //═══════════════════════════════════════');
      //');
    } catch (e, stackTrace) {
      //SEND EXCEPTION: $e');
      //Stack trace:');
      //$stackTrace');
      //═══════════════════════════════════════');
      //');

      // Mark as disconnected and try to reconnect
      _isConnected = false;
      _reconnect();
    }
  }

  // Public send methods
  void sendMessage(Map<String, dynamic> message) {
    // Add timestamp if not present
    // if (!message.containsKey('timestamp')) {
    //   message['timestamp'] = DateTime.now().toIso8601String();
    // }
    _sendJson(message);
  }

  Future<void> sendChatMessage(int rideId, String message) async {
    //sendChatMessage called');
    //   Ride: $rideId');
    //   Message: "$message"');

    // Get user info from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final userName =
        prefs.getString('user_name') ??
        prefs.getString('name') ??
        'Unknown User';

    //   User ID: $userId');
    //   User Name: $userName');

    // Create timestamp with timezone offset (mimicking Postman format)
    final now = DateTime.now();
    final offset = now.timeZoneOffset;
    final offsetHours = offset.inHours;
    final offsetMinutes = offset.inMinutes.remainder(60);
    final offsetString =
        '${offsetHours >= 0 ? '+' : ''}${offsetHours.toString().padLeft(2, '0')}:${offsetMinutes.abs().toString().padLeft(2, '0')}';
    final timestamp = '${now.toIso8601String()}$offsetString';

    final payload = {
      "type": "chat",
      "data": {
        "ride_id": rideId, // ← Now uses actual ride ID
        "message": message, // ← Now uses actual message
      },
      "timestamp": timestamp, // ← Proper timezone format
    };

    //   Full payload: $payload');
    //   Timestamp format: $timestamp');
    _sendJson(payload);
  }

  void sendRideRequest(Map<String, dynamic> rideData) {
    _sendJson({
      'type': 'ride_request',
      'data': rideData,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Listeners
  void listenToMessages(Function(dynamic) callback) {
    onMessageReceived = callback;
  }

  void disconnect() {
    //Disconnecting WebSocket');
    _socket?.close();
    _socket = null;
    _isConnected = false;
    _isConnecting = false;
    _reconnectAttempts = 0;
    //WebSocket disconnected');
  }

  void resetConnection() {
    //Resetting connection');
    disconnect();
    _reconnectAttempts = 0;
    connect();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  void dispose() {
    disconnect();
  }
}
