import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prbd_2526_c01/providers/client_state_provider.dart';
import 'package:prbd_2526_c01/providers/reference_time_provider.dart';

import '../../core/tools/debounce.dart';
import '../../core/tools/validating_text_editing_controller.dart';
import '../../core/widgets/data.error.widget.dart';
import '../../models/client_state.dart';

class NewReservationPage extends ConsumerStatefulWidget{
  @override
  ConsumerState<NewReservationPage>createState() => _NewReservationPageState();
}


class _NewReservationPageState extends ConsumerState<NewReservationPage>{
  late ValidatingTextEditingController _specialRequestsController;

  final Debouncer _capacityDebouncer = Debouncer(
    delay: Duration(milliseconds: 80),
  );

  @override
  void initState() {
    super.initState();
    _specialRequestsController = ValidatingTextEditingController(
      validator: _validateSpecialRequests,
    );
    _specialRequestsController.onAfterValidated = () => setState(() {});
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clientState = ref.watch(clientStateProvider);
    final clientNotifier = ref.read(clientStateProvider.notifier);

    return clientState.when(
      data: (state) => data(theme, state, clientNotifier),
      error: (err, stackTrace) => DataErrorWidget(
        error: err,
        stackTrace: stackTrace,
        notifier: clientNotifier,
      ),
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget data(
       ThemeData theme,
      ClientState state,
      ClientStateNotifier notifier,{
        bool isLoading = false,
      }) {

    final restaurant = state.currentRestaurant!;
    // final reservation = state.currentReservation;

    final selectedDate = state.selectedReservationDate;
    final now = ref.watch(referenceTimeProvider);
    final minDate = DateTime(now.year, now.month, now.day);
    final selectedDay = selectedDate == null
        ? null
        : DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final canGoPreviousDay = selectedDay != null && selectedDay.isAfter(minDate);
    final selectedSlot = state.selectedReservationSlot;
    final numberOfGuests = state.newReservationGuests;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(
            context,
            '/restaurant_details',
            arguments: restaurant.id,
          ),
        ),
        title: const Text('Nouvelle réservation'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir les données',
            onPressed: () {
              _specialRequestsController.clear();
              if (selectedDate != null) {
                notifier.loadReservationSlots(selectedDate);
              }
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
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  DateFormat('EEEE dd/MM/yyyy HH:mm', 'fr_FR').format(now),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.normal,
                  ),
                ),
              )
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if(isLoading)
                const LinearProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                restaurant.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          if (selectedDate == null) return;

                          final minDate = DateTime(now.year, now.month, now.day);

                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate.isBefore(minDate)
                                ? minDate
                                : selectedDate,
                            firstDate: minDate,
                            lastDate: minDate.add(const Duration(days: 365)),
                          );

                          if (picked != null) {
                            notifier.loadReservationSlots(picked);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Date'),
                                    Text(
                                      selectedDate == null
                                          ? ''
                                          : DateFormat('EEEE d/M/yyyy', 'fr_FR')
                                          .format(selectedDate),
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: canGoPreviousDay
                        ? () {
                      final newDate = selectedDay.subtract(
                        const Duration(days: 1),
                      );

                      notifier.loadReservationSlots(newDate);
                    }
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: selectedDay == null
                        ? null
                        : () {
                      final newDate = selectedDay.add(
                        const Duration(days: 1),
                      );

                      notifier.loadReservationSlots(newDate);
                    },
                  ),
                ],
              ),
              const Divider(),
              if (state.restaurantClosed)
                warningBox('Le restaurant est fermé ce jour-là'),
              if (state.clientHasReservationForAllServices)
                warningBox('Vous avez déjà réservé tous les services de ce jour-là'),

              if (state.availableSlots.isNotEmpty) ...[
                const Text(
                  'Créneaux disponibles',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final slot in state.availableSlots)
                      OutlinedButton(
                        onPressed: () {
                          notifier.selectReservationSlot(slot);
                          _capacityDebouncer.call(() {
                            notifier.checkNewReservationOverCapacity(numberOfGuests);
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: slot == selectedSlot
                              ? theme.colorScheme.primary
                              : null,

                          foregroundColor: slot == selectedSlot
                              ? theme.colorScheme.onPrimary
                              : null,
                        ),
                        child: Text(slot.substring(0, 5)),
                      ),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Nombre de convives'),
                subtitle: Text(numberOfGuests.toString()),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: numberOfGuests > 1
                          ? () {
                        final newGuests = numberOfGuests - 1;

                        notifier.changeNewReservationGuests(newGuests);

                        _capacityDebouncer.call(() {
                          notifier.checkNewReservationOverCapacity(newGuests);
                        });
                      }
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        final newGuests = numberOfGuests + 1;

                        notifier.changeNewReservationGuests(newGuests);

                        _capacityDebouncer.call(() {
                          notifier.checkNewReservationOverCapacity(newGuests);
                        });
                      },
                    ),
                  ],
                ),
              ),

              if (state.overCapacity)
                warningBox(
                  'Surréservation (capacité)\n'
                      'La capacité du restaurant pour ce créneau pourrait être insuffisante pour le nombre de convives demandé.',
                ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _specialRequestsController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                  labelText: 'Demandes spéciales (optionnel)',
                  border: OutlineInputBorder(),
                  errorText: _specialRequestsController.errorText,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              ElevatedButton.icon(
                onPressed: selectedSlot == null
                    ? null
                    : () => _createReservation(notifier),
                icon: const Icon(Icons.add),
                label: const Text('Créer la réservation'),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget warningBox(String message) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _specialRequestsController.dispose();
    _capacityDebouncer.cancel();
    super.dispose();
  }

  String? _validateSpecialRequests(String value) {
    final text = value.trim();
    if (text.isEmpty) {
      return null;
    }
    if (text.length < 10) {
      return 'Les demandes spéciales doivent contenir au moins 10 caractères';
    }
    return null;
  }

  Future<void> _createReservation(ClientStateNotifier notifier) async {
    await _specialRequestsController.validateAndWait();

    if (_specialRequestsController.isValid != true) {
      return;
    }

    String? specialRequests;
    if (_specialRequestsController.text.trim().isNotEmpty) {
      specialRequests = _specialRequestsController.text.trim();
    }
    await notifier.saveNewReservation(specialRequests);
    await notifier.getReservations('pending');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Réservation créée avec succès'),
      ),
    );
    Navigator.pushReplacementNamed(
      context,
      '/home',
      arguments: 'pending',
    );
  }

}