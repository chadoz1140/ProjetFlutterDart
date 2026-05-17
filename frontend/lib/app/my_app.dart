

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_c01/views/pages/home_client.dart';
import 'package:prbd_2526_c01/views/pages/search_restaurants_page.dart';
import 'package:prbd_2526_c01/views/pages/signup_page.dart';
import '../providers/security_provider.dart';
import '../views/pages/login_page.dart';

class MyApp extends ConsumerWidget{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final securityNotifier = ref.read(securityProvider.notifier);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Namer App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      initialRoute: securityNotifier.isLoggedIn ? '/home' : '/login',
      routes: {
        '/login' : (context) => LoginPage(),
        '/signup': (context) => SignupPage(),
        '/home' : (context) => HomeClient(),
        '/searchRestaurants' : (context) => SearchRestaurantsPage(),
      },
    );
  }
}