// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:intl/intl.dart';
// import 'package:muvam_rider/core/constants/colors.dart';
// import 'package:muvam_rider/core/constants/images.dart';
// import 'package:muvam_rider/features/communication/presentation/screens/call_screen.dart';
// import 'package:muvam_rider/core/services/socket_service.dart';
// import 'package:muvam_rider/core/utils/app_logger.dart';
// import 'package:muvam_rider/core/utils/custom_flushbar.dart';
// import 'package:muvam_rider/features/communication/data/models/chat_model.dart';
// import 'package:muvam_rider/features/communication/data/providers/chat_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../widgets/chat_bubble.dart';

// class ChatScreen extends StatefulWidget {
//   final int rideId;
//   final String passengerName;
//   final String? passengerImage;

//   const ChatScreen({
//     super.key,
//     required this.rideId,
//     required this.passengerName,
//     this.passengerImage,
//   });

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   late final SocketService socketService;
//   bool isLoading = true;
//   bool isConnected = false;
//   String? currentUserId;
//   final ScrollController _scrollController = ScrollController();
//   final TextEditingController _messageController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     _initializeSocket();
//     _loadCurrentUserId();
//   }

//   @override
//   void dispose() {
//     _messageController.dispose();
//     _scrollController.dispose();
//     socketService.disconnect();
//     super.dispose();
//   }

//   Future<String?> _getToken() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString('auth_token');
//   }

//   Future<void> _loadCurrentUserId() async {
//     final prefs = await SharedPreferences.getInstance();
//     currentUserId = prefs.getString('user_id');
//   }

//   void _initializeSocket() async {
//     try {
//       final token = await _getToken();
//       if (token == null) {
//         setState(() {
//           isLoading = false;
//         });
//         _showError('Authentication token not found');
//         return;
//       }

//       socketService = SocketService(token);
//       await socketService.connect();

//       setState(() {
//         isConnected = true;
//         isLoading = false;
//       });

//       socketService.listenToMessages((data) {
//         _handleIncomingMessage(data);
//       });

//       AppLogger.log('WebSocket initialized for ride: ${widget.rideId}');
//     } catch (e) {
//       AppLogger.log('Initialization error: $e');
//       if (mounted) {
//         setState(() {
//           isLoading = false;
//           isConnected = false;
//         });
//         _showError('Failed to connect to chat');
//       }
//     }
//   }

//   void _handleIncomingMessage(Map<String, dynamic> data) {
//     try {
//       AppLogger.log('=== INCOMING MESSAGE RECEIVED ===');
//       AppLogger.log('Raw data: $data');
//       AppLogger.log('Message type: ${data['type']}');
//       AppLogger.log('Current ride ID: ${widget.rideId}');

//       if (data['type'] == 'chat') {
//         AppLogger.log('✅ Chat message detected');
//         final messageData = data['data'] as Map<String, dynamic>;
//         final rideId = messageData['ride_id'] as int?;
//         AppLogger.log('Message ride ID: $rideId');
//         AppLogger.log('Message data: $messageData');

//         // Only process messages for current ride
//         if (rideId == widget.rideId) {
//           AppLogger.log('✅ Ride ID matches, processing message');
//           final message = ChatMessageModel(
//             message: messageData['message'] ?? '',
//             timestamp: data['timestamp'] ?? DateTime.now().toIso8601String(),
//             rideId: rideId,
//             userId: messageData['user_id']?.toString(),
//           );

//           AppLogger.log('Created message model: ${message.message}');
//           AppLogger.log('Message user ID: ${message.userId}');
//           AppLogger.log('Current user ID: $currentUserId');

//           if (mounted) {
//             context.read<ChatProvider>().addMessage(widget.rideId, message);
//             _scrollToBottom();
//             AppLogger.log('✅ Message added to chat');
//           } else {
//             AppLogger.log('⚠️ Widget not mounted, message not added');
//           }
//         } else {
//           AppLogger.log('⚠️ Ride ID mismatch, ignoring message');
//         }
//       } else {
//         AppLogger.log('⚠️ Not a chat message, ignoring');
//       }
//       AppLogger.log('=== END INCOMING MESSAGE ===\n');
//     } catch (e) {
//       AppLogger.log('❌ Error processing message: $e');
//     }
//   }

//   void _sendMessage() {
//     AppLogger.log('=== CHAT SEND MESSAGE BUTTON TAPPED ===');
//     AppLogger.log('Connected: $isConnected');
//     AppLogger.log('Ride ID: ${widget.rideId}');
//     AppLogger.log('Current User ID: $currentUserId');
    
//     if (!isConnected) {
//       AppLogger.log('❌ Not connected to chat');
//       _showError('Not connected to chat');
//       return;
//     }

//     final text = _messageController.text.trim();
//     AppLogger.log('Message text: "$text"');
//     AppLogger.log('Message length: ${text.length}');
    
//     if (text.isEmpty) {
//       AppLogger.log('⚠️ Message is empty, not sending');
//       return;
//     }

//     try {
//       AppLogger.log('📤 Calling socketService.sendMessage...');
//       socketService.sendMessage(widget.rideId, text);

//       // Add message locally for immediate UI update
//       final message = ChatMessageModel(
//         message: text,
//         timestamp: DateTime.now().toIso8601String(),
//         rideId: widget.rideId,
//         userId: currentUserId,
//       );

//       AppLogger.log('📝 Adding message to local chat provider');
//       context.read<ChatProvider>().addMessage(widget.rideId, message);
//       _messageController.clear();
//       _scrollToBottom();
//       AppLogger.log('✅ Message sent and added to UI');
//     } catch (e) {
//       AppLogger.log('❌ Error sending message: $e');
//       _showError('Failed to send message');
//     }
//     AppLogger.log('=== END CHAT SEND MESSAGE ===\n');
//   }

//   void _scrollToBottom() {
//     if (_scrollController.hasClients) {
//       _scrollController.animateTo(
//         0,
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeOut,
//       );
//     }
//   }

//   void _showError(String message) {
//     CustomFlushbar.showError(context: context, message: message);
//   }

//   String _extractTime(String timestamp) {
//     try {
//       final dt = DateTime.parse(timestamp);
//       return DateFormat('hh:mm a').format(dt);
//     } catch (e) {
//       return '';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Column(
//           children: [
//             Container(
//               width: 353.w,
//               height: 30.h,
//               margin: EdgeInsets.only(top: 20.h, left: 20.w, right: 20.w),
//               child: Row(
//                 children: [
//                   GestureDetector(
//                     onTap: () => Navigator.pop(context),
//                     child: Icon(
//                       Icons.arrow_back,
//                       size: 24.sp,
//                       color: Colors.black,
//                     ),
//                   ),
//                   SizedBox(width: 15.w),
//                   CircleAvatar(
//                     radius: 15.r,
//                     backgroundImage:
//                         widget.passengerImage != null &&
//                             widget.passengerImage!.isNotEmpty
//                         ? NetworkImage(widget.passengerImage!)
//                         : const AssetImage(ConstImages.avatar) as ImageProvider,
//                   ),
//                   SizedBox(width: 10.w),
//                   Expanded(
//                     child: Text(
//                       widget.passengerName,
//                       style: TextStyle(
//                         fontFamily: 'Inter',
//                         fontSize: 18.sp,
//                         fontWeight: FontWeight.w500,
//                         height: 21 / 18,
//                         letterSpacing: -0.32,
//                         color: Colors.black,
//                       ),
//                     ),
//                   ),
//                   GestureDetector(
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => CallScreen(
//                             driverName: widget.passengerName,
//                             rideId: widget.rideId,
//                           ),
//                         ),
//                       );
//                     },
//                     child: Icon(
//                       Icons.phone,
//                       size: 24.sp,
//                       color: Colors.black,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 10.h),
//             Divider(thickness: 1, color: Colors.grey.shade300),
//             Expanded(
//               child: isLoading
//                   ? Center(
//                       child: CircularProgressIndicator(
//                         color: Color(ConstColors.mainColor),
//                       ),
//                     )
//                   : Consumer<ChatProvider>(
//                       builder: (context, provider, child) {
//                         final messages = provider.getMessagesForRide(
//                           widget.rideId,
//                         );

//                         if (messages.isEmpty) {
//                           return Center(
//                             child: Padding(
//                               padding: EdgeInsets.all(20.w),
//                               child: Text(
//                                 "No messages yet. Start the conversation!",
//                                 style: TextStyle(
//                                   fontFamily: 'Inter',
//                                   fontSize: 14.sp,
//                                   color: Colors.grey,
//                                 ),
//                                 textAlign: TextAlign.center,
//                               ),
//                             ),
//                           );
//                         }

//                         return ListView.builder(
//                           padding: EdgeInsets.all(20.w),
//                           reverse: true,
//                           itemCount: messages.length,
//                           controller: _scrollController,
//                           itemBuilder: (context, index) {
//                             final message = messages[index];
//                             // Message is from driver (me) if userId matches current user
//                             final isMe = message.userId == currentUserId;
//                             final time = _extractTime(message.timestamp);

//                             return ChatBubble(
//                               text: message.message,
//                               isMe: isMe,
//                               time: time,
//                             );
//                           },
//                         );
//                       },
//                     ),
//             ),
//             Container(
//               margin: EdgeInsets.all(20.w),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Container(
//                       width: 324.w,
//                       height: 50.h,
//                       padding: EdgeInsets.all(10.w),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFFB1B1B1).withOpacity(0.2),
//                         borderRadius: BorderRadius.circular(15.r),
//                       ),
//                       child: TextField(
//                         controller: _messageController,
//                         decoration: InputDecoration(
//                           hintText: 'Send message',
//                           hintStyle: TextStyle(
//                             fontFamily: 'Inter',
//                             fontSize: 12.sp,
//                             fontWeight: FontWeight.w500,
//                             height: 1.0,
//                             letterSpacing: -0.32,
//                             color: const Color(0xFFB1B1B1),
//                           ),
//                           border: InputBorder.none,
//                           contentPadding: EdgeInsets.symmetric(vertical: 15.h),
//                         ),
//                         onSubmitted: (_) => _sendMessage(),
//                       ),
//                     ),
//                   ),
//                   SizedBox(width: 10.w),
//                   GestureDetector(
//                     onTap: isConnected ? _sendMessage : null,
//                     child: Opacity(
//                       opacity: isConnected ? 1.0 : 0.4,
//                       child: Container(
//                         width: 21.w,
//                         height: 21.h,
//                         child: Icon(
//                           Icons.send,
//                           size: 21.sp,
//                           color: Colors.black,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
















// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:intl/intl.dart';
// import 'package:muvam_rider/core/constants/colors.dart';
// import 'package:muvam_rider/core/constants/images.dart';
// import 'package:muvam_rider/core/services/socket_service.dart';
// import 'package:muvam_rider/core/utils/app_logger.dart';
// import 'package:muvam_rider/core/utils/custom_flushbar.dart';
// import 'package:muvam_rider/features/communication/data/models/chat_model.dart';
// import 'package:muvam_rider/features/communication/data/providers/chat_provider.dart';
// // import 'package:muvam_rider/features/chat/data/models/chat_model.dart';
// // import 'package:muvam_rider/features/chat/data/providers/chat_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'dart:async';
// import '../widgets/chat_bubble.dart';
// import 'call_screen.dart';

// class ChatScreen extends StatefulWidget {
//   final int rideId;
//   final String driverName;
//   final String? driverImage;

//   const ChatScreen({
//     super.key,
//     required this.rideId,
//     required this.driverName,
//     this.driverImage,
//   });

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   late final SocketService socketService;
//   bool isLoading = true;
//   bool isConnected = false;
//   String? currentUserId;
//   final ScrollController _scrollController = ScrollController();
//   final TextEditingController _messageController = TextEditingController();
  
//   // Store the callback reference so we can remove it later
//   late final Function(Map<String, dynamic>) _messageCallback;

//   @override
//   void initState() {
//     super.initState();
//     _messageCallback = _handleIncomingMessage;
//     _initializeSocket();
//   }

//   @override
//   void dispose() {
//     // CRITICAL: Remove this screen's listener when disposing
//     if (isConnected) {
//       socketService.removeMessageListener(_messageCallback);
//     }
//     _messageController.dispose();
//     _scrollController.dispose();
    
//     // Don't disconnect the socket here - other screens might be using it
//     // Only disconnect when the app closes or user logs out
    
//     super.dispose();
//   }

//   Future<String?> _getToken() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString('auth_token');
//   }

//   void _initializeSocket() async {
//     try {
//       AppLogger.log('🔧 Initializing socket for ChatScreen');
//       final token = await _getToken();
//       if (token == null) {
//         setState(() {
//           isLoading = false;
//         });
//         CustomFlushbar.showError(
//           context: context,
//           message: 'Authentication token not found',
//         );
//         return;
//       }

//       // Use singleton instance
//       socketService = SocketService(token);
      
//       // Connect (will reuse existing connection if available)
//       await socketService.connect();

//       setState(() {
//         isConnected = true;
//         isLoading = false;
//       });

//       // Register this screen's message handler
//       socketService.listenToMessages(_messageCallback);

//       AppLogger.log('✅ ChatScreen WebSocket initialized for ride: ${widget.rideId}');
//     } catch (e) {
//       AppLogger.log('❌ ChatScreen initialization error: $e');
//       if (mounted) {
//         setState(() {
//           isLoading = false;
//           isConnected = false;
//         });
//         CustomFlushbar.showError(
//           context: context,
//           message: 'Failed to connect to chat',
//         );
//       }
//     }
//   }

//   void _handleIncomingMessage(Map<String, dynamic> data) {
//     try {
//       AppLogger.log('📨 ChatScreen received data: $data');

//       if (data['type'] == 'chat') {
//         final messageData = data['data'] as Map<String, dynamic>;
//         final rideId = messageData['ride_id'] as int?;

//         AppLogger.log('💬 Chat message - Ride ID: $rideId, Current Ride: ${widget.rideId}');

//         // Only process messages for current ride
//         if (rideId == widget.rideId) {
//           AppLogger.log('✅ Message is for current ride, processing...');
          
//           final message = ChatMessageModel(
//             message: messageData['message'] ?? '',
//             timestamp: data['timestamp'] ?? DateTime.now().toIso8601String(),
//             rideId: rideId,
//             userId: messageData['user_id']?.toString(),
//           );

//           if (mounted) {
//             AppLogger.log('✅ Adding message to provider: "${message.message}"');
//             context.read<ChatProvider>().addMessage(widget.rideId, message);
            
//             // Scroll to bottom when new message arrives
//             WidgetsBinding.instance.addPostFrameCallback((_) {
//               if (_scrollController.hasClients) {
//                 _scrollController.animateTo(
//                   0,
//                   duration: Duration(milliseconds: 300),
//                   curve: Curves.easeOut,
//                 );
//               }
//             });
//           }
//         } else {
//           AppLogger.log('⚠️ Message is for different ride (${rideId}), ignoring');
//         }
//       }
//     } catch (e) {
//       AppLogger.log('❌ Error processing message in ChatScreen: $e');
//     }
//   }

//   void _sendMessage() {
//     if (!isConnected) {
//       CustomFlushbar.showError(
//         context: context,
//         message: 'Not connected to chat',
//       );
//       return;
//     }

//     final text = _messageController.text.trim();
//     if (text.isEmpty) return;

//     try {
//       AppLogger.log('📤 Sending message: "$text" for ride: ${widget.rideId}');
      
//       socketService.sendMessage(widget.rideId, text);

//       // Add message locally for immediate UI update
//       final message = ChatMessageModel(
//         message: text,
//         timestamp: DateTime.now().toIso8601String(),
//         rideId: widget.rideId,
//         userId: currentUserId,
//       );

//       context.read<ChatProvider>().addMessage(widget.rideId, message);
//       _messageController.clear();
      
//       AppLogger.log('✅ Message sent and added to UI');
//     } catch (e) {
//       AppLogger.log('❌ Error sending message: $e');
//       CustomFlushbar.showError(
//         context: context,
//         message: 'Failed to send message',
//       );
//     }
//   }

//   String _extractTime(String timestamp) {
//     try {
//       final dt = DateTime.parse(timestamp);
//       return DateFormat('hh:mm a').format(dt);
//     } catch (e) {
//       return '';
//     }
//   }

//   void _showCallDialog() {
//     showModalBottomSheet(
//       context: context,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
//       ),
//       builder: (context) => Container(
//         padding: EdgeInsets.all(20.w),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               width: 69.w,
//               height: 5.h,
//               margin: EdgeInsets.only(bottom: 20.h),
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade300,
//                 borderRadius: BorderRadius.circular(2.5.r),
//               ),
//             ),
//             Text(
//               'Call ${widget.driverName}',
//               style: TextStyle(
//                 fontFamily: 'Inter',
//                 fontSize: 18.sp,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.black,
//               ),
//             ),
//             SizedBox(height: 30.h),
//             GestureDetector(
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => CallScreen(
//                       driverName: widget.driverName,
//                       rideId: widget.rideId,
//                     ),
//                   ),
//                 );
//               },
//               child: Container(
//                 width: double.infinity,
//                 padding: EdgeInsets.symmetric(vertical: 15.h),
//                 child: Row(
//                   children: [
//                     Icon(Icons.phone_android, size: 24.sp),
//                     SizedBox(width: 15.w),
//                     Text(
//                       'Call via app',
//                       style: TextStyle(
//                         fontFamily: 'Inter',
//                         fontSize: 16.sp,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             SizedBox(height: 10.h),
//             GestureDetector(
//               onTap: () {
//                 Navigator.pop(context);
//                 _makeCall();
//               },
//               child: Container(
//                 width: double.infinity,
//                 padding: EdgeInsets.symmetric(vertical: 15.h),
//                 child: Row(
//                   children: [
//                     Icon(Icons.phone, size: 24.sp),
//                     SizedBox(width: 15.w),
//                     Text(
//                       'Call via phone',
//                       style: TextStyle(
//                         fontFamily: 'Inter',
//                         fontSize: 16.sp,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             SizedBox(height: 20.h),
//           ],
//         ),
//       ),
//     );
//   }

//   void _makeCall() async {
//     const phoneNumber = '+1234567890';
//     final uri = Uri.parse('tel:$phoneNumber');
    
//     try {
//       if (await canLaunchUrl(uri)) {
//         await launchUrl(uri);
//         AppLogger.log('📞 Call initiated to: $phoneNumber', tag: 'CHAT');
//       } else {
//         CustomFlushbar.showError(
//           context: context,
//           message: 'Cannot make phone calls on this device',
//         );
//       }
//     } catch (e) {
//       AppLogger.error('Failed to make call', error: e, tag: 'CHAT');
//       CustomFlushbar.showError(
//         context: context,
//         message: 'Failed to make call',
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Column(
//           children: [
//             Container(
//               width: 353.w,
//               height: 30.h,
//               margin: EdgeInsets.only(top: 20.h, left: 20.w, right: 20.w),
//               child: Row(
//                 children: [
//                   GestureDetector(
//                     onTap: () => Navigator.pop(context),
//                     child: Icon(
//                       Icons.arrow_back,
//                       size: 24.sp,
//                       color: Colors.black,
//                     ),
//                   ),
//                   SizedBox(width: 15.w),
//                   CircleAvatar(
//                     radius: 15.r,
//                     backgroundImage:
//                         widget.driverImage != null &&
//                             widget.driverImage!.isNotEmpty
//                         ? NetworkImage(widget.driverImage!)
//                         : AssetImage(ConstImages.avatar) as ImageProvider,
//                   ),
//                   SizedBox(width: 10.w),
//                   Expanded(
//                     child: Text(
//                       widget.driverName,
//                       style: TextStyle(
//                         fontFamily: 'Inter',
//                         fontSize: 18.sp,
//                         fontWeight: FontWeight.w500,
//                         height: 21 / 18,
//                         letterSpacing: -0.32,
//                         color: Colors.black,
//                       ),
//                     ),
//                   ),
                  
//                   GestureDetector(
//                     onTap: () {
//                       AppLogger.log('📞 Call button tapped for driver: ${widget.driverName}', tag: 'CHAT');
//                       _showCallDialog();
//                     },
//                     child: Container(
//                       padding: EdgeInsets.all(4.w),
//                       child: Icon(
//                         Icons.phone,
//                         size: 24.sp,
//                         color: Colors.black,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 10.h),
//             Divider(thickness: 1, color: Colors.grey.shade300),
//             Expanded(
//               child: isLoading
//                   ? Center(
//                       child: CircularProgressIndicator(
//                         color: Color(ConstColors.mainColor),
//                       ),
//                     )
//                   : Consumer<ChatProvider>(
//                       builder: (context, provider, child) {
//                         final messages = provider.getMessagesForRide(
//                           widget.rideId,
//                         );

//                         if (messages.isEmpty) {
//                           return Center(
//                             child: Padding(
//                               padding: EdgeInsets.all(20.w),
//                               child: Text(
//                                 "No messages yet. Start the conversation!",
//                                 style: TextStyle(
//                                   fontFamily: 'Inter',
//                                   fontSize: 14.sp,
//                                   color: Colors.grey,
//                                 ),
//                                 textAlign: TextAlign.center,
//                               ),
//                             ),
//                           );
//                         }

//                         return ListView.builder(
//                           padding: EdgeInsets.all(20.w),
//                           reverse: true,
//                           itemCount: messages.length,
//                           controller: _scrollController,
//                           itemBuilder: (context, index) {
//                             final message = messages[index];
//                             final isMe =
//                                 message.userId == currentUserId ||
//                                 message.userId == null;
//                             final time = _extractTime(message.timestamp);

//                             return ChatBubble(
//                               text: message.message,
//                               isMe: isMe,
//                               time: time,
//                             );
//                           },
//                         );
//                       },
//                     ),
//             ),
//             Container(
//               margin: EdgeInsets.all(20.w),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Container(
//                       width: 324.w,
//                       height: 50.h,
//                       padding: EdgeInsets.all(10.w),
//                       decoration: BoxDecoration(
//                         color: Color(0xFFB1B1B1).withOpacity(0.2),
//                         borderRadius: BorderRadius.circular(15.r),
//                       ),
//                       child: TextField(
//                         controller: _messageController,
//                         decoration: InputDecoration(
//                           hintText: 'Send message',
//                           hintStyle: TextStyle(
//                             fontFamily: 'Inter',
//                             fontSize: 12.sp,
//                             fontWeight: FontWeight.w500,
//                             height: 1.0,
//                             letterSpacing: -0.32,
//                             color: Color(0xFFB1B1B1),
//                           ),
//                           border: InputBorder.none,
//                           contentPadding: EdgeInsets.symmetric(vertical: 15.h),
//                         ),
//                         onSubmitted: (_) => _sendMessage(),
//                       ),
//                     ),
//                   ),
//                   SizedBox(width: 10.w),
//                   GestureDetector(
//                     onTap: isConnected ? _sendMessage : null,
//                     child: Opacity(
//                       opacity: isConnected ? 1.0 : 0.4,
//                       child: Container(
//                         width: 21.w,
//                         height: 21.h,
//                         child: Icon(
//                           Icons.send,
//                           size: 21.sp,
//                           color: Colors.black,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

























import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/images.dart';

import 'package:muvam_rider/core/services/websocket_service.dart'; // CHANGED

import 'package:muvam_rider/core/utils/app_logger.dart';
import 'package:muvam_rider/core/utils/custom_flushbar.dart';
import 'package:muvam_rider/features/communication/data/models/chat_model.dart';
import 'package:muvam_rider/features/communication/data/providers/chat_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../widgets/chat_bubble.dart';
import 'call_screen.dart';
// //FOR DRIVER
// class ChatScreen extends StatefulWidget {
//   final int rideId;
//   final String driverName;
//   final String? driverImage;

//   const ChatScreen({
//     super.key,
//     required this.rideId,
//     required this.driverName,
//     this.driverImage,
//   });

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   late final WebSocketService _webSocketService; // CHANGED
//   bool isLoading = true;
//   bool isConnected = false;
//   String? currentUserId;
//   final ScrollController _scrollController = ScrollController();
//   final TextEditingController _messageController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     _initializeWebSocket();
//   }

//   @override
//   void dispose() {
//     // Remove chat callback
//     if (_webSocketService.onChatMessage != null) {
//       _webSocketService.onChatMessage = null;
//     }

//     _messageController.dispose();
//     _scrollController.dispose();

//     // Don't disconnect - other parts of app might use it
//     super.dispose();
//   }

//   void _initializeWebSocket() async {
//     try {
//       AppLogger.log('🔧 Initializing WebSocket for ChatScreen');

//       // Use singleton instance
//       _webSocketService = WebSocketService.instance;

//       // Connect if not already connected
//       if (!_webSocketService.isConnected) {
//         AppLogger.log('📡 WebSocket not connected, connecting...');
//         await _webSocketService.connect();
//       } else {
//         AppLogger.log('✅ WebSocket already connected');
//       }

//       setState(() {
//         isConnected = _webSocketService.isConnected;
//         isLoading = false;
//       });

//       // Register chat message handler
//       _webSocketService.onChatMessage = _handleIncomingMessage;

//       AppLogger.log(
//         '✅ ChatScreen WebSocket initialized for ride: ${widget.rideId}',
//       );
//     } catch (e) {
//       AppLogger.log('❌ ChatScreen WebSocket initialization error: $e');
//       if (mounted) {
//         setState(() {
//           isLoading = false;
//           isConnected = false;
//         });
//         CustomFlushbar.showError(
//           context: context,
//           message: 'Failed to connect to chat',
//         );
//       }
//     }
//   }

//   void _handleIncomingMessage(Map<String, dynamic> data) {
//     try {
//       AppLogger.log('📨 ChatScreen received message: $data');

//       if (data['type'] == 'chat' || data['type'] == 'chat_message') {
//         final messageData = data['data'] as Map<String, dynamic>;
//         final rideId = messageData['ride_id'] as int?;

//         AppLogger.log(
//           '💬 Chat message - Ride ID: $rideId, Current Ride: ${widget.rideId}',
//         );

//         // Only process messages for current ride
//         if (rideId == widget.rideId) {
//           AppLogger.log('✅ Message is for current ride, processing...');

//           final message = ChatMessageModel(
//             message: messageData['message'] ?? '',
//             timestamp: data['timestamp'] ?? DateTime.now().toIso8601String(),
//             rideId: rideId,
//             userId: messageData['user_id']?.toString(),
//           );

//           if (mounted) {
//             AppLogger.log('✅ Adding message to provider: "${message.message}"');
//             context.read<ChatProvider>().addMessage(widget.rideId, message);

//             // Scroll to bottom when new message arrives
//             WidgetsBinding.instance.addPostFrameCallback((_) {
//               if (_scrollController.hasClients) {
//                 _scrollController.animateTo(
//                   0,
//                   duration: Duration(milliseconds: 300),
//                   curve: Curves.easeOut,
//                 );
//               }
//             });
//           }
//         } else {
//           AppLogger.log('⚠️ Message is for different ride ($rideId), ignoring');
//         }
//       }
//     } catch (e) {
//       AppLogger.log('❌ Error processing message in ChatScreen: $e');
//     }
//   }

//   void _sendMessage() {
//     if (!isConnected) {
//       CustomFlushbar.showError(
//         context: context,
//         message: 'Not connected to chat',
//       );
//       return;
//     }

//     final text = _messageController.text.trim();
//     if (text.isEmpty) return;

//     try {
//       AppLogger.log('📤 Sending message: "$text" for ride: ${widget.rideId}');

//       // Use the WebSocketService method
//       _webSocketService.sendChatMessage(widget.rideId, text);

//       // Add message locally for immediate UI update
//       final message = ChatMessageModel(
//         message: text,
//         timestamp: DateTime.now().toIso8601String(),
//         rideId: widget.rideId,
//         userId: currentUserId,
//       );

//       context.read<ChatProvider>().addMessage(widget.rideId, message);
//       _messageController.clear();

//       AppLogger.log('✅ Message sent and added to UI');
//     } catch (e) {
//       AppLogger.log('❌ Error sending message: $e');
//       CustomFlushbar.showError(
//         context: context,
//         message: 'Failed to send message',
//       );
//     }
//   }

//   String _extractTime(String timestamp) {
//     try {
//       final dt = DateTime.parse(timestamp);
//       return DateFormat('hh:mm a').format(dt);
//     } catch (e) {
//       return '';
//     }
//   }

//   void _showCallDialog() {
//     showModalBottomSheet(
//       context: context,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
//       ),
//       builder: (context) => Container(
//         padding: EdgeInsets.all(20.w),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               width: 69.w,
//               height: 5.h,
//               margin: EdgeInsets.only(bottom: 20.h),
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade300,
//                 borderRadius: BorderRadius.circular(2.5.r),
//               ),
//             ),
//             Text(
//               'Call ${widget.driverName}',
//               style: TextStyle(
//                 fontFamily: 'Inter',
//                 fontSize: 18.sp,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.black,
//               ),
//             ),
//             SizedBox(height: 30.h),
//             GestureDetector(
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => CallScreen(
//                       driverName: widget.driverName,
//                       rideId: widget.rideId,
//                     ),
//                   ),
//                 );
//               },
//               child: Container(
//                 width: double.infinity,
//                 padding: EdgeInsets.symmetric(vertical: 15.h),
//                 child: Row(
//                   children: [
//                     Icon(Icons.phone_android, size: 24.sp),
//                     SizedBox(width: 15.w),
//                     Text(
//                       'Call via app',
//                       style: TextStyle(
//                         fontFamily: 'Inter',
//                         fontSize: 16.sp,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             SizedBox(height: 10.h),
//             GestureDetector(
//               onTap: () {
//                 Navigator.pop(context);
//                 _makeCall();
//               },
//               child: Container(
//                 width: double.infinity,
//                 padding: EdgeInsets.symmetric(vertical: 15.h),
//                 child: Row(
//                   children: [
//                     Icon(Icons.phone, size: 24.sp),
//                     SizedBox(width: 15.w),
//                     Text(
//                       'Call via phone',
//                       style: TextStyle(
//                         fontFamily: 'Inter',
//                         fontSize: 16.sp,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             SizedBox(height: 20.h),
//           ],
//         ),
//       ),
//     );
//   }

//   void _makeCall() async {
//     const phoneNumber = '+1234567890';
//     final uri = Uri.parse('tel:$phoneNumber');

//     try {
//       if (await canLaunchUrl(uri)) {
//         await launchUrl(uri);
//         AppLogger.log('📞 Call initiated to: $phoneNumber', tag: 'CHAT');
//       } else {
//         CustomFlushbar.showError(
//           context: context,
//           message: 'Cannot make phone calls on this device',
//         );
//       }
//     } catch (e) {
//       AppLogger.error('Failed to make call', error: e, tag: 'CHAT');
//       CustomFlushbar.showError(
//         context: context,
//         message: 'Failed to make call',
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Column(
//           children: [
//             Container(
//               width: 353.w,
//               height: 30.h,
//               margin: EdgeInsets.only(top: 20.h, left: 20.w, right: 20.w),
//               child: Row(
//                 children: [
//                   GestureDetector(
//                     onTap: () => Navigator.pop(context),
//                     child: Icon(
//                       Icons.arrow_back,
//                       size: 24.sp,
//                       color: Colors.black,
//                     ),
//                   ),
//                   SizedBox(width: 15.w),
//                   CircleAvatar(
//                     radius: 15.r,
//                     backgroundImage:
//                         widget.driverImage != null &&
//                             widget.driverImage!.isNotEmpty
//                         ? NetworkImage(widget.driverImage!)
//                         : AssetImage(ConstImages.avatar) as ImageProvider,
//                   ),
//                   SizedBox(width: 10.w),
//                   Expanded(
//                     child: Text(
//                       widget.driverName,
//                       style: TextStyle(
//                         fontFamily: 'Inter',
//                         fontSize: 18.sp,
//                         fontWeight: FontWeight.w500,
//                         height: 21 / 18,
//                         letterSpacing: -0.32,
//                         color: Colors.black,
//                       ),
//                     ),
//                   ),

//                   GestureDetector(
//                     onTap: () {
//                       AppLogger.log(
//                         '📞 Call button tapped for driver: ${widget.driverName}',
//                         tag: 'CHAT',
//                       );
//                       _showCallDialog();
//                     },
//                     child: Container(
//                       padding: EdgeInsets.all(4.w),
//                       child: Icon(
//                         Icons.phone,
//                         size: 24.sp,
//                         color: Colors.black,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 10.h),
//             Divider(thickness: 1, color: Colors.grey.shade300),
//             Expanded(
//               child: isLoading
//                   ? Center(
//                       child: CircularProgressIndicator(
//                         color: Color(ConstColors.mainColor),
//                       ),
//                     )
//                   : Consumer<ChatProvider>(
//                       builder: (context, provider, child) {
//                         final messages = provider.getMessagesForRide(
//                           widget.rideId,
//                         );

//                         if (messages.isEmpty) {
//                           return Center(
//                             child: Padding(
//                               padding: EdgeInsets.all(20.w),
//                               child: Text(
//                                 "No messages yet. Start the conversation!",
//                                 style: TextStyle(
//                                   fontFamily: 'Inter',
//                                   fontSize: 14.sp,
//                                   color: Colors.grey,
//                                 ),
//                                 textAlign: TextAlign.center,
//                               ),
//                             ),
//                           );
//                         }

//                         return ListView.builder(
//                           padding: EdgeInsets.all(20.w),
//                           reverse: true,
//                           itemCount: messages.length,
//                           controller: _scrollController,
//                           itemBuilder: (context, index) {
//                             final message = messages[index];
//                             final isMe =
//                                 message.userId == currentUserId ||
//                                 message.userId == null;
//                             final time = _extractTime(message.timestamp);

//                             return ChatBubble(
//                               text: message.message,
//                               isMe: isMe,
//                               time: time,
//                             );
//                           },
//                         );
//                       },
//                     ),
//             ),
//             Container(
//               margin: EdgeInsets.all(20.w),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Container(
//                       width: 324.w,
//                       height: 50.h,
//                       padding: EdgeInsets.all(10.w),
//                       decoration: BoxDecoration(
//                         color: Color(0xFFB1B1B1).withOpacity(0.2),
//                         borderRadius: BorderRadius.circular(15.r),
//                       ),
//                       child: TextField(
//                         controller: _messageController,
//                         decoration: InputDecoration(
//                           hintText: 'Send message',
//                           hintStyle: TextStyle(
//                             fontFamily: 'Inter',
//                             fontSize: 12.sp,
//                             fontWeight: FontWeight.w500,
//                             height: 1.0,
//                             letterSpacing: -0.32,
//                             color: Color(0xFFB1B1B1),
//                           ),
//                           border: InputBorder.none,
//                           contentPadding: EdgeInsets.symmetric(vertical: 15.h),
//                         ),
//                         onSubmitted: (_) => _sendMessage(),
//                       ),
//                     ),
//                   ),
//                   SizedBox(width: 10.w),
//                   GestureDetector(
//                     onTap: isConnected ? _sendMessage : null,
//                     child: Opacity(
//                       opacity: isConnected ? 1.0 : 0.4,
//                       child: Container(
//                         width: 21.w,
//                         height: 21.h,
//                         child: Icon(
//                           Icons.send,
//                           size: 21.sp,
//                           color: Colors.black,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }










































// // FOR DRIVER - FIXED VERSION
// class ChatScreen extends StatefulWidget {
//   final int rideId;
//   final String driverName;
//   final String? driverImage;

//   const ChatScreen({
//     super.key,
//     required this.rideId,
//     required this.driverName,
//     this.driverImage,
//   });

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   late final WebSocketService _webSocketService;
//   bool isLoading = true;
//   bool isConnected = false;
//   String? currentUserId;
//   final ScrollController _scrollController = ScrollController();
//   final TextEditingController _messageController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     _loadUserId(); // ADDED: Load user ID first
//     _initializeWebSocket();
//   }

//   @override
//   void dispose() {
//     if (_webSocketService.onChatMessage != null) {
//       _webSocketService.onChatMessage = null;
//     }

//     _messageController.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }

//   // ADDED: Load current user ID
//   void _loadUserId() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       currentUserId = prefs.getString('user_id');
//     });
//     AppLogger.log('📱 Current User ID: $currentUserId');
//   }

//   void _initializeWebSocket() async {
//     try {
//       AppLogger.log('🔧 Initializing WebSocket for ChatScreen');

//       _webSocketService = WebSocketService.instance;

//       if (!_webSocketService.isConnected) {
//         AppLogger.log('📡 WebSocket not connected, connecting...');
//         await _webSocketService.connect();
//       } else {
//         AppLogger.log('✅ WebSocket already connected');
//       }

//       setState(() {
//         isConnected = _webSocketService.isConnected;
//         isLoading = false;
//       });

//       // Register chat message handler
//       _webSocketService.onChatMessage = _handleIncomingMessage;

//       AppLogger.log(
//         '✅ ChatScreen WebSocket initialized for ride: ${widget.rideId}',
//       );
//     } catch (e) {
//       AppLogger.log('❌ ChatScreen WebSocket initialization error: $e');
//       if (mounted) {
//         setState(() {
//           isLoading = false;
//           isConnected = false;
//         });
//         CustomFlushbar.showError(
//           context: context,
//           message: 'Failed to connect to chat',
//         );
//       }
//     }
//   }

//   // void _handleIncomingMessage(Map<String, dynamic> data) {
//   //   try {
//   //     AppLogger.log('📨 ChatScreen received message: $data');

//   //     if (data['type'] == 'chat' || data['type'] == 'chat_message') {
//   //       final messageData = data['data'] as Map<String, dynamic>?;
//   //       if (messageData == null) {
//   //         AppLogger.log('⚠️ No data field in message');
//   //         return;
//   //       }

//   //       final rideId = messageData['ride_id'] as int?;

//   //       AppLogger.log(
//   //         '💬 Chat message - Ride ID: $rideId, Current Ride: ${widget.rideId}',
//   //       );

//   //       // Only process messages for current ride
//   //       if (rideId == widget.rideId) {
//   //         AppLogger.log('✅ Message is for current ride, processing...');

//   //         final message = ChatMessageModel(
//   //           message: messageData['message'] ?? '',
//   //           timestamp: data['timestamp'] ?? DateTime.now().toIso8601String(),
//   //           rideId: rideId,
//   //           userId:
//   //               messageData['sender_id']?.toString() ??
//   //               messageData['user_id']?.toString(),
//   //         );

//   //         if (mounted) {
//   //           AppLogger.log('✅ Adding message to provider: "${message.message}"');
//   //           context.read<ChatProvider>().addMessage(widget.rideId, message);

//   //           // Scroll to bottom when new message arrives
//   //           WidgetsBinding.instance.addPostFrameCallback((_) {
//   //             if (_scrollController.hasClients) {
//   //               _scrollController.animateTo(
//   //                 0,
//   //                 duration: Duration(milliseconds: 300),
//   //                 curve: Curves.easeOut,
//   //               );
//   //             }
//   //           });
//   //         }
//   //       } else {
//   //         AppLogger.log('⚠️ Message is for different ride ($rideId), ignoring');
//   //       }
//   //     }
//   //   } catch (e) {
//   //     AppLogger.log('❌ Error processing message in ChatScreen: $e');
//   //   }
//   // }




// void _handleIncomingMessage(Map<String, dynamic> data) {
//   try {
//     print('📨 Driver ChatScreen received message: $data');

//     if (data['type'] == 'chat' || data['type'] == 'chat_message') {
//       final messageData = data['data'] as Map<String, dynamic>?;
//       if (messageData == null) {
//         print('⚠️ No data field in message');
//         return;
//       }

//       // Get ride_id from nested data (primary) or top-level (fallback)
//       final messageRideId = messageData['ride_id'] ?? data['ride_id'];
      
//       print('💬 Chat message - Message Ride ID: $messageRideId, Current Ride: ${widget.rideId}');

//       // Only process messages for current ride
//       if (messageRideId == widget.rideId) {
//         print('✅ Message is for current ride, processing...');

//         // Extract message details
//         final messageText = messageData['message'] ?? '';
//         final senderId = messageData['sender_id']?.toString() ?? 
//                          data['user_id']?.toString() ?? '';
//         final timestamp = data['timestamp'] ?? DateTime.now().toIso8601String();

//         final message = ChatMessageModel(
//           message: messageText,
//           timestamp: timestamp,
//           rideId: messageRideId as int,
//           userId: senderId,
//         );

//         if (mounted) {
//           print('✅ Adding message to provider: "${message.message}"');
//           context.read<ChatProvider>().addMessage(widget.rideId, message);

//           // Scroll to bottom
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             if (_scrollController.hasClients) {
//               _scrollController.animateTo(
//                 0,
//                 duration: Duration(milliseconds: 300),
//                 curve: Curves.easeOut,
//               );
//             }
//           });
//         }
//       } else {
//         print('⚠️ Message is for different ride ($messageRideId), ignoring');
//       }
//     }
//   } catch (e, stackTrace) {
//     print('❌ Error processing message in Driver ChatScreen: $e');
//     print('Stack trace: $stackTrace');
//   }
// }





//   // void _sendMessage() {
//   //   if (!isConnected) {
//   //     CustomFlushbar.showError(
//   //       context: context,
//   //       message: 'Not connected to chat',
//   //     );
//   //     return;
//   //   }

//   //   final text = _messageController.text.trim();
//   //   if (text.isEmpty) return;

//   //   try {
//   //     AppLogger.log('📤 Sending message: "$text" for ride: ${widget.rideId}');

//   //     // FIXED: Use sendMessage with correct format
//   //     _webSocketService.sendMessage({
//   //       'type': 'chat',
//   //       'data': {'ride_id': widget.rideId, 'message': text},
//   //       'timestamp': DateTime.now().toIso8601String(),
//   //     });

//   //     // Add message locally for immediate UI update
//   //     final message = ChatMessageModel(
//   //       message: text,
//   //       timestamp: DateTime.now().toIso8601String(),
//   //       rideId: widget.rideId,
//   //       userId: currentUserId,
//   //     );

//   //     context.read<ChatProvider>().addMessage(widget.rideId, message);
//   //     _messageController.clear();

//   //     AppLogger.log('✅ Message sent and added to UI');
//   //   } catch (e) {
//   //     AppLogger.log('❌ Error sending message: $e');
//   //     CustomFlushbar.showError(
//   //       context: context,
//   //       message: 'Failed to send message',
//   //     );
//   //   }
//   // }










// void _sendMessage() {
//   if (!isConnected) {
//     CustomFlushbar.showError(
//       context: context,
//       message: 'Not connected to chat',
//     );
//     return;
//   }

//   final text = _messageController.text.trim();
//   if (text.isEmpty) return;

//   try {
//     print('==================');
//     print('📤 DRIVER SENDING MESSAGE');
//     print('   Ride ID: ${widget.rideId}');
//     print('   Message: "$text"');
//     print('   User ID: $currentUserId');
//     print('==================');

//     // Send in exact Postman format
//     final messagePayload = {
//       'type': 'chat',
//       'data': {
//         'ride_id': widget.rideId,
//         'message': text,
//       },
//       'timestamp': DateTime.now().toIso8601String(),
//     };

//     print('📤 Sending payload: $messagePayload');
//     _webSocketService.sendMessage(messagePayload);

//     // Add message locally
//     final message = ChatMessageModel(
//       message: text,
//       timestamp: DateTime.now().toIso8601String(),
//       rideId: widget.rideId,
//       userId: currentUserId,
//     );

//     context.read<ChatProvider>().addMessage(widget.rideId, message);
//     _messageController.clear();

//     print('✅ Driver message sent and added to UI');
//   } catch (e, stackTrace) {
//     print('❌ Error sending message: $e');
//     print('Stack trace: $stackTrace');
//     CustomFlushbar.showError(
//       context: context,
//       message: 'Failed to send message',
//     );
//   }
// }






//   String _extractTime(String timestamp) {
//     try {
//       final dt = DateTime.parse(timestamp);
//       return DateFormat('hh:mm a').format(dt);
//     } catch (e) {
//       return '';
//     }
//   }

//   void _showCallDialog() {
//     showModalBottomSheet(
//       context: context,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
//       ),
//       builder: (context) => Container(
//         padding: EdgeInsets.all(20.w),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               width: 69.w,
//               height: 5.h,
//               margin: EdgeInsets.only(bottom: 20.h),
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade300,
//                 borderRadius: BorderRadius.circular(2.5.r),
//               ),
//             ),
//             Text(
//               'Call ${widget.driverName}',
//               style: TextStyle(
//                 fontFamily: 'Inter',
//                 fontSize: 18.sp,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.black,
//               ),
//             ),
//             SizedBox(height: 30.h),
//             GestureDetector(
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => CallScreen(
//                       driverName: widget.driverName,
//                       rideId: widget.rideId,
//                     ),
//                   ),
//                 );
//               },
//               child: Container(
//                 width: double.infinity,
//                 padding: EdgeInsets.symmetric(vertical: 15.h),
//                 child: Row(
//                   children: [
//                     Icon(Icons.phone_android, size: 24.sp),
//                     SizedBox(width: 15.w),
//                     Text(
//                       'Call via app',
//                       style: TextStyle(
//                         fontFamily: 'Inter',
//                         fontSize: 16.sp,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             SizedBox(height: 10.h),
//             GestureDetector(
//               onTap: () {
//                 Navigator.pop(context);
//                 _makeCall();
//               },
//               child: Container(
//                 width: double.infinity,
//                 padding: EdgeInsets.symmetric(vertical: 15.h),
//                 child: Row(
//                   children: [
//                     Icon(Icons.phone, size: 24.sp),
//                     SizedBox(width: 15.w),
//                     Text(
//                       'Call via phone',
//                       style: TextStyle(
//                         fontFamily: 'Inter',
//                         fontSize: 16.sp,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             SizedBox(height: 20.h),
//           ],
//         ),
//       ),
//     );
//   }

//   void _makeCall() async {
//     const phoneNumber = '+1234567890';
//     final uri = Uri.parse('tel:$phoneNumber');

//     try {
//       if (await canLaunchUrl(uri)) {
//         await launchUrl(uri);
//         AppLogger.log('📞 Call initiated to: $phoneNumber', tag: 'CHAT');
//       } else {
//         CustomFlushbar.showError(
//           context: context,
//           message: 'Cannot make phone calls on this device',
//         );
//       }
//     } catch (e) {
//       AppLogger.error('Failed to make call', error: e, tag: 'CHAT');
//       CustomFlushbar.showError(
//         context: context,
//         message: 'Failed to make call',
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Column(
//           children: [
//             Container(
//               width: 353.w,
//               height: 30.h,
//               margin: EdgeInsets.only(top: 20.h, left: 20.w, right: 20.w),
//               child: Row(
//                 children: [
//                   GestureDetector(
//                     onTap: () => Navigator.pop(context),
//                     child: Icon(
//                       Icons.arrow_back,
//                       size: 24.sp,
//                       color: Colors.black,
//                     ),
//                   ),
//                   SizedBox(width: 15.w),
//                   CircleAvatar(
//                     radius: 15.r,
//                     backgroundImage:
//                         widget.driverImage != null &&
//                             widget.driverImage!.isNotEmpty
//                         ? NetworkImage(widget.driverImage!)
//                         : AssetImage(ConstImages.avatar) as ImageProvider,
//                   ),
//                   SizedBox(width: 10.w),
//                   Expanded(
//                     child: Text(
//                       widget.driverName,
//                       style: TextStyle(
//                         fontFamily: 'Inter',
//                         fontSize: 18.sp,
//                         fontWeight: FontWeight.w500,
//                         height: 21 / 18,
//                         letterSpacing: -0.32,
//                         color: Colors.black,
//                       ),
//                     ),
//                   ),

//                   GestureDetector(
//                     onTap: () {
//                       AppLogger.log(
//                         '📞 Call button tapped for driver: ${widget.driverName}',
//                         tag: 'CHAT',
//                       );
//                       _showCallDialog();
//                     },
//                     child: Container(
//                       padding: EdgeInsets.all(4.w),
//                       child: Icon(
//                         Icons.phone,
//                         size: 24.sp,
//                         color: Colors.black,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 10.h),
//             Divider(thickness: 1, color: Colors.grey.shade300),
//             Expanded(
//               child: isLoading
//                   ? Center(
//                       child: CircularProgressIndicator(
//                         color: Color(ConstColors.mainColor),
//                       ),
//                     )
//                   : Consumer<ChatProvider>(
//                       builder: (context, provider, child) {
//                         final messages = provider.getMessagesForRide(
//                           widget.rideId,
//                         );

//                         if (messages.isEmpty) {
//                           return Center(
//                             child: Padding(
//                               padding: EdgeInsets.all(20.w),
//                               child: Text(
//                                 "No messages yet. Start the conversation!",
//                                 style: TextStyle(
//                                   fontFamily: 'Inter',
//                                   fontSize: 14.sp,
//                                   color: Colors.grey,
//                                 ),
//                                 textAlign: TextAlign.center,
//                               ),
//                             ),
//                           );
//                         }

//                         return ListView.builder(
//                           padding: EdgeInsets.all(20.w),
//                           reverse: true,
//                           itemCount: messages.length,
//                           controller: _scrollController,
//                           itemBuilder: (context, index) {
//                             final message = messages[index];
//                             final isMe =
//                                 message.userId == currentUserId ||
//                                 message.userId == null;
//                             final time = _extractTime(message.timestamp);

//                             return ChatBubble(
//                               text: message.message,
//                               isMe: isMe,
//                               time: time,
//                             );
//                           },
//                         );
//                       },
//                     ),
//             ),
//             Container(
//               margin: EdgeInsets.all(20.w),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Container(
//                       width: 324.w,
//                       height: 50.h,
//                       padding: EdgeInsets.all(10.w),
//                       decoration: BoxDecoration(
//                         color: Color(0xFFB1B1B1).withOpacity(0.2),
//                         borderRadius: BorderRadius.circular(15.r),
//                       ),
//                       child: TextField(
//                         controller: _messageController,
//                         decoration: InputDecoration(
//                           hintText: 'Send message',
//                           hintStyle: TextStyle(
//                             fontFamily: 'Inter',
//                             fontSize: 12.sp,
//                             fontWeight: FontWeight.w500,
//                             height: 1.0,
//                             letterSpacing: -0.32,
//                             color: Color(0xFFB1B1B1),
//                           ),
//                           border: InputBorder.none,
//                           contentPadding: EdgeInsets.symmetric(vertical: 15.h),
//                         ),
//                         onSubmitted: (_) => _sendMessage(),
//                       ),
//                     ),
//                   ),
//                   SizedBox(width: 10.w),
//                   GestureDetector(
//                     onTap: isConnected ? _sendMessage : null,
//                     child: Opacity(
//                       opacity: isConnected ? 1.0 : 0.4,
//                       child: Container(
//                         width: 21.w,
//                         height: 21.h,
//                         child: Icon(
//                           Icons.send,
//                           size: 21.sp,
//                           color: Colors.black,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }






// ChatScreen using Pure Native WebSocket (No packages)



// ChatScreen using Pure Native WebSocket (No packages)
class ChatScreen extends StatefulWidget {
  final int rideId;
  final String driverName;
  final String? driverImage;

  const ChatScreen({
    super.key,
    required this.rideId,
    required this.driverName,
    this.driverImage,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final WebSocketService _webSocketService;
  bool isLoading = true;
  bool isConnected = false;
  String? currentUserId;
  bool _userIdLoaded = false;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    print('🎬 ChatScreen initState - Ride ID: ${widget.rideId}');
    _initializeScreen();
  }

  @override
  void dispose() {
    print('🛑 ChatScreen dispose');
    _webSocketService.onChatMessage = null;
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    await _loadUserId();
    await _initializeWebSocket();
  }

  Future<void> _loadUserId() async {
    print('🔑 Loading user ID...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      
      print('🔑 User ID: $userId');
      
      if (mounted) {
        setState(() {
          currentUserId = userId;
          _userIdLoaded = true;
        });
      }
    } catch (e) {
      print('❌ Error loading user ID: $e');
      if (mounted) {
        setState(() {
          _userIdLoaded = true;
        });
      }
    }
  }

  Future<void> _initializeWebSocket() async {
    try {
      print('🔧 Initializing WebSocket');
      
      _webSocketService = WebSocketService.instance;
      
      if (!_webSocketService.isConnected) {
        print('📡 Connecting...');
        await _webSocketService.connect();
      } else {
        print('✅ Already connected');
      }

      if (mounted) {
        setState(() {
          isConnected = _webSocketService.isConnected;
          isLoading = false;
        });
      }

      // Register chat message handler
      _webSocketService.onChatMessage = _handleIncomingMessage;
      print('✅ Chat handler registered');

    } catch (e) {
      print('❌ WebSocket initialization error: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          isConnected = false;
        });
      }
    }
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    try {
      print('📨 Chat message handler called');
      print('   Data: $data');

      final messageData = data['data'] as Map<String, dynamic>?;
      if (messageData == null) {
        print('⚠️ No data field');
        return;
      }

      final messageRideId = messageData['ride_id'] ?? data['ride_id'];
      print('   Message ride: $messageRideId, Current ride: ${widget.rideId}');

      if (messageRideId != widget.rideId) {
        print('⚠️ Different ride, ignoring');
        return;
      }

      final messageText = messageData['message'] ?? '';
      final senderId = messageData['sender_id']?.toString() ?? 
                       data['user_id']?.toString() ?? '';
      final timestamp = data['timestamp'] ?? DateTime.now().toIso8601String();

      print('✅ Adding message: "$messageText"');
      print('   From: $senderId (Current user: $currentUserId)');

      if (mounted) {
        final message = ChatMessageModel(
          message: messageText,
          timestamp: timestamp,
          rideId: widget.rideId,
          userId: senderId,
        );

        context.read<ChatProvider>().addMessage(widget.rideId, message);
        
        // Auto-scroll
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      print('❌ Error handling message: $e');
    }
  }

  // void _sendMessage() {
  //   print('');
  //   print('🚀 SEND MESSAGE');

  //   if (!_userIdLoaded) {
  //     print('❌ User ID not loaded');
  //     return;
  //   }

  //   if (!isConnected) {
  //     print('❌ Not connected');
  //     CustomFlushbar.showError(
  //       context: context,
  //       message: 'Not connected to chat',
  //     );
  //     return;
  //   }

  //   final text = _messageController.text.trim();
  //   if (text.isEmpty) {
  //     print('❌ Empty message');
  //     return;
  //   }

  //   try {
  //     print('📤 Sending: "$text" for ride ${widget.rideId}');
      
  //     // Send using the exact format from Postman
  //     _webSocketService.sendMessage({
  //       'type': 'chat',
  //       'data': {
  //         'ride_id': widget.rideId,
  //         'message': text,
  //       },
  //       'timestamp': DateTime.now().toIso8601String(),
  //     });

  //     print('✅ Sent to WebSocket');

  //     // Add to local UI
  //     final localMessage = ChatMessageModel(
  //       message: text,
  //       timestamp: DateTime.now().toIso8601String(),
  //       rideId: widget.rideId,
  //       userId: currentUserId,
  //     );

  //     context.read<ChatProvider>().addMessage(widget.rideId, localMessage);
  //     _messageController.clear();
      
  //     print('✅ Added to UI');
  //     print('');
      
  //   } catch (e) {
  //     print('❌ Send error: $e');
  //     CustomFlushbar.showError(
  //       context: context,
  //       message: 'Failed to send message',
  //     );
  //   }
  // }


// void _sendMessage() {
//   print('');
//   print('🚀 ═══════════════════════════════════════');
//   print('   SEND MESSAGE INITIATED');
//   print('   ═══════════════════════════════════════');

//   if (!_userIdLoaded) {
//     print('   ❌ User ID not loaded');
//     print('');
//     return;
//   }

//   if (!isConnected) {
//     print('   ❌ Not connected');
//     print('');
//     CustomFlushbar.showError(
//       context: context,
//       message: 'Not connected to chat',
//     );
//     return;
//   }

//   final text = _messageController.text.trim();
//   if (text.isEmpty) {
//     print('   ❌ Empty message');
//     print('');
//     return;
//   }

//   try {
//     print('   📝 Message: "$text"');
//     print('   🎯 Ride ID: ${widget.rideId}');
//     print('   👤 User ID: $currentUserId');
//     print('   ⏰ Time: ${DateTime.now().toIso8601String()}');
    
//     // Send using the exact format - let WebSocketService add timestamp
//     _webSocketService.sendMessage({
//       'type': 'chat',
//       'data': {
//         'ride_id': widget.rideId,
//         'message': text,
//       },

//     });

//     print('   ✅ Passed to WebSocket service');
//     print('   🔄 Clearing input field');

//     _messageController.clear();
    
//     // DON'T add to local UI - wait for server echo
//     print('   ⏳ Waiting for server response...');
//     print('   ═══════════════════════════════════════');
//     print('');
    
//   } catch (e, stack) {
//     print('   ❌ Exception: $e');
//     print('   Stack: $stack');
//     print('   ═══════════════════════════════════════');
//     print('');
//     CustomFlushbar.showError(
//       context: context,
//       message: 'Failed to send message',
//     );
//   }
// }







void _sendMessage() async {
  print('');
  print('🚀 ═══════════════════════════════════════');
  print('   SEND MESSAGE INITIATED');
  print('   ═══════════════════════════════════════');

  if (!_userIdLoaded) {
    print('   ❌ User ID not loaded');
    print('');
    return;
  }

  if (!isConnected) {
    print('   ❌ Not connected');
    print('');
    CustomFlushbar.showError(
      context: context,
      message: 'Not connected to chat',
    );
    return;
  }

  final text = _messageController.text.trim();
  if (text.isEmpty) {
    print('   ❌ Empty message');
    print('');
    return;
  }

  try {
    print('   📝 Message: "$text"');
    print('   🎯 Ride ID: ${widget.rideId}');
    print('   👤 User ID: $currentUserId');
    print('   ⏰ Time: ${DateTime.now().toIso8601String()}');
    
    // Get user name from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('user_name') ?? 
                     prefs.getString('name') ?? 
                     'Unknown User';
    
    print('   👤 User Name: $userName');
    
    // Send with sender_id and sender_name in data object
    _webSocketService.sendMessage({
      "type": 'chat',
      'data': {
        'ride_id': widget.rideId,
        'message': text,
      },
      
    });

    print('   ✅ Passed to WebSocket service');
    print('   🔄 Clearing input field');

    _messageController.clear();
    
    print('   ⏳ Waiting for server response...');
    print('   ═══════════════════════════════════════');
    print('');
    
  } catch (e, stack) {
    print('   ❌ Exception: $e');
    print('   Stack: $stack');
    print('   ═══════════════════════════════════════');
    print('');
    CustomFlushbar.showError(
      context: context,
      message: 'Failed to send message',
    );
  }
}




  String _extractTime(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      return DateFormat('hh:mm a').format(dt);
    } catch (e) {
      return '';
    }
  }

  void _showCallDialog() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 69.w,
              height: 5.h,
              margin: EdgeInsets.only(bottom: 20.h),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.5.r),
              ),
            ),
            Text(
              'Call ${widget.driverName}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 30.h),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CallScreen(
                      driverName: widget.driverName,
                      rideId: widget.rideId,
                    ),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 15.h),
                child: Row(
                  children: [
                    Icon(Icons.phone_android, size: 24.sp),
                    SizedBox(width: 15.w),
                    Text(
                      'Call via app',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10.h),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _makeCall();
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 15.h),
                child: Row(
                  children: [
                    Icon(Icons.phone, size: 24.sp),
                    SizedBox(width: 15.w),
                    Text(
                      'Call via phone',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  void _makeCall() async {
    const phoneNumber = '+1234567890';
    final uri = Uri.parse('tel:$phoneNumber');
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        CustomFlushbar.showError(
          context: context,
          message: 'Cannot make phone calls on this device',
        );
      }
    } catch (e) {
      print('❌ Call error: $e');
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
                    child: Icon(Icons.arrow_back, size: 24.sp, color: Colors.black),
                  ),
                  SizedBox(width: 15.w),
                  CircleAvatar(
                    radius: 15.r,
                    backgroundImage: widget.driverImage != null && widget.driverImage!.isNotEmpty
                        ? NetworkImage(widget.driverImage!)
                        : AssetImage(ConstImages.avatar) as ImageProvider,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      widget.driverName,
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
                    onTap: _showCallDialog,
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      child: Icon(Icons.phone, size: 24.sp, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
            Divider(thickness: 1, color: Colors.grey.shade300),
            
            if (!isConnected && !isLoading)
              Container(
                color: Colors.orange.shade100,
                padding: EdgeInsets.all(8.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sync_problem, color: Colors.orange, size: 16.sp),
                    SizedBox(width: 8.w),
                    Text(
                      'Reconnecting...',
                      style: TextStyle(color: Colors.orange.shade900, fontSize: 12.sp),
                    ),
                  ],
                ),
              ),
            
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator(color: Color(ConstColors.mainColor)))
                  : Consumer<ChatProvider>(
                      builder: (context, provider, child) {
                        final messages = provider.getMessagesForRide(widget.rideId);

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
                            final isMe = message.userId == currentUserId || message.userId == null;
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
                        color: Color(0xFFB1B1B1).withOpacity(0.2),
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
                            color: Color(0xFFB1B1B1),
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
                    onTap: isConnected && _userIdLoaded ? _sendMessage : null,
                    child: Opacity(
                      opacity: isConnected && _userIdLoaded ? 1.0 : 0.4,
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