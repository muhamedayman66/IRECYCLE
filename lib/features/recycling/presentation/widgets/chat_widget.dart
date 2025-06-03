import 'package:flutter/material.dart';
import 'package:graduation_project11/core/api/api_constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class ChatWidget extends StatefulWidget {
  final int assignmentId;
  final String userEmail; // Represents the customer's email
  final String deliveryBoyEmail; // Represents the delivery boy's email
  final String
      currentSenderEmail; // Email of the person currently using the chat
  final String
      currentSenderType; // Type of the current sender ('user' or 'delivery_boy')

  const ChatWidget({
    Key? key,
    required this.assignmentId,
    required this.userEmail,
    required this.deliveryBoyEmail,
    required this.currentSenderEmail,
    required this.currentSenderType,
  }) : super(key: key);

  @override
  _ChatWidgetState createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isFetchingMessages = false; // Renamed from _isLoading
  bool _isInitialLoad = true; // New flag for initial load UI
  bool _isSending = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages(); // Initial load
    _refreshTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (mounted) {
        _loadMessages(); // Subsequent loads (refreshes)
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    if (_isFetchingMessages) return; // Prevent concurrent fetches

    setState(() {
      _isFetchingMessages = true;
      // Do not reset _messages here to avoid flicker during refresh
    });

    bool currentLoadAttemptIsInitial =
        _isInitialLoad; // Capture state for this attempt

    try {
      final response = await http.get(
        Uri.parse(
          ApiConstants.getChatMessages(
            widget.assignmentId,
            widget.currentSenderEmail,
          ),
        ),
      );

      if (!mounted) return;

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final newMessages = List<Map<String, dynamic>>.from(data);

        // Only update state if messages have actually changed
        // This prevents unnecessary rebuilds and flicker if the data is the same
        if (json.encode(_messages) != json.encode(newMessages)) {
          setState(() {
            _messages = newMessages;
          });
        }

        if (_messages.isNotEmpty) {
          // Scroll to bottom only if new messages were actually added or on initial load
          Future.delayed(Duration(milliseconds: 100), () {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      } else {
        final errorBody = json.decode(response.body);
        final errorMessage = errorBody['error'] ?? 'فشل في تحميل الرسائل';
        print('Error loading messages: $errorMessage');
        // Show SnackBar on error only if it's an initial load or no messages are currently displayed
        if (currentLoadAttemptIsInitial || _messages.isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMessage)));
        }
      }
    } catch (e) {
      if (!mounted) return;
      print('Error loading messages: $e');
      // Show SnackBar on error only if it's an initial load or no messages are currently displayed
      if (currentLoadAttemptIsInitial || _messages.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء تحميل الرسائل')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingMessages = false;
          if (currentLoadAttemptIsInitial) {
            // Only set _isInitialLoad to false after the first attempt
            _isInitialLoad = false;
          }
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      // إضافة الرسالة مؤقتًا للعرض الفوري
      final tempMessage = {
        'sender_type': widget.currentSenderType,
        'sender_id': widget.currentSenderEmail,
        'message': message,
        'created_at': DateTime.now().toIso8601String(),
      };

      setState(() {
        _messages.add(tempMessage);
      });

      // تمرير إلى آخر رسالة
      Future.delayed(Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

      // مسح حقل النص على الفور
      _messageController.clear();

      final response = await http.post(
        Uri.parse(ApiConstants.sendChatMessage(widget.assignmentId)),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
        },
        body: json.encode({
          'sender_type': widget.currentSenderType,
          'sender_id': widget.currentSenderEmail,
          'message': message,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        // Changed from 200 to 201
        // تحميل الرسائل من السيرفر لتحديثها
        await _loadMessages(); // Refresh messages from server
      } else {
        // On failure, DO NOT remove the optimistic message immediately.
        // It will remain visible until the next _loadMessages reconciles.
        // This addresses the user's concern about messages disappearing.
        if (mounted) {
          final errorBody = json.decode(response.body);
          final errorMessage =
              errorBody['error'] ?? 'فشل في إرسال الرسالة. حاول مرة أخرى.';
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMessage)));
        }
      }
    } catch (e) {
      print('Error sending message: $e');
      // On exception, also DO NOT remove the optimistic message immediately.
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء إرسال الرسالة')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Expanded(
            child: _isInitialLoad &&
                    _isFetchingMessages // Show loader only on the very first fetch attempt
                ? Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'ابدأ محادثة جديدة',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.all(8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          // A message is "mine" if the sender_id matches the currentSenderEmail
                          final isMe =
                              message['sender_id'] == widget.currentSenderEmail;

                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: 8,
                              left: isMe ? 40 : 8,
                              right: isMe ? 8 : 40,
                            ),
                            child: Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  message['message'] ?? '',
                                  style: TextStyle(
                                    color: isMe ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Divider(height: 1),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'اكتب رسالة...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: _isSending
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.send),
                  onPressed: _isSending ? null : _sendMessage,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
