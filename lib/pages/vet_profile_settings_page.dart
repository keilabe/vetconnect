import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../pages/login_page.dart';

class VetProfileSettingsPage extends StatefulWidget {
  const VetProfileSettingsPage({super.key});

  @override
  State<VetProfileSettingsPage> createState() => _VetProfileSettingsPageState();
}

class _VetProfileSettingsPageState extends State<VetProfileSettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _experienceController = TextEditingController();
  final _phoneController = TextEditingController();
  final _regionController = TextEditingController();
  String? _profileImageUrl;
  bool _isLoading = false;
  String? _selectedSpecialization;

  final List<String> _specializations = [
    'Small Animal Specialization',
    'Large Animal Specialization',
    'Indigenous Pet Specialization',
    'Exotic Pet Specialization'
  ];

  @override
  void initState() {
    super.initState();
    _loadVetProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _experienceController.dispose();
    _phoneController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  Future<void> _loadVetProfile() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final vetDoc = await _firestore.collection('veterinarians').doc(userId).get();
      if (vetDoc.exists) {
        final data = vetDoc.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = data['fullName'] ?? '';
          _selectedSpecialization = data['specialization'] ?? _specializations[0];
          _experienceController.text = data['experience']?.toString() ?? '';
          _phoneController.text = data['phoneNumber'] ?? '';
          _regionController.text = data['region'] ?? '';
          _profileImageUrl = data['profileImage'];
        });
      }
    } catch (e) {
      print('Error loading vet profile: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        setState(() => _isLoading = true);
        
        // TODO: Implement image upload to Firebase Storage
        // For now, we'll just update the UI
        setState(() {
          _profileImageUrl = image.path;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore.collection('veterinarians').doc(userId).update({
        'fullName': _nameController.text,
        'specialization': _selectedSpecialization,
        'experience': int.tryParse(_experienceController.text) ?? 0,
        'phoneNumber': _phoneController.text,
        'region': _regionController.text,
        'profileImage': _profileImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error saving vet profile: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      // Close the dialog first
      Navigator.pop(context);
      
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Sign out
      await FirebaseAuth.instance.signOut();
      
      // Remove loading indicator
      Navigator.pop(context);
      
      // Navigate to login page and clear the stack
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error logging out: $e');
      // Remove loading indicator if it's showing
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to logout. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Settings'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _profileImageUrl != null
                        ? NetworkImage(_profileImageUrl!)
                        : null,
                    child: _profileImageUrl == null
                        ? Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Colors.teal,
                      radius: 18,
                      child: IconButton(
                        icon: Icon(Icons.camera_alt, size: 18, color: Colors.white),
                        onPressed: _isLoading ? null : _pickImage,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedSpecialization,
                decoration: InputDecoration(
                  labelText: 'Specialization',
                  border: OutlineInputBorder(),
                ),
                items: _specializations.map((String specialization) {
                  return DropdownMenuItem<String>(
                    value: specialization,
                    child: Text(specialization),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedSpecialization = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select your specialization';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _experienceController,
                decoration: InputDecoration(
                  labelText: 'Years of Experience',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your experience';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _regionController,
                decoration: InputDecoration(
                  labelText: 'Region',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your region';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Save Profile',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => AlertDialog(
                        title: Text('Logout'),
                        content: Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => _handleLogout(context),
                            child: Text(
                              'Logout',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 16,
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
}