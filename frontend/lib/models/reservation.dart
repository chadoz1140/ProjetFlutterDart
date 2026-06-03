import 'dart:convert';

import 'package:intl/intl.dart';
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
    print('RESERVATION JSON: $json');
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

  static Future<Reservation> getReservation(int reservationId) async {
    final response = await ApiClient.post(
      'get_reservation_details',
      body: json.encode({'reservation_id': reservationId}),

    );
    if (response.statusCode == 200) {
      return Reservation.fromJson(json.decode(response.body));
    }
    else {
      throw Exception('Failed to get restaurant');
    }
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

  static Future<List<Reservation>> getReservationsByRestaurant(int restaurantId, {String? status}) async {
    final response = await ApiClient.post(
      'get_reservations_by_restaurant',
       body: json.encode({
        'restaurant_id': restaurantId,
        'p_status': status,
      }),
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

  static Future<Map<String, dynamic>> getSlotsForDate({
    required int restaurantId,
    required DateTime date,
    required int numberOfGuests,
  }) async {
    final response = await ApiClient.post(
      'get_slots_for_date',
      body: json.encode({
        'p_restaurant_id': restaurantId,
        'p_date': DateFormat('yyyy-MM-dd').format(date),
        'p_number_of_guests': numberOfGuests,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Impossible de charger les créneaux.');
    }
    final data = json.decode(response.body);

    final rawSlots = data['slots'] as List<dynamic>? ?? [];
    final slots = rawSlots
        .map((s) => (s as String).substring(0, 5))
        .toList();

    return {
      'slots': slots,
      'restaurantClosed': data['restaurant_closed'] as bool? ?? false,
      'overCapacity': data['over_capacity'] as bool? ?? false,
    };
  }


  static Future<void> updateReservation({
    required int reservationId,
    required DateTime newDateTime,
    required int numberOfGuests,
    String? specialRequests,
  }) async {
    final response = await ApiClient.post(
      'update_reservation',
      body: json.encode({
        'p_reservation_id': reservationId,
        'p_datetime': newDateTime.toIso8601String(),
        'p_number_of_guests': numberOfGuests,
        'p_special_requests': specialRequests,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      //print('update_reservation status: ${response.statusCode}');
      //print('update_reservation body: ${response.body}');
      throw Exception('Erreur lors de la modification de la réservation.');
    }
  }

}