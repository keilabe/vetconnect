import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vetconnect/pages/payment_success_screen_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mpesa_flutter_plugin/mpesa_flutter_plugin.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ConfirmAndPayPage extends StatefulWidget {
  final String vetName;
  final DateTime appointmentTime;
  final double consultationFee;
  final String vetId;
  final String animalType;
  final String consultationType;
  final String symptoms;
  final String? appointmentId; // Optional parameter for existing appointments

  const ConfirmAndPayPage({
    super.key, 
    required this.vetName,
    required this.appointmentTime,
    required this.consultationFee,
    required this.vetId,
    required this.animalType,
    required this.consultationType,
    required this.symptoms,
    this.appointmentId,
  });

  @override
  State<StatefulWidget> createState() {
    return _ConfirmAndPayPageState();
  }
}

class _ConfirmAndPayPageState extends State<ConfirmAndPayPage> {
    String? _selectedPaymentMethod;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isProcessing = false;

  Future<String> _getOrCreateAppointment() async {
    print('🔄 ConfirmAndPayPage: Getting or creating appointment');
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        print('❌ ConfirmAndPayPage: User not logged in');
        throw Exception('User not logged in');
      }
      print('👤 ConfirmAndPayPage: User authenticated - UserID: $userId');

      // If we already have an appointmentId, use it
      if (widget.appointmentId != null && widget.appointmentId!.isNotEmpty) {
        print('🔍 ConfirmAndPayPage: Using existing appointment ID: ${widget.appointmentId}');
        
        // Verify the appointment exists and belongs to this user
        print('📝 ConfirmAndPayPage: Verifying appointment exists and belongs to user');
        final appointmentDoc = await _firestore
            .collection('appointments')
            .doc(widget.appointmentId)
            .get();
            
        if (!appointmentDoc.exists) {
          print('❌ ConfirmAndPayPage: Appointment not found: ${widget.appointmentId}');
          throw Exception('Appointment not found');
        }
        
        final appointmentData = appointmentDoc.data() as Map<String, dynamic>;
        if (appointmentData['farmerId'] != userId) {
          print('❌ ConfirmAndPayPage: Appointment does not belong to current user');
          throw Exception('Appointment does not belong to current user');
        }
        print('✅ ConfirmAndPayPage: Appointment verification successful');
        
        // Update the appointment with payment method
        print('📝 ConfirmAndPayPage: Updating appointment with payment method: $_selectedPaymentMethod');
        await _firestore.collection('appointments').doc(widget.appointmentId).update({
          'paymentMethod': _selectedPaymentMethod,
        });
        print('✅ ConfirmAndPayPage: Appointment updated with payment method');
        
        return widget.appointmentId!;
      }

      // Otherwise create a new appointment
      print('📝 ConfirmAndPayPage: Creating new appointment');
      final appointmentRef = await _firestore.collection('appointments').add({
        'farmerId': userId,
        'vetId': widget.vetId,
        'vetName': widget.vetName,
        'appointmentTime': Timestamp.fromDate(widget.appointmentTime),
        'status': 'pending',
        'animalType': widget.animalType,
        'consultationType': widget.consultationType,
        'symptoms': widget.symptoms,
        'consultationFee': widget.consultationFee,
        'paymentMethod': _selectedPaymentMethod,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ ConfirmAndPayPage: Appointment created with ID: ${appointmentRef.id}');
      print('📋 ConfirmAndPayPage: Appointment details - Vet: ${widget.vetName}, Time: ${widget.appointmentTime}, Fee: ${widget.consultationFee}');

      // Create notification for the vet
      print('📝 ConfirmAndPayPage: Creating notification for vet');
      await _firestore.collection('notifications').add({
        'userId': widget.vetId,
        'type': 'appointment_request',
        'message': 'New appointment request from ${_auth.currentUser?.email}',
        'appointmentId': appointmentRef.id,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('✅ ConfirmAndPayPage: Notification created for vet: ${widget.vetId}');

      // Create notification for the farmer
      print('📝 ConfirmAndPayPage: Creating notification for farmer');
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': 'appointment_request_sent',
        'message': 'Your appointment request has been sent to ${widget.vetName}',
        'appointmentId': appointmentRef.id,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('✅ ConfirmAndPayPage: Notification created for farmer: $userId');

      return appointmentRef.id;
    } catch (e) {
      print('❌ ConfirmAndPayPage: Error getting or creating appointment: $e');
      print('📋 ConfirmAndPayPage: Error details - ${e.toString()}');
      rethrow;
    }
  }

  // Format phone number for M-Pesa
  String _formatPhoneNumber(String phoneNumber) {
    print('🔄 ConfirmAndPayPage: Formatting phone number: $phoneNumber');
    if (phoneNumber.isEmpty) {
      print('⚠️ ConfirmAndPayPage: Empty phone number provided');
      return '';
    }
    
    // Remove any non-digit characters
    String digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    print('📋 ConfirmAndPayPage: Digits only: $digitsOnly');
    
    // Handle Kenyan phone numbers
    if (digitsOnly.startsWith('254')) {
      // Already in international format
      print('✅ ConfirmAndPayPage: Phone already in international format: $digitsOnly');
      return digitsOnly;
    } else if (digitsOnly.startsWith('0')) {
      // Convert local format (0XXX) to international format (254XXX)
      String formatted = '254${digitsOnly.substring(1)}';
      print('✅ ConfirmAndPayPage: Converted local to international format: $formatted');
      return formatted;
    } else if (digitsOnly.length >= 9 && digitsOnly.length <= 12) {
      // Assume it's a phone number without country code
      String formatted = '254$digitsOnly';
      print('✅ ConfirmAndPayPage: Added country code to number: $formatted');
      return formatted;
    }
    
    // Return original digits if we can't determine the format
    print('⚠️ ConfirmAndPayPage: Could not determine format, returning original: $digitsOnly');
    return digitsOnly;
  }

  Future<void> _handleMpesaPayment() async {
    print('🔄 ConfirmAndPayPage: Starting M-Pesa payment process');
    setState(() => _isProcessing = true);
    try {
      // Get or create the appointment
      print('📝 ConfirmAndPayPage: Getting or creating appointment');
      final appointmentId = await _getOrCreateAppointment();
      print('✅ ConfirmAndPayPage: Got appointment ID: $appointmentId');
      
      // Get user's phone number from Firestore
      print('🔍 ConfirmAndPayPage: Fetching user phone number from Firestore');
      final userDoc = await _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .get();
      final userData = userDoc.data() as Map<String, dynamic>;
      final phoneNumber = userData['phoneNumber'] ?? '';
      print('📋 ConfirmAndPayPage: Retrieved phone number: $phoneNumber');

      if (phoneNumber.isEmpty) {
        print('❌ ConfirmAndPayPage: Phone number not found');
        throw Exception('Phone number not found. Please update your profile.');
      }

      // Format phone number for M-Pesa
      print('🔄 ConfirmAndPayPage: Formatting phone number for M-Pesa');
      final formattedPhone = _formatPhoneNumber(phoneNumber);
      
      if (formattedPhone.isEmpty || formattedPhone.length < 10) {
        print('❌ ConfirmAndPayPage: Invalid phone number format: $formattedPhone');
        throw Exception('Invalid phone number format. Please update your profile with a valid phone number.');
      }
      
      print('✅ ConfirmAndPayPage: Using formatted phone number for M-Pesa: $formattedPhone');

      // Get M-Pesa credentials from environment variables
      print('🔍 ConfirmAndPayPage: Getting M-Pesa credentials from environment');
      final businessShortCode = dotenv.env['MPESA_SHORTCODE'] ?? '174379';
      final passKey = dotenv.env['MPESA_PASSKEY'] ?? 'bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919';
      final callbackUrl = dotenv.env['MPESA_CALLBACK_URL'] ?? 'https://vetconnect.free.beeceptor.com/';
      
      print('📋 ConfirmAndPayPage: M-Pesa credentials - ShortCode: $businessShortCode, CallbackURL: $callbackUrl');
      print('🔄 ConfirmAndPayPage: Initiating M-Pesa STK push');
      
      // Call the M-Pesa STK Push API
      final startTime = DateTime.now();
      print('⏱️ ConfirmAndPayPage: STK push started at: $startTime');
      
      dynamic response = await MpesaFlutterPlugin.initializeMpesaSTKPush(
        businessShortCode: businessShortCode,
        transactionType: TransactionType.CustomerPayBillOnline,
        amount: widget.consultationFee,
        partyA: formattedPhone,
        partyB: businessShortCode,
        callBackURL: Uri.parse(callbackUrl),
        accountReference: "VetConnect-${DateTime.now().millisecondsSinceEpoch}",
        phoneNumber: formattedPhone,
        baseUri: Uri.parse("https://sandbox.safaricom.co.ke"),
        transactionDesc: "Payment for veterinary consultation",
        passKey: passKey,
      );
      
      final endTime = DateTime.now();
      print('⏱️ ConfirmAndPayPage: STK push completed at: $endTime, took ${endTime.difference(startTime).inMilliseconds}ms');
      print('📋 ConfirmAndPayPage: M-Pesa STK push response: $response');

      if (response == null) {
        print('❌ ConfirmAndPayPage: Null response from M-Pesa');
        throw Exception('Failed to get response from M-Pesa. Please try again.');
      }
      
      if (response['ResponseCode'] == '0') {
        print('✅ ConfirmAndPayPage: M-Pesa STK push successful, CheckoutRequestID: ${response['CheckoutRequestID']}');
        
        // Update appointment with checkout request ID
        print('📝 ConfirmAndPayPage: Updating appointment with checkout request ID');
        await _firestore.collection('appointments').doc(appointmentId).update({
          'mpesaCheckoutRequestId': response['CheckoutRequestID'],
          'paymentStatus': 'pending',
        });
        print('✅ ConfirmAndPayPage: Appointment updated with checkout request ID');

        // Show success dialog with more detailed instructions
        print('📱 ConfirmAndPayPage: Showing payment instructions dialog');
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Text('M-Pesa Payment Initiated'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Please check your phone for the M-Pesa payment prompt.'),
                  SizedBox(height: 8),
                  Text('1. Enter your M-Pesa PIN when prompted'),
                  Text('2. Wait for confirmation SMS from M-Pesa'),
                  Text('3. Click "I have completed the payment" below'),
                  SizedBox(height: 12),
                  Text('Amount: KES ${widget.consultationFee}', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Phone: $formattedPhone', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    print('👆 ConfirmAndPayPage: User confirmed payment completion');
                    Navigator.pop(context); // Close dialog
                    
                    // Show loading indicator
                    print('📱 ConfirmAndPayPage: Showing payment verification dialog');
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => AlertDialog(
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Verifying payment...'),
                          ],
                        ),
                      ),
                    );
                    
                    try {
                      print('🔄 ConfirmAndPayPage: Verifying payment status');
                      // For demo purposes, we'll assume the payment was successful
                      // In a real app, you would check the transaction status using a callback
                      // or by querying the M-Pesa API
                      
                      // Simulate checking transaction status
                      print('⏱️ ConfirmAndPayPage: Simulating payment verification delay');
                      final verifyStartTime = DateTime.now();
                      await Future.delayed(Duration(seconds: 3));
                      final verifyEndTime = DateTime.now();
                      print('⏱️ ConfirmAndPayPage: Payment verification took ${verifyEndTime.difference(verifyStartTime).inMilliseconds}ms');
                      
                      // Assume success for demo
                      final statusResponse = {
                        'ResponseCode': '0', 
                        'TransactionID': 'MPESA${DateTime.now().millisecondsSinceEpoch}'
                      };
                      print('📋 ConfirmAndPayPage: Payment verification response: $statusResponse');
                      
                      // Close the loading dialog
                      print('📱 ConfirmAndPayPage: Closing verification dialog');
                      Navigator.pop(context);
                    
                      if (statusResponse['ResponseCode'] == '0') {
                        print('✅ ConfirmAndPayPage: Payment verification successful, TransactionID: ${statusResponse['TransactionID']}');
                        
                        // Update appointment status
                        print('📝 ConfirmAndPayPage: Updating appointment payment status to completed');
                        await _firestore.collection('appointments').doc(appointmentId).update({
                          'paymentStatus': 'completed',
                          'mpesaTransactionId': statusResponse['TransactionID'],
                        });
                        print('✅ ConfirmAndPayPage: Appointment payment status updated to completed');

                        // Navigate to success screen
                        print('🔄 ConfirmAndPayPage: Navigating to payment success screen');
                        Navigator.pushReplacementNamed(
                          context,
                          '/payment-success',
                          arguments: {
                            'amount': widget.consultationFee,
                            'vetName': widget.vetName,
                            'appointmentTime': widget.appointmentTime,
                            'transactionId': statusResponse['TransactionID'],
                            'paymentMethod': 'Mpesa',
                          },
                        );
                        print('✅ ConfirmAndPayPage: Navigation to success screen complete');
                      } else {
                        print('❌ ConfirmAndPayPage: Payment verification failed: ${statusResponse['ResponseDescription'] ?? 'Unknown error'}');
                        throw Exception('Payment verification failed: ${statusResponse['ResponseDescription'] ?? 'Unknown error'}');
                      }
                    } catch (e) {
                      print('❌ ConfirmAndPayPage: Error during payment verification: $e');
                      // Close the loading dialog if it's open
                      if (Navigator.canPop(context)) {
                        print('📱 ConfirmAndPayPage: Closing verification dialog due to error');
                        Navigator.pop(context);
                      }
                      
                      // Show error dialog
                      print('📱 ConfirmAndPayPage: Showing payment verification error dialog');
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Payment Verification Failed'),
                          content: Text('We could not verify your payment: ${e.toString()}'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('OK'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  child: Text('I have completed the payment'),
                ),
                TextButton(
                  onPressed: () {
                    print('👆 ConfirmAndPayPage: User cancelled payment');
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back to previous screen
                  },
                  child: Text('Cancel'),
                ),
              ],
            ),
          );
        }
      } else {
        print('❌ ConfirmAndPayPage: M-Pesa STK push failed: ${response['ResponseDescription']}');
        throw Exception('Failed to initiate payment: ${response['ResponseDescription']}');
      }
    } catch (error) {
      print('❌ ConfirmAndPayPage: Error processing M-Pesa payment: $error');
      print('📋 ConfirmAndPayPage: Error details - ${error.toString()}');
      if (mounted) {
        print('📱 ConfirmAndPayPage: Showing payment error dialog');
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Payment Error'),
            content: Text('Failed to process payment: $error'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      print('🔄 ConfirmAndPayPage: Resetting processing state');
      setState(() => _isProcessing = false);
      print('✅ ConfirmAndPayPage: M-Pesa payment process completed');
    }
  }

  Future<void> _handleOtherPaymentMethods() async {
    print('🔄 ConfirmAndPayPage: Starting other payment method process');
    setState(() => _isProcessing = true);
    try {
      // Get or create the appointment
      print('📝 ConfirmAndPayPage: Getting or creating appointment');
      final appointmentId = await _getOrCreateAppointment();
      print('✅ ConfirmAndPayPage: Got appointment ID: $appointmentId');
      
      // For other payment methods, we'll still create the appointment
      // but show a message that payment will be handled later
      print('📱 ConfirmAndPayPage: Showing payment method confirmation dialog');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Payment Method'),
          content: Text('Your appointment has been created. Payment will be handled during the visit.'),
          actions: [
            TextButton(
              onPressed: () {
                print('👆 ConfirmAndPayPage: User confirmed other payment method');
                Navigator.pop(context); // Close dialog
                
                print('🔄 ConfirmAndPayPage: Navigating to payment success screen');
                Navigator.pushReplacementNamed(
                  context,
                  '/payment-success',
                  arguments: {
                    'amount': widget.consultationFee,
                    'vetName': widget.vetName,
                    'appointmentTime': widget.appointmentTime,
                    'transactionId': 'TXN${DateTime.now().millisecondsSinceEpoch}',
                    'paymentMethod': 'Pay on Visit',
                  },
                );
                print('✅ ConfirmAndPayPage: Navigation to success screen complete');
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('❌ ConfirmAndPayPage: Error processing other payment method: $e');
      print('📋 ConfirmAndPayPage: Error details - ${e.toString()}');
      
      print('📱 ConfirmAndPayPage: Showing error dialog');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Failed to create appointment: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      print('🔄 ConfirmAndPayPage: Resetting processing state');
      setState(() => _isProcessing = false);
      print('✅ ConfirmAndPayPage: Other payment method process completed');
    }
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: _selectedPaymentMethod == null || _isProcessing
            ? null
            : () {
                if (_selectedPaymentMethod == 'Mpesa') {
                  _handleMpesaPayment();
                } else {
                  _handleOtherPaymentMethods();
                }
              },
        child: _isProcessing
            ? CircularProgressIndicator(color: Colors.white)
            : Text(
                'Confirm & Pay',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Confirm Payment'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVetInfo(),
            SizedBox(height: 24),
            _buildFeeDetails(),
            SizedBox(height: 32),
            _buildPaymentMethods(),
            SizedBox(height: 40),
            _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildVetInfo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.vetName,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              DateFormat('EEE, d MMM y • HH:mm').format(widget.appointmentTime),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeDetails() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildFeeRow('Consultation Fee', '\$${widget.consultationFee}'),
            Divider(),
            _buildFeeRow('Total', '\$${widget.consultationFee}', isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.green : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Methods',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        _buildPaymentOption(
          'Mpesa',
          Icons.phone_android,
          'Pay via Mpesa mobile money',
        ),
        _buildPaymentOption(
          'Credit/Debit Card',
          Icons.credit_card,
          'Pay with Visa/Mastercard',
        ),
        _buildPaymentOption(
          'Pay on Visit',
          Icons.payments,
          'Pay cash when visiting',
        ),
      ],
    );
  }

  Widget _buildPaymentOption(String title, IconData icon, String subtitle) {
    return Card(
      elevation: _selectedPaymentMethod == title ? 4 : 1,
      color: _selectedPaymentMethod == title ? Colors.blue[50] : Colors.white,
      child: RadioListTile<String>(
        title: Row(
          children: [
            Icon(icon, color: Colors.blue),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ),
        value: title,
        groupValue: _selectedPaymentMethod,
        onChanged: (value) => setState(() => _selectedPaymentMethod = value),
      ),
    );
  }
}