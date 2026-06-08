import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prbd_2526_c01/providers/reference_time_provider.dart';
import 'package:prbd_2526_c01/models/service.dart';

import '../../providers/manager_state_provider.dart';

class AddEditService extends ConsumerStatefulWidget {
  final Service? service;
  const AddEditService({super.key, this.service});

  @override
  ConsumerState<AddEditService> createState() => _AddEditServiceState();
}

class _AddEditServiceState extends ConsumerState<AddEditService> {
  bool get _isEditMode => widget.service != null;
  int? _dayOfWeek = 1;

  int? _startHour;
  int? _startMinute;

  int? _endHour;
  int? _endMinute;

  String? _startHourError;
  String? _endHourError;
  String? _timeError;
bool _checkingBackend = false;
  String? _backendError;

  @override
  void initState() {
    super.initState();

    final service = widget.service;

    if (service != null) {
      _dayOfWeek = service.dayOfWeek;

      _startHour = int.parse(service.startTime.split(':')[0]);
      _startMinute = int.parse(service.startTime.split(':')[1]);

      _endHour = int.parse(service.endTime.split(':')[0]);
      _endMinute = int.parse(service.endTime.split(':')[1]);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = ref.watch(referenceTimeProvider);
    final restaurant = ref.watch(managerStateProvider).value?.currentRestaurant;
    final slotDuration = restaurant?.slotDuration ?? 30;
    final minuteValues = <int>[];

    for (int minute = 0; minute < 60; minute = minute + slotDuration) {
      minuteValues.add(minute);
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(_isEditMode ? 'Modifier le service' : 'Nouveau service'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Enregistrer',
            onPressed: _canSave ? _saveService : null,
            icon: const Icon(Icons.save),
          ),
          IconButton(
            tooltip: 'Rafraîchir',
            onPressed: () => {},
            icon: const Icon(Icons.refresh),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _dayOfWeek,
                  decoration: InputDecoration(
                    labelText: 'Jour',
                    border: const OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Lundi')),
                    DropdownMenuItem(value: 2, child: Text('Mardi')),
                    DropdownMenuItem(value: 3, child: Text('Mercredi')),
                    DropdownMenuItem(value: 4, child: Text('Jeudi')),
                    DropdownMenuItem(value: 5, child: Text('Vendredi')),
                    DropdownMenuItem(value: 6, child: Text('Samedi')),
                    DropdownMenuItem(value: 7, child: Text('Dimanche')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _dayOfWeek = value;
                    });

                    _validateService();
                  },
                ),
                if (_backendError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _backendError!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        initialValue: _startHour,
                        hint: const Text('--'),
                        decoration: InputDecoration(
                          labelText: 'Heure de début (heure)',
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          for (int h = 0; h < 24; h++)
                            DropdownMenuItem<int?>(
                              value: h,
                              child: Text('${h.toString().padLeft(2, '0')} h'),
                            ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _startHour = value;
                            _startMinute ??= 0;
                          });
                          _validateService();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        key: ValueKey('startMinute_$_startMinute'),
                        initialValue: _startMinute,
                        hint: const Text('--'),
                        decoration: const InputDecoration(
                          labelText: 'Minutes',
                          border: OutlineInputBorder(),
                        ),
                        items: minuteValues.map((minute) {
                          return DropdownMenuItem<int?>(
                            value: minute,
                            child: Text(
                              '${minute.toString().padLeft(2, '0')} min',
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _startMinute = value;
                          });
                          _validateService();
                        },
                      ),
                    ),
                  ],
                ),
                if (_startHourError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 16),
                    child: Text(
                      _startHourError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        initialValue: _endHour,
                        hint: const Text('--'),
                        decoration: InputDecoration(
                          labelText: 'Heure de fin (heure)',
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          for (int h = 0; h < 24; h++)
                            DropdownMenuItem<int?>(
                              value: h,
                              child: Text('${h.toString().padLeft(2, '0')} h'),
                            ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _endHour = value;
                            _endMinute ??= 0;
                          });
                          _validateService();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        key: ValueKey('endMinute_$_endMinute'),
                        initialValue: _endMinute,
                        hint: const Text('--'),
                        decoration: const InputDecoration(
                          labelText: 'Minutes',
                          border: OutlineInputBorder(),
                        ),
                        items: minuteValues.map((minute) {
                          return DropdownMenuItem<int?>(
                            value: minute,
                            child: Text(
                              '${minute.toString().padLeft(2, '0')} min',
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _endMinute = value;
                          });
                          _validateService();
                        },
                      ),
                    ),
                  ],
                ),
                if (_endHourError != null || _timeError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 16),
                    child: Text(
                      _endHourError ?? _timeError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _hasFrontErrors =>
    _startHourError != null ||
    _endHourError != null ||
    _timeError != null;

  bool get _hasErrors =>
    _hasFrontErrors || _backendError != null;

  bool get _isComplete =>
    _dayOfWeek != null &&
    _startHour != null &&
    _startMinute != null &&
    _endHour != null &&
    _endMinute != null;

    bool get _canSave =>
    _isComplete &&
    !_hasErrors &&
    !_checkingBackend;

  void _validateFrontErrors() {
    _startHourError = null;
    _endHourError = null;
    _timeError = null;

    if (_startHour == null) {
      _startHourError = 'Sélectionnez une heure de début';
    }

    if (_endHour == null) {
      _endHourError = 'Sélectionnez une heure de fin';
    }

    if (_startHour != null && _startMinute != null && _endHour != null && _endMinute != null) {
      final startTotalMinutes =
          _startHour! * 60 + _startMinute!;

      final endTotalMinutes =
          _endHour! * 60 + _endMinute!;

      if (endTotalMinutes <= startTotalMinutes) {
        _timeError =
        'L’heure de fin doit être après l’heure de début';
      } else if (endTotalMinutes - startTotalMinutes < 60) {
        _timeError =
        'La durée du service doit être d’au moins 1 heure';
      }
    }
  }

  Future<void> _validateService() async {
    setState(() {
      _backendError = null;
      _validateFrontErrors();
    });

    if (!_isComplete || _hasFrontErrors) {
      return;
    }

    final restaurant =
        ref.read(managerStateProvider).value?.currentRestaurant;

    if (restaurant == null) {
      return;
    }

    final startTime =
        '${_startHour!.toString().padLeft(2, '0')}:'
        '${_startMinute!.toString().padLeft(2, '0')}:00';

    final endTime =
        '${_endHour!.toString().padLeft(2, '0')}:'
        '${_endMinute!.toString().padLeft(2, '0')}:00';

    setState(() {
      _checkingBackend = true;
    });

    final error = await ref.read(managerStateProvider.notifier).checkServiceBusinessRules(restaurant.id, _dayOfWeek!, startTime, endTime, widget.service?.id);

    if (!mounted) return;

    setState(() {
      _backendError = error;
      _checkingBackend = false;
    });
  }

  Future<void> _saveService() async {
    final restaurant =
        ref.read(managerStateProvider).value?.currentRestaurant;

    if (restaurant == null || !_canSave) {
      return;
    }

    final startTime =
        '${_startHour!.toString().padLeft(2, '0')}:'
        '${_startMinute!.toString().padLeft(2, '0')}:00';

    final endTime =
        '${_endHour!.toString().padLeft(2, '0')}:'
        '${_endMinute!.toString().padLeft(2, '0')}:00';

    await ref.read(managerStateProvider.notifier).saveService(
      widget.service?.id,
      restaurant.id,
      _dayOfWeek!,
      startTime,
      endTime,
    );
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditMode
              ? 'Service modifié avec succès'
              : 'Service créé avec succès',
        ),
      ),
    );

    Navigator.pop(context);

  }

}