import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'farmer_home_page.dart';
import 'vet_home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _selectedUserType = 'farmer'; // Default to farmer

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);
      print('🔐 Login attempt - Email: ${_emailController.text.trim()}, User Type: $_selectedUserType');

      // Sign in with Firebase Auth
      print('📱 Attempting Firebase Authentication...');
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final userId = userCredential.user?.uid;
      print('👤 Firebase Auth successful - User ID: $userId');
      
      if (userId == null) throw Exception('User ID not found');

      // First check the user's role in the users collection
      print('🔍 Checking user role in Firestore - Path: users/$userId');
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      print('📄 User document exists: ${userDoc.exists}');
      if (!userDoc.exists) {
        throw Exception('User account not found. Please contact support.');
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      print('📋 User data retrieved: ${userData.toString()}');
      
      // Get userType and normalize it
      final storedUserType = (userData['userType'] as String?)?.toLowerCase();
      print('👥 User role from Firestore: $storedUserType');

      if (storedUserType == null) {
        print('❌ User type is null in Firestore document');
        throw Exception('User type not found. Please contact support.');
      }

      // Convert the stored type to match our internal types
      final normalizedStoredType = storedUserType == 'veterinarian' ? 'vet' : storedUserType;
      
      // Verify that the user's role matches their selected type
      print('✅ Comparing selected type ($_selectedUserType) with normalized type ($normalizedStoredType)');
      if (normalizedStoredType != _selectedUserType) {
        print('❌ Type mismatch - Selected: $_selectedUserType, Actual: $normalizedStoredType');
        final displayType = _selectedUserType == 'vet' ? 'Veterinarian' : 'Farmer';
        throw Exception('Invalid user type. Please select $displayType to login.');
      }

      if (!mounted) return;

      // Navigate based on user role
      print('🚀 Navigation - Role: $normalizedStoredType');
      if (normalizedStoredType == 'farmer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => FarmerHomePage()),
        );
      } else if (normalizedStoredType == 'vet') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => VetHomePage()),
        );
      } else {
        print('❌ Invalid role for navigation: $normalizedStoredType');
        throw Exception('Invalid user role');
      }
    } on FirebaseAuthException catch (e) {
      print('🚫 Firebase Auth Error - Code: ${e.code}, Message: ${e.message}');
      String message = 'An error occurred during login';
      if (e.code == 'user-not-found') {
        message = 'No user found with this email';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      }
      _showErrorDialog(message);
    } catch (e) {
      print('❌ General Error: ${e.toString()}');
      _showErrorDialog(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print('🏁 Login process completed');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Custom App Bar with Background Image
          Container(
            height: 100, // Increased height for the app bar area
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/cow_vet.png'),
              fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    Text(
                      'Vet Connect',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.help_outline, color: Colors.white),
                      onPressed: () {
                        // Implement help functionality
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Main Content
          Expanded(
        child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                      // Welcome Back Text
                Text(
                  'Welcome Back!',
                  style: TextStyle(
                          fontSize: 32,
                    fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),
                      // Email/Phone Field
                TextFormField(
                        controller: _emailController,
                  decoration: InputDecoration(
                          hintText: 'Phone number / Email',
                          filled: true,
                          fillColor: Color(0xFFF5F8FA),
                    border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                    ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                      // Password Field
                TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                  decoration: InputDecoration(
                          hintText: 'Password',
                          filled: true,
                          fillColor: Color(0xFFF5F8FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                      ),
                      SizedBox(height: 24),
                      // User Type Selection
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Color(0xFFF5F8FA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedUserType,
                            isExpanded: true,
                            items: [
                              DropdownMenuItem(
                                value: 'farmer',
                                child: Text('Farmer'),
                              ),
                              DropdownMenuItem(
                                value: 'vet',
                                child: Text('Veterinarian'),
                              ),
                            ],
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedUserType = newValue;
                                });
                              }
                            },
                          ),
                        ),
                ),
                SizedBox(height: 24),
                      // Social Login Buttons
                      ElevatedButton(
                        onPressed: () {
                          // Implement Apple login
                        },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.apple, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Login with Apple'),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () {
                          // Implement Google login
                        },
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/images/google.png', height: 24),
                            SizedBox(width: 8),
                            Text('Login with Google'),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Implement Facebook login
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.facebook, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Login with Facebook', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      // Login Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text('Login'),
                      ),
                      SizedBox(height: 16),
                      // Forgot Password
                      TextButton(
                        onPressed: () {
                          // Implement forgot password
                        },
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(color: Colors.grey),
                        ),
                ),
                SizedBox(height: 16),
                      // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                          Text("DON'T HAVE AN ACCOUNT? "),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      child: Text(
                              'SIGN UP',
                        style: TextStyle(
                          color: Colors.teal,
                                fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
            ),
          ),
        ],
      ),
    );
  }
}