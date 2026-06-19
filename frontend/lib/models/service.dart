
import 'dart:convert';
import 'dart:ffi';

import '../core/services/api_client.dart';

class Service {
  final int id;
  final int restaurant;
  final int dayOfWeek;
  final String startTime;
  final String endTime;


  Service({
    required this.id,
    required this.restaurant,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  Service copyWith({
    int? id,
    int? restaurant,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
  }) {
    return Service(
      id: id ?? this.id,
      restaurant: restaurant ?? this.restaurant,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  @override
  String toString() {
    return '$id $restaurant $dayOfWeek $startTime $endTime';
  }

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'],
      restaurant: json['restaurant'],
      dayOfWeek: json['day_of_week'],
      startTime: json['start_time'],
      endTime: json['end_time'],
    );
  }

  static Future<List<Service>> getServiceInfoByRestaurantId(int restaurantId) async {
    final response = await ApiClient.post(
      'get_service_info_by_restaurant_id',
       body: json.encode({'restaurant_id': restaurantId})
    );
    if(response.statusCode != 200) {
      throw Exception('Failed to get service info');
    }
    final List<dynamic> data = json.decode(response.body);
    return data.map((dynamic item) => Service.fromJson(item)).toList();
  }

  static Future<bool>canDeleteService(int serviceId) async{
    final response = await ApiClient.post(
        'can_delete_service',
        body: json.encode({'service_id': serviceId})

    );
    if(response.statusCode != 200) {
      throw Exception('Unable to check the service');
    }
    return json.decode(response.body);
  }

  static Future<void>deleteService(int serviceId) async{
    final response = await ApiClient.post(
      'delete_service',
        body: json.encode({'service_id': serviceId})
    );
    print('DELETE STATUS: ${response.statusCode}');
    print('DELETE BODY: ${response.body}');
    if (response.statusCode != 204) {
      throw Exception(
          'failed to delete service\n\n${response.body}'
      );
    }
  }

  static Future<String?> checkServiceBusinessRules(int restaurantId, int dayOfWeek, String startTime, String endTime, int? serviceId) async {
    final response = await ApiClient.post(
      'check_service_business_rules',
      body: json.encode({
        'p_restaurant_id': restaurantId,
        'p_day_of_week': dayOfWeek,
        'p_start_time': startTime,
        'p_end_time': endTime,
        'p_id_service': serviceId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      return null;
    }

    final error = json.decode(response.body);
    return error['message'];
  }


  static Future<Service> saveService(int? serviceId, int restaurantId, int dayOfWeek, String startTime, String endTime,) async {
    final response = await ApiClient.post(
      'save_service',
      body: json.encode({
        'id_service': serviceId,
        'id_restaurant': restaurantId,
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
      }),
    );

    if (response.statusCode != 200) {
      final error = json.decode(response.body);
      throw Exception(error['message']);
    }

    final data = json.decode(response.body);
    return Service.fromJson(data);
  }



}