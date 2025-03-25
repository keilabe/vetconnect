import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/farmer_bottom_nav_bar.dart';
import '../services/notification_service.dart';

class FarmerAppointmentsPage extends StatefulWidget {
  const FarmerAppointmentsPage({Key? key}) : super(key: key);

  @override
  State<FarmerAppointmentsPage> createState() => _FarmerAppointmentsPageState();
}

class _FarmerAppointmentsPageState extends State<FarmerAppointmentsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  String _selectedStatus = 'pending';
  int _selectedIndex = 1; // Appointments tab

  @override
  void initState() {
    super.initState();
    _setupNotificationListener();
  }

  void _setupNotificationListener() {
    _notificationService.getNotifications().listen((snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['type'] == 'appointment_confirmation' && !data['isRead']) {
          _notificationService.handleAppointmentConfirmation(
            context,
            data['appointmentId'],
          );
        }
      }
    });
  }

  void _onNavBarTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
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
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('appointments')
                  .where('farmerId', isEqualTo: userId)
                  .where('status', isEqualTo: _selectedStatus)
                  .orderBy('dateTime', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final appointments = snapshot.data?.docs ?? [];
                if (appointments.isEmpty) {
                  return Center(
                    child: Text('No appointments found'),
                  );
                }

                return ListView.builder(
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final appointment = appointments[index].data() as Map<String, dynamic>;
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
    return FilterChip(
      label: Text(label),
      selected: _selectedStatus == status,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = status;
        });
      },
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    try {
      final dateTime = (appointment['dateTime'] as Timestamp).toDate();
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
                    'Dr. ${appointment['vetName'] ?? 'Unknown Vet'}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(appointment['status'] ?? 'unknown'),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      appointment['status']?.toUpperCase() ?? 'UNKNOWN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text('Date: ${_formatDate(dateTime)}'),
              Text('Time: ${_formatTime(dateTime)}'),
              Text('Type: ${appointment['type'] ?? 'Unknown'}'),
              Text('Animal: ${appointment['animalType'] ?? 'Unknown'}'),
              if (appointment['description'] != null) ...[
                SizedBox(height: 8),
                Text(
                  'Description:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(appointment['description']),
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
          child: Text('Error displaying appointment'),
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

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
} 