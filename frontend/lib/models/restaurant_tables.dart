import 'dart:convert';
import 'package:prbd_2526_c01/models/restaurant.dart';
import '../core/services/api_client.dart';

class RestaurantTables{
  final int? id;
  final int tableNumber;
  final int capacity;
  final int restaurant;

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
      restaurant: json['restaurant'] is int
          ? json['restaurant']
          : (json['restaurant'] as Map<String, dynamic>)['id'],
    );
  }

  static Future<List<RestaurantTables>> getTablesByRestaurant(int restaurantId) async {
      final response = await ApiClient.post(
        'get_tables_by_restaurant',
        body: json.encode({'restaurant_id': restaurantId}),
      );
      if(response.statusCode != 200) {
        throw Exception('Failed to get tables.');
      }
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => RestaurantTables.fromJson(item as Map<String, dynamic>)).toList();
  }

  // Récupère la capacité minimum autorisée pour une table
  static Future<int> getMinCapacity(int tableId) async {
    final response = await ApiClient.post(
      'get_min_capacity_for_table',
      body: json.encode({'table_id': tableId}),
    );
    if (response.statusCode != 200) throw Exception('Failed to get min capacity.');
    return json.decode(response.body) as int;
  }

  // add table
  static Future<RestaurantTables> addTable({
    required int restaurantId,
    required int tableNumber,
    required int capacity,
  }) async {
    final response = await ApiClient.post(
      'add_table',
      body: json.encode({
        'p_restaurant_id': restaurantId,
        'p_table_number': tableNumber,
        'p_capacity': capacity,
      }),
    );
    if (response.statusCode != 200) throw Exception('Failed to add table.');
    return RestaurantTables.fromJson(json.decode(response.body));
  }

  // edit table
  static Future<RestaurantTables> updateTable({
    required int tableId,
    required int tableNumber,
    required int capacity,
  }) async {
    final response = await ApiClient.post(
      'update_table',
      body: json.encode({
        'p_table_id': tableId,
        'p_table_number': tableNumber,
        'p_capacity': capacity,
      }),
    );
    if (response.statusCode != 200) throw Exception('Failed to update table.');
    return RestaurantTables.fromJson(json.decode(response.body));
  }

}