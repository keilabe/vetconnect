import 'package:flutter/material.dart';
import 'package:vetconnect/pages/farmer_appointment.dart';
import 'package:vetconnect/pages/messages_page.dart';
import 'package:vetconnect/pages/settings_page.dart';
import 'package:vetconnect/pages/vet_listing_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});


  @override
  State<StatefulWidget> createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage> {

  String? userName;
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        toolbarHeight: 100,
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 200,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 40,
                child: Image.asset(
                  'assets/images/Group 2.png',
                  fit: BoxFit.contain,
                ),
              ),
              Text(
                "Welcome, Farmer Elijah!",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              )
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: MaterialButton(
              onPressed: (){
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VetListingPage(),
                  ),
                );
              },
              color: Colors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pets, color: Colors.white),            
                  SizedBox(width: 8),
                  Text(
                    "Book a Vet",
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _myHomePageBodyContainer(),
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

  Widget _myHomePageBodyContainer() {
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _searchVetNotificationsAndAnimalSelection(),
          SizedBox(height: 24),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _appointmentsAndVetRatingCards(),
          ),
          SizedBox(height: 24),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _healthTipsAndArticles(),
          ),
          SizedBox(height: 16), // Bottom padding
        ],
      ),
    ); 
  }

  Widget _searchVetNotificationsAndAnimalSelection() {
    return Container(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                // Search bar with location
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.grey[600]),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Enter your location',
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              fontFamily: 'Inter',
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.search, color: Colors.teal),
                        onPressed: () {
                          // Handle search with location
                        },
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 20),
                
                // Action buttons row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.message,
                      label: 'Messages',
                      onTap: () {
                        // Navigate to messages
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.emergency,
                      label: 'Emergency',
                      onTap: () {
                        // Navigate to emergency
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.health_and_safety,
                      label: 'Health Tips',
                      onTap: () {
                        // Navigate to health tips
                      },
                    ),
                  ],
                ),
                
                SizedBox(height: 20),
                
                // Animal categories
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildAnimalFilter(
                        icon: Icons.pets,
                        label: 'Cows',
                        onTap: () {
                          // Filter for cow specialists
                        },
                      ),
                      _buildAnimalFilter(
                        icon: Icons.pets,
                        label: 'Goats',
                        onTap: () {
                          // Filter for goat specialists
                        },
                      ),
                      _buildAnimalFilter(
                        icon: Icons.pets,
                        label: 'Sheep',
                        onTap: () {
                          // Filter for sheep specialists
                        },
                      ),
                      _buildAnimalFilter(
                        icon: Icons.pets,
                        label: 'Poultry',
                        onTap: () {
                          // Filter for poultry specialists
                        },
                      ),
                      _buildAnimalFilter(
                        icon: Icons.pets,
                        label: 'Pets',
                        onTap: () {
                          // Filter for pet specialists
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.teal),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAnimalFilter({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20),
              SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _appointmentsAndVetRatingCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _appointmentsTitleAndViewAll(),
        SizedBox(height: 16),
        _doctorAppointmentScheduleHorizontalSlides(),
        SizedBox(height: 24),
        _titleRatingAndViewAll(),
        SizedBox(height: 16),
        _vetRatingAndImageCarousel(),
      ],
    );
  }

  Widget _appointmentsTitleAndViewAll() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      children: [
        Text(
          "Appointments", 
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            fontWeight: FontWeight.w600            
          ),         
        ),
        SizedBox(width: 5,),
        TextButton(onPressed: (){}, 
        child: Text(
          "View All",   
          style: TextStyle(
            color: Colors.teal,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          ),
          ),
      ],
    );
  }

  Widget _doctorAppointmentScheduleHorizontalSlides() {
    return SizedBox(
      height: 220,
      child: ListView(
        physics: BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        children: [
          _buildAppointmentCard(
            doctorImage: 'assets/images/vet1.png',
            doctorName: 'Dr. Sarah Wilson',
            appointmentType: 'In-Person',
            dateTime: 'Today, 2:30 PM'
          ),
          _buildAppointmentCard(
            doctorImage: 'assets/images/vet2.png',
            doctorName: 'Dr. John Smith',
            appointmentType: 'Video Call', 
            dateTime: 'Tomorrow, 10:00 AM'
          ),
          _buildAppointmentCard(
            doctorImage: 'assets/images/vet3.png',
            doctorName: 'Dr. Maria Garcia',
            appointmentType: 'In-Person',
            dateTime: 'Wed, 4:15 PM'
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard({
    required String doctorImage,
    required String doctorName,
    required String appointmentType,
    required String dateTime,
  }) {
    return Container(
      width: 280,
      margin: EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.asset(
              doctorImage,
              height: 110,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctorName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      appointmentType == 'Video Call' ? Icons.videocam : Icons.person,
                      size: 16,
                      color: Colors.teal,
                    ),
                    SizedBox(width: 4),
                    Text(
                      appointmentType,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.teal,
                    ),
                    SizedBox(width: 4),
                    Text(
                      dateTime,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _titleRatingAndViewAll() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      children: [
        Text(
          "Vet Ratings", 
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            fontWeight: FontWeight.w600            
          ),         
        ),
        SizedBox(width: 5,),
        TextButton(onPressed: (){}, 
        child: Text(
          "View All",   
          style: TextStyle(
            color: Colors.teal,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          ),
          ),
      ],
    );
  }

  Widget _vetRatingAndImageCarousel() {
    return SizedBox(
      height: 220,
      child: ListView(
        physics: BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        children: [
          _buildVetCard(
            image: "assets/images/vet1.png",
            name: "Dr. Sarah Wilson",
            rating: 4.8,
            specialization: "Small Animal Specialist",
            charge: "\$50/consultation",
            isOnline: true,
            lastSeen: null
          ),
          _buildVetCard(
            image: "assets/images/vet2.png", 
            name: "Dr. James Miller",
            rating: 4.9,
            specialization: "Large Animal Specialist",
            charge: "\$60/consultation",
            isOnline: false,
            lastSeen: "2 hours ago"
          ),
          _buildVetCard(
            image: "assets/images/vet3.png",
            name: "Dr. Emily Brown",
            rating: 4.7,
            specialization: "Exotic Pet Specialist",
            charge: "\$55/consultation", 
            isOnline: true,
            lastSeen: null
          ),
        ],
      ),
    );
  }

  Widget _buildVetCard({
    required String image,
    required String name,
    required double rating,
    required String specialization,
    required String charge,
    required bool isOnline,
    String? lastSeen,
  }) {
    return Container(
      width: 280,
      margin: EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.asset(
                  image,
                  height: 110,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      SizedBox(width: 4),
                      Text(
                        rating.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOnline ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                if (!isOnline && lastSeen != null)
                  Text(
                    'Last seen $lastSeen',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontFamily: 'Inter',
                    ),
                  ),
                SizedBox(height: 4),
                Text(
                  specialization,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontFamily: 'Inter',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  charge,
                  style: TextStyle(
                    color: Colors.teal,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _healthTipsAndArticles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Health Tips & Articles",
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16),
        _buildHealthTipCard(
          title: "Cattle Care",
          image: "assets/images/cattle.jpg",
          icon: Icons.article_outlined,          
          onTap: () {
            // Navigate to cattle care articles
          },
        ),
        SizedBox(height: 12),
        _buildHealthTipCard(
          title: "Sheep Health",
          image: "assets/images/sheep.jpg",
          icon: Icons.pets_outlined,
          onTap: () {
            // Navigate to sheep health articles
          },
        ),
        SizedBox(height: 12),
        _buildHealthTipCard(
          title: "Poultry Tips",
          image: "assets/images/poultry.jpg",
          icon: Icons.egg_outlined,
          onTap: () {
            // Navigate to poultry tips articles
          },
        ),
      ],
    );
  }

  Widget _buildHealthTipCard({
    required String title,
    required String image,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: DecorationImage(
            image: AssetImage(image),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.4),
              BlendMode.darken,
            ),
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.teal,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onItemTapped(int index, BuildContext context) {
    if (index == _selectedIndex) return;

    Widget page;
    switch (index) {     
      case 1:
        page = FarmerAppointment();
        break;
      case 2:
        page = MessagesPage();
        break;
         case 3:
        page = SettingsPage();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }
}