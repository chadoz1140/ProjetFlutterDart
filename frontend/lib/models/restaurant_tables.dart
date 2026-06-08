import 'dart:convert';

import 'package:prbd_2526_c01/models/restaurant.dart';
import 'package:prbd_2526_c01/models/tables_status.dart';

import '../core/services/api_client.dart';

class RestaurantTables{
  final int? id;
  final int tableNumber;
  final int capacity;
  final int restaurant;
  final List<RestaurantTables>? reservedTables;
  final List<RestaurantTables>? notReservedTables;

  const RestaurantTables({
    this.id,
    required this.tableNumber,
    required this.capacity,
    required this.restaurant,
    this.reservedTables,
    this.notReservedTables
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

  static Future<TablesStatus> getTablesStatus(int reservationId) async {
    final response = await ApiClient.post(
      'get_table_info_status_by_reservation_id',
      body: json.encode({'reservation_id': reservationId}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      final reservedTables = (data['reserved'] as List)
          .map((tableJson) => RestaurantTables.fromJson(tableJson))
          .toList();

      final notReservedTables = (data['not_reserved'] as List)
          .map((tableJson) => RestaurantTables.fromJson(tableJson))
          .toList();

      return TablesStatus(reservedTables: reservedTables, notReservedTables: notReservedTables);
    }

    throw Exception('Failed to get table status');
  }
}