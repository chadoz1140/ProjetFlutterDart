

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_c01/core/tools/abstract_async_notifier.dart';
import 'package:prbd_2526_c01/providers/security_provider.dart';

import '../models/restaurant.dart';

final restaurantDetailsProvider = AsyncNotifierProvider<RestaurantNotifier, Restaurant?>(
    () => RestaurantNotifier(),
);


class RestaurantNotifier extends AbstractAsyncNotifier<Restaurant?> {
  int? _restaurantId;

  @override
  Future<Restaurant?> build() async {
    ref.watch(securityProvider);
    return null;
  }

  @override
  Future<void> refresh() async {
    await getRestaurantDetails(_restaurantId!);
  }

  Future<void> getRestaurantDetails(int restaurantId) async {
    _restaurantId = restaurantId;
    state = const AsyncValue.loading();
    try {
      final restaurantDetails = await Restaurant.getRestaurantDetails(restaurantId);
      state = AsyncValue.data(restaurantDetails);
    }catch(e, stackTrace) {
      state = AsyncValue.error(
        "Something went wrong loading restaurant details!\n Please try again later?",
        stackTrace,);
    }
  }

}