import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';
import '../services/payment_service.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PaymentService _paymentService = PaymentService();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (!_isInitialized) {
      await _paymentService.initialize();
      _isInitialized = true;
    }
  }

  Stream<List<NotificationModel>> getNotifications() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not logged in');
    }

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'read': true,
    });
  }

  Future<void> handleAppointmentConfirmation(String appointmentId) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final user = _auth.currentUser;
      if (user == null) return;

      // Get the appointment data
      final appointmentDoc = await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .get();

      if (!appointmentDoc.exists) {
        print('Appointment not found: $appointmentId');
        return;
      }

      final appointmentData = appointmentDoc.data() as Map<String, dynamic>;
      final farmerId = appointmentData['farmerId'] as String;
      final vetId = appointmentData['vetId'] as String;
      final status = appointmentData['status'] as String;

      // Check if notification already exists
      final existingNotification = await _firestore
          .collection('notifications')
          .where('appointmentId', isEqualTo: appointmentId)
          .where('type', isEqualTo: 'appointment_accepted')
          .get();

      if (existingNotification.docs.isNotEmpty) {
        print('Notification already exists for appointment: $appointmentId');
        return;
      }

      // Create notification for farmer
      await _createNotification(
        userId: farmerId,
        title: 'Appointment Confirmed',
        message: 'Your appointment has been confirmed by the veterinarian.',
        type: 'appointment_accepted',
        appointmentId: appointmentId,
      );
    } catch (e) {
      print('Error handling appointment confirmation: $e');
    }
  }

  Future<void> _handlePayment(String appointmentId, Map<String, dynamic> appointmentData) async {
    try {
      final amount = appointmentData['consultationFee'] as double;
      final success = await _paymentService.processPayment(
        appointmentId: appointmentId,
        amount: amount,
        paymentMethod: 'Mpesa',
      );

      if (success) {
        // Update appointment status
        await _firestore.collection('appointments').doc(appointmentId).update({
          'paymentStatus': 'completed',
          'status': 'confirmed',
        });
      }
    } catch (e) {
      print('Error processing payment: $e');
    }
  }

  Future<void> _createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? appointmentId,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
        'appointmentId': appointmentId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  Future<void> handleNewAppointment(String appointmentId) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final user = _auth.currentUser;
      if (user == null) return;

      print('Handling new appointment: $appointmentId');

      // Get the appointment data
      final appointmentDoc = await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .get();

      if (!appointmentDoc.exists) {
        print('Appointment not found: $appointmentId');
        return;
      }

      final appointmentData = appointmentDoc.data() as Map<String, dynamic>;
      final farmerId = appointmentData['farmerId'] as String;
      final vetId = appointmentData['vetId'] as String;
      final status = appointmentData['status'] as String;

      // Check if notifications already exist for this appointment
      final existingVetNotifications = await _firestore
          .collection('notifications')
          .where('appointmentId', isEqualTo: appointmentId)
          .where('userId', isEqualTo: vetId)
          .where('type', isEqualTo: 'appointment_request_sent')
          .get();

      final existingFarmerNotifications = await _firestore
          .collection('notifications')
          .where('appointmentId', isEqualTo: appointmentId)
          .where('userId', isEqualTo: farmerId)
          .where('type', isEqualTo: 'appointment_request_sent')
          .get();

      // Create notification for vet if it doesn't exist
      if (existingVetNotifications.docs.isEmpty) {
        print('Creating notification for vet: $vetId');
        await _createNotification(
          userId: vetId,
          title: 'New Appointment Request',
          message: 'A new appointment request has been received.',
          type: 'appointment_request_sent',
          appointmentId: appointmentId,
        );
      } else {
        print('Notification for vet already exists');
      }

      // Create notification for farmer if it doesn't exist
      if (existingFarmerNotifications.docs.isEmpty) {
        print('Creating notification for farmer: $farmerId');
        await _createNotification(
          userId: farmerId,
          title: 'Appointment Request Sent',
          message: 'Your appointment request has been sent to the veterinarian.',
          type: 'appointment_request_sent',
          appointmentId: appointmentId,
        );
      } else {
        print('Notification for farmer already exists');
      }
    } catch (e) {
      print('Error handling new appointment: $e');
    }
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'Date not available';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return 'Time not available';
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget buildNotificationItem(NotificationModel notification) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getNotificationColor(notification.type),
        child: Icon(_getNotificationIcon(notification.type), color: Colors.white),
      ),
      title: Text(notification.message),
      subtitle: Text(notification.getTimeText()),
      trailing: !notification.isRead
          ? Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            )
          : null,
      onTap: () => _handleNotificationTap(notification),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'appointment_request':
        return Icons.calendar_today;
      case 'appointment_confirmation':
        return Icons.check_circle;
      case 'appointment_rejection':
        return Icons.cancel;
      case 'payment':
        return Icons.payment;
      case 'message':
        return Icons.message;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'appointment_request':
        return Colors.orange;
      case 'appointment_confirmation':
        return Colors.green;
      case 'appointment_rejection':
        return Colors.red;
      case 'payment':
        return Colors.blue;
      case 'message':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Mark as read
    markAsRead(notification.id);

    // Handle different notification types
    switch (notification.type.toLowerCase()) {
      case 'appointment_request':
        if (notification.appointmentId != null) {
          // Handle appointment request
        }
        break;
      case 'appointment_confirmation':
        if (notification.appointmentId != null) {
          // Handle appointment confirmation
        }
        break;
      case 'appointment_rejection':
        // Handle appointment rejection
        break;
      case 'payment':
        // Handle payment notification
        break;
      case 'message':
        // Handle message notification
        break;
      default:
        // Handle unknown notification type
        break;
    }
  }
} 