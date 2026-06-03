import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prbd_2526_c01/providers/simulated_time_provider.dart';

import '../../providers/reference_time_provider.dart';


class SimulatedTimeDialog extends ConsumerStatefulWidget {
  const SimulatedTimeDialog({super.key});


  static Future<void> show(BuildContext context, WidgetRef ref) {
    return showDialog(
      context: context,
      builder: (_) => const SimulatedTimeDialog(),
    );
  }

  @override
  ConsumerState<SimulatedTimeDialog> createState() =>
      _SimulatedTimeDialogState();
}

class _SimulatedTimeDialogState extends ConsumerState<SimulatedTimeDialog> {
  // Date et heure temporaires
  late DateTime _tempDate;
  late TimeOfDay _tempTime;

  @override
  void initState() {
    super.initState();
    final current = ref.read(referenceTimeProvider);
    _tempDate = DateTime(current.year, current.month, current.day);
    _tempTime = TimeOfDay(hour: current.hour, minute: current.minute);
  }

  // Ouvre le sélecteur de date
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tempDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _tempDate = picked);
    }
  }

  // Ouvre le sélecteur d'heure
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _tempTime,
    );
    if (picked != null) {
      setState(() => _tempTime = picked);
    }
  }

  // Valide et enregistre le nouveau temps simulé
  Future<void> _validate() async {
    final newTime = DateTime(
      _tempDate.year,
      _tempDate.month,
      _tempDate.day,
      _tempTime.hour,
      _tempTime.minute,
    );
    await ref.read(simulatedTimeProvider.notifier).setTime(newTime);
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _clear() async {
    await ref.read(simulatedTimeProvider.notifier).clearTime();
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifier le temps simulé'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Date'),
            subtitle: Text(DateFormat('dd/MM/yyyy').format(_tempDate)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickDate,
          ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Heure'),
            subtitle: Text(_tempTime.format(context)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickTime,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: _clear,
          child: const Text('Effacer (null)'),
        ),
        TextButton(
          onPressed: _validate,
          child: const Text('Valider'),
        ),
      ],
    );
  }
}
