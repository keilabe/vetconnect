import 'dart:convert';
import 'package:http/http.dart' as http;

class MpesaProxy {
  static const String _proxyUrl = 'https://vetconnect.free.beeceptor.com'; // Your backend server URL

  static Future<String> getAccessToken() async {
    try {
      final response = await http.get(
        Uri.parse('$_proxyUrl/mpesa/token'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['access_token'];
      } else {
        throw Exception('Failed to get access token: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting access token: $e');
    }
  }

  static Future<Map<String, dynamic>> initiateSTKPush({
    required String phoneNumber,
    required double amount,
    required String accountReference,
    required String transactionDesc,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_proxyUrl/mpesa/stk-push'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phoneNumber': phoneNumber,
          'amount': amount,
          'accountReference': accountReference,
          'transactionDesc': transactionDesc,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to initiate STK push: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error initiating STK push: $e');
    }
  }
} 