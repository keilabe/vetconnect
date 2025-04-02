import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mpesa_flutter_plugin/mpesa_flutter_plugin.dart';
import 'package:vetconnect/firebase_options.dart';
import 'package:vetconnect/pages/confirm_and_pay_page.dart';
import 'package:vetconnect/pages/home_page.dart';
import 'package:vetconnect/pages/login_page.dart';
import 'package:vetconnect/pages/payment_success_screen_page.dart';
import 'package:vetconnect/pages/register_page.dart';
import 'package:vetconnect/pages/splash_screen1.dart';
import 'package:vetconnect/pages/splash_screen2.dart';
import 'package:vetconnect/pages/splash_screen3.dart';
import 'package:vetconnect/pages/vet_appointment_requests_page.dart';
import 'package:vetconnect/widgets/notifications_widget.dart';
import 'pages/farmer_home_page.dart';
import 'pages/vet_home_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vetconnect/services/payment_service.dart';
import 'package:vetconnect/services/mpesa_direct_service.dart';
import 'dart:async';
import '../models/chat_model.dart';  // This contains both ChatModel and MessageModel
import '../services/chat_service.dart';
import '../services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
 
  
  // Load environment variables
  try {
   await dotenv.load(fileName: ".env");
    
    // Validate critical environment variables
    _validateEnvironmentVariables([
      'MPESA_CONSUMER_KEY',
      'MPESA_CONSUMER_SECRET',
      'FIREBASE_API_KEY',
      'FIREBASE_APP_ID',
      'FIREBASE_SENDER_ID',
      'FIREBASE_PROJECT_ID',
    ]);
    
    print('✅ Environment variables loaded successfully');
  } catch (e) {
    print('⚠️ Warning: Could not load .env file: $e');
    print('⚠️ Using fallback values for environment variables');
    // Set fallback values for critical environment variables
    dotenv.env['MPESA_CONSUMER_KEY'] = 'fallback_key';
    dotenv.env['MPESA_CONSUMER_SECRET'] = 'fallback_secret';
  }
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  

  // Initialize M-Pesa services
  try {
    print('🔄 Main: Initializing M-Pesa services');
    print('📊 Main: Payment Tracking - Starting M-Pesa Services Initialization');
    final consumerKey = dotenv.env['MPESA_CONSUMER_KEY'] ?? '';
    final consumerSecret = dotenv.env['MPESA_CONSUMER_SECRET'] ?? '';
    
    if (consumerKey.isEmpty || consumerSecret.isEmpty) {
      print('⚠️ Main: M-Pesa credentials not found in environment variables');
      print('📊 Main: Payment Tracking - Missing M-Pesa Credentials');
    } else {
      print('✅ Main: M-Pesa credentials found, setting up services');
      print('📊 Main: Payment Tracking - M-Pesa Credentials Found');
    }
    
    // Initialize our direct implementation as primary payment method
    print('🔄 Main: Initializing M-Pesa Direct Service as primary payment method');
    print('📊 Main: Payment Tracking - Initializing MpesaDirectService');
    // Import and create an instance to initialize the singleton
    MpesaDirectService();
    
    
    print('✅ Main: M-Pesa Direct Service initialized successfully');
    print('📊 Main: Payment Tracking - MpesaDirectService Initialized Successfully');
    
    // Initialize the plugin as backup (may fail on some platforms)
    try {
      print('🔄 Main: Initializing M-Pesa Flutter Plugin as backup');
      print('📊 Main: Payment Tracking - Attempting to Initialize Plugin as Backup');
      MpesaFlutterPlugin.setConsumerKey(consumerKey);
      MpesaFlutterPlugin.setConsumerSecret(consumerSecret);
      print('✅ Main: M-Pesa Flutter Plugin initialized successfully');
      print('📊 Main: Payment Tracking - Plugin Initialized Successfully (Available as Backup)');
    } catch (pluginError) {
      print('⚠️ Main: Could not initialize M-Pesa Flutter Plugin: $pluginError');
      print('📊 Main: Payment Tracking - Plugin Initialization Failed, Will Use Direct Service Only');
      print('📋 Main: Plugin error details - ${pluginError.toString()}');
    }
    
    // Initialize payment service
    print('🔄 Main: Initializing Payment Service');
    final paymentService = PaymentService();
    await paymentService.initialize();
    print('✅ Main: Payment Service initialized successfully');
    
    print('✅ Main: M-Pesa services initialization complete');
  } catch (e) {
    print('❌ Main: Error initializing M-Pesa services: $e');
    print('📋 Main: Error details - ${e.toString()}');
  }
  
  runApp(MyApp());
}

void _validateEnvironmentVariables(List<String> requiredVars) {
  final missingVars = requiredVars.where((varName) => 
    dotenv.env[varName] == null || dotenv.env[varName]!.isEmpty
  ).toList();

  if (missingVars.isNotEmpty) {
    throw Exception('Missing required environment variables: ${missingVars.join(', ')}');
  }
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VetConnect',
      theme: ThemeData(
        iconTheme: IconThemeData(
          color: Colors.teal,
        ),
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

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool read;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.read,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      read: data['read'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'read': read,
    };
  }

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? text,
    DateTime? timestamp,
    bool? read,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      read: read ?? this.read,
    );
  }
}