
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
    try {
      final reservations = await Reservation.getReservations(status: status);
      state = AsyncValue.data(currentState.copyWith(
        reservations: reservations,
        reservationStatusFilter: status,
        clearReservationStatusFilter: status == null,
      ));
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
    final currentState = state.value ?? ClientState();
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

  List<Reservation> updateReservationInList(ClientState currentState, Reservation newReservation){
    final updatedReservations = <Reservation>[];
    final filter = currentState.reservationStatusFilter;

    for (final reservation in currentState.reservations) {

      final reservationToShow = reservation.id == newReservation.id ? newReservation : reservation;

      if (filter == null || reservationToShow.status.name == filter) {
        updatedReservations.add(reservationToShow);
      }
    }
    return updatedReservations;
  }

  Future<bool> cancelReservation(Reservation reservation) async{
    final currentState = state.value ?? ClientState();
    try{
      final newReservation = await Reservation.cancelReservation(reservation);
      final updatedReservations = updateReservationInList(currentState, newReservation);

      state = AsyncData(currentState.copyWith(
        currentReservation: newReservation,
        reservations: updatedReservations,
      ));
      return true;
    }
    catch(e){
      state = AsyncValue.error(
          "Something went wrong!\nPlease try again later.",
          StackTrace.current
      );
      return false;
    }
  }

  Future<void> loadReservationSlots(DateTime date, {bool firstOpening = false}) async {
    final currentState = state.value ?? ClientState();
    final restaurant = currentState.currentRestaurant;

    if (restaurant == null) return;

    state = const AsyncValue.loading();

    try {
      final data = await Reservation.getNewReservationData(
        restaurant.id,
        date,
      );


      final selectedDate =
            DateTime.parse(data['reservation_date']);

      final availableSlots = (data['slots'] as List<dynamic>? ?? [])
          .map((slot) => slot.toString())
          .toList();
      final numberOfGuests = firstOpening
          ? 2
          : currentState.newReservationGuests;

      String? slotToSelect;

      if (firstOpening && availableSlots.isNotEmpty) {
        slotToSelect = availableSlots.first;
      } else if (availableSlots.contains(currentState.selectedReservationSlot)) {
        slotToSelect = currentState.selectedReservationSlot;
      }

      state = AsyncValue.data(currentState.copyWith(
        selectedReservationDate: selectedDate,
        availableSlots: availableSlots,
        newReservationGuests: numberOfGuests,
        restaurantClosed: data['restaurant_closed'] ?? false,
        clientHasReservationForAllServices:
        data['client_has_reservation_for_all_services'] ?? false,

        selectedReservationSlot: slotToSelect,
        clearSelectedReservationSlot: slotToSelect == null,

        clearCurrentReservation: true,
        overCapacity: false,
      ));
      if (slotToSelect != null) {
        await checkNewReservationOverCapacity(
          numberOfGuests,
        );
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void changeNewReservationGuests(int numberOfGuests) {
    final currentState = state.value ?? ClientState();

    state = AsyncValue.data(currentState.copyWith(
      newReservationGuests: numberOfGuests,
      overCapacity: false,
    ));
  }

  void selectReservationSlot(String slot) {
    final currentState = state.value ?? ClientState();

    state = AsyncValue.data(currentState.copyWith(
      selectedReservationSlot: slot,
      overCapacity: false,
    ));
  }

  Future<void> checkNewReservationOverCapacity(int numberOfGuests) async {
    final currentState = state.value ?? ClientState();

    final restaurant = currentState.currentRestaurant;
    final date = currentState.selectedReservationDate;
    final slot = currentState.selectedReservationSlot;

    if (restaurant == null || date == null || slot == null) {
      return;
    }

    final parts = slot.split(':');
    final reservationDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    try {
      final overCapacity =
      await Reservation.checkReservationOverCapacity(
        restaurant.id,
        reservationDateTime,
        numberOfGuests,
      );

      final latestState = state.value ?? currentState;

      state = AsyncValue.data(latestState.copyWith(
        overCapacity: overCapacity,
      ));
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<Reservation> saveNewReservation(String? specialRequests) async {
    final currentState = state.value ?? ClientState();

    final restaurant = currentState.currentRestaurant;
    final date = currentState.selectedReservationDate;
    final slot = currentState.selectedReservationSlot;
    final numberOfGuests  = currentState.newReservationGuests;

    if (restaurant == null || date == null || slot == null) {
      throw Exception('Informations de réservation manquantes');
    }

    final parts = slot.split(':');

    final reservationDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    state = const AsyncValue.loading();

    try {
      final savedReservation = await Reservation.saveReservation(
        restaurant.id,
        reservationDateTime,
        numberOfGuests ,
        specialRequests,
      );

      state = AsyncValue.data(currentState.copyWith(
        currentReservation: savedReservation,
        reservations: [
          savedReservation,
          ...currentState.reservations,
        ],
      ));
      return savedReservation;
    } catch (e) {
      state = AsyncValue.error(
          "Something went wrong!\nPlease try again later.",
          StackTrace.current
      );
      throw Exception('Failed to save reservation');
    }
  }



}
