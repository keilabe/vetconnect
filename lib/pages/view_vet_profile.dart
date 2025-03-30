import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';
import 'booking_vet_page.dart';

class ViewVetProfile extends StatelessWidget {
  final String vetId;
  final Map<String, dynamic> vetData;

  const ViewVetProfile({
    super.key,
    required this.vetId,
    required this.vetData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Vet Profile',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Image
            Container(
              width: 150,
              height: 150,
              margin: EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(vetData['profileImage'] ?? 'https://via.placeholder.com/150'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            
            // Vet Name
            Text(
              'Dr. ${vetData['fullName'] ?? ''}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF008080),
              ),
            ),
            
            // Specialization and Location
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 20),
              child: Text(
                'Specialist in ${vetData['specialization'] ?? 'Veterinary Medicine'} | ${vetData['region'] ?? 'Location'}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),

            // Experience and Qualifications
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${vetData['experience'] ?? '10'} years Experience',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF008080),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(' • ', style: TextStyle(color: Color(0xFF008080))),
                  Text(
                    vetData['qualifications'] ?? 'DVM, MS Qualifications',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF008080),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Reviews Section
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reviews',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Navigate to all reviews
                        },
                        child: Text(
                          'See All',
                          style: TextStyle(
                            color: Color(0xFF008080),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Review Items
                  _buildReviewItem(
                    name: 'Lysandra F.',
                    rating: 4,
                    time: '3 days ago',
                    comment: 'Dr. Voss was incredibly helpful and knowledgeable. My dog is doing much better now!',
                    imageUrl: 'https://via.placeholder.com/50',
                  ),
                  SizedBox(height: 16),
                  _buildReviewItem(
                    name: 'Orion T.',
                    rating: 4,
                    time: '3 days ago',
                    comment: 'Highly recommend! Very professional and caring.',
                    imageUrl: 'https://via.placeholder.com/50',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Chat Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        receiverId: vetId,
                        receiverName: vetData['fullName'] ?? '',
                        receiverImage: vetData['profileImage'] ?? '',
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.chat_bubble_outline, color: Colors.white),
                label: Text('Chat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF008080),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12),
            // Book Appointment Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingVetPage(
                        vetId: vetId,
                        vetData: vetData,
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.check, color: Colors.white),
                label: Text('Book Appointment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF008080),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem({
    required String name,
    required int rating,
    required String time,
    required String comment,
    required String imageUrl,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(imageUrl),
                radius: 20,
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    time,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Spacer(),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 20,
                  );
                }),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(comment),
        ],
      ),
    );
  }
} 