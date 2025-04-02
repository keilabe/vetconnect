import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';
import 'dart:async';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _log(String message, [Object? error]) {
    if (error != null) {
      print('❌ ChatService: $message');
      print('📝 Error details: $error');
    } else {
      print('📱 ChatService: $message');
    }
  }

  // Get current user's ID
  String get currentUserId => _auth.currentUser?.uid ?? '';

  // Get user's chats with timeout
  Stream<QuerySnapshot> getUserChats() {
    _log('getUserChats: Fetching chats for user: $currentUserId');
    try {
      return _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .orderBy('lastMessageTime', descending: true)
          .snapshots()
          .timeout(
            Duration(seconds: 10),
            onTimeout: (sink) {
              _log('getUserChats: Query timed out after 10 seconds');
              sink.addError(TimeoutException('Chat query timed out'));
            },
          );
    } catch (e) {
      _log('getUserChats: Error setting up stream', e);
      rethrow;
    }
  }

  // Get messages for a specific chat with timeout
  Stream<List<MessageModel>> getChatMessages(String chatId) {
    _log('getChatMessages: Fetching messages for chat: $chatId');
    try {
      return _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => MessageModel.fromFirestore(doc))
              .toList());
    } catch (e) {
      _log('getChatMessages: Error setting up stream', e);
      rethrow;
    }
  }

  // Create a new chat
  Future<String> createChat(String otherUserId) async {
    _log('createChat: Checking for existing chat with user: $otherUserId');
    try {
      // Check for existing chat
      final existingChats = await _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .get();

      for (var doc in existingChats.docs) {
        final participants = List<String>.from(doc.data()['participants'] ?? []);
        if (participants.contains(otherUserId)) {
          _log('createChat: Found existing chat: ${doc.id}');
          return doc.id;
        }
      }

      // Create new chat
      final chatRef = await _firestore.collection('chats').add({
        'participants': [currentUserId, otherUserId],
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'typingUsers': [],
      });

      _log('createChat: Created new chat: ${chatRef.id}');
      return chatRef.id;
    } catch (e) {
      _log('createChat: Error creating chat', e);
      rethrow;
    }
  }

  // Send a message
  Future<void> sendMessage(String chatId, String text) async {
    _log('sendMessage: Sending message to chat: $chatId');
    try {
      final message = MessageModel(
        id: '',  // Firestore will generate this
        senderId: currentUserId,
        text: text,
        timestamp: Timestamp.now(),
        read: false,
      );

      final batch = _firestore.batch();
      
      // Add message to messages subcollection
      final messageRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc();
      batch.set(messageRef, message.toMap());

      // Update chat document with last message info
      final chatRef = _firestore.collection('chats').doc(chatId);
      batch.update(chatRef, {
        'lastMessage': text,
        'lastMessageTime': message.timestamp,
        'lastMessageSenderId': currentUserId,
      });

      await batch.commit();
      _log('sendMessage: Message sent successfully');
    } catch (e) {
      _log('sendMessage: Error sending message', e);
      rethrow;
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId) async {
    _log('markMessagesAsRead: Marking messages as read in chat: $chatId');
    try {
      final messages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: currentUserId)
          .where('read', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in messages.docs) {
        batch.update(doc.reference, {'read': true});
      }

      await batch.commit();
      _log('markMessagesAsRead: Messages marked as read successfully');
    } catch (e) {
      _log('markMessagesAsRead: Error marking messages as read', e);
      rethrow;
    }
  }

  // Update typing status
  Future<void> updateTypingStatus(String chatId, bool isTyping) async {
    _log('updateTypingStatus: Updating typing status for chat: $chatId');
    try {
      final chatRef = _firestore.collection('chats').doc(chatId);
      
      if (isTyping) {
        await chatRef.update({
          'typingUsers': FieldValue.arrayUnion([currentUserId])
        });
      } else {
        await chatRef.update({
          'typingUsers': FieldValue.arrayRemove([currentUserId])
        });
      }

      _log('updateTypingStatus: Typing status updated successfully');
    } catch (e) {
      _log('updateTypingStatus: Error updating typing status', e);
      rethrow;
    }
  }

  // Get typing users
  Stream<List<String>> getTypingUsers(String chatId) {
    _log('getTypingUsers: Setting up typing users listener for chat: $chatId');
    try {
      return _firestore
          .collection('chats')
          .doc(chatId)
          .snapshots()
          .map((snapshot) {
            final data = snapshot.data();
            if (data == null) return <String>[];
            return List<String>.from(data['typingUsers'] ?? []);
          });
    } catch (e) {
      _log('getTypingUsers: Error setting up stream', e);
      rethrow;
    }
  }

  // Update online status
  Future<void> updateOnlineStatus(bool isOnline) async {
    _log('updateOnlineStatus: Updating online status: $isOnline');
    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'isOnline': isOnline,
        'lastSeen': Timestamp.now(),
      });
      _log('updateOnlineStatus: Online status updated successfully');
    } catch (e) {
      _log('updateOnlineStatus: Error updating online status', e);
      rethrow;
    }
  }

  // Get user status
  Stream<bool> getUserStatus(String userId) {
    _log('getUserStatus: Setting up status listener for user: $userId');
    try {
      return _firestore
          .collection('users')
          .doc(userId)
          .snapshots()
          .map((snapshot) => snapshot.data()?['isOnline'] ?? false);
    } catch (e) {
      _log('getUserStatus: Error setting up stream', e);
      rethrow;
    }
  }

  // Delete a message
  Future<void> deleteMessage(String chatId, String messageId) async {
    _log('deleteMessage: Deleting message: $messageId from chat: $chatId');
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete();
      _log('deleteMessage: Message deleted successfully');
    } catch (e) {
      _log('deleteMessage: Error deleting message', e);
      rethrow;
    }
  }

  // Delete a chat
  Future<void> deleteChat(String chatId) async {
    _log('deleteChat: Deleting chat: $chatId');
    try {
      final messages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      final batch = _firestore.batch();
      for (var doc in messages.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_firestore.collection('chats').doc(chatId));

      await batch.commit();
      _log('deleteChat: Chat deleted successfully');
    } catch (e) {
      _log('deleteChat: Error deleting chat', e);
      rethrow;
    }
  }

  // Get available users to chat with (vets for farmers, farmers for vets)
  Stream<QuerySnapshot> getAvailableUsers() async* {
    if (currentUserId.isEmpty) {
      _log('getAvailableUsers: No user authenticated');
      yield* Stream.empty();
      return;
    }

    try {
      _log('getAvailableUsers: Getting current user type');
      
      // Get current user's type
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (!userDoc.exists) {
        _log('getAvailableUsers: Current user document not found');
        yield* Stream.empty();
        return;
      }

      final userType = userDoc.data()?['userType'] as String?;
      if (userType == null) {
        _log('getAvailableUsers: User type not found in document');
        yield* Stream.empty();
        return;
      }

      _log('getAvailableUsers: Current user type: $userType');
      
      // Filter users based on type
      final targetType = userType.toLowerCase() == 'farmer' ? 'Veterinarian' : 'Farmer';
      _log('getAvailableUsers: Fetching users of type: $targetType');
      
      yield* _firestore
          .collection('users')
          .where('userType', isEqualTo: targetType)
          .orderBy('fullName')
          .snapshots()
          .handleError((error) {
            _log('getAvailableUsers: Error fetching available users', error);
            return Stream.empty();
          });
    } catch (e) {
      _log('getAvailableUsers: Error setting up users stream', e);
      yield* Stream.empty();
    }
  }
} 