
import 'dart:convert';

import '../core/services/api_client.dart';

class Security {
  static Future<bool> isFullNameAvailable({String? fullName}) async{
    final response = await ApiClient.post(
      'check_full_name_available',
      body: json.encode({'full_name': fullName}),
      anonymous: true,
    );
    final dynamic body = json.decode(response.body);
    if(response.statusCode != 200) {
      throw Exception('Failed to validate full name \n\n${body['message']}');
    }
    return body;
  }

  static Future<bool> isEmailAvailable({String? email}) async {
    final response = await ApiClient.post(
      'check_email_available',
      body: json.encode({'email': email}),
      anonymous: true,
    );
    final dynamic body = json.decode(response.body);
    if(response.statusCode != 200) {
      throw Exception('Failed to validate email \n\n${body['message']}');
    }
    return body;
  }

  static Future<void> signup({
    required String email,
    required String fullName,
    required String password,
    String? phone
  }) async {
     final response = await ApiClient.post(
       'signup',
       body: json.encode({
         'email': email,
         'full_name': fullName,
         'password': password,
         'phone': phone != null && phone.isEmpty ? null : phone}),
       anonymous: true,
     );
     if(response.statusCode != 204) {
       throw Exception('Failed to signup \n\n${response.body}');
     }
  }
}