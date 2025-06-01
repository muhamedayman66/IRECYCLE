import 'package:flutter/material.dart';
import 'package:graduation_project11/core/api/api_constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:graduation_project11/core/utils/shared_keys.dart';

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
    _markChatAsRead(); // Mark as read when chat is opened
    _loadMessages(); // Initial load
    _refreshTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (mounted) {
        _loadMessages(
          isPeriodicRefresh: true,
        ); // Pass a flag for periodic refreshes
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

  Future<void> _markChatAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> unreadAssignments =
        prefs.getStringList(SharedKeys.unreadChatAssignments) ?? [];
    if (unreadAssignments.contains(widget.assignmentId.toString())) {
      unreadAssignments.remove(widget.assignmentId.toString());
      await prefs.setStringList(
        SharedKeys.unreadChatAssignments,
        unreadAssignments,
      );
      print('Chat for assignment ${widget.assignmentId} marked as read.');
    }
  }

  Future<void> _markChatAsUnread() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> unreadAssignments =
        prefs.getStringList(SharedKeys.unreadChatAssignments) ?? [];
    if (!unreadAssignments.contains(widget.assignmentId.toString())) {
      unreadAssignments.add(widget.assignmentId.toString());
      await prefs.setStringList(
        SharedKeys.unreadChatAssignments,
        unreadAssignments,
      );
      print('Chat for assignment ${widget.assignmentId} marked as UNREAD.');
    }
  }

  Future<void> _loadMessages({bool isPeriodicRefresh = false}) async {
    if (_isFetchingMessages && !isPeriodicRefresh) return;

    if (!isPeriodicRefresh) {
      // Only show full loading state for manual/initial loads
      setState(() {
        _isFetchingMessages = true;
      });
    }

    bool currentLoadAttemptIsInitial = _isInitialLoad;

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

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        final newMessages = List<Map<String, dynamic>>.from(data);
        bool hasNewMessagesFromOther = false;

        if (json.encode(_messages) != json.encode(newMessages)) {
          // Check if there are new messages from the other party
          if (newMessages.length > _messages.length) {
            for (int i = _messages.length; i < newMessages.length; i++) {
              if (newMessages[i]['sender_id'] != widget.currentSenderEmail) {
                hasNewMessagesFromOther = true;
                break;
              }
            }
          } else {
            // Also check if existing messages changed sender (less likely but good to cover)
            for (var msg in newMessages) {
              if (msg['sender_id'] != widget.currentSenderEmail &&
                  !_messages.any(
                    (oldMsg) =>
                        oldMsg['id'] == msg['id'] &&
                        oldMsg['sender_id'] == msg['sender_id'],
                  )) {
                // This logic might be complex if IDs are not stable or present.
                // A simpler check: if any message in newMessages is not from currentSenderEmail
                // and wasn't in the old _messages list (or its content changed).
                // For now, focusing on new incoming messages.
              }
            }
            // A simpler heuristic for periodic refresh: if the latest message is new and not from me.
            if (isPeriodicRefresh &&
                newMessages.isNotEmpty &&
                _messages.isNotEmpty &&
                newMessages.last['id'] != _messages.last['id']) {
              if (newMessages.last['sender_id'] != widget.currentSenderEmail) {
                hasNewMessagesFromOther = true;
              }
            } else if (isPeriodicRefresh &&
                newMessages.length > _messages.length &&
                newMessages.last['sender_id'] != widget.currentSenderEmail) {
              hasNewMessagesFromOther = true;
            }
          }

          setState(() {
            _messages = newMessages;
          });

          if (hasNewMessagesFromOther && isPeriodicRefresh) {
            // Only mark unread on periodic refresh if new message from other
            _markChatAsUnread();
          }
        }

        if (_messages.isNotEmpty && !isPeriodicRefresh) {
          // Scroll only on manual/initial load with messages
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
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        final serverErrorMessage =
            errorBody['error'] ?? 'Failed to load messages.';
        final displayErrorMessage =
            (serverErrorMessage == 'فشل في تحميل الرسائل')
                ? 'Failed to load messages.'
                : serverErrorMessage;
        print('Error loading messages: $displayErrorMessage');
      }
    } catch (e) {
      if (!mounted) return;
      print('Error loading messages: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingMessages = false;
          if (currentLoadAttemptIsInitial) {
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
        body: utf8.encode(
          json.encode({
            // Ensure body is UTF-8 encoded
            'sender_type': widget.currentSenderType,
            'sender_id': widget.currentSenderEmail,
            'message': message,
          }),
        ),
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
          final errorBody = json.decode(utf8.decode(response.bodyBytes));
          final serverErrorMessage =
              errorBody['error'] ??
              'Failed to send message. Try again.'; // Translated
          final displayErrorMessage =
              (serverErrorMessage == 'فشل في إرسال الرسالة. حاول مرة أخرى.')
                  ? 'Failed to send message. Try again.'
                  : serverErrorMessage;
          print('Error sending message: $displayErrorMessage');
          // SnackBar removed
        }
      }
    } catch (e) {
      print('Error sending message: $e');
      // SnackBar removed
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
            child:
                _isInitialLoad &&
                        _isFetchingMessages // Show loader only on the very first fetch attempt
                    ? Center(child: CircularProgressIndicator())
                    : _messages.isEmpty
                    ? Center(
                      child: Text(
                        'Start a new conversation', // Translated
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
                            alignment:
                                isMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isMe
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
                      hintText: 'Type a message...', // Translated
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
                  icon:
                      _isSending
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
