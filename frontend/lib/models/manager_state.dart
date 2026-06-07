
import 'package:prbd_2526_c01/models/reservation.dart';
import 'package:prbd_2526_c01/models/restaurant.dart';
import 'package:prbd_2526_c01/models/service.dart';
import 'package:prbd_2526_c01/models/restaurant_tables.dart';

class ManagerState {
  final Reservation? currentReservation;
  final List<Reservation> reservations;
  final Restaurant? currentRestaurant;
  final List<Restaurant> restaurants;
  final List<Service>services;
  final Map<int, bool>canDeleteServices;
  final List<RestaurantTables> tables;

  ManagerState({
    this.currentReservation,
    this.reservations = const [],
    this.currentRestaurant,
    this.restaurants = const[],
    this.services = const[],
    this.canDeleteServices = const {},
    this.tables = const[]
  });

  ManagerState copyWith({
    Reservation? currentReservation,
    List<Reservation>? reservations,
    Restaurant? currentRestaurant,
    List<Restaurant>? restaurants,
    List<Service>? services,
    Map<int, bool>? canDeleteServices,
    List<RestaurantTables>? tables,
  }) {
    return ManagerState(
      currentReservation: currentReservation ?? this.currentReservation,
      reservations: reservations ?? this.reservations,
      currentRestaurant: currentRestaurant ?? this.currentRestaurant,
      restaurants: restaurants ?? this.restaurants,
      services: services ?? this.services,
      canDeleteServices: canDeleteServices ?? this.canDeleteServices,
      tables: tables ?? this.tables,
    );
  }

}