import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prbd_2526_c01/core/widgets/data.error.widget.dart';
import 'package:prbd_2526_c01/providers/manager_state_provider.dart';
import 'package:prbd_2526_c01/providers/reference_time_provider.dart';
import 'package:prbd_2526_c01/views/pages/reservation_details_manager.dart';
import 'package:prbd_2526_c01/views/pages/restaurant_management_services.dart';
import 'package:prbd_2526_c01/views/widgets/restaurant_management_reservations_card.dart';

import '../../models/manager_state.dart';
import '../widgets/manager_bottom_navigation.dart';

class RestaurantManagementReservations extends ConsumerStatefulWidget{

  const RestaurantManagementReservations({super.key});

  @override
  ConsumerState<RestaurantManagementReservations> createState() => _RestaurantManagementReservationsState();

}

class _RestaurantManagementReservationsState extends ConsumerState<RestaurantManagementReservations> {
  String _selectedStatus = 'all';
  @override
  Widget build(BuildContext context) {
    final managerState = ref.watch(managerStateProvider);
    final managerNotifier = ref.read(managerStateProvider.notifier);

    final theme = Theme.of(context);
    final now = ref.watch(referenceTimeProvider);

    return managerState.when(
      data: (state) => data(state, managerNotifier, theme, now),
      error: (err, _) =>
          DataErrorWidget(
              error: err,
              stackTrace: StackTrace.current,
              notifier: managerNotifier),
      loading: () => data(managerState.value ?? ManagerState(), managerNotifier, theme, now, isLoading: true),
    );
  }
  Widget data(ManagerState state, ManagerStateNotifier notifier, ThemeData theme, DateTime now, {isLoading = false}) {
     final restaurant = state.currentRestaurant;
     if(restaurant == null) {
       return const Scaffold(
         body: Center(child : CircularProgressIndicator()),
       );
     }
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(restaurant.name),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Rafraîchir les données',
              onPressed: () => notifier.refresh(),
            ),
          ],
          elevation: 2,
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          surfaceTintColor: Colors.transparent,
          flexibleSpace: Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Tooltip(
                  message:
                  'Date/heure simulée utilisée pour les tests.\nCliquez pour modifier.',
                  child: Text(
                    DateFormat('EEEE dd/MM/yyyy HH:mm', 'fr_FR')
                        .format(now),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                child: SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: 'all',
                      icon: Icon(Icons.list, size: 24),
                      tooltip: 'Toutes',
                    ),
                    ButtonSegment(
                      value: 'pending',
                      icon: Icon(Icons.pending, size: 24, color: Colors.orange),
                      tooltip: 'En attente',
                    ),
                    ButtonSegment(
                      value: 'confirmed',
                      icon: Icon(
                          Icons.check_circle, size: 24, color: Colors.green),
                      tooltip: 'Confirmées',
                    ),
                    ButtonSegment(
                      value: 'completed',
                      icon: Icon(
                          Icons.event_available, size: 24, color: Colors.blue),
                      tooltip: 'Terminées',
                    ),
                    ButtonSegment(
                      value: 'cancelled',
                      icon: Icon(Icons.cancel, size: 24, color: Colors.red),
                      tooltip: 'Annulées',
                    ),
                  ],
                  selected: {_selectedStatus},
                  onSelectionChanged: (selection) {
                    setState(() => _selectedStatus = selection.first);
                    final status = selection.first == 'all' ? null : selection.first;
                    notifier.getReservationsByRestaurant(restaurant.id, status);
                  },
                ),
              ),
              const SizedBox(height: 8),
              if(isLoading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if(state.reservations.isEmpty)
                const Expanded(
                    child: Center(
                      child: Text('Aucune réservation.'),
                    ),
                )
              else
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                        for(var reservation in state.reservations)
                          RestaurantManagementReservationsCard(
                              reservation: reservation,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ReservationDetailsManager(
                                        reservation: reservation
                                    ),
                                  ),
                                ).then((_) => notifier.refresh());
                              },
                          )
                    ],
                  ),
                ),
            ],
          ),
        ),
        bottomNavigationBar: ManagerBottomNavigation(currentIndex: 0, context: context),

      );
    }
  }

