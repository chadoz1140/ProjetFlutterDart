import 'package:prbd_2526_c01/models/reservation.dart';
import 'package:prbd_2526_c01/models/restaurant.dart';

class ClientState {
  // Reservations
  final Reservation? currentReservation;
  final String? reservationStatusFilter; //status type ('pending',....)
  final List<Reservation> reservations;

  final DateTime? selectedReservationDate;
  final List<String> availableSlots;
  final bool restaurantClosed;
  final bool clientHasReservationForAllServices;
  final bool overCapacity;
  final String? selectedReservationSlot;
  final int newReservationGuests;

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

    this.selectedReservationDate,
    this.availableSlots = const[],
    this.restaurantClosed = false,
    this.clientHasReservationForAllServices = false,
    this.overCapacity = false,
    this.selectedReservationSlot,
    this.newReservationGuests = 2,
  });

  ClientState copyWith({
    Reservation? currentReservation,
    String? selectedReservationSlot,
    int? newReservationGuests,
    bool clearCurrentReservation = false,
    bool clearSelectedReservationSlot = false,
    bool clearReservationStatusFilter = false,
    String? reservationStatusFilter,
    List<Reservation>? reservations,
    Restaurant? currentRestaurant,
    String? searchText,
    List<Restaurant>? restaurants,
    bool? hasMoreResults,

    List<String>? availableSlots,
    bool? restaurantClosed,
    bool? clientHasReservationForAllServices,
    bool? overCapacity,
    DateTime? selectedReservationDate,
  }) {
    return ClientState(
      currentReservation: clearCurrentReservation ? null : (currentReservation ?? this.currentReservation),
      reservationStatusFilter: clearReservationStatusFilter ? null : reservationStatusFilter ?? this.reservationStatusFilter,
      reservations: reservations ?? this.reservations,
      currentRestaurant: currentRestaurant ?? this.currentRestaurant,
      searchText: searchText ?? this.searchText,
      restaurants: restaurants ?? this.restaurants,
      hasMoreResults: hasMoreResults ?? this.hasMoreResults,

      availableSlots: availableSlots ?? this.availableSlots,
      restaurantClosed: restaurantClosed ?? this.restaurantClosed,
      clientHasReservationForAllServices:
      clientHasReservationForAllServices ?? this.clientHasReservationForAllServices,
      overCapacity: overCapacity ?? this.overCapacity,
      selectedReservationDate:
      selectedReservationDate ?? this.selectedReservationDate,

      selectedReservationSlot: clearSelectedReservationSlot
          ? null : (selectedReservationSlot ?? this.selectedReservationSlot),

      newReservationGuests:
      newReservationGuests ?? this.newReservationGuests,

    );

  }
}