import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:prbd_2526_c01/core/services/api_client.dart';
import 'package:prbd_2526_c01/models/restaurant.dart';
import 'package:prbd_2526_c01/models/status.dart';
import 'package:prbd_2526_c01/models/restaurant_tables.dart';
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

  Future<Reservation> cancelReservation() async{
    try{
      final response = await ApiClient.post(
        'cancel_reservation',
        body: json.encode({
          'reservation_id' : this.id,
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

  Future<Reservation> cancelReservationManager() async{
    try{
      final response = await ApiClient.post(
        'cancel_reservation_manager',
        body: json.encode({
          'reservation_id' : this.id,
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

  Future<Reservation> completedReservationManager() async{
    try{
      final response = await ApiClient.post(
        'completed_reservation_manager',
        body: json.encode({
          'reservation_id' : this.id,
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

  Future<Reservation> confirmedReservationManager() async{
    try{
      final response = await ApiClient.post(
        'confirmed_reservation_manager',
        body: json.encode({
          'reservation_id' : this.id,
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

}