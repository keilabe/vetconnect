import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationsWidget extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('notifications')
          .where('userId', isEqualTo: _auth.currentUser?.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final notifications = snapshot.data?.docs ?? [];

        if (notifications.isEmpty) {
          return Center(
            child: Text(
              'No notifications',
              style: TextStyle(fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index].data() as Map<String, dynamic>;
            final notificationId = notifications[index].id;

            // Mark notification as read when viewed
            if (!notification['read']) {
              _markAsRead(notificationId);
            }

            return Card(
              margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: Icon(
                  _getNotificationIcon(notification['type']),
                  color: _getNotificationColor(notification['type']),
                ),
                title: Text(notification['message']),
                subtitle: Text(
                  DateFormat('MMM d, y HH:mm').format(
                    (notification['createdAt'] as Timestamp).toDate(),
                  ),
                ),
                onTap: () => _handleNotificationTap(context, notification),
              ),
            );
          },
        );
      },
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'appointment_request':
        return Icons.calendar_today;
      case 'appointment_request_sent':
        return Icons.send;
      case 'appointment_accepted':
        return Icons.check_circle;
      case 'appointment_declined':
        return Icons.cancel;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'appointment_request':
        return Colors.orange;
      case 'appointment_request_sent':
        return Colors.blue;
      case 'appointment_accepted':
        return Colors.green;
      case 'appointment_declined':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'read': true,
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  void _handleNotificationTap(BuildContext context, Map<String, dynamic> notification) {
    // Handle different notification types
    switch (notification['type']) {
      case 'appointment_request':
        // Navigate to appointment requests page for vets
        Navigator.pushNamed(context, '/vet-appointment-requests');
        break;
      case 'appointment_request_sent':
        // Show the sent message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(notification['message'])),
        );
        break;
      case 'appointment_accepted':
        // Navigate to payment page for farmers
        Navigator.pushNamed(context, '/confirm&pay');
        break;
      case 'appointment_declined':
        // Show declined message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Appointment request was declined')),
        );
        break;
    }
  }
} 