import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_c01/models/client_search_restaurant_state.dart';
import 'package:prbd_2526_c01/models/restaurant_list_item.dart';
import 'package:prbd_2526_c01/providers/security_provider.dart';
import '../core/tools/abstract_async_notifier.dart';

final restaurantProvider = AsyncNotifierProvider<ClientSearchRestaurantNotifier, ClientSearchRestaurantState>(
    () => ClientSearchRestaurantNotifier(),
);



class ClientSearchRestaurantNotifier extends AbstractAsyncNotifier<ClientSearchRestaurantState> {

  static final int maxResultNumber = 4;

  @override
  Future<ClientSearchRestaurantState> build() async {
    ref.watch(securityProvider);
    state = AsyncData(
        ClientSearchRestaurantState(
            searchText: '',
            restaurants: [],
            hasMoreResults: false
        )
    );
    state = AsyncValue.loading();
    try {
      final restaurants = await RestaurantListItem.getRestaurants('', resultNumber: maxResultNumber + 1);
      return ClientSearchRestaurantState(
          searchText: '',
          restaurants: restaurants,
          hasMoreResults: restaurants.length > maxResultNumber
      );
    }catch(e){
      throw "Something went wrong!\nPlease try again later.";
    }
  }


  Future<void> search(String text) async {
    state = AsyncValue.loading();
    try{
      final restaurants = await RestaurantListItem.getRestaurants(text, resultNumber: maxResultNumber + 1);
      state = AsyncData(ClientSearchRestaurantState(
          searchText: text,
          restaurants: restaurants,
          hasMoreResults: restaurants.length > maxResultNumber
      ));
    }catch(e){
      state = AsyncError(
        "Something went wrong!\nPlease try again later.",
        StackTrace.current,
      );
    }
  }

  @override
  Future<void> refresh() async{
    state = const AsyncValue.loading();
    try {
      final restaurants = await RestaurantListItem.getRestaurants('', resultNumber: maxResultNumber + 1);
      state = AsyncData(
           ClientSearchRestaurantState(
               searchText: '',
               restaurants: restaurants,
               hasMoreResults: restaurants.length > maxResultNumber
           )
       );
    }catch(e){
      state = AsyncError(
        "Something went wrong!\nPlease try again later.",
        StackTrace.current,
      );
    }
  }
}