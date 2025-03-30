import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'farmer_home_page.dart';
import 'vet_home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

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
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      
      print('🔐 Login attempt - Email: $email, User Type: $_selectedUserType');
      print('📝 Password length: ${password.length} characters');

      // Sign in with Firebase Auth
      print('📱 Attempting Firebase Authentication...');
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = userCredential.user?.uid;
      print('👤 Firebase Auth successful - User ID: $userId');
      
      if (userId == null) throw Exception('User ID not found');

      // First check the user's role in the users collection
      print('🔍 Checking user role in Firestore - Path: users/$userId');
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      print('📄 User document exists: ${userDoc.exists}');
      if (!userDoc.exists) {
        print('📝 Creating new user document in Firestore...');
        // Create a new user document with default values
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'email': email,
          'userType': _selectedUserType,
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
          'lastLogin': FieldValue.serverTimestamp(),
          'uid': userId,
        });
        print('✅ User document created successfully');
        
        // Fetch the newly created document
        userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
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
      print('🔍 Error Details:');
      print('   - Email: ${_emailController.text.trim()}');
      print('   - User Type: $_selectedUserType');
      print('   - Stack Trace: ${e.stackTrace}');
      
      String message = 'An error occurred during login';
      if (e.code == 'user-not-found') {
        message = 'No user found with this email';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      } else if (e.code == 'invalid-credential') {
        message = 'Invalid credentials. Please check your email and password.';
      }
      _showErrorDialog(message);
    } catch (e) {
      print('❌ General Error: ${e.toString()}');
      print('🔍 Stack Trace: ${e is Error ? e.stackTrace : ''}');
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

  Future<void> _verifyUser(String email) async {
    try {
      print('🔍 Starting user verification for: $email');
      print('📱 Current Platform: ${defaultTargetPlatform.toString()}');
      
      // Print current Firebase config
      final FirebaseApp app = Firebase.app();
      final options = app.options;
      print('🔧 Firebase Configuration:');
      print('   - Project ID: ${options.projectId}');
      print('   - API Key: ${options.apiKey}');
      print('   - Auth Domain: ${options.authDomain}');
      
      // Check Firebase Auth
      print('📱 Checking Firebase Authentication...');
      try {
        final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
        print('📧 Sign-in methods available: ${methods.isEmpty ? "None" : methods.join(", ")}');
        
        if (methods.isEmpty) {
          print('❌ No sign-in methods found for this email');
          _showErrorDialog('No sign-in methods found for this email address');
          return;
        }
        print('✅ User exists in Firebase Auth');
        
        // Try to sign in anonymously to verify Firebase connection
        try {
          final userCred = await FirebaseAuth.instance.signInAnonymously();
          print('✅ Firebase Auth connection test successful');
          await userCred.user?.delete();  // Clean up test user
        } catch (e) {
          print('❌ Firebase Auth connection test failed: $e');
        }

      } catch (authError) {
        print('❌ Error checking authentication methods: $authError');
        _showErrorDialog('Error checking authentication: $authError');
        return;
      }

      // Check Firestore
      print('📚 Checking Firestore...');
      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .get();

        print('📊 Firestore query completed. Documents found: ${querySnapshot.docs.length}');

        if (querySnapshot.docs.isEmpty) {
          print('❌ User not found in Firestore');
          _showErrorDialog('User not found in Firestore database');
          return;
        }

        final userData = querySnapshot.docs.first.data();
        print('📋 User data found in Firestore:');
        userData.forEach((key, value) {
          print('   - $key: $value');
        });

        _showErrorDialog('User verified successfully!\nType: ${userData['userType']}');
      } catch (firestoreError) {
        print('❌ Error checking Firestore: $firestoreError');
        _showErrorDialog('Error checking Firestore: $firestoreError');
      }
    } catch (e) {
      print('❌ General error during verification: $e');
      _showErrorDialog('Error during verification: $e');
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your email address')),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Password Reset'),
          content: Text('Password reset email sent to $email. Please check your inbox.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      print('Password Reset Error: ${e.code} - ${e.message}');
      if (!mounted) return;
      
      String message = 'Failed to send password reset email';
      if (e.code == 'user-not-found') {
        message = 'No user found with this email address';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
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
                        onPressed: _resetPassword,
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      // Add Verify User button after the Forgot Password button
                //       TextButton(
                //         onPressed: () => _verifyUser(_emailController.text.trim()),
                //         child: Text(
                //           'Verify User',
                //           style: TextStyle(color: Colors.blue),
                //         ),
                //       ),
                // SizedBox(height: 16),
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