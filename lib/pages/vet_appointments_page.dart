import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;
import '../services/notification_service.dart';
import '../models/notification_model.dart';

class VetAppointmentsPage extends StatefulWidget {
  const VetAppointmentsPage({super.key});

  @override
  State<VetAppointmentsPage> createState() => _VetAppointmentsPageState();
}

class _VetAppointmentsPageState extends State<VetAppointmentsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  String _selectedStatus = 'pending';
  final int _selectedIndex = 1; // Appointments tab
  List<NotificationModel> _notifications = [];
  // Set to track already processed appointment IDs to prevent duplicate handling
  final Set<String> _processedAppointmentIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    print('VetAppointmentsPage initialized');
    print('Current user ID: ${_auth.currentUser?.uid}');
    print('Setting up notification listener');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid;
    print('Building VetAppointmentsPage for user: $userId');
    if (userId == null) {
      print('No user ID found, showing login message');
      return Center(child: Text('Please log in to view appointments'));
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Appointments'),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Confirmed'),
              Tab(text: 'Completed'),
              Tab(text: 'Cancelled'),
            ],
          ),
        ),
        body: Column(
          children: [
            StreamBuilder<List<NotificationModel>>(
              stream: _notificationService.getNotifications(),
              builder: (context, snapshot) {
                if (snapshot.hasData && (snapshot.data?.isNotEmpty ?? false)) {
                  _notifications = snapshot.data!.where((notification) => 
                    notification.type == 'appointment_accepted' || 
                    notification.type == 'appointment_declined'
                  ).toList();
                  
                  if (_notifications.isNotEmpty) {
                    return Container(
                      padding: EdgeInsets.all(8),
                      margin: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Notifications',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                          ..._notifications.map((notification) {
                            IconData iconData;
                            Color iconColor;
                            
                            if (notification.type == 'appointment_accepted') {
                              iconData = Icons.check_circle;
                              iconColor = Colors.green;
                            } else {
                              iconData = Icons.cancel;
                              iconColor = Colors.red;
                            }
                            
                            return ListTile(
                              leading: Icon(iconData, color: iconColor),
                              title: Text(
                                notification.message ?? 'Appointment update',
                                style: TextStyle(fontFamily: 'Inter'),
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.close),
                                onPressed: () {
                                  _notificationService.markAsRead(notification.id ?? '');
                                  setState(() {
                                    _notifications.remove(notification);
                                  });
                                },
                              ),
                              dense: true,
                            );
                          }),
                        ],
                      ),
                    );
                  }
                }
                
                // Handle appointment_request notifications silently
                if (snapshot.hasData) {
                  for (var notification in snapshot.data ?? []) {
                    final appointmentId = notification.appointmentId ?? '';
                    if (notification.type == 'appointment_request' && 
                        !notification.isRead && 
                        appointmentId.isNotEmpty && 
                        !_processedAppointmentIds.contains(appointmentId)) {
                      
                      print('Processing new appointment request: $appointmentId');
                      _processedAppointmentIds.add(appointmentId);
                      
                      // Mark notification as read to prevent reprocessing
                      _notificationService.markAsRead(notification.id ?? '');
                      
                      // Only handle if not already processed
                      _notificationService.handleNewAppointment(appointmentId);
                    }
                  }
                }
                
                return Container(); // Return empty container if no notifications
              },
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
          children: [
            _buildAppointmentsList('pending'),
            _buildAppointmentsList('confirmed'),
            _buildAppointmentsList('completed'),
                  _buildAppointmentsList('rejected'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsList(String status) {
    print('Building appointments list for status: $status');
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('appointments')
          .where('vetId', isEqualTo: _auth.currentUser?.uid)
          .where('status', isEqualTo: status)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Error in appointments stream: ${snapshot.error}');
          return Center(child: Text('Error loading appointments'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          print('Waiting for appointments data...');
          return Center(child: CircularProgressIndicator());
        }

        final appointments = snapshot.data?.docs ?? [];
        print('Found ${appointments.length} $status appointments');

        if (appointments.isEmpty) {
          print('No $status appointments found for vet: ${_auth.currentUser?.uid}');
          return Center(
            child: Text('No $status appointments found'),
          );
        }

        // Sort appointments in memory with null check
        appointments.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          
          final aTime = aData['appointmentTime'];
          final bTime = bData['appointmentTime'];
          
          print('Appointment A time: $aTime');
          print('Appointment B time: $bTime');
          
          if (aTime == null || bTime == null) {
            print('Warning: Found null appointment time');
            return 0; // Keep original order if time is null
          }
          
          if (aTime is! Timestamp || bTime is! Timestamp) {
            print('Warning: Found non-Timestamp appointment time');
            return 0; // Keep original order if time is not Timestamp
          }
          
          return bTime.compareTo(aTime); // Sort in descending order
        });

        // Log details of each appointment
        for (var doc in appointments) {
          final appointment = doc.data() as Map<String, dynamic>;
          print('''
Appointment Details:
ID: ${doc.id}
Status: $status
DateTime: ${appointment['appointmentTime']}
Animal Type: ${appointment['animalType']}
Consultation Type: ${appointment['consultationType']}
Farmer ID: ${appointment['farmerId']}
''');
        }

        return ListView.builder(
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final appointment = appointments[index].data() as Map<String, dynamic>;
            final appointmentId = appointments[index].id;
            
            // Add null check for appointmentTime
            final appointmentTime = appointment['appointmentTime'];
            DateTime? dateTime;
            
            if (appointmentTime != null && appointmentTime is Timestamp) {
              dateTime = appointmentTime.toDate();
            } else {
              print('Warning: Invalid appointment time for appointment $appointmentId');
              dateTime = DateTime.now(); // Fallback to current time
            }

            print('Building appointment card for ID: $appointmentId');

            return Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Appointment Request',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16),
                        SizedBox(width: 8),
                        Text(
                          '${dateTime.day}/${dateTime.month}/${dateTime.year}',
                          style: TextStyle(fontFamily: 'Inter'),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16),
                        SizedBox(width: 8),
                        Text(
                          '${dateTime.hour}:${dateTime.minute}',
                          style: TextStyle(fontFamily: 'Inter'),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.pets, size: 16),
                        SizedBox(width: 8),
                        Text(
                          appointment['animalType'] ?? 'Unknown Animal',
                          style: TextStyle(fontFamily: 'Inter'),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.medical_services, size: 16),
                        SizedBox(width: 8),
                        Text(
                          appointment['consultationType'] ?? 'Unknown Type',
                          style: TextStyle(fontFamily: 'Inter'),
                        ),
                      ],
                    ),
                    if (appointment['symptoms'] != null) ...[
                      SizedBox(height: 8),
                      Text(
                        'Symptoms: ${appointment['symptoms']}',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                    if (status == 'pending') ...[
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => _rejectAppointment(appointmentId),
                            child: Text(
                              'Reject',
                              style: TextStyle(
                                color: Colors.red,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _confirmAppointment(appointmentId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                            ),
                            child: Text(
                              'Confirm',
                              style: TextStyle(fontFamily: 'Inter'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _confirmAppointment(String appointmentId) async {
    print('Attempting to confirm appointment: $appointmentId');
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Confirming appointment..."),
              ],
            ),
          ),
        );
      },
    );
    
    try {
      // Use a transaction to ensure all operations are atomic
      await _firestore.runTransaction((transaction) async {
        // Get the appointment data first
        final appointmentDocRef = _firestore.collection('appointments').doc(appointmentId);
        final appointmentDoc = await transaction.get(appointmentDocRef);
        
        if (!appointmentDoc.exists) {
          throw Exception('Appointment not found');
        }
        
        final appointment = appointmentDoc.data() as Map<String, dynamic>;
        print('Current appointment data: $appointment');
        
        // Check if appointment is already confirmed
        if (appointment['status'] == 'confirmed') {
          print('Appointment already confirmed');
          return;
        }
        
        // Update appointment status
        transaction.update(appointmentDocRef, {
        'status': 'confirmed',
        'confirmedAt': FieldValue.serverTimestamp(),
      });
        
        // Create notification for farmer
        final notificationRef = _firestore.collection('notifications').doc();
        transaction.set(notificationRef, {
          'userId': appointment['farmerId'],
          'type': 'appointment_accepted',
          'appointmentId': appointmentId,
          'message': 'Your appointment request has been accepted',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
      
      // Close loading dialog
      Navigator.of(context, rootNavigator: true).pop();
      
      // Verify the appointment was updated
      final updatedDoc = await _firestore.collection('appointments').doc(appointmentId).get();
      final updatedData = updatedDoc.data() as Map<String, dynamic>;
      
      if (updatedData['status'] == 'confirmed') {
        print('Appointment confirmed successfully. Updated data: $updatedData');
        
        // Force UI update
        setState(() {
          // This will trigger a rebuild of the UI
          _selectedStatus = 'confirmed';
          _tabController.animateTo(1); // Switch to Confirmed tab
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment confirmed successfully')),
      );
      } else {
        print('Warning: Appointment status not updated to confirmed. Current status: ${updatedData['status']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Appointment status may not have updated. Please refresh.')),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context, rootNavigator: true).pop();
      
      print('Error confirming appointment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error confirming appointment: ${e.toString().substring(0, math.min(e.toString().length, 100))}')),
      );
    }
  }

  Future<void> _rejectAppointment(String appointmentId) async {
    print('Attempting to reject appointment: $appointmentId');
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Rejecting appointment..."),
              ],
            ),
          ),
        );
      },
    );
    
    try {
      // Use a transaction to ensure all operations are atomic
      await _firestore.runTransaction((transaction) async {
        // Get the appointment data first
        final appointmentDocRef = _firestore.collection('appointments').doc(appointmentId);
        final appointmentDoc = await transaction.get(appointmentDocRef);
        
        if (!appointmentDoc.exists) {
          throw Exception('Appointment not found');
        }
        
        final appointment = appointmentDoc.data() as Map<String, dynamic>;
        print('Current appointment data: $appointment');
        
        // Check if appointment is already rejected
        if (appointment['status'] == 'rejected') {
          print('Appointment already rejected');
          return;
        }
        
        // Update appointment status
        transaction.update(appointmentDocRef, {
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });

        // Create notification for farmer
        final notificationRef = _firestore.collection('notifications').doc();
        transaction.set(notificationRef, {
          'userId': appointment['farmerId'],
          'type': 'appointment_declined',
          'appointmentId': appointmentId,
          'message': 'Your appointment request has been declined',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
      
      // Close loading dialog
      Navigator.of(context, rootNavigator: true).pop();
      
      // Verify the appointment was updated
      final updatedDoc = await _firestore.collection('appointments').doc(appointmentId).get();
      final updatedData = updatedDoc.data() as Map<String, dynamic>;
      
      if (updatedData['status'] == 'rejected') {
        print('Appointment rejected successfully. Updated data: $updatedData');
        
        // Force UI update
        setState(() {
          // This will trigger a rebuild of the UI
          _selectedStatus = 'rejected';
          _tabController.animateTo(3); // Switch to Cancelled tab
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Appointment rejected successfully')),
        );
      } else {
        print('Warning: Appointment status not updated to rejected. Current status: ${updatedData['status']}');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Appointment status may not have updated. Please refresh.')),
      );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context, rootNavigator: true).pop();
      
      print('Error rejecting appointment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting appointment: ${e.toString().substring(0, math.min(e.toString().length, 100))}')),
      );
    }
  }
} 