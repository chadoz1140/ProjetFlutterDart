import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prbd_2526_c01/providers/client_state_provider.dart';
import 'package:prbd_2526_c01/providers/reference_time_provider.dart';
import 'package:prbd_2526_c01/views/widgets/cancel_reservation.dart';
import '../../core/widgets/data_error_widget.dart';
import '../../models/status.dart';
import '../widgets/simulated_time_dialog.dart';
import '../../models/reservation.dart';
import '../../models/status.dart';

class ReservationDetails extends ConsumerStatefulWidget {
  final Reservation reservation;

  const ReservationDetails({
    super.key,
    required this.reservation,
  });

  @override
  ConsumerState<ReservationDetails> createState() =>
      _ReservationDetailsState();
}


class _ReservationDetailsState extends ConsumerState<ReservationDetails> {

  @override
  void initState() {
    super.initState();
    //Futur car on dois attendre la construction de la page (initState) avant de changer de state avec getReservation()
    Future(() {
      //appel getReservation et stocke celui ci dans state.currentReservation
      ref.read(clientStateProvider.notifier).getReservation(widget.reservation.id!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final clientState = ref.watch(clientStateProvider);
    final clientNotifier = ref.read(clientStateProvider.notifier);
    const List<String> days = ["lun.", "mar.", "mer.", "jeu.", "ven.", "sam.", "dim."];

    final theme = Theme.of(context);
    final now = ref.watch(referenceTimeProvider);

    return clientState.when(
      error: (err, _) => DataErrorWidget(
        error: err,
        stackTrace: StackTrace.current,
        notifier: clientNotifier,
      ),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      data: (state) => data(state.currentReservation!, theme, now, clientNotifier, days)
    );
  }

  Widget data(
      Reservation reservation,
      ThemeData  theme,
      DateTime now,
      ClientStateNotifier clientNotifier,
      List<String> days,
      ){
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamed(
                context,
                '/home'
            );
          },
        ),
        title: const Text('Détails de la réservation'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir les données',
            onPressed: () {
              clientNotifier.refreshReservationDetails();
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
                  DateFormat(
                    'EEEE dd/MM/yyyy HH:mm',
                    'fr_FR',
                  ).format(now),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      infoRow(Icons.restaurant, Text(reservation.restaurant.name,
                        style:
                        TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              reservation.restaurant.city,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            reservation.restaurant.phone,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      infoRow(Icons.calendar_today,
                        Text(
                            'Date: ${days[reservation.dateTime.weekday - 1]} '
                                '${DateFormat('dd/MM/yyyy').format(reservation.dateTime)} '
                        ),
                      ),
                      const SizedBox(height: 8),
                      infoRow(Icons.access_time,
                        Text('Heure: ${DateFormat('HH:mm').format(reservation.dateTime)}'
                        ),
                      ),
                      const SizedBox(height: 8),
                      infoRow(Icons.people,
                        Text('Nombre de convives: ${reservation.numberOfGuests}'
                        ),
                      ),
                      const SizedBox(height: 8),
                      infoRow(
                        Icons.info,
                        Row(
                          children: [
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
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
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
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (reservation.status != Status.completed && reservation.status != Status.cancelled)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: switch (reservation.status) {
                          Status.cancelled => null,
                          Status.completed => null,
                          Status.pending => () {},
                          Status.confirmed => reservation.dateTime.isBefore(now) ? null : (){},
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Modifier'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final cancelled = await CancelReservation().show(context);
                          if (cancelled){
                            clientNotifier.cancelReservation(reservation);
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
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget infoRow(
      IconData icon,
      Widget child,
      ) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Expanded(child: child),
      ],
    );
  }
}
