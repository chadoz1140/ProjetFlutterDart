import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prbd_2526_c01/models/manager_state.dart';
import 'package:prbd_2526_c01/models/restaurant_tables.dart';
import 'package:prbd_2526_c01/models/status.dart';
import 'package:prbd_2526_c01/views/pages/reservation_details_manager.dart';
import '../../core/widgets/data.error.widget.dart';
import '../../models/reservation.dart';
import '../../providers/manager_state_provider.dart';
import '../../providers/reference_time_provider.dart';
import '../widgets/simulated_time_dialog.dart';

class AssignTables extends ConsumerStatefulWidget{

  const AssignTables({super.key});

  @override
  ConsumerState<AssignTables> createState() => _AssignTablesState();
}

class _AssignTablesState extends ConsumerState<AssignTables> {
  int totalCapacity = 0;
  List<int> tableIds = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final reservation = ModalRoute.of(context)!.settings.arguments as Reservation;
      ref.read(managerStateProvider.notifier).getTablesStatus(reservation);
    });
  }

  @override
  Widget build(BuildContext context) {
    final managerState = ref.watch(managerStateProvider);
    final managerNotifier = ref.read(managerStateProvider.notifier);

    final theme = Theme.of(context);
    final now = ref.watch(referenceTimeProvider);


    return managerState.when(
        error: (err, _) =>
            DataErrorWidget(
              error: err,
              stackTrace: StackTrace.current,
              notifier: managerNotifier,
            ),
        loading: () =>
        const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        data: (state) => data(theme, now, managerNotifier, state)
    );
  }
  Widget data(
      ThemeData  theme,
      DateTime now,
      ManagerStateNotifier managerNotifier,
      ManagerState managerState,
      ){
    final reservedTables = managerState.restaurantTablesStatus.reservedTables;
    final notReservedTables = managerState.restaurantTablesStatus.notReservedTables;
    final currentReservation = managerState.currentReservation;

    if (currentReservation == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Assigner des tables'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir les données',
            onPressed: () {
              managerNotifier.refreshTablesStatus();
            },
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
                child: GestureDetector(
                  onTap: () => SimulatedTimeDialog.show(context, ref),
                  child: Text(
                    DateFormat('EEEE dd/MM/yyyy HH:mm', 'fr_FR').format(now),
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
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Réservation',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('${currentReservation.numberOfGuests} convives'),
                      Text('${DateFormat('dd/MM/yyyy').format(currentReservation.dateTime)} à '
                          '${DateFormat('HH:mm').format(currentReservation.dateTime)}'),
                    ],
                  ),
                ),
              ),
            ),
            if (totalCapacity > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  color: totalCapacity >= currentReservation.numberOfGuests
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          totalCapacity >= currentReservation.numberOfGuests
                              ? Icons.check_circle
                              : Icons.warning,
                          color: totalCapacity >= currentReservation.numberOfGuests
                              ? Colors.green[700]
                              : Colors.orange[700],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                               Text(
                                'Capacité totale: $totalCapacity places',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text( totalCapacity >= currentReservation.numberOfGuests ?
                              '✓ Capacité suffisante pour ${currentReservation.numberOfGuests} convives' :
                              ' ⚠️ Capacité insuffisante: $totalCapacity places pour ${currentReservation.numberOfGuests} convives',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: totalCapacity >= currentReservation.numberOfGuests
                                      ? Colors.green.shade700
                                      : Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  'Sélectionnez les tables disponibles',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  for (int i = 0; i < notReservedTables.length; ++i)
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: CheckboxListTile(
                        value: tableIds.contains(notReservedTables[i].id),
                        onChanged: (_) {
                          setState(() {
                            if (tableIds.contains(notReservedTables[i].id)){
                              totalCapacity -= notReservedTables[i].capacity;
                              tableIds.remove(notReservedTables[i].id);
                            }
                            else{
                              totalCapacity += notReservedTables[i].capacity;
                              tableIds.add(notReservedTables[i].id!);
                            }
                          });
                        },
                        title: Text('Table ${notReservedTables[i].tableNumber}'),
                        subtitle: Text(
                          'Capacité: ${notReservedTables[i].capacity} personnes',
                        ),
                        secondary: const Icon(Icons.table_restaurant),
                      ),
                    ),

                  for (int i = 0; i < reservedTables.length; ++i)
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: Colors.grey.shade100,
                      child: CheckboxListTile(
                        value: false,
                        onChanged: null,
                        title: Text(
                          'Table ${reservedTables[i].tableNumber}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        subtitle: Text(
                          'Occupée pour ce service',
                          style: TextStyle(
                            color: Colors.red.shade300,
                          ),
                        ),
                        secondary: Icon(
                          Icons.table_restaurant,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: totalCapacity >= currentReservation.numberOfGuests
                      ? () async {
                        if (await managerNotifier.confirmedReservationManager(currentReservation, tableIds)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Réservation confirmé avec les tables assignées"),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 3),
                            ),
                          );
                          //popUntil permet de revenir à une page en supprimant celle au dessus
                          Navigator.popUntil(
                            context,
                            ModalRoute.withName('/myRestaurantReservations'),
                          );
                        }
                      }
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Confirmer la réservation'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
