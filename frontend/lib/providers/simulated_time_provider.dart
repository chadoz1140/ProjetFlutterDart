
import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_c01/core/tools/abstract_async_notifier.dart';
import 'package:prbd_2526_c01/models/system_time.dart';

import '../core/services/api_client.dart';

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

  // Change le temps simulé
  Future<void> setTime(DateTime newTime) async {
    await ApiClient.post(
      'set_system_time',
      body: json.encode({'p_simulated_time': newTime.toIso8601String()}),
    );
    state = AsyncValue.data(newTime);
  }

  // Efface le temps simulé (retour au temps réel)
  Future<void> clearTime() async {
    await ApiClient.post(
      'set_system_time',
      body: json.encode({'p_simulated_time': null}),
    );
    state = const AsyncValue.data(null);
  }

}