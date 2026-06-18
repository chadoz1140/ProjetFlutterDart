import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:prbd_2526_c01/core/services/api_client.dart';
import 'package:prbd_2526_c01/models/restaurant.dart';
import 'package:prbd_2526_c01/models/restaurant_tables.dart';
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
  final List<RestaurantTables>? tables;

  //tout les champs ne sont pas required, pour la création d'une réservation
  const Reservation({
    this.id,
    this.client,
    required this.restaurant,
    required this.dateTime,
    required this.numberOfGuests,
    this.status = Status.pending,
    this.specialRequest,
    this.tables
  });


  Reservation copyWith({
    DateTime? dateTime,
    int? numberOfGuests,
    String? specialRequest,
    Status? status,
  }) {
    return Reservation(
      id: id,
      client: client,
      restaurant: restaurant,
      dateTime: dateTime ?? this.dateTime,
      numberOfGuests: numberOfGuests ?? this.numberOfGuests,
      status: status ?? this.status,
      specialRequest: specialRequest ?? this.specialRequest,
    );
  }

  factory Reservation.fromJson(Map<String, dynamic> json) {
    print('RESERVATION JSON: $json');
    return Reservation(
      id: json['id'],
      client: User.fromJson(json['client']),
      restaurant: Restaurant.fromJson(json['restaurant']),
      dateTime: DateTime.parse(json['datetime']),
      numberOfGuests: json['number_of_guests'],
      status: Status.fromJson(json['status']),
      specialRequest: json['special_requests'],
      /* si on reçois un tableau de tables lié a la reservation alors on parcours chaque éléments de la list
         et on le transforme en objet dart RestaurantTables et on finis par convertir en List */
      tables: json['restaurant_tables'] != null
          ? (json['restaurant_tables'] as List)
          .map((tableJson) => RestaurantTables.fromJson(tableJson))
          .toList()
          : null,
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

  static Future<Reservation> cancelReservation(Reservation reservation) async{
    try{
      final response = await ApiClient.post(
        'cancel_reservation',
        body: json.encode({
          'reservation_id' : reservation.id,
        }),
      );
      if (response.statusCode == 200){
        final dynamic = Reservation.fromJson(json.decode(response.body));
        return dynamic;
      }
      else {
        throw Exception('failed to cancel reservation: ${response.statusCode} ${response.body}',);
      }
    }
    catch(e, st){
      debugPrint('$e\n$st');
      throw Exception('Failed to cancel reservation');
    }
  }

  static Future<Reservation> getReservationDetailsManager(int reservationId) async {
    try{
      final response = await ApiClient.post(
        'get_reservations_details_manager',
        body: json.encode({
          'reservation_id' : reservationId,
        }),
      );
      if (response.statusCode == 200){
        final reservation = Reservation.fromJson(json.decode(response.body));
        return reservation;
      }
      else {
        throw Exception('get_reservations_details_manager failed: ${response.statusCode} ${response.body}',);
      }
    }
    catch(e, st){
      debugPrint('$e\n$st');
      throw Exception('Failed to cancel reservation');
    }
  }

  static Future<Reservation> cancelReservationManager(Reservation reservation) async{
    try{
      final response = await ApiClient.post(
        'cancel_reservation_manager',
        body: json.encode({
          'reservation_id' : reservation.id,
        }),
      );
      if (response.statusCode == 200){
        final dynamic = Reservation.fromJson(json.decode(response.body));
        return dynamic;
      }
      else {
        throw Exception('failed to cancel reservation: ${response.statusCode} ${response.body}',);
      }
    }
    catch(e, st){
      debugPrint('$e\n$st');
      throw Exception('Failed to cancel reservation');
    }
  }

  static Future<Reservation> completedReservationManager(Reservation reservation) async{
    try{
      final response = await ApiClient.post(
        'completed_reservation_manager',
        body: json.encode({
          'reservation_id' : reservation.id,
        }),
      );
      if (response.statusCode == 200){
        final dynamic = Reservation.fromJson(json.decode(response.body));
        return dynamic;
      }
      else {
        throw Exception('failed to complete reservation: ${response.statusCode} ${response.body}',);
      }
    }
    catch(e, st){
      debugPrint('$e\n$st');
      throw Exception('Failed to complete reservation');
    }
  }

  static Future<Reservation> confirmedReservationManager(Reservation reservation, List<int> tableId) async{
    try{
      final response = await ApiClient.post(
        'confirmed_reservation_manager',
        body: json.encode({
          'reservation_id' : reservation.id,
          'table_ids' : tableId
        }),
      );
      if (response.statusCode == 200){
        final dynamic = Reservation.fromJson(json.decode(response.body));
        return dynamic;
      }
      else {
        throw Exception('failed to complete reservation: ${response.statusCode} ${response.body}',);
      }
    }
    catch(e, st){
      debugPrint('$e\n$st');
      throw Exception('Failed to complete reservation');
    }
  }





  static Future<Map<String, dynamic>>getNewReservationData(int restaurantId, DateTime? date)async{
    String? dateText;
    if (date != null) {
      dateText = DateFormat('yyyy-MM-dd').format(date);
    }

    final response = await ApiClient.post(
      'get_new_reservation_data',
      body: json.encode({
        'p_restaurant_id': restaurantId,
        'p_date': dateText,
      }),
    );

    if (response.statusCode != 200) {
      print('GET NEW RESERVATION DATA STATUS: ${response.statusCode}');
      print('GET NEW RESERVATION DATA BODY: ${response.body}');
      throw Exception('Failed to load new reservation data');
    }

    final decodedBody = json.decode(response.body);

    return Map<String, dynamic>.from(decodedBody);

  }

  static Future<bool> checkReservationOverCapacity( int restaurantId, DateTime reservationDateTime, int numberOfGuests,) async {
    final dateText = DateFormat('yyyy-MM-dd').format(reservationDateTime);
    final slotText = DateFormat('HH:mm:ss').format(reservationDateTime);

    final response = await ApiClient.post(
      'check_reservation_over_capacity',
      body: json.encode({
        'p_restaurant_id': restaurantId,
        'p_date': dateText,
        'p_slot': slotText,
        'p_number_of_guests': numberOfGuests,
      }),
    );

    if (response.statusCode != 200) {
      print('CHECK CAPACITY ERROR STATUS: ${response.statusCode}');
      print('CHECK CAPACITY ERROR BODY: ${response.body}');
      throw Exception('Failed to check reservation capacity');
    }
    return json.decode(response.body) as bool;
  }

  static Future<Reservation> saveReservation(int restaurantId, DateTime dateTime, int numberOfGuests, String? specialRequests,) async {
    final response = await ApiClient.post(
      'save_reservation',
      body: json.encode({
        'p_restaurant_id': restaurantId,
        'p_datetime': dateTime.toIso8601String(),
        'p_number_of_guests': numberOfGuests,
        'p_special_requests': specialRequests,
      }),
    );

    if (response.statusCode != 200) {
      print('SAVE RESERVATION ERROR STATUS: ${response.statusCode}');
      print('SAVE RESERVATION ERROR BODY: ${response.body}');
      throw Exception('Failed to save reservation');
    }
    return Reservation.fromJson(json.decode(response.body));
  }


}