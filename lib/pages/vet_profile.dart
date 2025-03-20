import 'package:flutter/material.dart';
import 'package:vetconnect/pages/booking_vet_page.dart';

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final curatedTheme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: curatedTheme.scaffoldBackgroundColor,
      child: child,
    );
  }

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

class VetProfile extends StatefulWidget{
  const VetProfile({super.key});


  @override
  State<StatefulWidget> createState() {
    return _VetProfileState();
  }
}

class _VetProfileState extends State<VetProfile> {
  int _selectedIndex = 0;
  double? _deviceHeight, _deviceWidth;


  @override
  Widget build(BuildContext context) {
    _deviceHeight = MediaQuery.of(context).size.height;
    _deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(      
      body: CustomScrollView(
      slivers: [
        SliverPersistentHeader(
          delegate: _SliverAppBarDelegate(
            minHeight: 50.0,
            maxHeight: 100.0,
            child: AppBar(
              title: Text('Vet Profile'),
              centerTitle: true,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            child: Column(
              children: [
                _socialPhotoProfile(),
                _clientReview(),
                _chatButton(),
                SizedBox(height: _deviceHeight! * 0.05),
                _bookAppointmentButton(),
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

  Widget _socialPhotoProfile(){
    return Container(

      child: Column(
        children: [
          _avatarProfile(),
          _nameProfile(),
          
        ]
      ), 
    );
  }

  Widget _avatarProfile(){
    return const Center(
      child: CircleAvatar(
          radius: 50,
          backgroundImage: AssetImage('assets/images/vet1.png'),
        ),
    );    
  }

  Widget _nameProfile(){
    return RichText(
      text: const TextSpan(
        style: TextStyle(
          fontFamily: 'Inter',          
        ),
        children: [
          TextSpan(
            text: 'Dr. Lila Montgomery',
            style: TextStyle(
              fontSize: 22,            
            ),
          ),          
          TextSpan(
            text: '\nSpecialist in Cow Health & Orthopedics | \n Kiambu Ke',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          TextSpan(
            text: '\n10 years of experience DVM, MS Qualifications',
            style: TextStyle(
              fontSize: 16,
              color: Colors.teal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _clientReview(){
    return Container(
      child: Column(
        children: [
          _clientReviewTitle(),
          _clientReviewList(),
        ],
      ),
    );
  }

  Widget _clientReviewTitle(){
    return const Row(
      children: [
        Text('Reviews',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'Roboto',
        ),        
        ),
        Spacer(),
        Text('See All',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.teal,
        ),
        ),
      ],
    );
  }

  Widget _clientReviewList() {
    return SizedBox(
      height: 300, // Fixed height for scrollable area
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: 5, // Number of reviews to show
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _clientProfile(),
                _clientReviewItem(),
                const Divider(height: 16, thickness: 1), // Separator between reviews
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _clientProfile(){
    return Container(
      child: Row(
        children: [
          _clientProfileImage(),
          _clientProfileName(),         
        ],
      ),
    );
  }

  Widget _clientProfileImage(){
    return Container(
      child: CircleAvatar(
        radius: 20,
        backgroundImage: AssetImage('assets/images/client.jpg'),
      ),
    );
  }

  Widget _clientProfileName(){
    return Container(
      padding: const EdgeInsets.only(left: 12),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lysandra F.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
              color: Colors.black,
            ),
          ),
          Text(
            '2 hours ago',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontFamily: 'Roboto',
            ),
          ),
        ],
      ),
    );
  }

  Widget _clientReviewItem(){
    return Container(    padding: const EdgeInsets.only(left: 12),
      child: Column(
        children: [
          _clientProfileRating(),
          _clientReviewComment(),
        ],
      ),
    );
  }
  Widget _clientProfileRating(){
    return Container(
      padding: const EdgeInsets.only(left: 12),
      child: const Row(
        children: [
          Text(
            '4.5',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Icon(
            Icons.star,
            color: Colors.teal,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _clientReviewComment(){
    return Container(
      padding: const EdgeInsets.only(left: 12),
      child: const Text('Dr. Voss was incredibly helpful and knowledgeable.\n My dog is doing much better now!',
      style: TextStyle(
        fontSize: 15,
        fontFamily: 'PublicSans',        
      ),),
    );
  }

  Widget _chatButton() {
    return SizedBox(
      width: _deviceWidth! * 0.3,
      child: ElevatedButton(
        onPressed: (){},
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: Colors.teal,
          fixedSize: Size.fromHeight(55), 
        ),
        child: Stack(
          children: [
            Positioned(
              left: 10,
              top: 0,
              bottom: 0,
              child: Container(
                alignment: Alignment.center,
                child: Icon(Icons.messenger_outline_sharp, color: Colors.white),
              ),
            ),
            Center(
              child: Text(
                "Chat",
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bookAppointmentButton() {
    return SizedBox(
      width: _deviceWidth! * 0.35,
      child: ElevatedButton(
        onPressed: (){
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => BookingVetPage()),
          );
        },
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: Colors.teal,
          fixedSize: Size.fromHeight(55), 
        ),
        child: Stack(
          children: [
            Positioned(
              left: 10,
              top: 0,
              bottom: 0,
              child: Container(
                alignment: Alignment.center,
                child: Icon(Icons.calendar_month_outlined, color: Colors.white),
              ),
            ),
            Center(
              child: Text(
                "Book an appointment",
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  
}