import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _RegisterPageState();
  }
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final Map<String, FocusNode> _focusNodes = {};
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = false;
  
  String? _fullName;
  String? _phoneNumber;
  String? _email;
  String? _password;
  String? _confirmPassword;
  String? _userType;
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    // Initialize focus nodes for each text field without custom key event handling
    for (var field in ['Full Name', 'Phone Number', 'Email', 'Password', 'Confirm Password']) {
      _focusNodes[field] = FocusNode();
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    // Dispose all focus nodes
    for (var node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _handleRegistration() async {
    if (!mounted) return;  // Add mounted check
    
    developer.log('Starting registration process...', name: 'Registration');
    
    if (!_formKey.currentState!.validate()) {
      developer.log('Form validation failed', name: 'Registration');
      return;
    }
    
    if (!_agreedToTerms) {
      if (!mounted) return;
      developer.log('Terms not agreed to', name: 'Registration');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please agree to the terms and conditions')),
      );
      return;
    }

    _formKey.currentState!.save();
    
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      // Create authentication user
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _email!,
        password: _password!,
      );

      final User? user = userCredential.user;
      
      if (user != null) {
        // Store all users in the 'users' collection
        await _firestore.collection('users').doc(user.uid).set({
          'fullName': _fullName,
          'phoneNumber': _phoneNumber,
          'email': _email,
          'userType': _userType,
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
          'lastLogin': FieldValue.serverTimestamp(),
          'uid': user.uid,  // Add UID for easier querying
        });

        developer.log('User registered successfully in users collection with type: $_userType', name: 'Registration');
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration successful!')),
        );
        
        // Navigate to appropriate page based on user type
        if (!mounted) return;
        if (_userType == 'Veterinarian') {
          Navigator.pushReplacementNamed(context, '/vet_home');
        } else {
          Navigator.pushReplacementNamed(context, '/farmer_home');
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Registration failed';
      
      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'An account already exists for this email';
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      
      developer.log('Registration error: ${e.code}', name: 'Registration');
    } catch (e) {
      developer.log('Unexpected error during registration: $e', name: 'Registration');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        leading: Icon(Icons.arrow_back_ios_new, color: Colors.black),         
        title: Text(
          "Vet Connect",
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),       
        centerTitle: true,        
        actions: [
          Container(
            margin: EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
            ),
            child: IconButton(
              onPressed: (){}, 
              icon: Icon(Icons.question_mark_rounded, color: Colors.black, size: 20),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: _registerForm(),
      ),
    );
  }

  Widget _registerForm() {
    return Form(
      key: _formKey,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            SizedBox(height: 30),
            Text(
              "Create Your Account",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                fontFamily: 'PlusJakartaSans',
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Please fill in the form to continue",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w400,
                fontFamily: 'Inter',
              ),
            ),
            SizedBox(height: 30),
            _buildTextField(
              labelText: 'Full Name',
              icon: Icons.person,
              onSaved: (value) => _fullName = value,
              validator: (value) => value!.isEmpty ? 'Please enter your full name' : null,
            ),
            SizedBox(height: 20),
            _buildTextField(
              labelText: 'Phone Number',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              onSaved: (value) => _phoneNumber = value,
              validator: (value) => value!.isEmpty ? 'Please enter your phone number' : null,
            ),
            SizedBox(height: 20),
            _buildTextField(
              labelText: 'Email',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              onSaved: (value) => _email = value,
              validator: (value) => !value!.contains('@') ? 'Enter a valid email' : null,
            ),
            SizedBox(height: 20),
            _buildTextField(
              labelText: 'Password',
              icon: Icons.lock,
              obscureText: true,
              onSaved: (value) => _password = value,
              validator: (value) => value!.length < 6 ? 'Password must be at least 6 characters' : null,
              controller: _passwordController,
            ),
            SizedBox(height: 20),
            _buildTextField(
              labelText: 'Confirm Password',
              icon: Icons.lock,
              obscureText: true,
              onSaved: (value) => _confirmPassword = value,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'User Type',
                  prefixIcon: Icon(Icons.person_outline, color: Colors.black),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
                items: ['Farmer', 'Veterinarian'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                validator: (value) => value == null ? 'Please select a user type' : null,
                onChanged: (value) {
                  setState(() {
                    _userType = value;
                  });
                },
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Checkbox(
                  value: _agreedToTerms,
                  onChanged: (value) {
                    setState(() {
                      _agreedToTerms = value ?? false;
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    'I agree to the Terms and Conditions',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Create Account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
              ),
            ),
            SizedBox(height: 20),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "ALREADY HAVE AN ACCOUNT? ",            
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Inter',
                    ),
                  ),
                  TextSpan(
                    text: "LOGIN",
                    style: TextStyle(
                      color: Colors.teal,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String labelText,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    required Function(String?) onSaved,
    required String? Function(String?) validator,
    TextEditingController? controller,
  }) {
    return SizedBox(
      width: double.infinity,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        focusNode: _focusNodes[labelText],
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: Icon(icon, color: Colors.black),
          filled: true,
          fillColor: Colors.grey.shade200,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 15),
        ),
        validator: validator,
        onSaved: onSaved,
      ),
    );
  }
}