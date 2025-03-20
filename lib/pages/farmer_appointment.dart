import 'package:firebase_core_web/firebase_core_web_interop.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vetconnect/pages/home_page.dart';
import 'package:vetconnect/pages/messages_page.dart';
import 'package:vetconnect/pages/settings_page.dart';

class FarmerAppointment extends StatefulWidget{

  @override
  State<StatefulWidget> createState() {
    return _FarmerAppointmentState();
  }
}

class _FarmerAppointmentState extends State<FarmerAppointment> {
  int _selectedIndex = 0;
  final List<Map<String, dynamic>> _allAppointments = [
    {
      'name': 'Dr. Samuel L.Ewing',
      'date': DateTime(2023, 10, 15, 15, 0),
      'status': 'Confirmed'
    },
    {
      'name': 'Dr. Orion Star',
      'date': DateTime(2023, 10, 18, 10, 0),
      'status': 'Pending'
    },
    {
      'name': 'Dr. Nova Light',
      'date': DateTime(2023, 9, 20, 13, 0),
      'status': 'Confirmed'
    },
    {
      'name': 'Dr. Astra Galaxy',
      'date': DateTime(2023, 9, 22, 11, 0),
      'status': 'Completed'
    },
    {
      'name': 'Dr. Luna Sky',
      'date': DateTime(2023, 10, 25, 14, 0),
      'status': 'Confirmed'
    },
  ];

  List<Map<String, dynamic>> get _upcomingAppointments =>
      _allAppointments.where((appt) => appt['date'].isAfter(DateTime.now())).toList();

  List<Map<String, dynamic>> get _pastAppointments =>
      _allAppointments.where((appt) => appt['date'].isBefore(DateTime.now())).toList();

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Confirmed':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Appointments"
          ),
          centerTitle: true,
           bottom: const TabBar(
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Past'),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
          ),
      ),
      body: TabBarView(
          children: [
            // Upcoming Appointments Tab
            Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _upcomingAppointments.length,
                    itemBuilder: (context, index) {
                      final appointment = _upcomingAppointments[index];
                      return _buildAppointmentCard(appointment);
                    },
                  ),
                ),
                _buildActionButtons(),
              ],
            ),
            
            // Past Appointments Tab
            ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _pastAppointments.length,
              itemBuilder: (context, index) {
                final appointment = _pastAppointments[index];
                return _buildAppointmentCard(appointment);
              },
            ),
          ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => _onItemTapped(index, context),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        elevation: 0,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message_outlined),
            activeIcon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

   Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  appointment['name'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Chip(
                  backgroundColor: _getStatusColor(appointment['status'])
                      .withOpacity(0.1),
                  label: Text(
                    appointment['status'],
                    style: TextStyle(
                      color: _getStatusColor(appointment['status']),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              DateFormat('MMM d, y, h:mm a').format(appointment['date']),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {},
              child: Text('Reschedule'),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {},
              child: Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index, BuildContext context) {
    if (index == _selectedIndex) return;

    setState(() {
    _selectedIndex = index;
  });

  print('SelectedIndex: $index');

    
    switch (index) {
    case 0:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
      break;
    case 2:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MessagesPage()),
      );
      break;
    case 3:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SettingsPage()),
      );
      break;
    default:
      return;
  }
  }
}