import 'package:prbd_2526_c01/models/restaurant.dart';

class RestaurantTables{
  final int? id;
  final int tableNumber;
  final int capacity;
  final Restaurant restaurant;

  //tout les champs ne sont pas required, pour la création d'une réservation
  const RestaurantTables({
    this.id,
    required this.tableNumber,
    required this.capacity,
    required this.restaurant
  });

  factory RestaurantTables.fromJson(Map<String, dynamic> json) {
    print('TABLE JSON: $json');
    return RestaurantTables(
      id: json['id'],
      tableNumber: json['table_number'],
      capacity: json['capacity'],
      restaurant: Restaurant.fromJson(json['restaurant']),
    );
  }
}