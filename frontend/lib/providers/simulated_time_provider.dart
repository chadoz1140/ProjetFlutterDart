
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_c01/core/tools/abstract_async_notifier.dart';
import 'package:prbd_2526_c01/models/system_time.dart';

final simulatedTimeProvider = AsyncNotifierProvider<SimulatedTimeNotifier, DateTime?>(
    () => SimulatedTimeNotifier(),
);

class SimulatedTimeNotifier extends AbstractAsyncNotifier<DateTime?> {
  @override
  FutureOr<DateTime?> build() async{
    final systemTime = await SystemTime.getSystemTime();
    return systemTime.simulatedTime;
  }

  @override
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    final systemTime = await SystemTime.getSystemTime();
    state = AsyncValue.data(systemTime.simulatedTime);
  }

}