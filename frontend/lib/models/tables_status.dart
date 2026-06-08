import 'package:prbd_2526_c01/models/restaurant_tables.dart';

class TablesStatus {
  final List<RestaurantTables> reservedTables;
  final List<RestaurantTables> notReservedTables;

  const TablesStatus({
    this.reservedTables = const[],
    this.notReservedTables = const[],
  });
}