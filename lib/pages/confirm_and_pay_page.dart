import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/mpesa_direct_service.dart';
import 'package:logging/logging.dart';

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
  String? _phoneNumber;
  final Logger _logger = Logger('ConfirmAndPayPage');
  final MpesaDirectService _mpesaService = MpesaDirectService();
  final TextEditingController _phoneController = TextEditingController();
  String? _phoneError;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

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
  String _formatPhoneNumber(String phone) {
    _logger.info('Formatting phone number: $phone');
    
    // Remove any non-digit characters
    String digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
    _logger.info('Digits only: $digitsOnly');

    // If the number starts with 0, replace it with 254
    if (digitsOnly.startsWith('0')) {
      digitsOnly = '254${digitsOnly.substring(1)}';
      _logger.info('Converted to international format: $digitsOnly');
    }
    // If the number starts with +, remove it
    else if (digitsOnly.startsWith('+')) {
      digitsOnly = digitsOnly.substring(1);
      _logger.info('Removed + prefix: $digitsOnly');
    }
    // If the number doesn't start with 254, add it
    else if (!digitsOnly.startsWith('254')) {
      digitsOnly = '254$digitsOnly';
      _logger.info('Added country code: $digitsOnly');
    }

    _logger.info('Formatted phone number: $digitsOnly');
    return digitsOnly;
  }

  bool _validatePhoneNumber(String phone) {
    if (phone.isEmpty) {
      setState(() => _phoneError = 'Phone number is required');
      return false;
    }

    final formattedPhone = _formatPhoneNumber(phone);
    if (!RegExp(r'^254[17]\d{8}$').hasMatch(formattedPhone)) {
      setState(() => _phoneError = 'Please enter a valid Safaricom number');
      return false;
    }

    setState(() => _phoneError = null);
    return true;
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

  Future<void> _handleMpesaPayment() async {
    print('🔄 ConfirmAndPayPage: Starting M-Pesa payment process');
    setState(() => _isProcessing = true);
    
    try {
      // Get or create the appointment first
      print('📝 ConfirmAndPayPage: Getting or creating appointment');
      final appointmentId = await _getOrCreateAppointment();
      print('✅ ConfirmAndPayPage: Got appointment ID: $appointmentId');

      // Show phone number input dialog
      print('📱 ConfirmAndPayPage: Showing phone number input dialog');
      final phoneNumber = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('Enter M-Pesa Phone Number'),
          content: TextField(
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'e.g., 254712345678',
              prefixText: '+',
            ),
            onChanged: (value) => _phoneNumber = value,
          ),
          actions: [
            TextButton(
              onPressed: () {
                print('❌ ConfirmAndPayPage: User cancelled phone number input');
                Navigator.pop(context, null);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                print('✅ ConfirmAndPayPage: User entered phone number: $_phoneNumber');
                Navigator.pop(context, _phoneNumber);
              },
              child: Text('Continue'),
            ),
          ],
        ),
      );

      if (phoneNumber == null || phoneNumber.isEmpty) {
        print('❌ ConfirmAndPayPage: No phone number provided');
        setState(() => _isProcessing = false);
        return;
      }

      // Format phone number
      final formattedPhone = _formatPhoneNumber(phoneNumber);
      print('📱 ConfirmAndPayPage: Formatted phone number: $formattedPhone');

      // Show processing dialog
      print('⏳ ConfirmAndPayPage: Showing processing dialog');
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Processing payment...\nPlease check your phone for the M-Pesa prompt.'),
            ],
          ),
        ),
      );

      // Initiate STK Push
      print('📤 ConfirmAndPayPage: Initiating STK Push');
      final result = await _mpesaService.initiateSTKPush(
        phoneNumber: formattedPhone,
        amount: widget.consultationFee,
        reference: appointmentId,
        description: 'Payment for veterinary consultation with ${widget.vetName}',
      );

      // Close processing dialog
      print('✅ ConfirmAndPayPage: Closing processing dialog');
      Navigator.pop(context);

      if (result['ResponseCode'] == '0') {
        print('✅ ConfirmAndPayPage: STK Push initiated successfully');
        
        // Update appointment with payment details
        print('📝 ConfirmAndPayPage: Updating appointment with payment details');
        await _firestore.collection('appointments').doc(appointmentId).update({
          'paymentStatus': 'pending',
          'paymentMethod': 'mpesa',
          'mpesaCheckoutRequestId': result['checkoutRequestId'],
          'mpesaMerchantRequestId': result['merchantRequestId'],
        });

        // Show success dialog
        print('🎉 ConfirmAndPayPage: Showing success dialog');
        _showSuccessDialog();
      } else {
        print('❌ ConfirmAndPayPage: STK Push failed: ${result['ResponseDescription']}');
        _showErrorDialog('Payment failed: ${result['ResponseDescription']}');
      }
    } catch (e) {
      print('❌ ConfirmAndPayPage: Error processing M-Pesa payment: $e');
      setState(() => _isProcessing = false);
      
      // Show error dialog
      print('⚠️ ConfirmAndPayPage: Showing error dialog');
      _showErrorDialog('An error occurred while processing your payment.');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Payment Initiated'),
        content: const Text(
          'Please check your phone for the M-Pesa prompt and enter your PIN to complete the payment.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(true); // Return to previous screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
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