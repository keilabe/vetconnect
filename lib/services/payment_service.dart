import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isInitialized = false;
  static final Logger _logger = Logger('PaymentService');


  Future<void> initialize() async {
    print('🔧 PaymentService: Initializing payment service');
    // Initialize Mpesa service here
    // This would typically involve setting up API keys, endpoints, etc.
    _isInitialized = true;
    print('✅ PaymentService: Payment service initialized successfully');
    _logger.info('Payment service initialized successfully');
  }

  Future<bool> processPayment({
    required String appointmentId,
    required double amount,
    required String paymentMethod,
  }) async {
    _logger.fine('Starting payment process for appointment: $appointmentId');

    try {
      if (!_isInitialized) {
        _logger.warning('Payment service not initialized, initializing now');
        await initialize();
      }

      // Get the current user
      final user = _auth.currentUser;
      if (user == null) {
        _logger.severe('User not logged in');
        throw Exception('User not logged in');
      }
      _logger.info('User authenticated - UserID: ${user.uid}');

      // Create payment record
      _logger.fine('Creating payment record in Firestore');
      final paymentRef = await _firestore.collection('payments').add({
        'appointmentId': appointmentId,
        'userId': user.uid,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      _logger.info('Payment record created - PaymentID: ${paymentRef.id}');

      // Update appointment with payment reference
      _logger.fine('Updating appointment with payment reference');
      await _firestore.collection('appointments').doc(appointmentId).update({
        'paymentId': paymentRef.id,
        'paymentStatus': 'pending',
      });
      _logger.info('Appointment updated with payment reference');

      // Simulate Mpesa payment process
      _logger.fine('Simulating Mpesa payment process');
      await Future.delayed(Duration(seconds: 2));
      _logger.info('Mpesa payment simulation completed');

      // Update payment status
      _logger.fine('Updating payment status to completed');
      await paymentRef.update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });
      _logger.info('Payment status updated to completed');

      // Update appointment status
      _logger.fine('Updating appointment payment status to completed');
      await _firestore.collection('appointments').doc(appointmentId).update({
        'paymentStatus': 'completed',
      });
      _logger.info('Appointment payment status updated to completed');

      _logger.info('Payment process completed successfully');
      return true;
    } on Exception catch (e) {
      _logger.severe('Error processing payment: $e', e);
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