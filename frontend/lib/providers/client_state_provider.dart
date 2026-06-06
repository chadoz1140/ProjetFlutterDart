
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_c01/core/tools/abstract_async_notifier.dart';
import 'package:prbd_2526_c01/models/client_state.dart';
import 'package:prbd_2526_c01/providers/current_user_provider.dart';

import '../models/reservation.dart';
import '../models/restaurant.dart';

final clientStateProvider = AsyncNotifierProvider<ClientStateNotifier, ClientState>(
      () => ClientStateNotifier(),
);

class ClientStateNotifier extends AbstractAsyncNotifier<ClientState> {

  static final int maxResultNumber = 4;

  // Charge les réservations au démarrage
  @override
  Future<ClientState> build() async {
    ref.watch(currentUserProvider);
    try {
      final reservations = await Reservation.getReservations(status: null);
      final restaurants = await Restaurant.getRestaurants(
        '',
        resultNumber: maxResultNumber + 1,
      );
      return ClientState(
          reservations: reservations,
          restaurants: restaurants,
          searchText: '',
          hasMoreResults: restaurants.length > maxResultNumber
      );
    }catch(e, stackTrace) {
      state = AsyncValue.error(
        "Something went wrong \n Please try again later?",
        stackTrace,);
      return ClientState();
    }
  }

  // Réservations
  Future<void> getReservations(String? status) async {
    final currentState = state.value ?? ClientState();
    state = const AsyncValue.loading();
    try {
      final reservations = await Reservation.getReservations(status: status);
      print('RESERVATIONS: $reservations');
      state = AsyncValue.data(currentState.copyWith(
        reservations: reservations,
        reservationStatusFilter: status,
      )
      );
    }catch(e, stackTrace) {
      state = AsyncValue.error(
          "Something went wrong loading reservations!\n Please try again later?",
          stackTrace);
    }
  }
  // Refresh page home
  @override
  Future<void> refresh() async {
    await getReservations(null);
  }

  // Réservation courante
  Future<void> getReservation(int reservationId) async{
    /* AsyncValue.loading() consèrve l'ancien state
       donc on est pas obliger de l'initialiser dans une variable (final currentState = state.value ?? ManagerState()) */
    final currentState = state.value ?? ClientState();
    state = const AsyncValue.loading();
    try{
      final reservation = await Reservation.getReservation(reservationId);
      state = AsyncData(currentState.copyWith(
        currentReservation: reservation,
      ));
    }
    catch (e) {
      state = AsyncError(
        "Something went wrong!\nPlease try again later.",
        StackTrace.current,
      );
    }
  }

  // Refresh page details restaurant
  Future<void> refreshReservationDetails() async {
    final reservationId = state.value?.currentReservation?.id;
    if(reservationId == null) return;
    await getReservation(reservationId);
  }

  // Restaurants — chercher
  Future<void> search(String text) async {
    final currentState = state.value ?? ClientState();
    state = AsyncValue.loading();
    try{
      final restaurants = await Restaurant.getRestaurants(text, resultNumber: maxResultNumber + 1);
      state = AsyncData(currentState.copyWith(
        searchText: text,
        restaurants: restaurants,
        hasMoreResults: restaurants.length > maxResultNumber,
      ));
    }catch(e){
      state = AsyncError(
        "Something went wrong!\nPlease try again later.",
        StackTrace.current,
      );
    }
  }

  // Refresh page restaurants
  Future<void> refreshRestaurants() async{
    await search('');
  }


  // Restaurant details
  Future<void> getRestaurantDetails(int restaurantId) async {
    state = const AsyncValue.loading();
    try {
      final restaurantDetails = await Restaurant.getRestaurantDetails(restaurantId);
      state = AsyncValue.data(state.value!.copyWith(
        currentRestaurant: restaurantDetails,
      ));
    }catch(e, stackTrace) {
      state = AsyncValue.error(
        "Something went wrong loading restaurant details!\n Please try again later?",
        stackTrace,);
    }
  }

  // Refresh page restaurant details
  Future<void> refreshRestaurantDetails() async {
    final restaurantId = state.value?.currentRestaurant?.id;
    if(restaurantId == null) return;
    await getRestaurantDetails(restaurantId);
  }

   // Modifie une réservation et recharge ses détails
   Future<void> updateReservation({
     required int reservationId,
     required DateTime newDateTime,
     required int numberOfGuests,
     String? specialRequests,
   }) async {
     await Reservation.updateReservation(
       reservationId: reservationId,
       newDateTime: newDateTime,
       numberOfGuests: numberOfGuests,
       specialRequests: specialRequests,
     );
     await getReservation(reservationId);
   }

  Future<void> cancelReservation(Reservation reservation) async{
    state = const AsyncValue.loading();
    try{
      final newReservation = await reservation.cancelReservation();
      state = AsyncData(
        state.value!.copyWith(currentReservation: newReservation),
      );
      await getReservations(state.value!.reservationStatusFilter);
    }
    catch(e){
      state = AsyncValue.error(
          "Something went wrong!\nPlease try again later.",
          StackTrace.current
      );
    }
  }

  Future<void> loadNewReservationForm(int restaurantId) async {
    final currentState = state.value ?? ClientState();
    const numberOfGuests = 2;

    state = const AsyncValue.loading();

    try {
      final data = await Reservation.getFirstAvailableReservationSlot(
        restaurantId,
        numberOfGuests,
      );

      final initialReservation = Reservation.fromInitialReservationJson(
        data,
        numberOfGuests,
      );

      final restaurant = Restaurant.fromJson(data['restaurant']);
      final selectedReservationDate = DateTime.parse(data['reservation_date']);
      final availableSlots = (data['slots'] as List<dynamic>? ?? [])
          .map((slot) => slot.toString())
          .toList();
      final restaurantClosed = data['restaurant_closed'] ?? false;
      final clientHasReservationForAllServices =
          data['client_has_reservation_for_all_services'] ?? false;
      final overCapacity = data['over_capacity'] ?? false;

      state = AsyncValue.data(currentState.copyWith(
        currentReservation: initialReservation,
        clearCurrentReservation: initialReservation == null,
        currentRestaurant: restaurant,
        selectedReservationDate: selectedReservationDate,
        availableSlots: availableSlots,
        restaurantClosed: restaurantClosed,
        clientHasReservationForAllServices: clientHasReservationForAllServices,
        overCapacity: overCapacity,
      ));
    } catch(e, stackTrace) {
      state = AsyncValue.error(
        "Something went wrong loading restaurant details!\n Please try again later?",
        stackTrace,);
    }

  }

  Future<void> loadReservationSlots(DateTime date) async {
    final currentState = state.value ?? ClientState();
    final restaurant = currentState.currentRestaurant;
    final numberOfGuests = currentState.currentReservation?.numberOfGuests ?? 2;

    if (restaurant == null) return;

    state = const AsyncValue.loading();

    try {
      final data = await Reservation.getReservationSlots(
        restaurant.id,
        date,
        numberOfGuests,
      );

      final initialReservation = Reservation.fromInitialReservationJson(
        data,
        numberOfGuests,
      );

      final selectedReservationDate = DateTime.parse(data['reservation_date']);

      final availableSlots = (data['slots'] as List<dynamic>? ?? [])
          .map((slot) => slot.toString())
          .toList();

      state = AsyncValue.data(currentState.copyWith(
        currentReservation: initialReservation,
        clearCurrentReservation: initialReservation == null,
        selectedReservationDate: selectedReservationDate,
        availableSlots: availableSlots,
        restaurantClosed: data['restaurant_closed'] ?? false,
        clientHasReservationForAllServices:
        data['client_has_reservation_for_all_services'] ?? false,
        overCapacity: data['over_capacity'] ?? false,
      ));
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void selectReservationSlot(String slot) {
    final currentState = state.value ?? ClientState();
    final reservation = currentState.currentReservation;
    final selectedDate = currentState.selectedReservationDate;

    if (reservation == null || selectedDate == null) return;

    final parts = slot.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final selectedDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      hour,
      minute,
    );

    final updatedReservation = reservation.copyWith(
      dateTime: selectedDateTime,
    );

    state = AsyncValue.data(currentState.copyWith(
      currentReservation: updatedReservation,
    ));
  }

  Future<void> checkNewReservationOverCapacity(int numberOfGuests) async {
    final currentState = state.value ?? ClientState();
    final reservation = currentState.currentReservation;

    if (reservation == null) return;

    final reservationToCheck = reservation.copyWith(
      numberOfGuests: numberOfGuests,
    );

    try {
      final overCapacity = await Reservation.checkReservationOverCapacity(
        reservationToCheck.restaurant.id,
        reservationToCheck.dateTime,
        numberOfGuests,
      );

      final latestState = state.value ?? currentState;

      state = AsyncValue.data(latestState.copyWith(
        currentReservation: reservationToCheck,
        overCapacity: overCapacity,
      ));
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<Reservation> saveNewReservation(String? specialRequests) async {
    final currentState = state.value ?? ClientState();
    final reservation = currentState.currentReservation;

    if (reservation == null) {
      throw Exception('No reservation selected');
    }

    state = const AsyncValue.loading();

    try {
      final savedReservation = await Reservation.saveReservation(
        reservation.restaurant.id,
        reservation.dateTime,
        reservation.numberOfGuests,
        specialRequests,
      );

      final reservations = [
        savedReservation,
        ...currentState.reservations,
      ];

      state = AsyncValue.data(currentState.copyWith(
        currentReservation: savedReservation,
        reservations: reservations,
      ));
      return savedReservation;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  void changeNewReservationGuests(int numberOfGuests) {
    final currentState = state.value ?? ClientState();
    final reservation = currentState.currentReservation;

    if (reservation == null) return;

    final updatedReservation = reservation.copyWith(
      numberOfGuests: numberOfGuests,
    );

    state = AsyncValue.data(currentState.copyWith(
      currentReservation: updatedReservation,
      overCapacity: false,
    ));
  }

}
