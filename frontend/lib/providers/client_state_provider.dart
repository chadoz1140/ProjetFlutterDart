
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_c01/core/tools/abstract_async_notifier.dart';
import 'package:prbd_2526_c01/models/client_state.dart';
import 'package:prbd_2526_c01/providers/current_user_provider.dart';

import '../models/reservation.dart';
import '../models/restaurant.dart';
import '../models/status.dart';

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
    state = const AsyncValue.loading();
    try{
      final reservation = await Reservation.getReservation(reservationId);
      state = AsyncData(state.value!.copyWith(
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


}
