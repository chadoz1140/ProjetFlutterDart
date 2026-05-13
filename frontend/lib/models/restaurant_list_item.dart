import 'dart:convert';

import 'package:prbd_2526_c01/core/services/api_client.dart';

class RestaurantListItem {

  final int id;
  final String name;
  final String city;
  final double? rating;
  final DateTime? lastReservationDatetime;
  final int pendingCount;

  RestaurantListItem({
    required this.id,
    required this.name,
    required this.city,
    required this.rating,
    required this.lastReservationDatetime,
    required this.pendingCount,
  });

  @override
  String toString() {
    return '$id $name $city, $rating, $lastReservationDatetime, $pendingCount';
  }


  factory RestaurantListItem.fromJson(Map<String, dynamic> json) {
    return RestaurantListItem(
      id: json['id'],
      name: json['name'],
      city: json['city'],
      rating: json['rating'] == null ? null : (json['rating'] as num).toDouble(),
      lastReservationDatetime: json['last_reservation_datetime'] == null
          ? null
          : DateTime.parse(json['last_reservation_datetime']),
      pendingCount: json['pending_requests_count'] ?? 0,
    );
  }

  static Future<List<RestaurantListItem>> getRestaurants( String? searchText, {required int resultNumber}) async{
    final response = await ApiClient.post('get_restaurants',
      body: json.encode(
          {'search_restaurant': searchText, 'result_number' : resultNumber}
      )
    );
    if (response.statusCode != 200) {
      print('GET RESTAURANTS ERROR STATUS: ${response.statusCode}');
      print('GET RESTAURANTS ERROR BODY: ${response.body}');
      throw Exception('Failed to get restaunts');
    }
    final List<dynamic> data = json.decode(response.body);
    return data.map((dynamic item) => RestaurantListItem.fromJson(item)).toList();
  }





}