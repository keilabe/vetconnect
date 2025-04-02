import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _log(String message, [Object? error]) {
    if (error != null) {
      print('❌ AuthService: $message');
      print('📝 Error details: $error');
    } else {
      print('📱 AuthService: $message');
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      _log('Attempting sign in with email: $email');
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Verify user document exists
        final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
        
        if (!userDoc.exists) {
          _log('User document not found, creating one');
          // Create user document if it doesn't exist
          await _createUserDocument(
            userCredential.user!.uid,
            email,
            email.split('@')[0], // Temporary name
            'farmer', // Default type
            '', // Empty phone number
          );
        } else {
          _log('User document found, updating online status');
          await _updateUserStatus(userCredential.user!.uid, true);
        }
      }

      _log('Sign in successful - UID: ${userCredential.user?.uid}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      _log('Firebase Auth Error', e);
      rethrow;
    } on FirebaseException catch (e) {
      _log('Firestore Error', e);
      rethrow;
    } catch (e) {
      _log('Unexpected error during sign in', e);
      rethrow;
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
    String fullName,
    String userType,
    String phoneNumber,
  ) async {
    try {
      _log('Attempting registration for: $email');
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Create user document
        await _createUserDocument(
          userCredential.user!.uid,
          email,
          fullName,
          userType,
          phoneNumber,
        );
      }

      _log('Registration successful - UID: ${userCredential.user?.uid}');
      return userCredential;
    } catch (e) {
      _log('Registration failed', e);
      rethrow;
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(
    String uid,
    String email,
    String fullName,
    String userType,
    String phoneNumber,
  ) async {
    try {
      _log('Creating user document for UID: $uid');
      
      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'fullName': fullName,
        'userType': userType,
        'phoneNumber': phoneNumber,
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'profileImage': null,
      });

      _log('User document created successfully');
    } catch (e) {
      _log('Failed to create user document', e);
      rethrow;
    }
  }

  // Update user's online status
  Future<void> _updateUserStatus(String uid, bool isOnline) async {
    try {
      _log('Updating online status: $isOnline for UID: $uid');
      
      await _firestore.collection('users').doc(uid).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });

      _log('Online status updated successfully');
    } catch (e) {
      _log('Failed to update online status', e);
      // Don't rethrow as this is not critical
      print('Error updating online status: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _log('Attempting sign out');
      
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        await _updateUserStatus(uid, false);
      }

      await _auth.signOut();
      _log('Sign out successful');
    } catch (e) {
      _log('Sign out failed', e);
      rethrow;
    }
  }

  // Get current user's type with retry mechanism
  Future<String?> getCurrentUserType() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _log('No authenticated user found');
        return null;
      }

      _log('Fetching user type for UID: ${user.uid}');
      
      // Add retry mechanism
      for (int i = 0; i < 3; i++) {
        try {
          final doc = await _firestore.collection('users').doc(user.uid).get();
          if (doc.exists) {
            final userType = doc.data()?['userType'] as String?;
            _log('User type found: $userType');
            return userType;
          } else if (i < 2) {
            _log('User document not found, retrying...');
            await Future.delayed(Duration(seconds: 1));
          }
        } catch (e) {
          if (i < 2) {
            _log('Error fetching user type, retrying...', e);
            await Future.delayed(Duration(seconds: 1));
          } else {
            rethrow;
          }
        }
      }

      _log('User document not found after retries');
      return null;
    } catch (e) {
      _log('Failed to get user type', e);
      return null;
    }
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      if (currentUser == null) return null;
      
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }
} 