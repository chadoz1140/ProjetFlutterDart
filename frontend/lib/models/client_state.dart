import 'package:prbd_2526_c01/models/reservation.dart';
import 'package:prbd_2526_c01/models/restaurant.dart';
import 'package:prbd_2526_c01/models/status.dart';

class ClientState {
  // Reservations
  final Reservation? currentReservation;
  final String? reservationStatusFilter; //status type ('pending',....)
  final List<Reservation> reservations;

  // Restaurants
  final Restaurant? currentRestaurant;
  final String searchText;
  final List<Restaurant> restaurants;
  final bool hasMoreResults;

  ClientState({
    this.currentReservation,
    this.reservationStatusFilter,
    this.reservations = const [],
    this.currentRestaurant,
    this.searchText = '',
    this.restaurants = const [],
    this.hasMoreResults = false,
  });

  ClientState copyWith({
    Reservation? currentReservation,
    String? reservationStatusFilter,
    List<Reservation>? reservations,
    Restaurant? currentRestaurant,
    String? searchText,
    List<Restaurant>? restaurants,
    bool? hasMoreResults,
  }) {
    return ClientState(
        currentReservation: currentReservation ?? this.currentReservation,
        reservationStatusFilter: reservationStatusFilter ?? this.reservationStatusFilter,
        reservations: reservations ?? this.reservations,
        currentRestaurant: currentRestaurant ?? this.currentRestaurant,
        searchText: searchText ?? this.searchText,
        restaurants: restaurants ?? this.restaurants,
        hasMoreResults: hasMoreResults ?? this.hasMoreResults,
    );

  }
}