import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vetconnect/pages/login_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(snapshot.data!.uid)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingScreen();
              }

              if (userSnapshot.hasError || userSnapshot.data?.data() == null) {
                return LoginPage();
              }

              final userData = userSnapshot.data!.data()! as Map<String, dynamic>;
              final userType = userData['userType']?.toString().toLowerCase() ?? '';

              // Schedule navigation after current build phase
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _navigateBasedOnUserType(context, userType);
              });

              return _buildLoadingScreen(); // Temporary screen while navigating
            },
          );
        }

        return LoginPage();
      },
    );
  }

  void _navigateBasedOnUserType(BuildContext context, String userType) {
    String route;
    if (userType == 'farmer') {
      route = '/farmer-home';
    } else if (userType == 'veterinarian' || userType == 'vet') {
      route = '/vet-home';
    } else {
      route = '/homepage';
    }

    Navigator.of(context).pushReplacementNamed(route);
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}