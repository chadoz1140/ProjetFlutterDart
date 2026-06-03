

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_c01/core/tools/abstract_async_notifier.dart';
import 'package:prbd_2526_c01/models/client_state.dart';
import 'package:prbd_2526_c01/models/manager_state.dart';
import 'package:prbd_2526_c01/models/reservation.dart';
import 'package:prbd_2526_c01/models/restaurant.dart';
import 'package:prbd_2526_c01/providers/current_user_provider.dart';

final managerStateProvider = AsyncNotifierProvider<ManagerStateNotifier, ManagerState>(
    () => ManagerStateNotifier(),
);

class ManagerStateNotifier extends AbstractAsyncNotifier<ManagerState> {

  // Au démarrage charge les restaurants du manager
  @override
  FutureOr<ManagerState> build() async {
    return ManagerState();

  }

  // Reservations by restaurant
  Future<void> getReservationsByRestaurant(int restaurantId, String? status) async {
    final currentState = state.value ?? ManagerState();
    state = const AsyncValue.loading();
    try {
      final reservations = await Reservation.getReservationsByRestaurant(restaurantId, status: status);
      state = AsyncValue.data(currentState.copyWith(
        reservations : reservations,
      ));
    }catch(e, stackTrace) {
      state = AsyncValue.error(
          "Something went wrong loading reservations!",
           stackTrace);
    }
  }

  // Refresh page restaurant management reservations
  @override
  Future<void> refresh() async {
    final restaurantId = state.value?.currentRestaurant?.id;
    if(restaurantId == null) return;
    return getReservationsByRestaurant(restaurantId, null);
  }

  Future<void> getReservationDetailsManager(int reservationId) async {
    /*AsyncValue.loading() consèrve l'ancien state
     donc on est pas obliger de l'initialiser dans une variable (final currentState = state.value ?? ManagerState())*/

    state = const AsyncValue.loading();
    try {
      final reservation = await Reservation.getReservationDetailsManager(reservationId);
      state = AsyncData(state.value!.copyWith(
        currentReservation: reservation,
      ));
    } catch (e) {
      state = AsyncError(
        "Something went wrong!\nPlease try again later.",
        StackTrace.current,
      );
    }
  }

  // Refresh page details restaurant
  Future<void> refreshReservationDetailsManager() async {
    final reservationId = state.value?.currentReservation?.id;
    if (reservationId == null) return;

    await getReservationDetailsManager(reservationId);
  }

  Future<void> cancelReservationManager(Reservation reservation) async{
    state = const AsyncValue.loading();
    try{
      final newReservation = await reservation.cancelReservationManager();
      state = AsyncData(
        state.value!.copyWith(currentReservation: newReservation),
      );

    }
    catch(e){
      state = AsyncValue.error(
          "Something went wrong!\nPlease try again later.",
          StackTrace.current
      );
    }
  }

  Future<void> completedReservationManager(Reservation reservation) async{
    state = const AsyncValue.loading();
    try{
      final newReservation = await reservation.completedReservationManager();
      state = AsyncData(
        state.value!.copyWith(currentReservation: newReservation),
      );

    }
    catch(e){
      state = AsyncValue.error(
          "Something went wrong!\nPlease try again later.",
          StackTrace.current
      );
    }
  }

  Future<void> confirmedReservationManager(Reservation reservation) async{
    state = const AsyncValue.loading();
    try{
      final newReservation = await reservation.confirmedReservationManager();
      state = AsyncData(
        state.value!.copyWith(currentReservation: newReservation),
      );

    }
    catch(e){
      state = AsyncValue.error(
          "Something went wrong!\nPlease try again later.",
          StackTrace.current
      );
    }
  }
}
