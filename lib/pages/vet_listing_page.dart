import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'vet_profile.dart';

class VetListingPage extends StatefulWidget {
  const VetListingPage({super.key});

  @override
  State<VetListingPage> createState() => _VetListingPageState();
}

class _VetListingPageState extends State<VetListingPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  String _selectedRegion = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Available Veterinarians'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _selectedRegion = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Enter region to search...',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),

          // Vet List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .where('userType', isEqualTo: 'Veterinarian')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading veterinarians'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                var vets = snapshot.data?.docs ?? [];

                // Filter vets based on region if search query is not empty
                if (_selectedRegion.isNotEmpty) {
                  vets = vets.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final region = (data['region'] ?? '').toString().toLowerCase();
                    return region.contains(_selectedRegion.toLowerCase());
                  }).toList();
                }

                // Show message if no vets found
                if (vets.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          _selectedRegion.isEmpty
                              ? 'Enter a region to search for veterinarians'
                              : 'No veterinarians found in $_selectedRegion',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: vets.length,
                  itemBuilder: (context, index) {
                    final doc = vets[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return Card(
                      margin: EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VetProfile(
                                vetId: doc.id,
                                vetData: data,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Vet Image
                              CircleAvatar(
                                radius: 30,
                                backgroundImage: NetworkImage(
                                  data['profileImage'] ?? 'https://via.placeholder.com/60',
                                ),
                              ),
                              SizedBox(width: 16),
                              // Vet Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dr. ${data['fullName'] ?? ''}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      data['specialization'] ?? 'General Veterinarian',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on, 
                                          size: 16, 
                                          color: Colors.grey[600]
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          data['region'] ?? 'Location not specified',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Rating
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.star, 
                                        size: 16, 
                                        color: Colors.amber
                                      ),
                                      Text(
                                        ' ${data['rating'] ?? '4.5'}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      data['isOnline'] == true ? 'Online' : 'Offline',
                                      style: TextStyle(
                                        color: data['isOnline'] == true 
                                          ? Colors.green 
                                          : Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 