import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/farmer_bottom_nav_bar.dart';
import 'farmer_appointments_page.dart';
import 'farmer_messages_page.dart';
import 'farmer_profile_page.dart';
import 'view_vet_profile.dart';
import 'vet_search_results_page.dart';
import 'login_page.dart';
import 'chat_list_page.dart';

class FarmerHomePage extends StatefulWidget {
  const FarmerHomePage({super.key});

  @override
  State<FarmerHomePage> createState() => _FarmerHomePageState();
}

class _FarmerHomePageState extends State<FarmerHomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _selectedIndex = 0;
  String? _farmerName;
  String? _farmerRegion;
  String? _farmerPhone;
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot>? _searchResults;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadFarmerData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _searchResults = null;
        _isSearching = false;
      });
    } else {
      setState(() => _isSearching = true);
    }
  }

  void _handleSearch() {
    if (_searchController.text.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VetSearchResultsPage(
            searchQuery: _searchController.text.trim(),
          ),
        ),
      );
    } else {
      // If search is empty, show all vets
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VetSearchResultsPage(
            searchQuery: '',
          ),
        ),
      );
    }
  }

  Future<void> _performSearch(String region) async {
    try {
      setState(() => _isSearching = true);
      
      final querySnapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'Veterinarian')
          .where('region', isGreaterThanOrEqualTo: region)
          .where('region', isLessThan: '${region}z')
          .get();

      setState(() {
        _searchResults = querySnapshot.docs;
        _isSearching = false;
      });
    } catch (e) {
      print('Error searching vets: $e');
      setState(() => _isSearching = false);
      
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching veterinarians. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadFarmerData() async {
    if (!mounted) return;  // Add early return if widget is unmounted
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No user logged in');
        return;
      }

      print('Loading farmer data for user: ${user.uid}');
      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        print('User document does not exist');
        return;
      }

      final data = doc.data();
      print('User data loaded: $data');

      // Verify that this is a farmer account
      if (data?['userType'] != 'Farmer') {
        print('User is not a farmer');
        return;
      }

      if (!mounted) return;  // Check mounted again before setState
      
      setState(() {
        _farmerName = data?['fullName'] ?? 'Farmer';
        _farmerRegion = data?['region'] ?? 'Not specified';
        _farmerPhone = data?['phoneNumber'] ?? 'Not specified';
      });
    } catch (e) {
      print('Error loading farmer data: $e');
      if (!mounted) return;  // Check mounted before showing snackbar
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading farmer data. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VetConnect'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              }
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Home Tab
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom App Bar with Logo and Book Button
                Container(
                  padding: EdgeInsets.fromLTRB(16, 40, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset(
                            'assets/images/Group 2.png',
                            height: 40,
                          ),
                          Text(
                            'Welcome, ${_farmerName ?? 'Farmer'}!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VetSearchResultsPage(
                                searchQuery: '',
                              ),
                            ),
                          );
                        },
                        icon: Icon(Icons.pets, color: Colors.white),
                        label: Text('Book a Vet'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF008080),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Search Bar
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Color(0xFFE8F3F3),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: Colors.grey),
                        SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Find veterinarians by region...',
                              border: InputBorder.none,
                              suffixIcon: _isSearching 
                                ? Container(
                                    width: 20,
                                    height: 20,
                                    padding: EdgeInsets.all(8),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.grey,
                                    ),
                                  )
                                : IconButton(
                                    icon: Icon(Icons.search),
                                    onPressed: _handleSearch,
                                  ),
                            ),
                            onSubmitted: (_) => _handleSearch(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Search Results
                if (_searchResults != null)
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Search Results',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        ..._searchResults!.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ViewVetProfile(
                                    vetId: doc.id,
                                    vetData: data,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin: EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(12),
                                    ),
                                    child: Image.network(
                                      data['profileImage'] ?? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(data['fullName'] ?? 'Vet')}&background=random',
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Dr. ${data['fullName'] ?? ''}',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Specialist in ${data['specialization'] ?? 'Veterinary Medicine'} | ${data['region'] ?? ''}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Icons.star, color: Colors.amber, size: 16),
                                            Text(
                                              ' ${data['rating'] ?? '4.5'} • ',
                                              style: TextStyle(color: Colors.grey[600]),
                                            ),
                                            Icon(
                                              Icons.circle,
                                              color: Colors.green,
                                              size: 8,
                                            ),
                                            Text(
                                              ' Online',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            Spacer(),
                                            Text(
                                              '\$${data['charge'] ?? '50'}/visit',
                                              style: TextStyle(
                                                color: Color(0xFF008080),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                if (_searchResults == null) ...[
                  // Quick Actions
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildQuickAction(
                          icon: Icons.message,
                          label: 'Messages',
                          color: Colors.teal,
                          onTap: () => setState(() => _selectedIndex = 2),
                        ),
                        _buildQuickAction(
                          icon: Icons.warning,
                          label: 'Emergency\nRequest',
                          color: Colors.red,
                          onTap: () {
                            // Handle emergency request
                          },
                        ),
                        _buildQuickAction(
                          icon: Icons.book,
                          label: 'Health Tips',
                          color: Colors.teal,
                          onTap: () {
                            // Navigate to health tips
                          },
                        ),
                      ],
                    ),
                  ),

                  // Animal Categories
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildAnimalCategory(icon: '🐄', label: 'Cow'),
                        SizedBox(width: 16),
                        _buildAnimalCategory(icon: '🐑', label: 'Sheep'),
                        SizedBox(width: 16),
                        _buildAnimalCategory(icon: '🐐', label: 'Goat'),
                        SizedBox(width: 16),
                        _buildAnimalCategory(icon: '🐷', label: 'Pig'),
                      ],
                    ),
                  ),

                  // Appointments Section
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Appointments',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _selectedIndex = 1);
                          },
                          child: Text(
                            'View All',
                            style: TextStyle(
                              color: Colors.teal,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Appointments List
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('appointments')
                          .where('farmerId', isEqualTo: _auth.currentUser?.uid)
                          .where('status', isEqualTo: 'confirmed')
                          .orderBy('dateTime')
                          .limit(3)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text('Error loading appointments');
                        }

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        }

                        final appointments = snapshot.data?.docs ?? [];

                        return Row(
                          children: appointments.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final dateTime = (data['dateTime'] as Timestamp).toDate();
                            return Container(
                              width: 280,
                              margin: EdgeInsets.only(right: 16),
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 30,
                                            backgroundImage: NetworkImage(
                                              data['vetImage'] ?? 'https://via.placeholder.com/60',
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                data['vetName'] ?? 'Dr. Name',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              Text(
                                                '${data['appointmentType'] ?? 'Consultation'} - ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.hour >= 12 ? 'PM' : 'AM'}',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),

                  // Available Vets Section
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Available Veterinarians',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Navigate to all vets page
                          },
                          child: Text(
                            'View All',
                            style: TextStyle(
                              color: Colors.teal,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Vets List
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('users')
                          .where('userType', isEqualTo: 'Veterinarian')
                          .where('isOnline', isEqualTo: true)
                          .limit(5)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text('Error loading veterinarians');
                        }

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        }

                        final vets = snapshot.data?.docs ?? [];

                        return Row(
                          children: vets.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return Container(
                              width: 300,
                              margin: EdgeInsets.only(right: 16, bottom: 16),
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(12),
                                      ),
                                      child: Image.network(
                                        data['profileImage'] ?? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(data['fullName'] ?? 'Vet')}&background=random',
                                        height: 200,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Dr. ${data['fullName'] ?? 'Name'}',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Icon(Icons.star, color: Colors.amber, size: 16),
                                              Text(
                                                ' ${data['rating'] ?? '4.5'} stars',
                                                style: TextStyle(color: Colors.grey),
                                              ),
                                              Text(
                                                ' • ${data['specialization'] ?? 'General'} • \$${data['charge'] ?? '50'}',
                                                style: TextStyle(color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.circle,
                                                color: Colors.green,
                                                size: 12,
                                              ),
                                              Text(
                                                ' Online',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),

                  // Health Tips Section
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Health Tips & Articles',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        _buildHealthTipCard(
                          title: 'Cattle Care',
                          icon: Icons.article,
                          color: Color(0xFFE8F3F3),
                        ),
                        SizedBox(height: 12),
                        _buildHealthTipCard(
                          title: 'Sheep Health',
                          icon: Icons.health_and_safety,
                          color: Color(0xFFE8F3F3),
                        ),
                        SizedBox(height: 12),
                        _buildHealthTipCard(
                          title: 'Poultry Tips',
                          icon: Icons.pets,
                          color: Color(0xFFE8F3F3),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Appointments Tab
          FarmerAppointmentsPage(),
          // Messages Tab
          FarmerMessagesPage(),
          // Profile Tab
          FarmerProfilePage(),
        ],
      ),
      bottomNavigationBar: FarmerBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatListPage()),
          );
        },
        child: const Icon(Icons.chat),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimalCategory({
    required String icon,
    required String label,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Text(icon, style: TextStyle(fontSize: 24)),
          SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildHealthTipCard({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Icon(icon),
        ],
      ),
    );
  }
} 