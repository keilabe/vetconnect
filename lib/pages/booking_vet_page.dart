import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:vetconnect/pages/confirm_and_pay_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum TimePickerMode { h12, h24 }

class BookingVetPage extends StatefulWidget {
  final String vetId;
  final Map<String, dynamic> vetData;

  const BookingVetPage({
    super.key,
    required this.vetId,
    required this.vetData,
  });
  
  @override
  State<BookingVetPage> createState() => _BookingVetPageState();
}

class _BookingVetPageState extends State<BookingVetPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  double? _deviceHeight;
  double? _deviceWidth;
  bool _isInPerson = true;
  DateTime? _selectedDate = DateTime.now();
  final TimePickerMode _timePickerMode = TimePickerMode.h24;
  String _animalType = '';
  String _gender = '';
  String _symptoms = '';
  String _location = '';
  int _selectedIndex = 0;
  String vetName = ''; 
  String appointmentTime = '';
  double consultationFee = 0.0;
  TimeOfDay? _selectedTime;
  String? _selectedAnimal;
  String? _selectedType;
  final TextEditingController _notesController = TextEditingController();
  String _selectedGender = 'Male';
  final List<String> _genderOptions = ['Male', 'Female'];

  final List<Map<String, dynamic>> _previousAppointments = [
  {
    'date': '2023-03-15 14:30',
    'animal': 'Dairy Cow',
    'type': 'Vaccination',
    'status': 'Completed',
    'vet': 'Dr. Lila Montgomery'
  },
  {
    'date': '2023-02-28 10:00',
    'animal': 'Bull',
    'type': 'Orthopedic Checkup',
    'status': 'Completed',
    'vet': 'Dr. James Kariuki'
  },
  {
    'date': '2023-02-15 09:00',
    'animal': 'Calf',
    'type': 'Routine Checkup',
    'status': 'Cancelled',
    'vet': 'Dr. Lila Montgomery'
  },
];

  final List<String> _appointmentTypes = [
    'General Checkup',
    'Vaccination',
    'Surgery',
    'Emergency',
    'Follow-up',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  _deviceHeight = MediaQuery.of(context).size.height;
  _deviceWidth = MediaQuery.of(context).size.width;

  return Scaffold(
    appBar: AppBar(
      toolbarHeight: 120,
      backgroundColor: Colors.blue[900],
      leading: Container(
        padding: EdgeInsets.only(left: 16),
        child: Row(
          children: [
            _vetProfileIcon(),
            SizedBox(width: 12),
            _vetProfile(),
          ],
        ),
      ),
      leadingWidth: _deviceWidth! * 0.7,
      title: Container(), // Empty title since we're using leading for content
      actions: [
        IconButton(
          icon: Icon(Icons.notifications_active_outlined, color: Colors.white),
          onPressed: () {},
        ),
      ],
    ),
    body: Stack(
      children: [
        // Blue background section
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: _deviceHeight! * 0.25,
          child: Container(
            color: Colors.blue[900],
          ),
        ),
        
        // Form positioned over the blue background
        Positioned(
          top: _deviceHeight! * 0.005,
          left: 16,
          right: 16,
          child: _reservationForm(),
        ),
        
        // Additional section below the form
        Positioned(
          top: _deviceHeight! * 0.5, 
          left: 0,
          right: 0,
          bottom: 0,
          child: SingleChildScrollView(
        child: Column(
          children: [
            _previousAppointmentsSection(),
            SizedBox(height: 20),
          ],
        ),
      ),
        ),
      ],
    ),
    bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
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

Widget _reservationForm() {
  return Card(
    elevation: 6,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: Container(
      padding: EdgeInsets.all(20),
      constraints: BoxConstraints(
        maxHeight: 300, 
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _buildFormTypeButton('In-Person Visit', true),
                SizedBox(width: 10),
                _buildFormTypeButton('Video Call', false),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.blue),
                SizedBox(width: 10),
                ElevatedButton(
      onPressed: () => _selectDateTime(context),
      child: Row(
    children: [
                Text(
                  DateFormat('EEE, d MMM y HH:mm').format(_selectedDate!),
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(width: 5),
                Icon(Icons.arrow_drop_down, color: Colors.blue),
    ],
  ),
),
              ],
            ),
            SizedBox(height: 20),

            // Animal Details
            TextField(
              decoration: InputDecoration(
                labelText: 'Animal Type',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _animalType = value),
            ),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: InputDecoration(
                labelText: 'Gender',
                border: OutlineInputBorder(),
              ),
              items: _genderOptions.map((String gender) {
                return DropdownMenuItem<String>(
                  value: gender,
                  child: Text(gender),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedGender = newValue;
                    _gender = newValue;
                  });
                }
              },
            ),
            SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                labelText: 'Symptoms',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) => setState(() => _symptoms = value),
            ),

            // Location Input (for In-Person Visit)
            if (_isInPerson)
              TextField(
                decoration: InputDecoration(
                  labelText: 'Meeting Location',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _location = value),
              ),

            SizedBox(height: 20),

            // Confirm Appointment Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _confirmAppointment(),
                child: Text(
                  'Confirm Appointment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _vetProfile() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        'Dr. ${widget.vetData['fullName'] ?? 'Unknown Vet'}',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      SizedBox(height: 4),
      Text(
        widget.vetData['specialization'] ?? 'Veterinarian',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
      ),
      Text(
        '${widget.vetData['region'] ?? 'Unknown Location'}',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
      ),
    ],
    );
  }

   Widget _vetProfileIcon() {
    return CircleAvatar(
      radius: 30,
      backgroundImage: widget.vetData['profileImage'] != null
          ? NetworkImage(widget.vetData['profileImage'])
          : AssetImage('assets/images/vet1.png') as ImageProvider,
      onBackgroundImageError: (exception, stackTrace) {
        print('Error loading vet profile image: $exception');
        // Fallback to default image if there's an error
        setState(() {
          widget.vetData['profileImage'] = null;
        });
      },
    );
  }

  void _selectTime(BuildContext context) async {
  final TimeOfDay initialTime = _selectedDate != null 
      ? TimeOfDay.fromDateTime(_selectedDate!)
      : TimeOfDay.now();

  final pickedTime = await showTimePicker(
    context: context,
    initialTime: initialTime,
    builder: (BuildContext context, Widget? child) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(
          alwaysUse24HourFormat: _timePickerMode == TimePickerMode.h24,
        ),
        child: child!,
      );
    },
  );

  if (pickedTime != null) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }
}

   Widget _buildFormTypeButton(String text, bool isInPerson) {
  return Expanded(
    child: GestureDetector(
      onTap: () => setState(() => _isInPerson = isInPerson),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _isInPerson == isInPerson ? Colors.teal : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                text,
                style: TextStyle(
                  color: _isInPerson == isInPerson ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              if (isInPerson) 
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Time',
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(width: 5),
                    Icon(Icons.access_time, size: 16, color: Colors.grey),
                  ],
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

  String _formatTime() {
  return DateFormat.jm().format(_selectedDate!).toString();
}

  void _selectDateTime(BuildContext context) async {
  final pickedDate = await showDatePicker(
    context: context,
    initialDate: _selectedDate ?? DateTime.now(),
    firstDate: DateTime.now(),
    lastDate: DateTime(2025, 12, 31),
  );

    TimeOfDay? pickedTime;

  if (pickedDate != null) {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate ?? DateTime.now()),
    );

   if (pickedTime != null) {
      setState(() {
        _selectedDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
   }
  }  
  }

  void _confirmAppointment() async {
    try {
      if (_selectedDate == null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text('Please select a valid date and time'),
          ),
        );
        return;
      }

      // Get current user
      final user = _auth.currentUser;
      if (user == null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text('Please login to book an appointment'),
          ),
        );
        return;
      }

      // Create appointment document with proper timestamp
      final appointmentRef = await _firestore.collection('appointments').add({
        'vetId': widget.vetId,
        'farmerId': user.uid,
        'appointmentTime': Timestamp.fromDate(_selectedDate!), // Convert DateTime to Timestamp
        'status': 'pending',
        'animalType': _animalType,
        'gender': _gender,
        'symptoms': _symptoms,
        'location': _location,
        'consultationType': _isInPerson ? 'in-person' : 'video',
        'consultationFee': 50.0,
        'createdAt': FieldValue.serverTimestamp(),
        'vetName': 'Dr. ${widget.vetData['fullName'] ?? 'Unknown Vet'}',
      });

      // Create notification for vet
      await _firestore.collection('notifications').add({
        'userId': widget.vetId,
        'type': 'appointment_request',
        'appointmentId': appointmentRef.id,
        'message': 'New appointment request from a farmer',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create notification for farmer
      await _firestore.collection('notifications').add({
        'userId': user.uid,
        'type': 'appointment_request_sent',
        'appointmentId': appointmentRef.id,
        'message': 'Your appointment request has been sent to Dr. ${widget.vetData['fullName'] ?? 'Unknown Vet'}',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Appointment Request Sent'),
          content: Text('Your appointment request has been sent to the veterinarian. You will be notified once they respond.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      print("Error creating appointment: $e");
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Failed to create appointment. Please try again.'),
        ),
      );
    }
  }
  
Widget _previousAppointmentsSection() {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Previous Appointments',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'See All',
                style: TextStyle(
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _previousAppointments.length,
          itemBuilder: (context, index) {
            final appointment = _previousAppointments[index];
            return Card(
              margin: EdgeInsets.only(bottom: 12),
              elevation: 2,
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
                              DateTime.parse(appointment['date'])),
                        ),
                        Chip(
                          backgroundColor: appointment['status'] == 'Completed'
                              ? Colors.green[50]
                              : Colors.orange[50],
                          label: Text(
                            appointment['status'],
                            style: TextStyle(
                              color: appointment['status'] == 'Completed'
                                  ? Colors.green
                                  : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      appointment['vet'],
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.blue[900],
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.pets, size: 16, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(
                          '${appointment['animal']} • ${appointment['type']}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    ),
  );
}
}