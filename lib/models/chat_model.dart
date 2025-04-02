import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final Timestamp lastMessageTime;
  final String lastMessageSenderId;
  final List<String> typingUsers;

  ChatModel({
    required this.id,
    required this.participants,
    this.lastMessage = '',
    required this.lastMessageTime,
    required this.lastMessageSenderId,
    this.typingUsers = const [],
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: data['lastMessageTime'] ?? Timestamp.now(),
      lastMessageSenderId: data['lastMessageSenderId'] ?? '',
      typingUsers: List<String>.from(data['typingUsers'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'lastMessageSenderId': lastMessageSenderId,
      'typingUsers': typingUsers,
    };
  }

  ChatModel copyWith({
    String? id,
    List<String>? participants,
    String? lastMessage,
    Timestamp? lastMessageTime,
    String? lastMessageSenderId,
    List<String>? typingUsers,
  }) {
    return ChatModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      typingUsers: typingUsers ?? this.typingUsers,
    );
  }
} 