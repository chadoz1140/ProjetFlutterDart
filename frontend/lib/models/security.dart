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

  static Future<void> resetDatabase() async {
    final response = await ApiClient.post('reset_database',
      body: json.encode({}),
        anonymous: true,
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to reset database');
    }
  }
  // static Future<void> resetDatabase() async {
  //   final response = await ApiClient.post(
  //     'reset_database',
  //     body: json.encode({}),
  //     anonymous: true,
  //   );
  //
  //   print('RESET STATUS: ${response.statusCode}');
  //   print('RESET BODY: ${response.body}');
  //
  //   if (response.statusCode < 200 || response.statusCode >= 300) {
  //     throw Exception('Failed to reset database: ${response.body}');
  //   }
  // }

}