

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

}
