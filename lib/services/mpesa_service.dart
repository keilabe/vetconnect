import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:convert/convert.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'mpesa_proxy.dart';

class MpesaService {
  static const String _baseUrl = 'https://sandbox.safaricom.co.ke';
  static const String _shortcode = '174379';
  static const String _callbackUrl = 'https://vetconnect.free.beeceptor.com';

  // Singleton instance
  static final MpesaService _instance = MpesaService._internal();
  factory MpesaService() => _instance;
  MpesaService._internal();

  bool _isInitialized = false;
  String? _cachedAccessToken;
  DateTime? _tokenExpiryTime;

  // Payment process logging
  void _logPaymentStep(String step, {Map<String, dynamic>? details}) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = StringBuffer();
    logMessage.writeln('[$timestamp] M-Pesa Payment Step: $step');
    if (details != null) {
      logMessage.writeln('Details:');
      details.forEach((key, value) {
        logMessage.writeln('  $key: $value');
      });
    }
    print(logMessage.toString());
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logPaymentStep('Service Initialization');
      
      _logPaymentStep('Loading Environment Variables');
      await dotenv.load(fileName: ".env");

      // Verify environment variables are loaded
      final consumerKey = dotenv.env['MPESA_CONSUMER_KEY'];
      final consumerSecret = dotenv.env['MPESA_CONSUMER_SECRET'];
      final passkey = dotenv.env['MPESA_PASSKEY'];

      _logPaymentStep('Environment Variables Check', details: {
        'consumerKey': consumerKey != null ? 'Present' : 'Missing',
        'consumerSecret': consumerSecret != null ? 'Present' : 'Missing',
        'passkey': passkey != null ? 'Present' : 'Missing',
      });

      if (consumerKey == null || consumerSecret == null || passkey == null) {
        throw Exception('M-Pesa credentials not found in environment variables');
      }

      _isInitialized = true;
      _logPaymentStep('Service Initialization Complete');
    } catch (e) {
      _logPaymentStep('Service Initialization Failed', details: {'error': e.toString()});
      rethrow;
    }
  }

  String get _consumerKey {
    if (!_isInitialized) {
      throw Exception('M-Pesa service not initialized. Call initialize() first.');
    }
    final key = dotenv.env['MPESA_CONSUMER_KEY'];
    if (key == null) {
      throw Exception('MPESA_CONSUMER_KEY not found in environment variables');
    }
    return key;
  }

  String get _consumerSecret {
    if (!_isInitialized) {
      throw Exception('M-Pesa service not initialized. Call initialize() first.');
    }
    final secret = dotenv.env['MPESA_CONSUMER_SECRET'];
    if (secret == null) {
      throw Exception('MPESA_CONSUMER_SECRET not found in environment variables');
    }
    return secret;
  }

  String get _passkey {
    if (!_isInitialized) {
      throw Exception('M-Pesa service not initialized. Call initialize() first.');
    }
    final key = dotenv.env['MPESA_PASSKEY'];
    if (key == null) {
      throw Exception('MPESA_PASSKEY not found in environment variables');
    }
    return key;
  }

  Future<String> _getAccessToken() async {
    try {
      _logPaymentStep('Requesting New Access Token');
      final token = await MpesaProxy.getAccessToken();
      _cachedAccessToken = token;
      _tokenExpiryTime = DateTime.now().add(const Duration(hours: 1));
      return token;
    } catch (e) {
      _logPaymentStep('Access Token Request Error', details: {'error': e.toString()});
      rethrow;
    }
  }

  Future<Map<String, dynamic>> initiateSTKPush({
    required String phoneNumber,
    required double amount,
    required String accountReference,
    required String transactionDesc,
  }) async {
    if (!_isInitialized) {
      throw Exception('M-Pesa service not initialized. Call initialize() first.');
    }

    try {
      _logPaymentStep('Initiating STK Push', details: {
        'phoneNumber': phoneNumber,
        'amount': amount,
        'accountReference': accountReference,
        'transactionDesc': transactionDesc,
      });

      final result = await MpesaProxy.initiateSTKPush(
        phoneNumber: phoneNumber,
        amount: amount,
        accountReference: accountReference,
        transactionDesc: transactionDesc,
      );

      _logPaymentStep('STK Push Initiated Successfully', details: result);
      return result;
    } catch (e) {
      _logPaymentStep('STK Push Failed', details: {'error': e.toString()});
      rethrow;
    }
  }

  Future<Map<String, dynamic>> checkTransactionStatus({
    required String checkoutRequestId,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      _logPaymentStep('Checking Transaction Status', details: {
        'checkoutRequestId': checkoutRequestId,
      });

      final accessToken = await _getAccessToken();
      final timestamp = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
      final password = base64Encode(utf8.encode('$_shortcode$_passkey$timestamp'));

      final requestBody = {
        'BusinessShortCode': _shortcode,
        'Password': password,
        'Timestamp': timestamp,
        'CheckoutRequestID': checkoutRequestId,
      };

      _logPaymentStep('Transaction Status Request Details', details: requestBody);

      final response = await http.post(
        Uri.parse('$_baseUrl/mpesa/stkpushquery/v1/query'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      _logPaymentStep('Transaction Status Response', details: {
        'statusCode': response.statusCode,
        'response': response.body,
      });

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _logPaymentStep('Transaction Status Check Complete', details: responseData);
        return responseData;
      } else {
        throw Exception('Failed to check transaction status: ${response.body}');
      }
    } catch (e) {
      _logPaymentStep('Transaction Status Check Failed', details: {'error': e.toString()});
      rethrow;
    }
  }
} 