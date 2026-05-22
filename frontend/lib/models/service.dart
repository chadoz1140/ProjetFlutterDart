
import 'dart:convert';

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


}