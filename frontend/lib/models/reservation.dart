import 'dart:convert';

import 'package:prbd_2526_c01/core/services/api_client.dart';
import 'package:prbd_2526_c01/models/restaurant.dart';
import 'package:prbd_2526_c01/models/status.dart';
import 'package:prbd_2526_c01/models/user.dart';

class Reservation{
  final int? id;
  final User? client;
  final Restaurant restaurant;
  final DateTime dateTime;
  final int numberOfGuests;
  final Status status;
  final String? specialRequest;

  //tout les champs ne sont pas required, pour la création d'une réservation
  const Reservation({
    this.id,
    this.client,
    required this.restaurant,
    required this.dateTime,
    required this.numberOfGuests,
    this.status = Status.pending,
    this.specialRequest
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'],
      client: User.fromJson(json['client']),
      restaurant: Restaurant.fromJson(json['restaurant']),
      dateTime: DateTime.parse(json['datetime']),
      numberOfGuests: json['number_of_guests'],
      status: Status.fromJson(json['status']),
      specialRequest: json['special_requests']
    );
  }

  static Future<Reservation> getReservation(int reservationId) async{
    final response = await ApiClient.post(
      'get_reservation_details',
      body: json.encode({'reservation_id' : reservationId}),
      anonymous: true,
    );
    if (response.statusCode == 200){
      return Reservation.fromJson(json.decode(response.body));
    }
    else{
      throw Exception('Failed to get restaurant');
    }
  }
}