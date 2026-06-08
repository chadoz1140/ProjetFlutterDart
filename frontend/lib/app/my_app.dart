

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_c01/views/pages/add_edit_table.dart';
import 'package:prbd_2526_c01/views/pages/assign_tables.dart';
import 'package:prbd_2526_c01/views/pages/home_client.dart';
import 'package:prbd_2526_c01/views/pages/search_restaurants_page.dart';
import 'package:prbd_2526_c01/views/pages/signup_page.dart';
import '../models/restaurant_tables.dart';
import '../providers/current_user_provider.dart';
import '../views/pages/edit_reservation.dart';
import '../views/pages/home_manager.dart';
import '../views/pages/login_page.dart';
import '../views/pages/new_reservation_page.dart';
import '../views/pages/reservation_details.dart';
import '../views/pages/restaurant_details.dart';
import '../views/pages/restaurant_management_reservations.dart';
import '../views/pages/restaurant_management_services.dart';

class MyApp extends ConsumerWidget{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserNotifier = ref.read(currentUserProvider.notifier);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Namer App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      initialRoute: currentUserNotifier.isLoggedIn ? (currentUserNotifier.isManager ? '/homeManager' : '/home'): '/login',
      routes: {
        '/login' : (context) => LoginPage(),
        '/signup': (context) => SignupPage(),
        '/home' : (context) => HomeClient(),
        '/homeManager' : (context) =>  HomeManager(),
        '/searchRestaurants' : (context) => SearchRestaurantsPage(),
        '/restaurant_details' : (context) => RestaurantDetails(),
        '/reservation_details': (context) => ReservationDetails(),
        '/new_reservation': (context) => NewReservationPage(),
        '/myRestaurantReservations' : (context) => RestaurantManagementReservations(),
        '/edit_reservation'     : (context) =>  EditReservationPage(),
        '/RestaurantManagementServices' : (context) => RestaurantManagementServices(),

        '/add_edit_table': (context) {
          final table = ModalRoute.of(context)?.settings.arguments as RestaurantTables?;
          return AddEditTable(table: table);
        },
        '/assign_tables' : (context) => AssignTables()
      },
    );
  }
}