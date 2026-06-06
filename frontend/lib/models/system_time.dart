
import 'dart:convert';

import 'package:prbd_2526_c01/core/services/api_client.dart';

class SystemTime {
  final DateTime? simulatedTime;

  SystemTime({this.simulatedTime});

  factory SystemTime.fromJson(Map<String, dynamic> json) {
    return SystemTime(
      simulatedTime: json['simulated_time'] != null
          ? DateTime.parse(json['simulated_time'])
          : null,
    );
  }

  static Future<SystemTime> getSystemTime() async {
    final response = await ApiClient.get('get_system_time', anonymous: true);
    if(response.statusCode != 200) throw Exception('Failed to get system time');
    return SystemTime.fromJson(json.decode(response.body));
  }

}