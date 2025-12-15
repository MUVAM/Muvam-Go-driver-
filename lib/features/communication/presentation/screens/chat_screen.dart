import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/features/communication/presentation/screens/call_screen.dart';
import 'package:muvam_rider/core/services/socket_service.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';
import 'package:muvam_rider/core/utils/custom_flushbar.dart';
import 'package:muvam_rider/features/communication/data/models/chat_model.dart';
import 'package:muvam_rider/features/communication/data/providers/chat_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  final int rideId;
  final String passengerName;
  final String? passengerImage;

  const ChatScreen({
    super.key,
    required this.rideId,
    required this.passengerName,
    this.passengerImage,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final SocketService socketService;
  bool isLoading = true;
  bool isConnected = false;
  String? currentUserId;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeSocket();
    _loadCurrentUserId();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    socketService.disconnect();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getString('user_id');
  }

  void _initializeSocket() async {
    try {
      final token = await _getToken();
      if (token == null) {
        setState(() {
          isLoading = false;
        });
        _showError('Authentication token not found');
        return;
      }

      socketService = SocketService(token);
      await socketService.connect();

      setState(() {
        isConnected = true;
        isLoading = false;
      });

      socketService.listenToMessages((data) {
        _handleIncomingMessage(data);
      });

      AppLogger.log('WebSocket initialized for ride: ${widget.rideId}');
    } catch (e) {
      AppLogger.log('Initialization error: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          isConnected = false;
        });
        _showError('Failed to connect to chat');
      }
    }
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    try {
      AppLogger.log('=== INCOMING MESSAGE RECEIVED ===');
      AppLogger.log('Raw data: $data');
      AppLogger.log('Message type: ${data['type']}');
      AppLogger.log('Current ride ID: ${widget.rideId}');

      if (data['type'] == 'chat') {
        AppLogger.log('✅ Chat message detected');
        final messageData = data['data'] as Map<String, dynamic>;
        final rideId = messageData['ride_id'] as int?;
        AppLogger.log('Message ride ID: $rideId');
        AppLogger.log('Message data: $messageData');

        // Only process messages for current ride
        if (rideId == widget.rideId) {
          AppLogger.log('✅ Ride ID matches, processing message');
          final message = ChatMessageModel(
            message: messageData['message'] ?? '',
            timestamp: data['timestamp'] ?? DateTime.now().toIso8601String(),
            rideId: rideId,
            userId: messageData['user_id']?.toString(),
          );

          AppLogger.log('Created message model: ${message.message}');
          AppLogger.log('Message user ID: ${message.userId}');
          AppLogger.log('Current user ID: $currentUserId');

          if (mounted) {
            context.read<ChatProvider>().addMessage(widget.rideId, message);
            _scrollToBottom();
            AppLogger.log('✅ Message added to chat');
          } else {
            AppLogger.log('⚠️ Widget not mounted, message not added');
          }
        } else {
          AppLogger.log('⚠️ Ride ID mismatch, ignoring message');
        }
      } else {
        AppLogger.log('⚠️ Not a chat message, ignoring');
      }
      AppLogger.log('=== END INCOMING MESSAGE ===\n');
    } catch (e) {
      AppLogger.log('❌ Error processing message: $e');
    }
  }

  void _sendMessage() {
    AppLogger.log('=== CHAT SEND MESSAGE BUTTON TAPPED ===');
    AppLogger.log('Connected: $isConnected');
    AppLogger.log('Ride ID: ${widget.rideId}');
    AppLogger.log('Current User ID: $currentUserId');
    
    if (!isConnected) {
      AppLogger.log('❌ Not connected to chat');
      _showError('Not connected to chat');
      return;
    }

    final text = _messageController.text.trim();
    AppLogger.log('Message text: "$text"');
    AppLogger.log('Message length: ${text.length}');
    
    if (text.isEmpty) {
      AppLogger.log('⚠️ Message is empty, not sending');
      return;
    }

    try {
      AppLogger.log('📤 Calling socketService.sendMessage...');
      socketService.sendMessage(widget.rideId, text);

      // Add message locally for immediate UI update
      final message = ChatMessageModel(
        message: text,
        timestamp: DateTime.now().toIso8601String(),
        rideId: widget.rideId,
        userId: currentUserId,
      );

      AppLogger.log('📝 Adding message to local chat provider');
      context.read<ChatProvider>().addMessage(widget.rideId, message);
      _messageController.clear();
      _scrollToBottom();
      AppLogger.log('✅ Message sent and added to UI');
    } catch (e) {
      AppLogger.log('❌ Error sending message: $e');
      _showError('Failed to send message');
    }
    AppLogger.log('=== END CHAT SEND MESSAGE ===\n');
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showError(String message) {
    CustomFlushbar.showError(context: context, message: message);
  }

  String _extractTime(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      return DateFormat('hh:mm a').format(dt);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: 353.w,
              height: 30.h,
              margin: EdgeInsets.only(top: 20.h, left: 20.w, right: 20.w),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.arrow_back,
                      size: 24.sp,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(width: 15.w),
                  CircleAvatar(
                    radius: 15.r,
                    backgroundImage:
                        widget.passengerImage != null &&
                            widget.passengerImage!.isNotEmpty
                        ? NetworkImage(widget.passengerImage!)
                        : const AssetImage(ConstImages.avatar) as ImageProvider,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      widget.passengerName,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w500,
                        height: 21 / 18,
                        letterSpacing: -0.32,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CallScreen(
                            driverName: widget.passengerName,
                            rideId: widget.rideId,
                          ),
                        ),
                      );
                    },
                    child: Icon(
                      Icons.phone,
                      size: 24.sp,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
            Divider(thickness: 1, color: Colors.grey.shade300),
            Expanded(
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Color(ConstColors.mainColor),
                      ),
                    )
                  : Consumer<ChatProvider>(
                      builder: (context, provider, child) {
                        final messages = provider.getMessagesForRide(
                          widget.rideId,
                        );

                        if (messages.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.w),
                              child: Text(
                                "No messages yet. Start the conversation!",
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14.sp,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: EdgeInsets.all(20.w),
                          reverse: true,
                          itemCount: messages.length,
                          controller: _scrollController,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            // Message is from driver (me) if userId matches current user
                            final isMe = message.userId == currentUserId;
                            final time = _extractTime(message.timestamp);

                            return ChatBubble(
                              text: message.message,
                              isMe: isMe,
                              time: time,
                            );
                          },
                        );
                      },
                    ),
            ),
            Container(
              margin: EdgeInsets.all(20.w),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      width: 324.w,
                      height: 50.h,
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB1B1B1).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15.r),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Send message',
                          hintStyle: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            height: 1.0,
                            letterSpacing: -0.32,
                            color: const Color(0xFFB1B1B1),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 15.h),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  GestureDetector(
                    onTap: isConnected ? _sendMessage : null,
                    child: Opacity(
                      opacity: isConnected ? 1.0 : 0.4,
                      child: Container(
                        width: 21.w,
                        height: 21.h,
                        child: Icon(
                          Icons.send,
                          size: 21.sp,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
