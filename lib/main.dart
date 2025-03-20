import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Check if user is first time or already logged in
  bool isFirstTime = await UserService.isFirstTimeUser();
  bool isLoggedIn = await UserService.isUserLoggedIn();
  
  String initialRoute = isFirstTime ? '/splash' : (isLoggedIn ? '/homepage' : '/login');
  
  runApp(MainApp(initialRoute: initialRoute));
}

class MainApp extends StatelessWidget {
  final String initialRoute;
  
  const MainApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VetConnect',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Architect',
      ),
      initialRoute: initialRoute,
      routes: {
        '/splash': (context) => const SplashNavigator(),
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/homepage': (context) => HomePage(),
        '/vetprofile': (context) => VetProfile(),        
        '/bookvet': (context) => BookingVetPage(),
        '/confirm&pay': (context) => ConfirmAndPayPage(vetName: 'Dr. Lila Montgomery', appointmentTime: DateTime.now(), consultationFee: 50.0),
        '/paymentConfirmation': (context) => PaymentSuccessScreen(),
        '/splash1': (context) => SplashScreen1(),
        '/splash2': (context) => SplashScreen2(),
        '/splash3': (context) => SplashScreen3(),
      },
    );
  }
}
