import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_c01/views/pages/restaurant_management_services.dart';

import '../../providers/manager_state_provider.dart';
import '../pages/restaurant_management_reservations.dart';

class ManagerBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final BuildContext context;

  const ManagerBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: (index) async {
        if (index == currentIndex) return;
        if (index == 0) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  RestaurantManagementReservations(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        } else if (index == 1) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  RestaurantManagementServices(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        } else if (index == 2) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  RestaurantManagementReservations(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.book),
          label: 'Réservations',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.schedule),
          label: 'Services',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.table_restaurant),
          label: 'Tables',
        ),
      ],
    );
  }
}