
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_c01/providers/simulated_time_provider.dart';

final referenceTimeProvider = Provider<DateTime>((ref) {
  final simulated = ref.watch(simulatedTimeProvider);

  return simulated.when(
      data: (simulated) => simulated ?? DateTime.now(),
      loading: () => DateTime.now(),
      error: (_, __) => DateTime.now(),);
});