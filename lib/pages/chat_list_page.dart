import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';
import 'chat_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({Key? key}) : super(key: key);

  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    _chatService.updateOnlineStatus(true);
  }

  @override
  void dispose() {
    _chatService.updateOnlineStatus(false);
    super.dispose();
  }

  String _getOtherUserId(List<String> participants) {
    return participants.firstWhere(
      (id) => id != _chatService.currentUserId,
      orElse: () => '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: _chatService.currentUserId)
            .orderBy('lastMessageTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data!.docs
              .map((doc) => ChatModel.fromFirestore(doc))
              .toList();

          if (chats.isEmpty) {
            return const Center(
              child: Text('No chats yet. Start a conversation!'),
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final otherUserId = _getOtherUserId(chat.participants);

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUserId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(
                      title: Text('Loading...'),
                    );
                  }

                  final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  final otherUserName = userData['name'] ?? 'Unknown User';

                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(otherUserName[0].toUpperCase()),
                    ),
                    title: Row(
                      children: [
                        Text(otherUserName),
                        const SizedBox(width: 8),
                        StreamBuilder<bool>(
                          stream: _chatService.getUserStatus(otherUserId),
                          builder: (context, statusSnapshot) {
                            final isOnline = statusSnapshot.data ?? false;
                            return Icon(
                              isOnline ? Icons.circle : Icons.circle_outlined,
                              size: 12,
                              color: isOnline ? Colors.green : Colors.grey,
                            );
                          },
                        ),
                      ],
                    ),
                    subtitle: Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatTimestamp(chat.lastMessageTime),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            chatId: chat.id,
                            otherUserId: otherUserId,
                            otherUserName: otherUserName,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
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