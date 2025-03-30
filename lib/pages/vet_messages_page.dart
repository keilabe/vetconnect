import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VetMessagesPage extends StatefulWidget {
  const VetMessagesPage({super.key});

  @override
  State<VetMessagesPage> createState() => _VetMessagesPageState();
}

class _VetMessagesPageState extends State<VetMessagesPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  String? _selectedChatId;
  String? _selectedFarmerName;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _selectedChatId == null) return;

    try {
      final message = {
        'text': _messageController.text.trim(),
        'senderId': _auth.currentUser?.uid,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('chats')
          .doc(_selectedChatId)
          .collection('messages')
          .add(message);

      // Update last message in chat document
      await _firestore.collection('chats').doc(_selectedChatId).update({
        'lastMessage': message['text'],
        'lastMessageTime': message['timestamp'],
      });

      _messageController.clear();
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Chat List
          Container(
            width: 300,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .where('participants', arrayContains: _auth.currentUser?.uid)
                  .orderBy('lastMessageTime', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading chats'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final chats = snapshot.data?.docs ?? [];

                return ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index].data() as Map<String, dynamic>;
                    final participants = chat['participants'] as List<dynamic>;
                    final otherUserId = participants.firstWhere(
                      (id) => id != _auth.currentUser?.uid,
                    );

                    return FutureBuilder<DocumentSnapshot>(
                      future: _firestore
                          .collection('farmers')
                          .doc(otherUserId)
                          .get(),
                      builder: (context, farmerSnapshot) {
                        final farmerData = farmerSnapshot.data?.data()
                            as Map<String, dynamic>?;
                        final farmerName = farmerData?['name'] ?? 'Unknown Farmer';

                        return ListTile(
                          selected: _selectedChatId == chats[index].id,
                          leading: CircleAvatar(
                            child: Text(farmerName[0]),
                          ),
                          title: Text(farmerName),
                          subtitle: Text(
                            chat['lastMessage'] ?? 'No messages yet',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
            setState(() {
                              _selectedChatId = chats[index].id;
                              _selectedFarmerName = farmerName;
            });
          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          // Chat Messages
          Expanded(
            child: _selectedChatId == null
                ? Center(
                    child: Text('Select a chat to start messaging'),
                  )
                : Column(
              children: [
                      // Chat Header
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              child: Text(_selectedFarmerName?[0] ?? 'F'),
                            ),
                            SizedBox(width: 12),
                Text(
                              _selectedFarmerName ?? 'Unknown Farmer',
                  style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
                      ),
                      // Messages List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(_selectedChatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading messages'));
                }

                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data?.docs ?? [];

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                                final message =
                                    messages[index].data() as Map<String, dynamic>;
                                final isMe = message['senderId'] ==
                                    _auth.currentUser?.uid;

                                return Align(
                                  alignment: isMe
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    margin: EdgeInsets.symmetric(
                            horizontal: 16,
                                      vertical: 4,
                          ),
                                    padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                                      color: isMe
                                          ? Colors.teal[100]
                                          : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(message['text'] ?? ''),
                                  ),
                    );
                  },
                );
              },
            ),
          ),
                      // Message Input
          Container(
                        padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                            top: BorderSide(color: Colors.grey[300]!),
                          ),
                    ),
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
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                        IconButton(
                          onPressed: _sendMessage,
                              icon: Icon(Icons.send),
                              color: Colors.teal,
                        ),
                      ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 