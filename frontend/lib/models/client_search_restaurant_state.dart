import 'package:prbd_2526_c01/models/restaurant_list_item.dart';

class ClientSearchRestaurantState {
  final String searchText;
  final List<RestaurantListItem> restaurants;
  final bool hasMoreResults;

  ClientSearchRestaurantState({
    required this.searchText,
    required this.restaurants,
    required this.hasMoreResults
  });





}