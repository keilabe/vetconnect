import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/farmer_bottom_nav_bar.dart';
import '../services/notification_service.dart';
import 'package:intl/intl.dart';
import '../models/notification_model.dart';

class FarmerAppointmentsPage extends StatefulWidget {
  const FarmerAppointmentsPage({super.key});

  @override
  State<FarmerAppointmentsPage> createState() => _FarmerAppointmentsPageState();
}

class _FarmerAppointmentsPageState extends State<FarmerAppointmentsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  String _selectedStatus = 'pending';
  int _selectedIndex = 1; // Appointments tab
  List<NotificationModel> _notifications = [];

  @override
  void initState() {
    super.initState();
    print('FarmerAppointmentsPage initialized');
    print('Current user ID: ${_auth.currentUser?.uid}');
    _setupNotificationListener();
  }

  void _setupNotificationListener() {
    print('Setting up notification listener');
    _notificationService.getNotifications().listen((notifications) {
      if (notifications.isEmpty) return;
      
      print('Received ${notifications.length} notifications');
      for (var notification in notifications) {
        print('Notification type: ${notification.type}, isRead: ${notification.isRead}');
        if (notification.type == 'appointment_accepted' && !notification.isRead) {
          print('Handling appointment confirmation for appointment: ${notification.appointmentId}');
          _handleAppointmentConfirmation(notification.appointmentId ?? '');
        } else if (notification.type == 'appointment_declined' && !notification.isRead) {
          print('Handling appointment rejection for appointment: ${notification.appointmentId}');
          _handleAppointmentRejection(notification.appointmentId ?? '');
        }
      }
    });
  }

  Future<void> _handleAppointmentRejection(String appointmentId) async {
    try {
      // Get the appointment data
      final appointmentDoc = await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .get();

      if (!appointmentDoc.exists) {
        print('Appointment not found: $appointmentId');
        return;
      }

      final appointment = appointmentDoc.data() as Map<String, dynamic>;
      
      // Show dialog to inform the user
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Appointment Declined'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your appointment request has been declined by ${appointment['vetName'] ?? 'the veterinarian'}.'),
                SizedBox(height: 8),
                Text('You can try booking with another veterinarian.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  // Optionally navigate to vet listing page
                  Navigator.pushNamed(context, '/vet-listing');
                },
                child: Text('Find Another Vet'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      }

      // Mark notification as read
      final notifications = await _firestore
          .collection('notifications')
          .where('appointmentId', isEqualTo: appointmentId)
          .get();

      for (var doc in notifications.docs) {
        await _notificationService.markAsRead(doc.id);
      }

      // Update UI to show cancelled tab
      setState(() {
        _selectedStatus = 'cancelled';
      });
    } catch (e) {
      print('Error handling appointment rejection: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing notification'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handleAppointmentConfirmation(String appointmentId) async {
    try {
      // Get the appointment data
      final appointmentDoc = await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .get();

      if (!appointmentDoc.exists) {
        print('Appointment not found: $appointmentId');
        return;
      }

      final appointment = appointmentDoc.data() as Map<String, dynamic>;
      
      // Show dialog to proceed with payment
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text('Appointment Confirmed'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your appointment has been confirmed by ${appointment['vetName'] ?? 'the veterinarian'}.'),
                SizedBox(height: 8),
                Text('Appointment Details:'),
                Text('• Date: ${DateFormat('MMM d, y').format((appointment['appointmentTime'] as Timestamp).toDate())}'),
                Text('• Time: ${DateFormat('h:mm a').format((appointment['appointmentTime'] as Timestamp).toDate())}'),
                Text('• Fee: KES ${appointment['consultationFee']?.toString() ?? '50.0'}'),
                SizedBox(height: 16),
                Text('Please proceed with payment to complete the booking.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  // Navigate to payment page
                  Navigator.pushNamed(
                    context,
                    '/confirm&pay',
                    arguments: {
                      'vetName': appointment['vetName'] ?? 'Unknown Vet',
                      'appointmentTime': (appointment['appointmentTime'] as Timestamp).toDate(),
                      'consultationFee': appointment['consultationFee']?.toDouble() ?? 50.0,
                      'vetId': appointment['vetId'] ?? '',
                      'animalType': appointment['animalType'] ?? 'Unknown Animal',
                      'consultationType': appointment['consultationType'] ?? 'General Checkup',
                      'symptoms': appointment['symptoms'] ?? 'No specific symptoms',
                      'appointmentId': appointmentId,
                    },
                  );
                },
                child: Text('Proceed to Payment'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                },
                child: Text('Pay Later'),
              ),
            ],
          ),
        );
      }

      // Mark notification as read
      final notifications = await _firestore
          .collection('notifications')
          .where('appointmentId', isEqualTo: appointmentId)
          .get();

      for (var doc in notifications.docs) {
        await _notificationService.markAsRead(doc.id);
      }
    } catch (e) {
      print('Error handling appointment confirmation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing notification'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _onNavBarTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid;
    print('Building FarmerAppointmentsPage for user: $userId');
    if (userId == null) {
      print('No user ID found, showing login message');
      return Center(child: Text('Please log in to view appointments'));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Appointments',
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'Inter',
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatusFilter('pending', 'Pending'),
                _buildStatusFilter('confirmed', 'Confirmed'),
                _buildStatusFilter('completed', 'Completed'),
                _buildStatusFilter('cancelled', 'Cancelled'),
              ],
            ),
          ),
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
                              notification.message,
                              style: TextStyle(fontFamily: 'Inter'),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.close),
                              onPressed: () {
                                _notificationService.markAsRead(notification.id);
                                setState(() {
                                  _notifications.remove(notification);
                                });
                              },
                            ),
                            dense: true,
                            onTap: () {
                              print('Notification tapped: ${notification.type} - ${notification.appointmentId}');
                              // Handle notification tap based on type
                              if (notification.type == 'appointment_accepted') {
                                _handleAppointmentConfirmation(notification.appointmentId ?? '');
                              } else if (notification.type == 'appointment_declined') {
                                _handleAppointmentRejection(notification.appointmentId ?? '');
                              }
                            },
                            // Make it look clickable
                            hoverColor: Colors.grey[300],
                            tileColor: Colors.grey[100],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey[300]!, width: 1),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  );
                }
              }
              
              // Handle notifications silently
              if (snapshot.hasData) {
                for (var notification in snapshot.data ?? []) {
                  if (notification.type == 'appointment_request' && !notification.isRead) {
                    _notificationService.handleNewAppointment(
                      notification.appointmentId ?? ''
                    );
                  }
                }
              }
              
              return Container(); // Return empty container if no notifications
            },
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('appointments')
                  .where('farmerId', isEqualTo: userId)
                  .where('status', isEqualTo: _selectedStatus)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print('Error in appointments stream: ${snapshot.error}');
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  print('Waiting for appointments data...');
                  return Center(child: CircularProgressIndicator());
                }

                final appointments = snapshot.data?.docs ?? [];
                print('Found ${appointments.length} $_selectedStatus appointments');

                if (appointments.isEmpty) {
                  print('No $_selectedStatus appointments found for farmer: $userId');
                  return Center(
                    child: Text('No appointments found'),
                  );
                }

                // Sort appointments in memory
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
                appointments.forEach((doc) {
                  final appointment = doc.data() as Map<String, dynamic>;
                  print('''
Appointment Details:
ID: ${doc.id}
Status: $_selectedStatus
DateTime: ${appointment['appointmentTime']}
Animal Type: ${appointment['animalType']}
Consultation Type: ${appointment['consultationType']}
Vet ID: ${appointment['vetId']}
''');
                });

                return ListView.builder(
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final appointment = appointments[index].data() as Map<String, dynamic>;
                    print('Building appointment card for ID: ${appointments[index].id}');
                    return _buildAppointmentCard(appointment);
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: FarmerBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavBarTap,
      ),
    );
  }

  Widget _buildStatusFilter(String status, String label) {
    print('Building status filter for: $status');
    return FilterChip(
      label: Text(label),
      selected: _selectedStatus == status,
      onSelected: (selected) {
        print('Status filter selected: $status');
        setState(() {
          _selectedStatus = status;
        });
      },
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    try {
      print('Building appointment card with data: $appointment');
      final appointmentTime = appointment['appointmentTime'];
      DateTime? dateTime;
      
      if (appointmentTime != null && appointmentTime is Timestamp) {
        dateTime = appointmentTime.toDate();
        print('Appointment time: ${dateTime.toString()}');
      } else {
        print('Warning: Invalid appointment time for appointment ${appointment['id']}');
        dateTime = DateTime.now(); // Fallback to current time
      }

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
                    appointment['vetName'] ?? 'Unknown Vet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(appointment['status']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      appointment['status'].toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(appointment['status']),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    DateFormat('MMM d, y').format(dateTime),
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    DateFormat('h:mm a').format(dateTime),
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Animal Type: ${appointment['animalType'] ?? 'Not specified'}',
                style: TextStyle(color: Colors.grey),
              ),
              if (appointment['status'] == 'confirmed' && appointment['paymentStatus'] != 'completed') ...[
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/confirm&pay',
                        arguments: {
                          'vetName': appointment['vetName'] ?? 'Unknown Vet',
                          'appointmentTime': dateTime,
                          'consultationFee': appointment['consultationFee']?.toDouble() ?? 50.0,
                          'vetId': appointment['vetId'] ?? '',
                          'animalType': appointment['animalType'] ?? 'Unknown Animal',
                          'consultationType': appointment['consultationType'] ?? 'General Checkup',
                          'symptoms': appointment['symptoms'] ?? 'No specific symptoms',
                          'appointmentId': appointment['id'],
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Proceed to Payment',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    } catch (e) {
      print('Error building appointment card: $e');
      return Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Error loading appointment details'),
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
} 