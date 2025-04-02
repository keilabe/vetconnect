import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

class MpesaDirectService {
  final Logger _logger = Logger('MpesaDirectService');
  // Singleton pattern
  static final MpesaDirectService _instance = MpesaDirectService._internal();
  factory MpesaDirectService() => _instance;
  MpesaDirectService._internal();

  // Base URLs with HTTPS
  final String _sandboxBaseUrl = 'https://sandbox.safaricom.co.ke';
  final String _liveBaseUrl = 'https://api.safaricom.co.ke';
  
  // Get base URL from environment or default to sandbox
  String get baseUrl => dotenv.env['MPESA_LIVE_MODE'] == 'true' 
      ? _liveBaseUrl 
      : _sandboxBaseUrl;

  // Get credentials from environment
  String get _consumerKey => dotenv.env['MPESA_CONSUMER_KEY'] ?? '';
  String get _consumerSecret => dotenv.env['MPESA_CONSUMER_SECRET'] ?? '';
  String get _shortCode => dotenv.env['MPESA_SHORTCODE'] ?? '174379';
  String get _passKey => dotenv.env['MPESA_PASSKEY'] ?? 'bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919';
  String get _callbackUrl => dotenv.env['MPESA_CALLBACK_URL'] ?? 'https://vetconnect.free.beeceptor.com/';

  // Maximum number of retry attempts for network operations
  final int _maxRetries = 3;
  
  // Delay between retry attempts (in milliseconds)
  final int _retryDelay = 2000;
  
  final Duration _timeout = Duration(seconds: 30);

  // Custom HTTP client with longer timeout
  http.Client _createClient() {
    return http.Client();
  }

  // Verify network connectivity
  Future<bool> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  // Enhanced error handling for network requests
  Future<http.Response> _makeHttpRequest(Uri uri, {
    required Map<String, String> headers,
    String? body,
    String method = 'GET'
  }) async {
    final client = _createClient();
    try {
      http.Response response;
      
      if (method == 'POST') {
        response = await client.post(
          uri,
          headers: headers,
          body: body,
        ).timeout(_timeout);
      } else {
        response = await client.get(
          uri,
          headers: headers,
        ).timeout(_timeout);
      }
      
      return response;
    } on SocketException catch (e) {
      throw Exception('Network connection error. Please check your internet connection. (Detail: $e)');
    } on TimeoutException catch (e) {
      throw Exception('Request timed out. Please try again. (Detail: $e)');
    } on HandshakeException catch (e) {
      throw Exception('SSL/TLS handshake failed. Please check your security settings. (Detail: $e)');
    } catch (e) {
      throw Exception('An unexpected error occurred. Please try again. (Detail: $e)');
    } finally {
      client.close();
    }
  }

  // Generate the auth token with retry logic
  Future<String> _getAuthToken() async {
    _logger.info('Getting auth token');
    
    // Check network connectivity first
    if (!await _checkConnectivity()) {
      throw Exception('No internet connection available');
    }

    final credentials = base64Encode(utf8.encode('$_consumerKey:$_consumerSecret'));
    final uri = Uri.parse('$baseUrl/oauth/v1/generate?grant_type=client_credentials');
    
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        _logger.info('Auth token attempt $attempt/$_maxRetries');
        
        final response = await _makeHttpRequest(
          uri,
          headers: {
            'Authorization': 'Basic $credentials',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data.containsKey('access_token')) {
            _logger.info('Auth token obtained successfully');
            return data['access_token'];
          }
          throw Exception('Invalid response format: missing access_token');
        } else {
          throw Exception('HTTP ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        _logger.warning('Error getting auth token: $e');
        if (attempt == _maxRetries) {
          throw Exception('Failed to get auth token after $_maxRetries attempts: $e');
        }
        await Future.delayed(Duration(milliseconds: _retryDelay));
      }
    }
    
    throw Exception('Failed to get auth token after $_maxRetries attempts');
  }

  // Generate the password for STK Push
  String _generatePassword() {
    print('🔄 MpesaDirectService: Generating password');
    print('📊 MpesaDirectService: Payment Tracking - Generating STK Push Password');
    
    final timestamp = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
    final dataToEncode = '$_shortCode$_passKey$timestamp';
    final password = base64.encode(utf8.encode(dataToEncode));
    
    print('✅ MpesaDirectService: Password generated successfully');
    print('📊 MpesaDirectService: Payment Tracking - Password Generated with Timestamp: $timestamp');
    return password;
  }
  
  // Initiate STK Push with retry logic
  Future<Map<String, dynamic>> initiateSTKPush({
    required double amount,
    required String phoneNumber,
    String? reference,
    String? description,
  }) async {
    _logger.info('Initiating STK Push');
    _logger.info('Amount: $amount, Phone: $phoneNumber');
    
    // Check network connectivity first
    if (!await _checkConnectivity()) {
      throw Exception('No internet connection available');
    }

    final transactionReference = reference ?? 'VetConnect-${DateTime.now().millisecondsSinceEpoch}';
    final startTime = DateTime.now();
    
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final token = await _getAuthToken();
        final timestamp = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
        final password = base64Encode(utf8.encode('$_shortCode$_passKey$timestamp'));
        
        final body = {
          'BusinessShortCode': _shortCode,
          'Password': password,
          'Timestamp': timestamp,
          'TransactionType': 'CustomerPayBillOnline',
          'Amount': amount.toStringAsFixed(0),
          'PartyA': phoneNumber,
          'PartyB': _shortCode,
          'PhoneNumber': phoneNumber,
          'CallBackURL': _callbackUrl,
          'AccountReference': transactionReference,
          'TransactionDesc': description ?? 'Payment for veterinary consultation',
        };
        
        _logger.info('Sending STK Push request');
        _logger.info('Request body: ${json.encode(body)}');
        
        final response = await _makeHttpRequest(
          Uri.parse('$baseUrl/mpesa/stkpush/v1/processrequest'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode(body),
          method: 'POST',
        );
        
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime).inMilliseconds;
        _logger.info('Request duration: ${duration}ms');
        
        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);
          _logger.info('STK Push response: $jsonResponse');
          
          if (jsonResponse.containsKey('ResponseCode')) {
            if (jsonResponse['ResponseCode'] == '0') {
              _logger.info('STK Push successful');
              return jsonResponse;
            } else {
              throw Exception('STK Push failed: ${jsonResponse['ResponseDescription']}');
            }
          } else {
            throw Exception('Invalid response format: missing ResponseCode');
          }
        } else {
          throw Exception('HTTP ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        _logger.severe('Error in STK Push attempt $attempt: $e');
        if (attempt == _maxRetries) {
          throw Exception('Failed to process payment after $_maxRetries attempts: $e');
        }
        await Future.delayed(Duration(milliseconds: _retryDelay));
      }
    }
    
    throw Exception('Failed to process payment after $_maxRetries attempts');
  }

  // Check transaction status with retry logic
  Future<Map<String, dynamic>> checkTransactionStatus(String checkoutRequestId) async {
    _logger.info('Checking transaction status for: $checkoutRequestId');
    print('📊 MpesaDirectService: Payment Tracking - Transaction Status Check Started');
    print('📊 MpesaDirectService: Payment Tracking - Checkout Request ID: $checkoutRequestId');
    
    final startTime = DateTime.now();
    print('📊 MpesaDirectService: Payment Tracking - Status Check Start Time: ${startTime.toIso8601String()}');
    
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final token = await _getAuthToken();
        final timestamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[-:.]'), '').substring(0, 14);
        final password = base64Encode(utf8.encode('$_shortCode$_passKey$timestamp'));
        
        // Prepare request body
        final body = {
          'BusinessShortCode': _shortCode,
          'Password': password,
          'Timestamp': timestamp,
          'CheckoutRequestID': checkoutRequestId,
        };
        
        print('📊 MpesaDirectService: Payment Tracking - Status Check Request Prepared');
        
        // Make the request with timeout
        print('📊 MpesaDirectService: Payment Tracking - Sending Status Check Request to M-Pesa API');
        final response = await http.post(
          Uri.parse('$baseUrl/mpesa/stkpushquery/v1/query'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode(body),
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException('Request timed out');
          },
        );
        
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime).inMilliseconds;
        print('📊 MpesaDirectService: Payment Tracking - Status Check Request Duration: ${duration}ms');
        
        print('📊 MpesaDirectService: Payment Tracking - Status Check Response Received');
        print('📊 MpesaDirectService: Payment Tracking - Status Check Response Status: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);
          print('✅ MpesaDirectService: Transaction status check successful');
          print('📊 MpesaDirectService: Payment Tracking - Status Check Success');
          
          // Log the result code and description
          if (jsonResponse.containsKey('ResultCode')) {
            print('📊 MpesaDirectService: Payment Tracking - Result Code: ${jsonResponse['ResultCode']}');
            print('📊 MpesaDirectService: Payment Tracking - Result Description: ${jsonResponse['ResultDesc'] ?? 'No description'}');
          }
          
          return jsonResponse;
        } else {
          print('❌ MpesaDirectService: Failed to check transaction status - Status: ${response.statusCode}');
          print('📊 MpesaDirectService: Payment Tracking - Status Check Failed');
          print('📊 MpesaDirectService: Payment Tracking - Error Status: ${response.statusCode}');
          
          if (attempt < _maxRetries) {
            print('🔄 MpesaDirectService: Retrying status check request in ${_retryDelay}ms');
            print('📊 MpesaDirectService: Payment Tracking - Will Retry Status Check Request');
            await Future.delayed(Duration(milliseconds: _retryDelay));
            continue;
          }
          
          throw Exception('Failed to check transaction status after $_maxRetries attempts: ${response.body}');
        }
      } catch (e) {
        _logger.severe('Error checking transaction status: $e');
        if (attempt == _maxRetries) {
          throw Exception('Failed to check transaction status after $_maxRetries attempts: $e');
        }
        await Future.delayed(Duration(milliseconds: _retryDelay));
      }
    }
    
    // This should never be reached due to the throws above, but added for completeness
    throw Exception('Failed to check transaction status after $_maxRetries attempts');
  }
}