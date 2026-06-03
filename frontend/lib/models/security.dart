
import 'dart:convert';

import 'package:prbd_2526_c01/core/services/api_client.dart';

class Security {

  static Future<String?> login(String email, String password) async{
    final response = await ApiClient.post('login',
      body: json.encode({'email' : email, 'password' : password}),
      anonymous: true,
    );

    if(response.statusCode != 200){
      throw Exception('Failed to login');
    }
    final dynamic body = json.decode(response.body);
    String token = body['token'];
    return token;
  }

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

  static Future<void> resetDatabase() async {
    final response = await ApiClient.post(
        'reset_database',
         anonymous: true,
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to reset database');
    }
  }

}