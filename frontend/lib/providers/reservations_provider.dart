

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_c01/core/tools/abstract_async_notifier.dart';
import 'package:prbd_2526_c01/models/reservation.dart';
import 'package:prbd_2526_c01/providers/security_provider.dart';


final ReservationsProvider = AsyncNotifierProvider<ReservationsNotifier, List<Reservation>>(
    () => ReservationsNotifier(),
);

class ReservationsNotifier extends AbstractAsyncNotifier<List<Reservation>> {
  String? _currentStatus;

  @override
  Future<List<Reservation>> build() async {
    ref.watch(securityProvider);
    try{
      return await Reservation.getReservations(status: _currentStatus);
    }catch(e, stackTrace) {
      state= AsyncValue.error(
      "Something went wrong loading reservations!\n Please try again later?",
      stackTrace,);
    }
     return [];
  }

  @override
  Future<void> refresh() async {
    _currentStatus = null;
     await getReservations(null);
  }

  Future<void> getReservations(String? status) async {
    _currentStatus = status;
    state = const AsyncValue.loading();
    try {
      final reservations = await Reservation.getReservations(status: status);
      state = AsyncValue.data(reservations);
    }catch(e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

}