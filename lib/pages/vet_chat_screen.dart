import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';

class VetChatScreen extends StatefulWidget {
  final String chatId;
  final String farmerId;
  final String farmerName;

  const VetChatScreen({
    Key? key,
    required this.chatId,
    required this.farmerId,
    required this.farmerName,
  }) : super(key: key);

  @override
  _VetChatScreenState createState() => _VetChatScreenState();
}

class _VetChatScreenState extends State<VetChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
    _setupTypingListener();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    _chatService.updateTypingStatus(widget.chatId, false);
    super.dispose();
  }

  void _markMessagesAsRead() {
    _chatService.markMessagesAsRead(widget.chatId);
  }

  void _setupTypingListener() {
    _messageController.addListener(() {
      _updateTypingStatus();
    });
  }

  void _updateTypingStatus() {
    if (_messageController.text.isNotEmpty) {
      _chatService.updateTypingStatus(widget.chatId, true);
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 2), () {
        _chatService.updateTypingStatus(widget.chatId, false);
      });
    } else {
      _chatService.updateTypingStatus(widget.chatId, false);
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      _chatService.sendMessage(widget.chatId, _messageController.text.trim());
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.farmerName),
            const SizedBox(width: 8),
            StreamBuilder<bool>(
              stream: _chatService.getUserStatus(widget.farmerId),
              builder: (context, snapshot) {
                final isOnline = snapshot.data ?? false;
                return Icon(
                  isOnline ? Icons.circle : Icons.circle_outlined,
                  size: 12,
                  color: isOnline ? Colors.green : Colors.grey,
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.getChatMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;
                
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isCurrentUser = message.senderId == _chatService.currentUserId;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisAlignment: isCurrentUser
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.7,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isCurrentUser
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: isCurrentUser
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.text,
                                  style: TextStyle(
                                    color: isCurrentUser ? Colors.white : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formatTimestamp(message.timestamp),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isCurrentUser
                                            ? Colors.white.withOpacity(0.7)
                                            : Colors.black54,
                                      ),
                                    ),
                                    if (isCurrentUser) ...[
                                      const SizedBox(width: 4),
                                      Icon(
                                        message.read
                                            ? Icons.done_all_rounded
                                            : Icons.done_rounded,
                                        size: 16,
                                        color: message.read
                                            ? Colors.blue
                                            : Colors.white.withOpacity(0.7),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          StreamBuilder<List<String>>(
            stream: _chatService.getTypingUsers(widget.chatId),
            builder: (context, snapshot) {
              if (snapshot.hasData &&
                  snapshot.data!.isNotEmpty &&
                  !snapshot.data!.contains(_chatService.currentUserId)) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '${widget.farmerName} is typing...',
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send_rounded),
                  onPressed: _sendMessage,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
} 