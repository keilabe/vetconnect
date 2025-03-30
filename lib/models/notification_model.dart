import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String type;
  final String message;
  final bool isRead;
  final Timestamp? createdAt;
  final String? appointmentId;
  final String userId;

  NotificationModel({
    required this.id,
    required this.type,
    required this.message,
    required this.isRead,
    this.createdAt,
    this.appointmentId,
    required this.userId,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      type: map['type'] as String? ?? 'general',
      message: map['message'] as String? ?? 'No message',
      isRead: map['read'] as bool? ?? false,
      createdAt: map['createdAt'] as Timestamp?,
      appointmentId: map['appointmentId'] as String?,
      userId: map['userId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'message': message,
      'read': isRead,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'appointmentId': appointmentId,
      'userId': userId,
    };
  }

  String getTimeText() {
    if (createdAt == null) return 'Just now';
    
    try {
      final now = DateTime.now();
      final notificationTime = createdAt!.toDate();
      final difference = now.difference(notificationTime);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${notificationTime.day}/${notificationTime.month}/${notificationTime.year}';
      }
    } catch (e) {
      print('Error formatting notification time: $e');
      return 'Just now';
    }
  }
} 