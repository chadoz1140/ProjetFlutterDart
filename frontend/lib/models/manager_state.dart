
import 'package:prbd_2526_c01/models/reservation.dart';
import 'package:prbd_2526_c01/models/restaurant.dart';
import 'package:prbd_2526_c01/models/restaurant_tables.dart';
import 'package:prbd_2526_c01/models/tables_status.dart';

class ManagerState {
  final Reservation? currentReservation;
  final List<Reservation> reservations;
  final Restaurant? currentRestaurant;
  final List<Restaurant> restaurants;
  final List<RestaurantTables> tables;
  final TablesStatus restaurantTablesStatus;

  ManagerState({
    this.currentReservation,
    this.reservations = const [],
    this.currentRestaurant,
    this.restaurants = const[],
    this.tables = const[],
    this.restaurantTablesStatus = const TablesStatus(),
  });

  ManagerState copyWith({
    Reservation? currentReservation,
    List<Reservation>? reservations,
    Restaurant? currentRestaurant,
    List<Restaurant>? restaurants,
    List<RestaurantTables>? tables,
    TablesStatus? restaurantTablesStatus
  }) {
    return ManagerState(
      currentReservation: currentReservation ?? this.currentReservation,
      reservations: reservations ?? this.reservations,
      currentRestaurant: currentRestaurant ?? this.currentRestaurant,
      restaurants: restaurants ?? this.restaurants,
      tables: tables ?? this.tables,
      restaurantTablesStatus: restaurantTablesStatus ?? this.restaurantTablesStatus,
    );
  }

}