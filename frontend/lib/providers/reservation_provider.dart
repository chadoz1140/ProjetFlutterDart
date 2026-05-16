import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_c01/core/tools/abstract_async_notifier.dart';
import 'package:prbd_2526_c01/models/reservation.dart';
import 'package:prbd_2526_c01/providers/security_provider.dart';

final reservationProvider =
  AsyncNotifierProvider.family<ReservationNotifier, Reservation, int>(
    ReservationNotifier.new,
);

class ReservationNotifier extends AbstractAsyncNotifier<Reservation> {
  final int reservationId;

  ReservationNotifier(this.reservationId);

  @override
  Future<Reservation> build() async{
    ref.watch(securityProvider);
    try{
      state = AsyncLoading();
      return await Reservation.getReservation(reservationId);
    }
    catch (e) {
      throw "Something went wrong!\nPlease try again later.";
    }
  }

  @override
  Future<void> refresh() async {
    await getReservation();
  }

  Future<void> getReservation() async{
    state = const AsyncValue.loading();
    try{
      final reservation = await Reservation.getReservation(reservationId);
      state = AsyncData(reservation);
    }
    catch (e) {
      state = AsyncError(
        "Something went wrong!\nPlease try again later.",
        StackTrace.current,
      );
    }
  }
}
