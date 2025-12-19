
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_webrtc/flutter_webrtc.dart';
 import 'package:muvam_rider/core/services/socket_service.dart';
import 'package:muvam_rider/core/services/websocket_service.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';

import 'package:shared_preferences/shared_preferences.dart';
// import 'package:audioplayers/audioplayers.dart';
// // //FOR DRIVER
// //FOR DRIVER - USES WebSocketService
// class CallService {
//   static const String baseUrl = 'http://44.222.121.219/api/v1';
//   WebSocketService? _webSocketService; // CHANGED
//   Function(String)? onCallStateChanged;
//   Function(Map<String, dynamic>)? onIncomingCall;
//   int? _currentSessionId;
//   int _callStartTime = 0;
//   final AudioPlayer _audioPlayer = AudioPlayer();
//   bool _isRinging = false;

//   // WebRTC Properties
//   RTCPeerConnection? _peerConnection;
//   MediaStream? _localStream;
//   MediaStream? _remoteStream;
  
//   MediaStream? get remoteStream => _remoteStream;
//   MediaStream? get localStream => _localStream;
  
//   List<RTCIceCandidate> _iceCandidates = [];
//   bool _isInitiator = false;
//   int? _recipientId;
//   int? _rideId;

//   final Map<String, dynamic> _configuration = {
//     'iceServers': [
//       {'urls': 'stun:stun.l.google.com:19302'},
//       {'urls': 'stun:stun1.l.google.com:19302'},
//       {'urls': 'stun:stun.cloudflare.com:3478'},
//     ],
//     'sdpSemantics': 'unified-plan',
//   };

//   final Map<String, dynamic> _constraints = {
//     'mandatory': {},
//     'optional': [
//       {'DtlsSrtpKeyAgreement': true},
//     ],
//   };

//   Future<void> initialize() async {
//     AppLogger.log('🔧 Initializing CallService (Driver)...', tag: 'CALL');
    
//     // Use singleton WebSocketService
//     _webSocketService = WebSocketService.instance;
    
//     // Ensure it's connected
//     if (!_webSocketService!.isConnected) {
//       AppLogger.log('🔌 WebSocket not connected, connecting...', tag: 'CALL');
//       await _webSocketService!.connect();
//     }
    
//     // Register call message handler
//     _webSocketService!.onIncomingCall = _handleWebSocketMessage;
    
//     AppLogger.log('✅ CallService initialized successfully', tag: 'CALL');
//   }
  
//   void _handleWebSocketMessage(Map<String, dynamic> data) async {
//     // Only process call-related messages
//     final type = data['type'];
//     if (type?.toString().startsWith('call') != true) {
//       return;
//     }
    
//     AppLogger.log('📨 CallService received: $type', tag: 'CALL');
    
//     if (type == 'call_initiate') {
//       AppLogger.log('📞 Incoming call received', tag: 'CALL');
//       _playRingtone();
//       onIncomingCall?.call(data);

//       if (data['data'] != null) {
//         _currentSessionId = data['data']['session_id'];
//         _rideId = data['data']['ride_id'];
//         _recipientId = data['data']['caller_id'];
//         _isInitiator = false;
//       }
//     } else if (type == 'call_answer') {
//       AppLogger.log('✅ Call answered by passenger', tag: 'CALL');
//       _stopRingtone();
//       onCallStateChanged?.call('Connected');
//       _callStartTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
//     } else if (type == 'call_reject') {
//       AppLogger.log('❌ Call rejected', tag: 'CALL');
//       _stopRingtone();
//       onCallStateChanged?.call('Call rejected');
//       await _cleanupWebRTC();
//     } else if (type == 'call_end') {
//       AppLogger.log('📞 Call ended', tag: 'CALL');
//       _stopRingtone();
//       onCallStateChanged?.call('Call ended');
//       await _cleanupWebRTC();
//     } else if (type == 'call_offer') {
//       AppLogger.log('📥 Received WebRTC offer', tag: 'CALL');
//       await _handleOffer(data['data']);
//     } else if (type == 'call_answer_sdp') {
//       AppLogger.log('📥 Received WebRTC answer', tag: 'CALL');
//       await _handleAnswer(data['data']);
//     } else if (type == 'call_ice_candidate') {
//       AppLogger.log('📥 Received ICE candidate', tag: 'CALL');
//       await _handleIceCandidate(data['data']);
//     }
//   }

//   Future<String?> _getToken() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString('auth_token');
//   }

//   Future<Map<String, String>> _getHeaders() async {
//     final token = await _getToken();
//     return {
//       'Authorization': 'Bearer $token',
//       'Content-Type': 'application/json',
//     };
//   }

//   Future<void> _playRingtone() async {
//     if (_isRinging) return;
//     _isRinging = true;
//     AppLogger.log('🔔 Playing ringtone...', tag: 'CALL');
//     try {
//       await _audioPlayer.setReleaseMode(ReleaseMode.loop);
//       await _audioPlayer.setVolume(1.0);
//       await _audioPlayer.play(AssetSource('sounds/calling.mp3'));
//       AppLogger.log('✅ Ringtone started', tag: 'CALL');
//     } catch (e) {
//       AppLogger.error('❌ Failed to play ringtone', error: e, tag: 'CALL');
//     }
//   }

//   Future<void> _stopRingtone() async {
//     if (!_isRinging) return;
//     _isRinging = false;
//     AppLogger.log('🔕 Stopping ringtone...', tag: 'CALL');
//     await _audioPlayer.stop();
//   }

//   // Future<void> _setupLocalMedia() async {
//   //   try {
//   //     AppLogger.log('🎤 Setting up local media...', tag: 'CALL');

//   //     final Map<String, dynamic> mediaConstraints = {
//   //       'audio': {
//   //         'echoCancellation': true,
//   //         'noiseSuppression': true,
//   //         'autoGainControl': true,
//   //       },
//   //       'video': false,
//   //     };

//   //     _localStream = await navigator.mediaDevices.getUserMedia(
//   //       mediaConstraints,
//   //     );
//   //     AppLogger.log('✅ Local media stream obtained', tag: 'CALL');
//   //     AppLogger.log('🎤 Audio tracks: ${_localStream!.getAudioTracks().length}', tag: 'CALL');
//   //   } catch (e) {
//   //     AppLogger.error('❌ Failed to get local media', error: e, tag: 'CALL');
//   //     rethrow;
//   //   }
//   // }

//   Future<void> _createPeerConnection() async {
//     try {
//       AppLogger.log('🔗 Creating peer connection...', tag: 'CALL');

//       _peerConnection = await createPeerConnection(
//         _configuration,
//         _constraints,
//       );

//       if (_localStream != null) {
//         _localStream!.getTracks().forEach((track) {
//           _peerConnection!.addTrack(track, _localStream!);
//           AppLogger.log('➕ Added local track: ${track.kind}', tag: 'CALL');
//         });
//       }

//       _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
//         AppLogger.log('🧊 New ICE candidate: ${candidate.candidate}', tag: 'CALL');
//         _sendIceCandidate(candidate);
//       };

//       _peerConnection!.onTrack = (RTCTrackEvent event) {
//         AppLogger.log('🎵 Remote track received: ${event.track.kind}', tag: 'CALL');
//         if (event.streams.isNotEmpty) {
//           _remoteStream = event.streams[0];
//           AppLogger.log('✅ Remote stream set with ${_remoteStream!.getAudioTracks().length} audio tracks', tag: 'CALL');
//           onCallStateChanged?.call('Connected');
//         }
//       };

//       _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
//         AppLogger.log('🔄 Connection state: $state', tag: 'CALL');
//         if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
//           AppLogger.log('✅ Peer connection CONNECTED', tag: 'CALL');
//           onCallStateChanged?.call('Connected');
//         } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
//           AppLogger.log('❌ Peer connection FAILED', tag: 'CALL');
//           onCallStateChanged?.call('Connection failed');
//         }
//       };

//       _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
//         AppLogger.log('🧊 ICE connection state: $state', tag: 'CALL');
//         if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
//             state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
//           AppLogger.log('✅ ICE connection established', tag: 'CALL');
//         } else if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
//           AppLogger.log('❌ ICE connection failed', tag: 'CALL');
//         }
//       };

//       AppLogger.log('✅ Peer connection created', tag: 'CALL');
//     } catch (e) {
//       AppLogger.error('❌ Failed to create peer connection', error: e, tag: 'CALL');
//       rethrow;
//     }
//   }




// Future<void> _setupLocalMedia() async {
//   try {
//     AppLogger.log('🎤 Setting up local media...', tag: 'CALL');

//     final Map<String, dynamic> mediaConstraints = {
//       'audio': {
//         'echoCancellation': true,
//         'noiseSuppression': true,
//         'autoGainControl': true,
//       },
//       'video': false,
//     };

//     _localStream = await navigator.mediaDevices.getUserMedia(
//       mediaConstraints,
//     );
//     AppLogger.log('✅ Local media stream obtained', tag: 'CALL');
//     AppLogger.log('🎤 Audio tracks: ${_localStream!.getAudioTracks().length}', tag: 'CALL');
//   } catch (e) {
//     AppLogger.error('❌ Failed to get local media', error: e, tag: 'CALL');
//     AppLogger.log('💡 Hint: Check if microphone permission is granted', tag: 'CALL');
//     rethrow;
//   }
// }


//   Future<void> _createAndSendOffer() async {
//     try {
//       AppLogger.log('📤 Creating offer...', tag: 'CALL');

//       RTCSessionDescription offer = await _peerConnection!.createOffer();
//       await _peerConnection!.setLocalDescription(offer);

//       AppLogger.log('📤 Sending offer via WebSocket', tag: 'CALL');

//       _webSocketService?.sendMessage({
//         'type': 'call_offer',
//         'data': {
//           'session_id': _currentSessionId,
//           'ride_id': _rideId,
//           'recipient_id': _recipientId,
//           'sdp': offer.sdp,
//         },
//       });

//       AppLogger.log('✅ Offer sent', tag: 'CALL');
//     } catch (e) {
//       AppLogger.error('❌ Failed to create/send offer', error: e, tag: 'CALL');
//       rethrow;
//     }
//   }

//   Future<void> _handleOffer(Map<String, dynamic> data) async {
//     try {
//       AppLogger.log('📥 Handling offer...', tag: 'CALL');

//       await _setupLocalMedia();
//       await _createPeerConnection();

//       RTCSessionDescription remoteDescription = RTCSessionDescription(
//         data['sdp'],
//         'offer',
//       );
//       await _peerConnection!.setRemoteDescription(remoteDescription);

//       AppLogger.log('✅ Remote description set', tag: 'CALL');

//       await _createAndSendAnswer();
//     } catch (e) {
//       AppLogger.error('❌ Failed to handle offer', error: e, tag: 'CALL');
//     }
//   }

//   Future<void> _createAndSendAnswer() async {
//     try {
//       AppLogger.log('📤 Creating answer...', tag: 'CALL');

//       RTCSessionDescription answer = await _peerConnection!.createAnswer();
//       await _peerConnection!.setLocalDescription(answer);

//       AppLogger.log('📤 Sending answer via WebSocket', tag: 'CALL');

//       _webSocketService?.sendMessage({
//         'type': 'call_answer_sdp',
//         'data': {
//           'session_id': _currentSessionId,
//           'ride_id': _rideId,
//           'recipient_id': _recipientId,
//           'sdp': answer.sdp,
//         },
//       });

//       AppLogger.log('✅ Answer sent', tag: 'CALL');
//     } catch (e) {
//       AppLogger.error('❌ Failed to create/send answer', error: e, tag: 'CALL');
//       rethrow;
//     }
//   }

//   Future<void> _handleAnswer(Map<String, dynamic> data) async {
//     try {
//       AppLogger.log('📥 Handling answer...', tag: 'CALL');

//       RTCSessionDescription remoteDescription = RTCSessionDescription(
//         data['sdp'],
//         'answer',
//       );
//       await _peerConnection!.setRemoteDescription(remoteDescription);

//       AppLogger.log('✅ Remote answer set', tag: 'CALL');
//     } catch (e) {
//       AppLogger.error('❌ Failed to handle answer', error: e, tag: 'CALL');
//     }
//   }

//   void _sendIceCandidate(RTCIceCandidate candidate) {
//     try {
//       _webSocketService?.sendMessage({
//         'type': 'call_ice_candidate',
//         'data': {
//           'session_id': _currentSessionId,
//           'ride_id': _rideId,
//           'recipient_id': _recipientId,
//           'candidate': {
//             'candidate': candidate.candidate,
//             'sdpMLineIndex': candidate.sdpMLineIndex,
//             'sdpMid': candidate.sdpMid,
//           },
//         },
//       });
//     } catch (e) {
//       AppLogger.error('❌ Failed to send ICE candidate', error: e, tag: 'CALL');
//     }
//   }

//   Future<void> _handleIceCandidate(Map<String, dynamic> data) async {
//     try {
//       AppLogger.log('🧊 Adding ICE candidate...', tag: 'CALL');

//       final candidateData = data['candidate'];
//       RTCIceCandidate candidate = RTCIceCandidate(
//         candidateData['candidate'],
//         candidateData['sdpMid'],
//         candidateData['sdpMLineIndex'],
//       );

//       if (_peerConnection != null) {
//         await _peerConnection!.addCandidate(candidate);
//         AppLogger.log('✅ ICE candidate added', tag: 'CALL');
//       } else {
//         _iceCandidates.add(candidate);
//         AppLogger.log('💾 ICE candidate stored for later', tag: 'CALL');
//       }
//     } catch (e) {
//       AppLogger.error('❌ Failed to add ICE candidate', error: e, tag: 'CALL');
//     }
//   }

//   Future<void> _cleanupWebRTC() async {
//     AppLogger.log('🧹 Cleaning up WebRTC...', tag: 'CALL');

//     if (_localStream != null) {
//       _localStream!.getTracks().forEach((track) {
//         track.stop();
//       });
//       await _localStream!.dispose();
//       _localStream = null;
//     }

//     if (_remoteStream != null) {
//       await _remoteStream!.dispose();
//       _remoteStream = null;
//     }

//     if (_peerConnection != null) {
//       await _peerConnection!.close();
//       await _peerConnection!.dispose();
//       _peerConnection = null;
//     }

//     _iceCandidates.clear();

//     AppLogger.log('✅ WebRTC cleanup complete', tag: 'CALL');
//   }

//   Future<Map<String, dynamic>> initiateCall(int rideId) async {
//     try {
//       AppLogger.log('📞 Initiating call for ride ID: $rideId', tag: 'CALL');
//       _isInitiator = true;
//       _rideId = rideId;

//       // Check for any existing session and end it first
//       await _cleanupPreviousSession();

//       final headers = await _getHeaders();
//       AppLogger.log('📤 Sending POST request to: $baseUrl/rides/$rideId/call', tag: 'CALL');

//       final response = await http.post(
//         Uri.parse('$baseUrl/rides/$rideId/call'),
//         headers: headers,
//       );

//       AppLogger.log('📥 Response status: ${response.statusCode}', tag: 'CALL');
//       AppLogger.log('📥 Response body: ${response.body}', tag: 'CALL');

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         _currentSessionId = data['session_id'];
//         _recipientId = data['recipient_id'];

//         // Store session ID for cleanup in case of app crash
//         await _storeSessionId(_currentSessionId!);

//         AppLogger.log('✅ Call initiated successfully', tag: 'CALL');
//         AppLogger.log('🆔 Session ID: $_currentSessionId', tag: 'CALL');
//         AppLogger.log('👤 Recipient ID: $_recipientId', tag: 'CALL');

//         _playRingtone();

//         // Setup WebRTC
//         await _setupLocalMedia();
//         await _createPeerConnection();
//         await _createAndSendOffer();

//         return data;
//       } else {
//         AppLogger.log('❌ Failed to initiate call: ${response.body}', tag: 'CALL');
//         throw Exception('Failed to initiate call: ${response.body}');
//       }
//     } catch (e) {
//       AppLogger.error('❌ Call initiation failed', error: e, tag: 'CALL');
//       rethrow;
//     }
//   }

//   Future<void> answerCall(int sessionId) async {
//     try {
//       AppLogger.log('✅ Answering call...', tag: 'CALL');

//       final headers = await _getHeaders();
//       await http.post(
//         Uri.parse('$baseUrl/calls/$sessionId/answer'),
//         headers: headers,
//       );

//       _stopRingtone();
//       _callStartTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

//       AppLogger.log('✅ Call answered', tag: 'CALL');
//     } catch (e) {
//       AppLogger.error('❌ Failed to answer call', error: e, tag: 'CALL');
//     }
//   }

//   Future<void> rejectCall(int sessionId) async {
//     try {
//       final headers = await _getHeaders();
//       await http.post(
//         Uri.parse('$baseUrl/calls/$sessionId/reject'),
//         headers: headers,
//       );
//       _stopRingtone();
//       await _cleanupWebRTC();
//       AppLogger.log('❌ Call rejected', tag: 'CALL');
//     } catch (e) {
//       AppLogger.error('❌ Failed to reject call', error: e, tag: 'CALL');
//     }
//   }

//   Future<void> endCall(int? sessionId, int duration) async {
//     AppLogger.log('═══════════════════════════════════════', tag: 'CALL_END');
//     AppLogger.log('🔴 END CALL PROCESS STARTED', tag: 'CALL_END');
//     AppLogger.log('═══════════════════════════════════════', tag: 'CALL_END');
    
//     if (sessionId == null) {
//       AppLogger.log('⚠️ No session ID provided, skipping end call', tag: 'CALL_END');
//       AppLogger.log('═══════════════════════════════════════', tag: 'CALL_END');
//       return;
//     }

//     try {
//       AppLogger.log('📊 Call Details:', tag: 'CALL_END');
//       AppLogger.log('   - Session ID: $sessionId', tag: 'CALL_END');
//       AppLogger.log('   - Duration: $duration seconds', tag: 'CALL_END');
//       AppLogger.log('   - Timestamp: ${DateTime.now().toIso8601String()}', tag: 'CALL_END');
      
//       AppLogger.log('🔕 Stopping ringtone...', tag: 'CALL_END');
//       _stopRingtone();

//       AppLogger.log('🔑 Getting authentication headers...', tag: 'CALL_END');
//       final headers = await _getHeaders();
//       AppLogger.log('✅ Headers obtained', tag: 'CALL_END');
      
//       final endpoint = '$baseUrl/calls/$sessionId/end';
//       final requestBody = json.encode({'duration': duration});
      
//       AppLogger.log('📤 Preparing API call:', tag: 'CALL_END');
//       AppLogger.log('   - Endpoint: $endpoint', tag: 'CALL_END');
//       AppLogger.log('   - Method: POST', tag: 'CALL_END');
//       AppLogger.log('   - Body: $requestBody', tag: 'CALL_END');
//       AppLogger.log('   - Headers: ${headers.keys.join(", ")}', tag: 'CALL_END');
      
//       AppLogger.log('🚀 Sending end call request...', tag: 'CALL_END');
//       final response = await http.post(
//         Uri.parse(endpoint),
//         headers: headers,
//         body: requestBody,
//       );

//       AppLogger.log('📥 Response received:', tag: 'CALL_END');
//       AppLogger.log('   - Status Code: ${response.statusCode}', tag: 'CALL_END');
//       AppLogger.log('   - Response Body: ${response.body}', tag: 'CALL_END');
//       AppLogger.log('   - Response Headers: ${response.headers}', tag: 'CALL_END');

//       AppLogger.log('🧹 Starting WebRTC cleanup...', tag: 'CALL_END');
//       await _cleanupWebRTC();
//       AppLogger.log('✅ WebRTC cleanup completed', tag: 'CALL_END');
      
//       AppLogger.log('🗑️ Clearing stored session ID...', tag: 'CALL_END');
//       await _clearStoredSessionId();
//       AppLogger.log('✅ Session ID cleared', tag: 'CALL_END');

//       if (response.statusCode == 200) {
//         AppLogger.log('✅✅✅ CALL ENDED SUCCESSFULLY ✅✅✅', tag: 'CALL_END');
//       } else {
//         AppLogger.log('⚠️⚠️⚠️ END CALL RETURNED NON-200 STATUS ⚠️⚠️⚠️', tag: 'CALL_END');
//         AppLogger.log('   - Expected: 200', tag: 'CALL_END');
//         AppLogger.log('   - Received: ${response.statusCode}', tag: 'CALL_END');
//       }
//     } catch (e, stackTrace) {
//       AppLogger.log('❌❌❌ FAILED TO END CALL ❌❌❌', tag: 'CALL_END');
//       AppLogger.error('Error details:', error: e, tag: 'CALL_END');
//       AppLogger.log('Stack trace: $stackTrace', tag: 'CALL_END');
//     } finally {
//       AppLogger.log('═══════════════════════════════════════', tag: 'CALL_END');
//       AppLogger.log('🔴 END CALL PROCESS COMPLETED', tag: 'CALL_END');
//       AppLogger.log('═══════════════════════════════════════', tag: 'CALL_END');
//     }
//   }

//   void toggleMute(bool isMuted) {
//     AppLogger.log('🎤 Mute toggled: $isMuted', tag: 'CALL');
//     if (_localStream != null) {
//       _localStream!.getAudioTracks().forEach((track) {
//         track.enabled = !isMuted;
//       });
//     }
//   }

//   void toggleSpeaker(bool isSpeakerOn) {
//     AppLogger.log('🔊 Speaker toggled: $isSpeakerOn', tag: 'CALL');
//     Helper.setSpeakerphoneOn(isSpeakerOn);
//   }

//   // Store session ID for cleanup in case of app crash
//   Future<void> _storeSessionId(int sessionId) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setInt('active_call_session_id', sessionId);
//       await prefs.setInt('active_call_start_time', DateTime.now().millisecondsSinceEpoch);
//       AppLogger.log('💾 Stored session ID: $sessionId', tag: 'CALL');
//     } catch (e) {
//       AppLogger.error('❌ Failed to store session ID', error: e, tag: 'CALL');
//     }
//   }

//   // Clear stored session ID
//   Future<void> _clearStoredSessionId() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.remove('active_call_session_id');
//       await prefs.remove('active_call_start_time');
//       AppLogger.log('🧹 Cleared stored session ID', tag: 'CALL');
//     } catch (e) {
//       AppLogger.error('❌ Failed to clear stored session ID', error: e, tag: 'CALL');
//     }
//   }

//   // Check for and cleanup any previous session
//   Future<void> _cleanupPreviousSession() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final previousSessionId = prefs.getInt('active_call_session_id');
//       final startTime = prefs.getInt('active_call_start_time');
      
//       if (previousSessionId != null) {
//         AppLogger.log('🧹 Found previous session ID: $previousSessionId', tag: 'CALL');
        
//         // Calculate duration if start time is available
//         int duration = 0;
//         if (startTime != null) {
//           duration = (DateTime.now().millisecondsSinceEpoch - startTime) ~/ 1000;
//         }
        
//         // End the previous call
//         await endCall(previousSessionId, duration);
//         AppLogger.log('✅ Previous session cleaned up', tag: 'CALL');
//       }
//     } catch (e) {
//       AppLogger.error('❌ Failed to cleanup previous session', error: e, tag: 'CALL');
//     }
//   }

//   void dispose() {
//     AppLogger.log('🧹 Disposing CallService...', tag: 'CALL');
//     _stopRingtone();
//     _audioPlayer.dispose();
//     _cleanupWebRTC();
    
//     // Clear callback
//     if (_webSocketService != null) {
//       _webSocketService!.onIncomingCall = null;
//     }
    
//     AppLogger.log('✅ CallService disposed', tag: 'CALL');
//   }
// }







// Call Service with improved audio configuration and ringtone management
class CallService {
  static const String baseUrl = 'http://44.222.121.219/api/v1';
  WebSocketService? _webSocketService;
  Function(String)? onCallStateChanged;
  Function(Map<String, dynamic>)? onIncomingCall;
  int? _currentSessionId;
  int _callStartTime = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRinging = false;

  // WebRTC Properties
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  
  MediaStream? get remoteStream => _remoteStream;
  MediaStream? get localStream => _localStream;
  
  List<RTCIceCandidate> _iceCandidates = [];
  bool _isInitiator = false;
  int? _recipientId;
  int? _rideId;

  // FIXED: Improved STUN/TURN configuration for better connectivity
  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun.cloudflare.com:3478'},
      {'urls': 'stun:stun2.l.google.com:19302'},
      {'urls': 'stun:stun3.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan',
    'iceCandidatePoolSize': 10,
  };

  final Map<String, dynamic> _constraints = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ],
  };

  Future<void> initialize() async {
    AppLogger.log('🔧 Initializing CallService (Driver)...', tag: 'CALL');
    
    _webSocketService = WebSocketService.instance;
    
    if (!_webSocketService!.isConnected) {
      AppLogger.log('🔌 WebSocket not connected, connecting...', tag: 'CALL');
      await _webSocketService!.connect();
    }
    
    _webSocketService!.onIncomingCall = _handleWebSocketMessage;
    
    AppLogger.log('✅ CallService initialized successfully', tag: 'CALL');
  }
  
  void _handleWebSocketMessage(Map<String, dynamic> data) async {
    final type = data['type'];
    if (type?.toString().startsWith('call') != true) {
      return;
    }
    
    AppLogger.log('📨 CallService received: $type', tag: 'CALL');
    
    if (type == 'call_initiate') {
      AppLogger.log('📞 Incoming call received', tag: 'CALL');
      _playRingtone();
      onIncomingCall?.call(data);

      if (data['data'] != null) {
        _currentSessionId = data['data']['session_id'];
        _rideId = data['data']['ride_id'];
        _recipientId = data['data']['caller_id'];
        _isInitiator = false;
      }
    } else if (type == 'call_answer') {
      AppLogger.log('✅ Call answered by passenger', tag: 'CALL');
      _stopRingtone(); // FIXED: Stop ringtone when answered
      onCallStateChanged?.call('Connected');
      _callStartTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    } else if (type == 'call_reject') {
      AppLogger.log('❌ Call rejected', tag: 'CALL');
      _stopRingtone();
      onCallStateChanged?.call('Call rejected');
      await _cleanupWebRTC();
    } else if (type == 'call_end') {
      AppLogger.log('📞 Call ended', tag: 'CALL');
      _stopRingtone();
      onCallStateChanged?.call('Call ended');
      await _cleanupWebRTC();
    } else if (type == 'call_offer') {
      AppLogger.log('📥 Received WebRTC offer', tag: 'CALL');
      await _handleOffer(data['data']);
    } else if (type == 'call_answer_sdp') {
      AppLogger.log('📥 Received WebRTC answer', tag: 'CALL');
      await _handleAnswer(data['data']);
    } else if (type == 'call_ice_candidate') {
      AppLogger.log('📥 Received ICE candidate', tag: 'CALL');
      await _handleIceCandidate(data['data']);
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<void> _playRingtone() async {
    if (_isRinging) return;
    _isRinging = true;
    AppLogger.log('🔔 Playing ringtone...', tag: 'CALL');
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(AssetSource('sounds/calling.mp3'));
      AppLogger.log('✅ Ringtone started', tag: 'CALL');
    } catch (e) {
      AppLogger.error('❌ Failed to play ringtone', error: e, tag: 'CALL');
    }
  }

  Future<void> _stopRingtone() async {
    if (!_isRinging) return;
    _isRinging = false;
    AppLogger.log('🔕 Stopping ringtone...', tag: 'CALL');
    await _audioPlayer.stop();
  }

  // FIXED: Public method to stop ringtone from outside
  Future<void> stopRingtone() async {
    await _stopRingtone();
  }

  // FIXED: Improved audio configuration for better clarity
  Future<void> _setupLocalMedia() async {
    try {
      AppLogger.log('🎤 Setting up local media...', tag: 'CALL');

      final Map<String, dynamic> mediaConstraints = {
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
          'googEchoCancellation': true,
          'googAutoGainControl': true,
          'googNoiseSuppression': true,
          'googHighpassFilter': true,
          'googTypingNoiseDetection': true,
        },
        'video': false,
      };

      _localStream = await navigator.mediaDevices.getUserMedia(
        mediaConstraints,
      );
      AppLogger.log('✅ Local media stream obtained', tag: 'CALL');
      AppLogger.log('🎤 Audio tracks: ${_localStream!.getAudioTracks().length}', tag: 'CALL');
    } catch (e) {
      AppLogger.error('❌ Failed to get local media', error: e, tag: 'CALL');
      AppLogger.log('💡 Hint: Check if microphone permission is granted', tag: 'CALL');
      rethrow;
    }
  }

  Future<void> _createPeerConnection() async {
    try {
      AppLogger.log('🔗 Creating peer connection...', tag: 'CALL');

      _peerConnection = await createPeerConnection(
        _configuration,
        _constraints,
      );

      if (_localStream != null) {
        _localStream!.getTracks().forEach((track) {
          _peerConnection!.addTrack(track, _localStream!);
          AppLogger.log('➕ Added local track: ${track.kind}', tag: 'CALL');
        });
      }

      _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        AppLogger.log('🧊 New ICE candidate: ${candidate.candidate}', tag: 'CALL');
        _sendIceCandidate(candidate);
      };

      _peerConnection!.onTrack = (RTCTrackEvent event) {
        AppLogger.log('🎵 Remote track received: ${event.track.kind}', tag: 'CALL');
        if (event.streams.isNotEmpty) {
          _remoteStream = event.streams[0];
          AppLogger.log('✅ Remote stream set with ${_remoteStream!.getAudioTracks().length} audio tracks', tag: 'CALL');
          
          // FIXED: Stop ringtone when remote track is received
          _stopRingtone();
          onCallStateChanged?.call('Connected');
        }
      };

      _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
        AppLogger.log('🔄 Connection state: $state', tag: 'CALL');
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          AppLogger.log('✅ Peer connection CONNECTED', tag: 'CALL');
          // FIXED: Stop ringtone when connection is established
          _stopRingtone();
          onCallStateChanged?.call('Connected');
        } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          AppLogger.log('❌ Peer connection FAILED', tag: 'CALL');
          _stopRingtone();
          onCallStateChanged?.call('Connection failed');
        } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
          AppLogger.log('🔌 Peer connection DISCONNECTED', tag: 'CALL');
          _stopRingtone();
          onCallStateChanged?.call('Call ended');
        }
      };

      _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
        AppLogger.log('🧊 ICE connection state: $state', tag: 'CALL');
        if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
            state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
          AppLogger.log('✅ ICE connection established', tag: 'CALL');
          // FIXED: Stop ringtone when ICE is connected
          _stopRingtone();
        } else if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
          AppLogger.log('❌ ICE connection failed', tag: 'CALL');
          _stopRingtone();
        }
      };

      AppLogger.log('✅ Peer connection created', tag: 'CALL');
    } catch (e) {
      AppLogger.error('❌ Failed to create peer connection', error: e, tag: 'CALL');
      rethrow;
    }
  }

  Future<void> _createAndSendOffer() async {
    try {
      AppLogger.log('📤 Creating offer...', tag: 'CALL');

      RTCSessionDescription offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      AppLogger.log('📤 Sending offer via WebSocket', tag: 'CALL');

      _webSocketService?.sendMessage({
        'type': 'call_offer',
        'data': {
          'session_id': _currentSessionId,
          'ride_id': _rideId,
          'recipient_id': _recipientId,
          'sdp': offer.sdp,
        },
      });

      AppLogger.log('✅ Offer sent', tag: 'CALL');
    } catch (e) {
      AppLogger.error('❌ Failed to create/send offer', error: e, tag: 'CALL');
      rethrow;
    }
  }

  Future<void> _handleOffer(Map<String, dynamic> data) async {
    try {
      AppLogger.log('📥 Handling offer...', tag: 'CALL');

      await _setupLocalMedia();
      await _createPeerConnection();

      RTCSessionDescription remoteDescription = RTCSessionDescription(
        data['sdp'],
        'offer',
      );
      await _peerConnection!.setRemoteDescription(remoteDescription);

      AppLogger.log('✅ Remote description set', tag: 'CALL');

      await _createAndSendAnswer();
    } catch (e) {
      AppLogger.error('❌ Failed to handle offer', error: e, tag: 'CALL');
    }
  }

  Future<void> _createAndSendAnswer() async {
    try {
      AppLogger.log('📤 Creating answer...', tag: 'CALL');

      RTCSessionDescription answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      AppLogger.log('📤 Sending answer via WebSocket', tag: 'CALL');

      _webSocketService?.sendMessage({
        'type': 'call_answer_sdp',
        'data': {
          'session_id': _currentSessionId,
          'ride_id': _rideId,
          'recipient_id': _recipientId,
          'sdp': answer.sdp,
        },
      });

      AppLogger.log('✅ Answer sent', tag: 'CALL');
    } catch (e) {
      AppLogger.error('❌ Failed to create/send answer', error: e, tag: 'CALL');
      rethrow;
    }
  }

  Future<void> _handleAnswer(Map<String, dynamic> data) async {
    try {
      AppLogger.log('📥 Handling answer...', tag: 'CALL');

      RTCSessionDescription remoteDescription = RTCSessionDescription(
        data['sdp'],
        'answer',
      );
      await _peerConnection!.setRemoteDescription(remoteDescription);

      AppLogger.log('✅ Remote answer set', tag: 'CALL');
    } catch (e) {
      AppLogger.error('❌ Failed to handle answer', error: e, tag: 'CALL');
    }
  }

  void _sendIceCandidate(RTCIceCandidate candidate) {
    try {
      _webSocketService?.sendMessage({
        'type': 'call_ice_candidate',
        'data': {
          'session_id': _currentSessionId,
          'ride_id': _rideId,
          'recipient_id': _recipientId,
          'candidate': {
            'candidate': candidate.candidate,
            'sdpMLineIndex': candidate.sdpMLineIndex,
            'sdpMid': candidate.sdpMid,
          },
        },
      });
    } catch (e) {
      AppLogger.error('❌ Failed to send ICE candidate', error: e, tag: 'CALL');
    }
  }

  Future<void> _handleIceCandidate(Map<String, dynamic> data) async {
    try {
      AppLogger.log('🧊 Adding ICE candidate...', tag: 'CALL');

      final candidateData = data['candidate'];
      RTCIceCandidate candidate = RTCIceCandidate(
        candidateData['candidate'],
        candidateData['sdpMid'],
        candidateData['sdpMLineIndex'],
      );

      if (_peerConnection != null) {
        await _peerConnection!.addCandidate(candidate);
        AppLogger.log('✅ ICE candidate added', tag: 'CALL');
      } else {
        _iceCandidates.add(candidate);
        AppLogger.log('💾 ICE candidate stored for later', tag: 'CALL');
      }
    } catch (e) {
      AppLogger.error('❌ Failed to add ICE candidate', error: e, tag: 'CALL');
    }
  }

  Future<void> _cleanupWebRTC() async {
    AppLogger.log('🧹 Cleaning up WebRTC...', tag: 'CALL');

    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) {
        track.stop();
      });
      await _localStream!.dispose();
      _localStream = null;
    }

    if (_remoteStream != null) {
      await _remoteStream!.dispose();
      _remoteStream = null;
    }

    if (_peerConnection != null) {
      await _peerConnection!.close();
      await _peerConnection!.dispose();
      _peerConnection = null;
    }

    _iceCandidates.clear();

    AppLogger.log('✅ WebRTC cleanup complete', tag: 'CALL');
  }

  Future<Map<String, dynamic>> initiateCall(int rideId) async {
    try {
      AppLogger.log('📞 Initiating call for ride ID: $rideId', tag: 'CALL');
      _isInitiator = true;
      _rideId = rideId;

      await _cleanupPreviousSession();

      final headers = await _getHeaders();
      AppLogger.log('📤 Sending POST request to: $baseUrl/rides/$rideId/call', tag: 'CALL');

      final response = await http.post(
        Uri.parse('$baseUrl/rides/$rideId/call'),
        headers: headers,
      );

      AppLogger.log('📥 Response status: ${response.statusCode}', tag: 'CALL');
      AppLogger.log('📥 Response body: ${response.body}', tag: 'CALL');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _currentSessionId = data['session_id'];
        _recipientId = data['recipient_id'];

        await _storeSessionId(_currentSessionId!);

        AppLogger.log('✅ Call initiated successfully', tag: 'CALL');
        AppLogger.log('🆔 Session ID: $_currentSessionId', tag: 'CALL');
        AppLogger.log('👤 Recipient ID: $_recipientId', tag: 'CALL');

        _playRingtone();

        await _setupLocalMedia();
        await _createPeerConnection();
        await _createAndSendOffer();

        return data;
      } else {
        AppLogger.log('❌ Failed to initiate call: ${response.body}', tag: 'CALL');
        throw Exception('Failed to initiate call: ${response.body}');
      }
    } catch (e) {
      AppLogger.error('❌ Call initiation failed', error: e, tag: 'CALL');
      rethrow;
    }
  }

  Future<void> answerCall(int sessionId) async {
    try {
      AppLogger.log('✅ Answering call...', tag: 'CALL');

      final headers = await _getHeaders();
      await http.post(
        Uri.parse('$baseUrl/calls/$sessionId/answer'),
        headers: headers,
      );

      _stopRingtone();
      _callStartTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      AppLogger.log('✅ Call answered', tag: 'CALL');
    } catch (e) {
      AppLogger.error('❌ Failed to answer call', error: e, tag: 'CALL');
    }
  }

  Future<void> rejectCall(int sessionId) async {
    try {
      final headers = await _getHeaders();
      await http.post(
        Uri.parse('$baseUrl/calls/$sessionId/reject'),
        headers: headers,
      );
      _stopRingtone();
      await _cleanupWebRTC();
      AppLogger.log('❌ Call rejected', tag: 'CALL');
    } catch (e) {
      AppLogger.error('❌ Failed to reject call', error: e, tag: 'CALL');
    }
  }

  // FIXED: Better null handling for session ID
  Future<void> endCall(int? sessionId, int duration) async {
    AppLogger.log('═══════════════════════════════════════', tag: 'CALL_END');
    AppLogger.log('🔴 END CALL PROCESS STARTED', tag: 'CALL_END');
    AppLogger.log('═══════════════════════════════════════', tag: 'CALL_END');
    
    if (sessionId == null || sessionId <= 0) {
      AppLogger.log('⚠️ No valid session ID provided, skipping end call', tag: 'CALL_END');
      AppLogger.log('═══════════════════════════════════════', tag: 'CALL_END');
      return;
    }

    try {
      AppLogger.log('📊 Call Details:', tag: 'CALL_END');
      AppLogger.log('   - Session ID: $sessionId', tag: 'CALL_END');
      AppLogger.log('   - Duration: $duration seconds', tag: 'CALL_END');
      AppLogger.log('   - Timestamp: ${DateTime.now().toIso8601String()}', tag: 'CALL_END');
      
      AppLogger.log('🔕 Stopping ringtone...', tag: 'CALL_END');
      _stopRingtone();

      AppLogger.log('🔑 Getting authentication headers...', tag: 'CALL_END');
      final headers = await _getHeaders();
      AppLogger.log('✅ Headers obtained', tag: 'CALL_END');
      
      final endpoint = '$baseUrl/calls/$sessionId/end';
      final requestBody = json.encode({'duration': duration});
      
      AppLogger.log('📤 Preparing API call:', tag: 'CALL_END');
      AppLogger.log('   - Endpoint: $endpoint', tag: 'CALL_END');
      AppLogger.log('   - Method: POST', tag: 'CALL_END');
      AppLogger.log('   - Body: $requestBody', tag: 'CALL_END');
      
      AppLogger.log('🚀 Sending end call request...', tag: 'CALL_END');
      final response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: requestBody,
      );

      AppLogger.log('📥 Response received:', tag: 'CALL_END');
      AppLogger.log('   - Status Code: ${response.statusCode}', tag: 'CALL_END');
      AppLogger.log('   - Response Body: ${response.body}', tag: 'CALL_END');

      AppLogger.log('🧹 Starting WebRTC cleanup...', tag: 'CALL_END');
      await _cleanupWebRTC();
      AppLogger.log('✅ WebRTC cleanup completed', tag: 'CALL_END');
      
      AppLogger.log('🗑️ Clearing stored session ID...', tag: 'CALL_END');
      await _clearStoredSessionId();
      AppLogger.log('✅ Session ID cleared', tag: 'CALL_END');

      if (response.statusCode == 200) {
        AppLogger.log('✅✅✅ CALL ENDED SUCCESSFULLY ✅✅✅', tag: 'CALL_END');
      } else {
        AppLogger.log('⚠️⚠️⚠️ END CALL RETURNED NON-200 STATUS ⚠️⚠️⚠️', tag: 'CALL_END');
      }
    } catch (e, stackTrace) {
      AppLogger.log('❌❌❌ FAILED TO END CALL ❌❌❌', tag: 'CALL_END');
      AppLogger.error('Error details:', error: e, tag: 'CALL_END');
      AppLogger.log('Stack trace: $stackTrace', tag: 'CALL_END');
    } finally {
      AppLogger.log('═══════════════════════════════════════', tag: 'CALL_END');
      AppLogger.log('🔴 END CALL PROCESS COMPLETED', tag: 'CALL_END');
      AppLogger.log('═══════════════════════════════════════', tag: 'CALL_END');
    }
  }

  void toggleMute(bool isMuted) {
    AppLogger.log('🎤 Mute toggled: $isMuted', tag: 'CALL');
    if (_localStream != null) {
      _localStream!.getAudioTracks().forEach((track) {
        track.enabled = !isMuted;
      });
    }
  }

  void toggleSpeaker(bool isSpeakerOn) {
    AppLogger.log('🔊 Speaker toggled: $isSpeakerOn', tag: 'CALL');
    Helper.setSpeakerphoneOn(isSpeakerOn);
  }

  Future<void> _storeSessionId(int sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('active_call_session_id', sessionId);
      await prefs.setInt('active_call_start_time', DateTime.now().millisecondsSinceEpoch);
      AppLogger.log('💾 Stored session ID: $sessionId', tag: 'CALL');
    } catch (e) {
      AppLogger.error('❌ Failed to store session ID', error: e, tag: 'CALL');
    }
  }

  Future<void> _clearStoredSessionId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('active_call_session_id');
      await prefs.remove('active_call_start_time');
      AppLogger.log('🧹 Cleared stored session ID', tag: 'CALL');
    } catch (e) {
      AppLogger.error('❌ Failed to clear stored session ID', error: e, tag: 'CALL');
    }
  }

  Future<void> _cleanupPreviousSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final previousSessionId = prefs.getInt('active_call_session_id');
      final startTime = prefs.getInt('active_call_start_time');
      
      if (previousSessionId != null) {
        AppLogger.log('🧹 Found previous session ID: $previousSessionId', tag: 'CALL');
        
        int duration = 0;
        if (startTime != null) {
          duration = (DateTime.now().millisecondsSinceEpoch - startTime) ~/ 1000;
        }
        
        await endCall(previousSessionId, duration);
        AppLogger.log('✅ Previous session cleaned up', tag: 'CALL');
      }
    } catch (e) {
      AppLogger.error('❌ Failed to cleanup previous session', error: e, tag: 'CALL');
    }
  }

  void dispose() {
    AppLogger.log('🧹 Disposing CallService...', tag: 'CALL');
    _stopRingtone();
    _audioPlayer.dispose();
    _cleanupWebRTC();
    
    if (_webSocketService != null) {
      _webSocketService!.onIncomingCall = null;
    }
    
    AppLogger.log('✅ CallService disposed', tag: 'CALL');
  }
}