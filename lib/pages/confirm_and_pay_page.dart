import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vetconnect/pages/payment_success_screen_page.dart';

class ConfirmAndPayPage extends StatefulWidget {
  final String vetName;
  final DateTime appointmentTime;
  final double consultationFee;

  const ConfirmAndPayPage({super.key, 
    required this.vetName,
    required this.appointmentTime,
    required this.consultationFee,
  });

  @override
  State<StatefulWidget> createState() {
    return _ConfirmAndPayPageState();
  }
}

class _ConfirmAndPayPageState extends State<ConfirmAndPayPage> {
    String? _selectedPaymentMethod;


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
        onPressed: _selectedPaymentMethod == null
            ? null
            : () {
                // Handle payment confirmation
                print('Payment confirmed with $_selectedPaymentMethod');
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => PaymentSuccessScreen()),
                );
              },
        child: Text(
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
}