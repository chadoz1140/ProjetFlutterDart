
import 'dart:convert';

import 'package:prbd_2526_c01/core/services/api_client.dart';

class Reservation {
  final int id;
  final int client;
  final String datetime;
  final int number_of_guests;
  final String status;
  final String restaurantName;
  final String restaurantCity;

  Reservation({
    required this.id,
    required this.client,
    required this.datetime,
    required this.number_of_guests,
    required this.status,
    required this.restaurantName,
    required this.restaurantCity,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
        id: json['id'],
        client: json['client'],
        datetime: json['datetime'],
        number_of_guests: json['number_of_guests'],
        status: json['status'],
        restaurantName: json['restaurant']['name'],
        restaurantCity: json['restaurant']['city'],
    );
  }

  static Future<List<Reservation>> getReservations({String? status}) async {
      final response = await ApiClient.post(
          'get_reservations',
           body: json.encode({'p_status': status}),
      );
      if(response.statusCode != 200) {
        throw Exception("Failed to get reservations");
      }
      final dynamic decoded = json.decode(response.body);
      if(decoded == null) {
        return [];
      }
      final List<dynamic> body = List<dynamic>.from(decoded);
      return body.map((dynamic item) => Reservation.fromJson(item)).toList();
  }



}
