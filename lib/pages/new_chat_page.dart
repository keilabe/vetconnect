import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_page.dart';
import '../services/chat_service.dart';

class NewChatPage extends StatefulWidget {
  const NewChatPage({super.key});

  @override
  State<NewChatPage> createState() => _NewChatPageState();
}

class _NewChatPageState extends State<NewChatPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ChatService _chatService = ChatService();
  String? _searchQuery;
  String? _userType;

  @override
  void initState() {
    super.initState();
    _loadUserType();
  }

  Future<void> _loadUserType() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      final userData = userDoc.data() as Map<String, dynamic>;
      setState(() {
        _userType = userData['userType'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: UserSearchDelegate(
                  userType: _userType,
                  onUserSelected: _startChat,
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getUsersStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data?.docs ?? [];

          if (users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No users found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userData = users[index].data() as Map<String, dynamic>;
              final userId = users[index].id;

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(
                    userData['profileImage'] ?? 
                    'https://ui-avatars.com/api/?name=${Uri.encodeComponent(userData['fullName'] ?? 'User')}&background=random',
                  ),
                ),
                title: Text(userData['fullName'] ?? 'Unknown User'),
                subtitle: Text(userData['userType'] ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: () => _startChat(userId, userData['fullName'] ?? 'Unknown User'),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Stream<QuerySnapshot> _getUsersStream() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return Stream.empty();

    Query query = _firestore.collection('users');

    // Filter based on user type
    if (_userType == 'Farmer') {
      query = query.where('userType', isEqualTo: 'Veterinarian');
    } else if (_userType == 'Veterinarian') {
      query = query.where('userType', isEqualTo: 'Farmer');
    }

    // Exclude current user
    query = query.where(FieldPath.documentId, isNotEqualTo: currentUserId);

    // Apply search if query exists
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      query = query.where('fullName', isGreaterThanOrEqualTo: _searchQuery)
                   .where('fullName', isLessThanOrEqualTo: '${_searchQuery}z');
    }

    return query.snapshots();
  }

  Future<void> _startChat(String userId, String userName) async {
    try {
      final chatId = await _chatService.createChat(userId);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              chatId: chatId,
              otherUserId: userId,
              otherUserName: userName,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting chat: $e')),
        );
      }
    }
  }
}

class UserSearchDelegate extends SearchDelegate<String> {
  final String? userType;
  final Function(String, String) onUserSelected;

  UserSearchDelegate({
    required this.userType,
    required this.onUserSelected,
  });

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('userType', isEqualTo: userType == 'Farmer' ? 'Veterinarian' : 'Farmer')
          .where('fullName', isGreaterThanOrEqualTo: query)
          .where('fullName', isLessThanOrEqualTo: '${query}z')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data?.docs ?? [];

        if (users.isEmpty) {
          return Center(
            child: Text(
              'No users found',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userData = users[index].data() as Map<String, dynamic>;
            final userId = users[index].id;

            return ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(
                  userData['profileImage'] ?? 
                  'https://ui-avatars.com/api/?name=${Uri.encodeComponent(userData['fullName'] ?? 'User')}&background=random',
                ),
              ),
              title: Text(userData['fullName'] ?? 'Unknown User'),
              subtitle: Text(userData['userType'] ?? ''),
              onTap: () {
                onUserSelected(userId, userData['fullName'] ?? 'Unknown User');
                close(context, '');
              },
            );
          },
        );
      },
    );
  }
} 