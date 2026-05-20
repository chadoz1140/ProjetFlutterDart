import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prbd_2526_c01/core/widgets/data_error_widget.dart';
import 'package:prbd_2526_c01/models/reservation.dart';
import 'package:prbd_2526_c01/providers/reference_time_provider.dart';
import 'package:prbd_2526_c01/providers/reservations_provider.dart';
import 'package:prbd_2526_c01/providers/security_provider.dart';

import '../../core/widgets/reservation_card.dart';

class HomeClient extends ConsumerStatefulWidget{
  const HomeClient({super.key});

  @override
  ConsumerState<HomeClient> createState() => _HomeClientState();

}

class _HomeClientState extends ConsumerState<HomeClient> {

  String _selectedStatus = 'all';

  void _logout() {
    ref.read(securityProvider.notifier).logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(ReservationsProvider);
    final notifier = ref.read(ReservationsProvider.notifier);
    final theme = Theme.of(context);
    final now = ref.watch(referenceTimeProvider);


    return asyncState.when(
        data: (state) => data(state, notifier, theme, now),
        error: (err, _) => DataErrorWidget(
            error: err,
            stackTrace: StackTrace.current,
            notifier: notifier,
        ),
        loading: () => data(asyncState.value ?? [], notifier, theme, now, isLoading: true),
    );
  }


  Widget data(List<Reservation> reservations, ReservationsNotifier notifier, ThemeData theme, DateTime now, {isLoading = false,}){
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes réservations'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, '/searchRestaurants'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir les données',
            onPressed: () {
              setState(() => _selectedStatus = 'all');
              notifier.refresh();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: _logout,
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
                message: 'Date/heure simulée utilisée pour les tests.\nCliquez pour modifier.',
                child: Text(
                  DateFormat('EEEE dd/MM/yyyy HH:mm', 'fr_BE').format(now),
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
                    icon: Icon(Icons.check_circle, size: 24, color: Colors.green),
                    tooltip: 'Confirmées',
                  ),
                  ButtonSegment(
                    value: 'completed',
                    icon: Icon(Icons.event_available, size: 24, color: Colors.blue),
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
                    setState( () => _selectedStatus = selection.first);
                    final status = selection.first == 'all' ? null : selection.first;
                    notifier.getReservations(status);
                },
              ),
            ),
            const SizedBox(height: 8),
            if(isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if(reservations.isEmpty)
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
                    for (var reservation in reservations)
                      ReservationCard(
                        reservation: reservation,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/reservation_details',
                            arguments: reservation.id
                            //                 pour afficher la page reservation_details sinon elle ne s'affiche pas
                            //arguments: reservationId
                            // après << arguments: >> on met l'id de la reservation,
                            // pour afficher la page reservation_details
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Nouvelle réservation'),
          ),
        );
  }


}
