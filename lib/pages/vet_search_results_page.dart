import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vetconnect/pages/booking_vet_page.dart';

class VetSearchResultsPage extends StatefulWidget {
  final String searchQuery;

  const VetSearchResultsPage({
    Key? key,
    required this.searchQuery,
  }) : super(key: key);

  @override
  State<VetSearchResultsPage> createState() => _VetSearchResultsPageState();
}

class _VetSearchResultsPageState extends State<VetSearchResultsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<DocumentSnapshot>? _searchResults;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  Future<void> _performSearch() async {
    try {
      setState(() => _isLoading = true);
      
      print('Starting search with query: ${widget.searchQuery}');
      
      // Get all vets first
      final querySnapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'Veterinarian')
          .get();

      print('Found ${querySnapshot.docs.length} total vets');
      
      // Debug: Print all vets and their regions
      print('\nAll vets found:');
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print('Vet: ${data['fullName']}');
        print('Region: ${data['region']}');
        print('Type: ${data['userType']}');
        print('-------------------');
      }
      
      // Filter vets by region in memory (case-insensitive)
      final filteredDocs = querySnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final region = data['region']?.toString().toLowerCase() ?? '';
        final searchQuery = widget.searchQuery.toLowerCase();
        print('Comparing region: "$region" with search: "$searchQuery"');
        return region.contains(searchQuery);
      }).toList();

      print('\nFound ${filteredDocs.length} vets in region ${widget.searchQuery}');
      
      // Debug: Print filtered vet data
      print('\nFiltered vet details:');
      for (var doc in filteredDocs) {
        final data = doc.data() as Map<String, dynamic>;
        print('Vet ID: ${doc.id}');
        print('Name: ${data['fullName']}');
        print('Region: ${data['region']}');
        print('Type: ${data['userType']}');
        print('Specialization: ${data['specialization']}');
        print('Rating: ${data['rating']}');
        print('Online: ${data['isOnline']}');
        print('-------------------');
      }

      setState(() {
        _searchResults = filteredDocs;
        _isLoading = false;
      });
    } catch (e) {
      print('Error searching vets: $e');
      setState(() => _isLoading = false);
      
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching veterinarians. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vets in ${widget.searchQuery}'),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _searchResults == null || _searchResults!.isEmpty
              ? Center(
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
                        'No veterinarians found in ${widget.searchQuery}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _searchResults!.length,
                  itemBuilder: (context, index) {
                    final doc = _searchResults![index];
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
                              builder: (context) => BookingVetPage(
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
                                  data['profileImage'] ?? 'https://ui-avatars.com/api/?name=${data['fullName'] ?? 'Vet'}&background=random',
                                ),
                                onBackgroundImageError: (exception, stackTrace) {
                                  print('Error loading profile image: $exception');
                                },
                                child: data['profileImage'] == null
                                    ? Icon(Icons.person, size: 30, color: Colors.grey[600])
                                    : null,
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
                              // Rating and Online Status
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
                ),
    );
  }
} 