import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prbd_2526_c01/models/reservation.dart';
import 'package:prbd_2526_c01/providers/client_state_provider.dart';
import 'package:prbd_2526_c01/providers/reference_time_provider.dart';
import 'package:prbd_2526_c01/views/widgets/simulated_time_dialog.dart';

class EditReservationPage extends ConsumerStatefulWidget {
  const EditReservationPage({super.key});

  @override
  ConsumerState<EditReservationPage> createState() =>
      _EditReservationPageState();
}

  class _EditReservationPageState extends ConsumerState<EditReservationPage> {

  late int _reservationId;
  late int _restaurantId;
  late String _restaurantName;

  late String _reservationStatus;

  late DateTime _selectedDate;
  String? _selectedSlot;
  late int _numberOfGuests;
  late TextEditingController _specialRequestsController;
  String? _specialRequestsError;

  List<String> _slots = [];
  bool _restaurantClosed = false;
  bool _overCapacity = false;
  bool _isLoadingSlots = false;
  bool _isSaving = false;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _specialRequestsController = TextEditingController();
    Future.microtask(() {
      _reservationId = ModalRoute.of(context)!.settings.arguments as int;
      _initFromCurrentReservation();
    });
  }

  void _initFromCurrentReservation() {
    final reservation = ref.read(clientStateProvider).value?.currentReservation;
    if (reservation == null) return;
    setState(() {
      _restaurantId = reservation.restaurant.id;
      _restaurantName = reservation.restaurant.name;
      _reservationStatus = reservation.status.name;
      _selectedDate = reservation.dateTime;
      _selectedSlot = DateFormat('HH:mm').format(reservation.dateTime);
      _numberOfGuests = reservation.numberOfGuests;
      _specialRequestsController.text = reservation.specialRequest ?? '';
      _isReady = true;
    });
    _loadSlots();
  }

  Future<void> _refresh() async {
    await ref.read(clientStateProvider.notifier).getReservation(_reservationId);
    _initFromCurrentReservation();
  }

  Future<void> _loadSlots() async {
    if (!_isReady) return;
    setState(() => _isLoadingSlots = true);
    try {
      final result = await Reservation.getSlotsForDate(
        restaurantId: _restaurantId,
        date: _selectedDate,
        numberOfGuests: _numberOfGuests,
      );
      final slots = result['slots'] as List<String>;
      setState(() {
        _slots = slots;
        _restaurantClosed = result['restaurantClosed'] as bool;
        _overCapacity = result['overCapacity'] as bool;
        if (!_slots.contains(_selectedSlot)) {
          _selectedSlot = _slots.isNotEmpty ? _slots.first : null;
        }
      });
    } catch (_) {
      setState(() {
        _slots = [];
        _restaurantClosed = false;
        _overCapacity = false;
      });
    } finally {
      setState(() => _isLoadingSlots = false);
    }
  }

  bool _validateSpecialRequests() {
    final text = _specialRequestsController.text.trim();
    if (text.isNotEmpty && text.length < 10) {
      setState(() => _specialRequestsError =
      'Les demandes spéciales doivent contenir au moins 10 caractères');
      return false;
    }
    setState(() => _specialRequestsError = null);
    return true;
  }

  Future<void> _save() async {
    if (_selectedSlot == null) return;
    if (!_validateSpecialRequests()) return;

    // Si réservation confirmée /demander confirmation avant de continuer
    if (_reservationStatus == 'confirmed') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Modifier une réservation confirmée'),
          content: const Text(
            'Cette réservation est confirmée. La modifier la remettra en attente '
                'et les tables associées seront libérées. Souhaitez-vous continuer ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Continuer'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    final parts = _selectedSlot!.split(':');
    final newDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    setState(() => _isSaving = true);
    try {
      await ref.read(clientStateProvider.notifier).updateReservation(
        reservationId: _reservationId,
        newDateTime: newDateTime,
        numberOfGuests: _numberOfGuests,
        specialRequests: _specialRequestsController.text.trim().isEmpty
            ? null
            : _specialRequestsController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Réservation modifiée avec succès'),
          backgroundColor: Colors.black54,
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.black54,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _specialRequestsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = ref.watch(referenceTimeProvider);
    final minDate = DateTime(now.year, now.month, now.day);

    if (!_isReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Modifier une réservation'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir les créneaux',
            onPressed: _refresh,
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              Text(
                _restaurantName,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate.isBefore(minDate)
                                ? minDate
                                : _selectedDate,
                            firstDate: minDate,
                            lastDate: minDate.add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                            _loadSlots();
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('Date'),
                                    Text(
                                      DateFormat('EEEE d/MM/yyyy', 'fr_FR')
                                          .format(_selectedDate),
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
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      // Normaliser la date (enlever l'heure) avant de comparer
                      final today = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
                      final prev = today.subtract(const Duration(days: 1));
                      if (!prev.isBefore(minDate)) {
                        setState(() => _selectedDate = prev);
                        _loadSlots();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      final today = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
                      setState(() => _selectedDate = today.add(const Duration(days: 1)));
                      _loadSlots();
                    },
                  ),
                  const SizedBox(width: 16),
                ],
              ),
              const Divider(),

              if (_restaurantClosed) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Le restaurant est fermé ce jour-là.',
                          style: TextStyle(color: Colors.orange, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              const Text(
                'Créneaux disponibles',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              if (_isLoadingSlots)
                const Center(child: CircularProgressIndicator())
              else if (!_restaurantClosed && _slots.isEmpty)
                const Text(
                  'Aucun créneau disponible pour cette date.',
                  style: TextStyle(color: Colors.grey),
                )
              else if (!_restaurantClosed)
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [
                      for (final slot in _slots)
                        GestureDetector(
                          onTap: () => setState(() => _selectedSlot = slot),
                          child: Container(
                            width: 80,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedSlot == slot
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _selectedSlot == slot
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outline,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                slot,
                                style: TextStyle(
                                  color: _selectedSlot == slot
                                      ? Colors.white
                                      : theme.colorScheme.onSurface,
                                  fontSize: 14,
                                  fontWeight: _selectedSlot == slot
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

              const SizedBox(height: 24),

              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Nombre de convives'),
                subtitle: Text('$_numberOfGuests'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: _numberOfGuests > 1
                          ? () {
                        setState(() => _numberOfGuests--);
                        _loadSlots();
                      }
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        setState(() => _numberOfGuests++);
                        _loadSlots();
                      },
                    ),
                  ],
                ),
              ),

              if (_overCapacity) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Surréservation (capacité)',
                              style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        'La capacité du restaurant pour ce créneau pourrait être insuffisante pour le nombre de convives demandé.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              TextFormField(
                controller: _specialRequestsController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Demandes spéciales (optionnel)',
                  border: const OutlineInputBorder(),
                  hintText: 'Allergies, préférences...',
                  errorText: _specialRequestsError,
                ),
                onChanged: (_) => _validateSpecialRequests(),
              ),

              const SizedBox(height: 32),

              ElevatedButton.icon(
                onPressed:
                (_isSaving || _selectedSlot == null || _restaurantClosed)
                    ? null
                    : _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: _isSaving
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.edit),
                label: const Text('Modifier la réservation'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
