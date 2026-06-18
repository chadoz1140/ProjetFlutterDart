
import 'package:prbd_2526_c01/models/reservation.dart';
import 'package:prbd_2526_c01/models/restaurant.dart';
import 'package:prbd_2526_c01/models/service.dart';
import 'package:prbd_2526_c01/models/restaurant_tables.dart';
import 'package:prbd_2526_c01/models/tables_status.dart';

class ManagerState {
  final Reservation? currentReservation;
  final List<Reservation> reservations;
  final String? reservationStatusFilter;
  final Restaurant? currentRestaurant;
  final List<Restaurant> restaurants;
  final List<Service>services;
  final Map<int, bool>canDeleteServices;
  final List<RestaurantTables> tables;
  final TablesStatus restaurantTablesStatus;

  ManagerState({
    this.currentReservation,
    this.reservations = const [],
    this.reservationStatusFilter,
    this.currentRestaurant,
    this.restaurants = const[],
    this.tables = const[],
    this.restaurantTablesStatus = const TablesStatus(),
    this.services = const[],
    this.canDeleteServices = const {},
  });

  ManagerState copyWith({
    Reservation? currentReservation,
    List<Reservation>? reservations,
    String? reservationStatusFilter,
    bool clearReservationStatusFilter = false,
    Restaurant? currentRestaurant,
    List<Restaurant>? restaurants,
    List<Service>? services,
    Map<int, bool>? canDeleteServices,
    List<RestaurantTables>? tables,
    TablesStatus? restaurantTablesStatus
  }) {
    return ManagerState(
      currentReservation: currentReservation ?? this.currentReservation,
      reservations: reservations ?? this.reservations,
      reservationStatusFilter: clearReservationStatusFilter ? null : (reservationStatusFilter ?? this.reservationStatusFilter),
      currentRestaurant: currentRestaurant ?? this.currentRestaurant,
      restaurants: restaurants ?? this.restaurants,
      services: services ?? this.services,
      canDeleteServices: canDeleteServices ?? this.canDeleteServices,
      tables: tables ?? this.tables,
      restaurantTablesStatus: restaurantTablesStatus ?? this.restaurantTablesStatus,
    );
  }

}