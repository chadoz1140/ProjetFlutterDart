
import 'package:prbd_2526_c01/models/reservation.dart';
import 'package:prbd_2526_c01/models/restaurant.dart';
import 'package:prbd_2526_c01/models/service.dart';

class ManagerState {
  final Reservation? currentReservation;
  final List<Reservation> reservations;
  final Restaurant? currentRestaurant;
  final List<Restaurant> restaurants;
  final List<Service>services;
  final Map<int, bool>canDeleteServices;

  ManagerState({
    this.currentReservation,
    this.reservations = const [],
    this.currentRestaurant,
    this.restaurants = const[],
    this.services = const[],
    this.canDeleteServices = const {},
  });

  ManagerState copyWith({
    Reservation? currentReservation,
    List<Reservation>? reservations,
    Restaurant? currentRestaurant,
    List<Restaurant>? restaurants,
    List<Service>? services,
    Map<int, bool>? canDeleteServices,
  }) {
    return ManagerState(
      currentReservation: currentReservation ?? this.currentReservation,
      reservations: reservations ?? this.reservations,
      currentRestaurant: currentRestaurant ?? this.currentRestaurant,
      restaurants: restaurants ?? this.restaurants,
      services: services ?? this.services,
      canDeleteServices: canDeleteServices ?? this.canDeleteServices
    );
  }

}