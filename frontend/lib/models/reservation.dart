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

  static Reservation? fromInitialReservationJson(
      Map<String, dynamic> json,
      int numberOfGuests,
      ) {
    final String? selectedSlot = json['selected_slot'];

    if (selectedSlot == null) {
      return null;
    }

    final String reservationDate = json['reservation_date'];

    return Reservation(
      restaurant: Restaurant.fromJson(json['restaurant']),
      dateTime: DateTime.parse('$reservationDate $selectedSlot'),
      numberOfGuests: numberOfGuests,
      status: Status.pending,
    );
  }

  static Future<Map<String, dynamic>> getFirstAvailableReservationSlot(int restaurantId, int numberOfGuests) async{
    final response = await ApiClient.post('get_first_available_reservation_slot',
        body: json.encode(
            {'p_restaurant_id' : restaurantId, 'number_of_guests' : numberOfGuests}
        )
    );
    if (response.statusCode != 200) {
      print('GET RESTAURANTS ERROR STATUS: ${response.statusCode}');
      print('GET RESTAURANTS ERROR BODY: ${response.body}');
      throw Exception('Failed to get restaunts');
    }
    final decodedBody = json.decode(response.body);
    final data = Map<String, dynamic>.from(decodedBody);
    return data;
  }

  static Future<Map<String, dynamic>> getReservationSlots(int restaurantId, DateTime date, int numberOfGuests,) async {
    final dateText = DateFormat('yyyy-MM-dd').format(date);

    final response = await ApiClient.post(
      'get_reservation_slots',
      body: json.encode({
        'p_restaurant_id': restaurantId,
        'p_date': dateText,
        'p_number_of_guests': numberOfGuests,
      }),
    );

    if (response.statusCode != 200) {
      print('GET RESERVATION SLOTS ERROR STATUS: ${response.statusCode}');
      print('GET RESERVATION SLOTS ERROR BODY: ${response.body}');
      throw Exception('Failed to get reservation slots');
    }

    final decodedBody = json.decode(response.body);
    final data = Map<String, dynamic>.from(decodedBody);
    return data;
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