import 'dart:convert';

import 'package:prbd_2526_c01/core/services/api_client.dart';
import 'package:prbd_2526_c01/models/service.dart';

class Restaurant {

  final int id;
  final String name;
  final String address;
  final String city;
  final String phone;
  final String description;
  final double? rating;
  final int? priceRange;
  final DateTime? lastReservationDatetime;
  final int? pendingCount;
  final List<Service> services;

  Restaurant({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.phone,
    required this.description,
    required this.rating,
    this.priceRange,
    required this.lastReservationDatetime,
    required this.pendingCount,
    required this.services,
  });

  @override
  String toString() {
    return '$id $name $city, $rating, $lastReservationDatetime, $pendingCount, $services';
  }


  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'],
      name: json['name'],
      address: json['address'] ?? '',
      city: json['city'],
      phone: json['phone'],
      description: json['description'] ?? '',
      rating: json['rating'] == null ? null : (json['rating'] as num).toDouble(),
      priceRange: json['price_range'],
      lastReservationDatetime: json['last_reservation_datetime'] == null
          ? null
          : DateTime.parse(json['last_reservation_datetime']),
      pendingCount: json['pending_requests_count'] ?? 0,
      services: [],
    );
  }

  factory Restaurant.fromDetailJson(Map<String, dynamic> json) {
    return Restaurant(
        id: json['id'],
        name: json['name'],
        address: json['address'],
        city: json['city'],
        phone: json['phone'],
        description: json['description'],
        rating: json['rating'] == null ? null : (json['rating'] as num).toDouble(),
        lastReservationDatetime: json['last_reservation_datetime'] == null
            ? null
            : DateTime.parse(json['last_reservation_datetime']),
        pendingCount: json['pending_requests_count'] ?? 0,
        services: (json['services'] as List).map((s) => Service.fromJson(s)).toList(),
    );
  }

  static Future<List<Restaurant>> getRestaurants( String? searchText, {required int resultNumber}) async{
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
    return data.map((dynamic item) => Restaurant.fromJson(item)).toList();
  }

  static Future<Restaurant> getRestaurantDetails(int restaurantId) async{
    final response = await ApiClient.post(
      'get_restaurant_details',
       body: json.encode({'restaurant_id' : restaurantId})
    );
    if(response.statusCode != 200) {
      throw Exception('Failed to get restaurant details.');
    }
    final data = json.decode(response.body);
    return Restaurant.fromDetailJson(data);
  }

  static Future<List<Restaurant>> getMyRestaurants() async{
    final response = await ApiClient.post(
      'get_my_restaurants',
      body: json.encode({}),
    );
    if(response.statusCode != 200) {
      print('GET MY RESTAURANTS ERROR STATUS: ${response.statusCode}');
      print('GET MY RESTAURANTS ERROR BODY: ${response.body}');
      throw Exception('Failed to get my restaurants.');
    }
    final List<dynamic> data = json.decode(response.body);
    print('GET MY RESTAURANTS DATA: $data');
    return data.map((item) => Restaurant.fromJson(item as Map<String, dynamic>)).toList();
  }
}