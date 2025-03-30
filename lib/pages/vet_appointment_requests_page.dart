import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:vetconnect/pages/confirm_and_pay_page.dart';

class VetAppointmentRequestsPage extends StatefulWidget {
  @override
  _VetAppointmentRequestsPageState createState() => _VetAppointmentRequestsPageState();
}

class _VetAppointmentRequestsPageState extends State<VetAppointmentRequestsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Appointment Requests'),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('appointments')
            .where('vetId', isEqualTo: _auth.currentUser?.uid)
            .where('status', isEqualTo: 'pending')
            .orderBy('appointmentTime', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final appointments = snapshot.data?.docs ?? [];

          if (appointments.isEmpty) {
            return Center(
              child: Text(
                'No pending appointment requests',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index].data() as Map<String, dynamic>;
              final appointmentId = appointments[index].id;

              return Card(
                margin: EdgeInsets.all(8),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('EEE, d MMM y • HH:mm').format(
                              (appointment['appointmentTime'] as Timestamp).toDate(),
                            ),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Chip(
                            label: Text('Pending'),
                            backgroundColor: Colors.orange[100],
                            labelStyle: TextStyle(color: Colors.orange[900]),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Animal Type: ${appointment['animalType']}',
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Gender: ${appointment['gender']}',
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Symptoms: ${appointment['symptoms']}',
                        style: TextStyle(fontSize: 14),
                      ),
                      if (appointment['consultationType'] == 'in-person')
                        Text(
                          'Location: ${appointment['location']}',
                          style: TextStyle(fontSize: 14),
                        ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => _declineAppointment(appointmentId),
                            child: Text(
                              'Decline',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _acceptAppointment(appointmentId, appointment),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                            ),
                            child: Text('Accept'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _acceptAppointment(String appointmentId, Map<String, dynamic> appointment) async {
    try {
      // Update appointment status
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      // Create notification for farmer
      await _firestore.collection('notifications').add({
        'userId': appointment['farmerId'],
        'type': 'appointment_accepted',
        'appointmentId': appointmentId,
        'message': 'Your appointment request has been accepted',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Navigate to payment page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConfirmAndPayPage(
            vetName: appointment['vetName'] ?? 'Unknown Vet',
            appointmentTime: (appointment['appointmentTime'] as Timestamp).toDate(),
            consultationFee: appointment['consultationFee']?.toDouble() ?? 0.0,
            vetId: appointment['vetId'] ?? '',
            animalType: appointment['animalType'] ?? 'Unknown Animal',
            consultationType: appointment['consultationType'] ?? 'General Checkup',
            symptoms: appointment['symptoms'] ?? 'No specific symptoms',
          ),
        ),
      );
    } catch (e) {
      print('Error accepting appointment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept appointment. Please try again.')),
      );
    }
  }

  Future<void> _declineAppointment(String appointmentId) async {
    try {
      // Get appointment data first
      final appointmentDoc = await _firestore.collection('appointments').doc(appointmentId).get();
      final appointment = appointmentDoc.data() as Map<String, dynamic>;

      // Update appointment status
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      // Create notification for farmer
      await _firestore.collection('notifications').add({
        'userId': appointment['farmerId'],
        'type': 'appointment_declined',
        'appointmentId': appointmentId,
        'message': 'Your appointment request has been declined',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment request declined')),
      );
    } catch (e) {
      print('Error declining appointment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to decline appointment. Please try again.')),
      );
    }
  }
} 