import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isInitialized = false;

  Future<void> initialize() async {
    print('🔧 PaymentService: Initializing payment service');
    // Initialize Mpesa service here
    // This would typically involve setting up API keys, endpoints, etc.
    _isInitialized = true;
    print('✅ PaymentService: Payment service initialized successfully');
  }

  Future<bool> processPayment({
    required String appointmentId,
    required double amount,
    required String paymentMethod,
  }) async {
    print('🔄 PaymentService: Starting payment process');
    print('📋 PaymentService: Payment details - AppointmentID: $appointmentId, Amount: $amount, Method: $paymentMethod');
    
    try {
      if (!_isInitialized) {
        print('⚠️ PaymentService: Service not initialized, initializing now');
        await initialize();
      }

      // Get the current user
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ PaymentService: User not logged in');
        throw Exception('User not logged in');
      }
      print('👤 PaymentService: User authenticated - UserID: ${user.uid}');

      // Create payment record
      print('📝 PaymentService: Creating payment record in Firestore');
      final paymentRef = await _firestore.collection('payments').add({
        'appointmentId': appointmentId,
        'userId': user.uid,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('✅ PaymentService: Payment record created - PaymentID: ${paymentRef.id}');

      // Update appointment with payment reference
      print('📝 PaymentService: Updating appointment with payment reference');
      await _firestore.collection('appointments').doc(appointmentId).update({
        'paymentId': paymentRef.id,
        'paymentStatus': 'pending',
      });
      print('✅ PaymentService: Appointment updated with payment reference');

      // Here you would integrate with actual Mpesa API
      // For now, we'll simulate a successful payment
      print('🔄 PaymentService: Processing payment with Mpesa (simulated)');
      final startTime = DateTime.now();
      await Future.delayed(Duration(seconds: 2));
      final endTime = DateTime.now();
      print('⏱️ PaymentService: Payment processing took ${endTime.difference(startTime).inMilliseconds}ms');

      // Update payment status
      print('📝 PaymentService: Updating payment status to completed');
      await paymentRef.update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });
      print('✅ PaymentService: Payment status updated to completed');

      // Update appointment status
      print('📝 PaymentService: Updating appointment payment status to completed');
      await _firestore.collection('appointments').doc(appointmentId).update({
        'paymentStatus': 'completed',
      });
      print('✅ PaymentService: Appointment payment status updated to completed');

      print('🎉 PaymentService: Payment process completed successfully');
      return true;
    } catch (e) {
      print('❌ PaymentService: Error processing payment: $e');
      print('📋 PaymentService: Error details - ${e.toString()}');
      print('🔍 PaymentService: Error occurred during payment processing for appointment: $appointmentId');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPaymentDetails(String appointmentId) async {
    print('🔍 PaymentService: Getting payment details for appointment: $appointmentId');
    try {
      print('📝 PaymentService: Fetching appointment document');
      final appointmentDoc = await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .get();

      if (!appointmentDoc.exists) {
        print('❌ PaymentService: Appointment not found: $appointmentId');
        throw Exception('Appointment not found');
      }
      print('✅ PaymentService: Appointment document retrieved');

      final appointmentData = appointmentDoc.data() as Map<String, dynamic>;
      final paymentId = appointmentData['paymentId'];
      print('📋 PaymentService: Appointment data - PaymentID: $paymentId, Status: ${appointmentData['status']}');

      if (paymentId == null) {
        print('ℹ️ PaymentService: No payment record found for this appointment');
        return {
          'status': 'not_initiated',
          'amount': appointmentData['consultationFee'] ?? 0,
          'paymentMethod': appointmentData['paymentMethod'] ?? 'Mpesa',
        };
      }

      print('📝 PaymentService: Fetching payment document');
      final paymentDoc = await _firestore
          .collection('payments')
          .doc(paymentId)
          .get();

      if (!paymentDoc.exists) {
        print('❌ PaymentService: Payment record not found: $paymentId');
        throw Exception('Payment record not found');
      }
      print('✅ PaymentService: Payment document retrieved');

      final paymentData = paymentDoc.data() as Map<String, dynamic>;
      print('📋 PaymentService: Payment data - Status: ${paymentData['status']}, Amount: ${paymentData['amount']}');
      
      return paymentData;
    } catch (e) {
      print('❌ PaymentService: Error getting payment details: $e');
      print('📋 PaymentService: Error details - ${e.toString()}');
      rethrow;
    }
  }
} 