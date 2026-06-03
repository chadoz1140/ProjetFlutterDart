import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prbd_2526_c01/providers/client_state_provider.dart';
import 'package:prbd_2526_c01/providers/reference_time_provider.dart';
import 'package:prbd_2526_c01/views/widgets/cancel_reservation.dart';
import 'package:prbd_2526_c01/views/widgets/simulated_time_dialog.dart';
import '../../core/widgets/data_error_widget.dart';
import '../../models/status.dart';

class ReservationDetails extends ConsumerStatefulWidget {
  const ReservationDetails({super.key});

  @override
  ConsumerState<ReservationDetails> createState() => _ReservationDetailsState();
}

class _ReservationDetailsState extends ConsumerState<ReservationDetails> {

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final reservationId = ModalRoute.of(context)!.settings.arguments as int;
      ref.read(clientStateProvider.notifier).getReservation(reservationId);
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
      data: (state) {
        final reservation = state.currentReservation;
        if (reservation == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final canEdit = reservation.status == Status.pending ||
            (reservation.status == Status.confirmed &&
                reservation.dateTime.isAfter(now));

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Détails de la réservation'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Rafraîchir les données',
                onPressed: () => clientNotifier.refreshReservationDetails(),
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
                          _infoRow(
                            Icons.restaurant,
                            Text(
                              reservation.restaurant.name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.grey),
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
                              const Icon(Icons.phone, size: 16, color: Colors.grey),
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
                          _infoRow(
                            Icons.calendar_today,
                            Text('Date: ${days[reservation.dateTime.weekday - 1]} '
                                '${DateFormat('dd/MM/yyyy').format(reservation.dateTime)} '),
                          ),
                          const SizedBox(height: 8),
                          _infoRow(
                            Icons.access_time,
                            Text('Heure: ${DateFormat('HH:mm').format(reservation.dateTime)}'),
                          ),
                          const SizedBox(height: 8),
                          _infoRow(
                            Icons.people,
                            Text('Nombre de convives: ${reservation.numberOfGuests}'),
                          ),
                          const SizedBox(height: 8),
                          _infoRow(
                            Icons.info,
                            Row(
                              children: [
                                const Text('Statut: '),
                                Chip(
                                  label: Text(
                                    reservation.status.value,
                                    style: const TextStyle(fontSize: 12, color: Colors.white),
                                  ),
                                  backgroundColor: switch (reservation.status) {
                                    Status.pending   => Colors.orange,
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
                          const Text(
                            'Demandes spéciales',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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

                  if (reservation.status != Status.completed &&
                      reservation.status != Status.cancelled)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: canEdit
                                ? () => Navigator.pushNamed(
                              context,
                              '/edit_reservation',
                              arguments: reservation.id,
                            )
                                : null,
                            icon: const Icon(Icons.edit),
                            label: const Text('Modifier'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final cancelled = await CancelReservation().show(context);
                              if (cancelled) {
                                clientNotifier.cancelReservation(reservation);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Réservation annulée avec succès'),
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
      },
    );
  }

  Widget _infoRow(IconData icon, Widget child) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Expanded(child: child),
      ],
    );
  }
}
