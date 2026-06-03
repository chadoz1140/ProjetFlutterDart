import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/data.error.widget.dart';
import '../../models/reservation.dart';
import '../../models/status.dart';
import '../../providers/manager_state_provider.dart';
import '../../providers/reference_time_provider.dart';
import '../widgets/cancel_reservation.dart';
import '../widgets/completed_reservation.dart';

class ReservationDetailsManager extends ConsumerStatefulWidget {
  final Reservation reservation;

  const ReservationDetailsManager({
    super.key,
    required this.reservation,
  });

  @override
  ConsumerState<ReservationDetailsManager> createState() =>
      _ReservationDetailsManagerState();
}

class _ReservationDetailsManagerState extends ConsumerState<ReservationDetailsManager> {

  @override
  void initState() {
    super.initState();
    //Futur car on dois attendre la construction de la page (initState) avant de changer de state avec getReservation()
    Future(() {
      //appel getReservation et stocke celui ci dans state.currentReservation
      ref.read(managerStateProvider.notifier).getReservationDetailsManager(widget.reservation.id!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final managerState = ref.watch(managerStateProvider);
    final managerNotifier = ref.read(managerStateProvider.notifier);
    const List<String> days = ["lun.", "mar.", "mer.", "jeu.", "ven.", "sam.", "dim."];

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
        data: (state) =>
            data(state.currentReservation!, theme, now, managerNotifier, days)
    );
  }
    Widget data(
        Reservation reservation,
        ThemeData  theme,
        DateTime now,
        ManagerStateNotifier managerNotifier,
        List<String> days,
        ){
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              /*
                back vers la liste des restaurant du manager connecté /homeManager
                Navigator.pushNamed(
                  context,
                  '/homeManager'
                );
              */
            },
          ),
          title: const Text('Détails de la réservation'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Rafraîchir les données',
              onPressed: () {
                managerNotifier.refreshReservationDetailsManager();
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informations client',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.person, size: 20),
                            SizedBox(width: 8),
                            //reservation.client?.fullName veut dire que client peut etre null et si c'est le cas on affiche Inconnu
                            Text('Nom: ${reservation.client?.fullName ?? "Inconnu"} '),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.email, size: 20),
                            SizedBox(width: 8),
                            Text('Email: ${reservation.client?.email ?? "Inconnu"}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.phone, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Téléphone: ${reservation.client?.phone ?? "Non renseigné"}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Détails de la réservation',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.restaurant, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                reservation.restaurant.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Date: ${days[reservation.dateTime.weekday - 1]}'
                                  '${DateFormat('dd/MM/yyyy').format(reservation.dateTime)} '
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 20),
                            const SizedBox(width: 8),
                            Text('Heure: ${DateFormat('HH:mm').format(reservation.dateTime)}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.people, size: 20),
                            const SizedBox(width: 8),
                            Text('Nombre de convives: ${reservation.numberOfGuests}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.info, size: 20),
                            const SizedBox(width: 8),
                            const Text('Statut: '),
                            Chip(
                              label: Text(
                                reservation.status.value,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                              backgroundColor: switch (reservation.status) {
                                Status.pending => Colors.orange,
                                Status.confirmed => Colors.green,
                                Status.cancelled => Colors.red,
                                Status.completed => Colors.blue,
                              },
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        if (reservation.specialRequest != null && reservation.specialRequest!.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Demandes spéciales',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                reservation.specialRequest ?? '',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ],
                          )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  ' Tables assignées',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (reservation.status == Status.pending || reservation.status == Status.cancelled)
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (reservation.status == Status.pending)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('Aucune table assignée (en attente de confirmation)'),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(

                                onPressed:  () async {
                                  /*
                                    navique vers la page assignation table et quand la table est assigné on lance
                                    la méthode qui permettra de confirmer la réservation
                                  */
                                },
                                icon: const Icon(Icons.table_restaurant),
                                label: const Text('Confirmer et assigner tables'),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  /*la méthode sera implémenter quand la liste des reservation du manager sera disponible,
                                 pour la synchronisation de la liste de reservation*/
                                  final cancelled = await CancelReservation().show(context);
                                  if (cancelled){
                                    await managerNotifier.cancelReservationManager(reservation);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Réservation annulé avec succès"),
                                        backgroundColor: Colors.black54,
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.cancel),
                                label: const Text('Annuler'),
                              ),
                            ],
                          )
                        else
                          const Text('Aucune table assignée'),
                      ],
                  )

                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  //on place le for après le children car la boucle vas créer plusieurs widgets
                                  for (final table in reservation.tables ?? [])
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.table_restaurant, size: 20),
                                          const SizedBox(width: 8),
                                          Text('Table ${table.tableNumber}'),
                                          const SizedBox(width: 16),
                                          Text(
                                            '(${table.capacity} places)',
                                            style: TextStyle(color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (reservation.status == Status.confirmed)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton.icon(
                              //si la reservation n'a pas encore eu lieu ou n'est pas en cours alors on désactive le bouton
                              onPressed: reservation.dateTime.isAfter(now)
                                  ? null :
                                  () async {
                                    final completed = await CompletedReservation().show(context);
                                    if (completed) {
                                      await managerNotifier.completedReservationManager(reservation);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Réservation terminé avec succès"),
                                          backgroundColor: Colors.black54,
                                          duration: Duration(seconds: 3),
                                        ),
                                      );
                                    }
                                  },
                              icon: const Icon(Icons.check_circle),
                              label: const Text('Marquer comme terminée'),
                            ),
                            if (reservation.dateTime.isAfter(now))
                              Text(
                                'La réservation ne peut être terminée que durant son service ou après celui-ci',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.red
                                ),
                              ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () async {
                                final cancelled = await CancelReservation().show(context);
                                if (cancelled){
                                  managerNotifier.cancelReservationManager(reservation);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Réservation annulé avec succès"),
                                      backgroundColor: Colors.black54,
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.cancel),
                              label: const Text('Annuler'),
                            ),
                          ],
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      );
    }
}