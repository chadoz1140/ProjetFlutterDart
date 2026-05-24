

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_c01/views/pages/home_client.dart';
import 'package:prbd_2526_c01/views/pages/search_restaurants_page.dart';
import 'package:prbd_2526_c01/views/pages/signup_page.dart';
import '../providers/current_user_provider.dart';
import '../views/pages/login_page.dart';
import '../views/pages/reservation_details.dart';
import '../views/pages/restaurant_details.dart';
import '../views/pages/restaurant_management_reservations.dart';

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
        '/reservation_details': (context) => ReservationDetails(),
        '/searchRestaurants' : (context) => SearchRestaurantsPage(),
        '/restaurant_details' : (context) => RestaurantDetails(),
        '/myRestantReservations' : (context) => RestaurantManagementReservations(),
      },
    );
  }
}