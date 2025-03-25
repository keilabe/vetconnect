import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vetconnect/firebase_options.dart';
import 'package:vetconnect/pages/booking_vet_page.dart';
import 'package:vetconnect/pages/confirm_and_pay_page.dart';
import 'package:vetconnect/pages/home_page.dart';
import 'package:vetconnect/pages/login_page.dart';
import 'package:vetconnect/pages/payment_success_screen_page.dart';
import 'package:vetconnect/pages/register_page.dart';
import 'package:vetconnect/pages/splash_screen1.dart';
import 'package:vetconnect/pages/splash_screen2.dart';
import 'package:vetconnect/pages/splash_screen3.dart';
import 'package:vetconnect/pages/splash_navigator.dart';
import 'package:vetconnect/pages/vet_profile.dart';
import 'package:vetconnect/services/user_service.dart';
import 'pages/farmer_home_page.dart';
import 'pages/vet_home_page.dart';
import 'package:vetconnect/widgets/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VetConnect',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: AuthWrapper(),
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/homepage': (context) => HomePage(),
        '/farmer-home': (context) => FarmerHomePage(),
        '/vet-home': (context) => VetHomePage(),
        '/confirm&pay': (context) => ConfirmAndPayPage(
          vetName: 'Dr. Lila Montgomery',
          appointmentTime: DateTime.now(),
          consultationFee: 50.0
        ),
        '/paymentConfirmation': (context) => PaymentSuccessScreen(),
        '/splash1': (context) => SplashScreen1(),
        '/splash2': (context) => SplashScreen2(),
        '/splash3': (context) => SplashScreen3(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(snapshot.data!.uid)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (userSnapshot.hasError) {
                print('Error loading user data: ${userSnapshot.error}');
                return LoginPage();
              }

              final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
              if (userData == null) {
                return LoginPage();
              }

              // Normalize user type for comparison
              final userType = userData['userType']?.toString().toLowerCase() ?? '';
              print('User type: $userType'); // Debug log

              Widget homePage;
              if (userType == 'farmer') {
                homePage = FarmerHomePage();
              } else if (userType == 'veterinarian' || userType == 'vet') {
                homePage = VetHomePage();
              } else {
                homePage = HomePage();
              }

              // Use Navigator to set the initial route
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => homePage),
                );
              });

              return homePage;
            },
          );
        }

        return LoginPage();
      },
    );
  }
}
