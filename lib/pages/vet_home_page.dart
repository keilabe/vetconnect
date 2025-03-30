import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/vet_bottom_nav_bar.dart';
import 'vet_appointments_page.dart';
import 'vet_messages_page.dart';
import 'vet_profile_settings_page.dart';
import 'vet_services_page.dart';

class VetHomePage extends StatefulWidget {
  const VetHomePage({super.key});

  @override
  State<VetHomePage> createState() => _VetHomePageState();
}

class _VetHomePageState extends State<VetHomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _selectedIndex = 0;
  String? _vetName;
  String? _specialty;

  @override
  void initState() {
    super.initState();
    _loadVetData();
  }

  Future<void> _loadVetData() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // First get user data from users collection
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        print('User document not found');
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      
      setState(() {
        _vetName = userData['fullName'] ?? 'Veterinarian';
        _specialty = userData['specialization'] ?? '';
      });

    } catch (e) {
      print('Error loading vet data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome, ${_vetName ?? 'Veterinarian'}'),
            if (_specialty != null)
            Text(
                _specialty!,
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Home Tab
          SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Today's Schedule
                Text(
                  'Today\'s Schedule',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('appointments')
                      .where('vetId', isEqualTo: _auth.currentUser?.uid)
                      .where('status', isEqualTo: 'confirmed')
                      .where('dateTime',
                          isGreaterThanOrEqualTo: DateTime.now())
                      .orderBy('dateTime')
                      .limit(5)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('Error loading appointments');
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    }

                    final appointments = snapshot.data?.docs ?? [];

                    if (appointments.isEmpty) {
                      return Text('No appointments scheduled for today');
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: appointments.length,
                      itemBuilder: (context, index) {
                        final appointment = appointments[index].data()
                            as Map<String, dynamic>;
                        final dateTime = appointment['dateTime'] != null
                            ? (appointment['dateTime'] as Timestamp).toDate()
                            : DateTime.now();

                        return Card(
                          margin: EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Icon(Icons.pets),
                            ),
                            title: Text('Appointment with Farmer'),
                            subtitle: Text(
                              '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} - ${appointment['type'] ?? 'Consultation'}',
                            ),
                            trailing: Icon(Icons.arrow_forward_ios),
                            onTap: () {
                              setState(() => _selectedIndex = 1);
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
                SizedBox(height: 24),
                // Quick Actions
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildQuickActionCard(
                      icon: Icons.calendar_today,
                      title: 'Appointments',
                      onTap: () {
                        setState(() => _selectedIndex = 1);
                      },
                    ),
                    _buildQuickActionCard(
                      icon: Icons.medical_services,
                      title: 'Services',
                      onTap: () {
                        setState(() => _selectedIndex = 2);
                      },
                    ),
                    _buildQuickActionCard(
                      icon: Icons.message,
                      title: 'Messages',
                      onTap: () {
                        setState(() => _selectedIndex = 3);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Appointments Tab
          VetAppointmentsPage(),
          // Services Tab
          VetServicesPage(),
          // Messages Tab
          VetMessagesPage(),
          // Profile Tab
          VetProfileSettingsPage(),
        ],
      ),
      bottomNavigationBar: VetBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 100,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.teal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.teal, size: 32),
            SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.teal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 