import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mpesa_flutter_plugin/mpesa_flutter_plugin.dart';
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
import 'package:vetconnect/pages/vet_appointment_requests_page.dart';
import 'package:vetconnect/services/user_service.dart';
import 'package:vetconnect/widgets/notifications_widget.dart';
import 'pages/farmer_home_page.dart';
import 'pages/vet_home_page.dart';
import 'package:vetconnect/widgets/auth_wrapper.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vetconnect/services/payment_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize M-Pesa Flutter Plugin
  MpesaFlutterPlugin.setConsumerKey(dotenv.env['MPESA_CONSUMER_KEY'] ?? '');
  MpesaFlutterPlugin.setConsumerSecret(dotenv.env['MPESA_CONSUMER_SECRET'] ?? '');
  
  // Initialize M-Pesa service
  final paymentService = PaymentService();
  await paymentService.initialize();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VetConnect',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: TextTheme(
          displayLarge: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
          ),
          displayMedium: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
          displaySmall: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
          bodyLarge: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
          ),
          titleLarge: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
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
        '/confirm&pay': (context) {
          // Get arguments passed from the previous screen
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          
          if (args != null) {
            // If arguments are provided, use them
            return ConfirmAndPayPage(
              vetName: args['vetName'] ?? 'Unknown Vet',
              appointmentTime: args['appointmentTime'] ?? DateTime.now(),
              consultationFee: args['consultationFee']?.toDouble() ?? 50.0,
              vetId: args['vetId'] ?? 'default_vet_id',
              animalType: args['animalType'] ?? 'Unknown Animal',
              consultationType: args['consultationType'] ?? 'General Checkup',
              symptoms: args['symptoms'] ?? 'No specific symptoms',
              appointmentId: args['appointmentId'],
            );
          } else {
            // Fallback to default values if no arguments are provided
            return ConfirmAndPayPage(
              vetName: 'Dr. Lila Montgomery',
              appointmentTime: DateTime.now(),
              consultationFee: 50.0,
              vetId: 'default_vet_id',
              animalType: 'Cow',
              consultationType: 'General Checkup',
              symptoms: 'No specific symptoms',
            );
          }
        },
        '/payment-success': (context) => PaymentSuccessScreen(
          amount: 50.0,
          vetName: 'Dr. Lila Montgomery',
          appointmentTime: DateTime.now(),
          transactionId: 'TXN${DateTime.now().millisecondsSinceEpoch}',
          paymentMethod: 'Mpesa',
        ),
        '/splash1': (context) => SplashScreen1(),
        '/splash2': (context) => SplashScreen2(),
        '/splash3': (context) => SplashScreen3(),
        '/vet-appointment-requests': (context) => VetAppointmentRequestsPage(),
        '/notifications': (context) => Scaffold(
          appBar: AppBar(
            title: Text('Notifications'),
            backgroundColor: Colors.teal,
          ),
          body: NotificationsWidget(),
        ),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

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
