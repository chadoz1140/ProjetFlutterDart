import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prbd_2526_c01/models/restaurant_tables.dart';
import 'package:prbd_2526_c01/providers/manager_state_provider.dart';

import '../../providers/reference_time_provider.dart';


class AddEditTable extends ConsumerStatefulWidget {
  //Si table == null mode add / table != null mode edit
  final RestaurantTables? table;

  const AddEditTable({super.key, this.table});
  @override
  ConsumerState<AddEditTable> createState() =>
      _AddEditTableState();

}

class _AddEditTableState extends ConsumerState<AddEditTable> {
  late TextEditingController _tableNumberController;
  int _capacity = 2;
  int _minCapacity = 1;
  String? _tableNumberError;
  bool get _isEditMode => widget.table != null;
  bool get _hasErrors => _tableNumberError != null;
  bool _showCapacityWarning = false;

  @override
  void initState() {
      super.initState();
      _tableNumberController = TextEditingController(
        text: widget.table?.tableNumber.toString() ?? '',
      );
      _capacity = widget.table?.capacity ?? 2;

      if(_isEditMode) {
        Future(() async {
          final minCapacity = await RestaurantTables.getMinCapacity(widget.table!.id!); // le id ca peut etre null
          setState(() => _minCapacity = minCapacity);
        });
      }
  }

  // Pour libérer la memoire du controller
  @override
  void dispose() {
    _tableNumberController.dispose();
    super.dispose();

  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = ref.watch(referenceTimeProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title:  Text(_isEditMode ? 'Modifier la table' : 'Nouvelle table'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Enregistrer',
            onPressed: _hasErrors ? null : () =>_save(),
            icon: const Icon(Icons.save),
          ),

          IconButton(
            tooltip: 'Rafraîchir',
            onPressed: () =>_refresh(),
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
          child: Form(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _tableNumberController,
                  onChanged: (val) =>_validateTableNumber(val),
                  decoration: InputDecoration(
                    labelText: 'Numéro de table',
                    border: const OutlineInputBorder(),
                    errorText: _tableNumberError,
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                const Text('Capacité'),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      tooltip: _capacity <= _minCapacity        // ← ligne ajoutée
                          ? 'Capacité minimale ($_minCapacity personne)'
                          : null,
                      onPressed: () {
                        if (_capacity > _minCapacity) {
                          setState(() {
                            _capacity--;
                            _showCapacityWarning = false;  // cache le warning
                          });
                        } else {
                          setState(() => _showCapacityWarning = _minCapacity > 1);  // affiche le warning
                        }
                      },
                    ),
                    Text(
                      '$_capacity personnes',
                      style: const TextStyle(fontSize: 18),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => setState(() {
                        _capacity++;
                        _showCapacityWarning = false;
                      }),
                    ),
                  ],
                ),
                if (_showCapacityWarning)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Impossible de diminuer la capacité : une ou plusieurs '
                          'réservations utilisent cette table et nécessitent au moins cette capacité.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  void _validateTableNumber(String val) {
    final tables = ref.read(managerStateProvider).value?.tables ?? [];
    final number = int.tryParse(val);
    setState(() {
      if(val.isEmpty) {
        _tableNumberError = 'Le numéro est requis';
      } else if(number == null || number <= 0) {
        _tableNumberError = 'Numéro invalide'; 
      } else if(tables.any((table)=>table.tableNumber == number && table.id != widget.table?.id)) {
        _tableNumberError = 'Ce numéro de table est déjà utilisé pour ce restaurant';
      } else {
        _tableNumberError = null;
      }
    });
  }

  Future<void> _save() async{
      final notifier = ref.read(managerStateProvider.notifier);
      final number = int.parse(_tableNumberController.text);

      if(_isEditMode) {
        await notifier.updateTable(tableId : widget.table!.id!, tableNumber: number, capacity: _capacity);
      } else {
        await notifier.addTable(tableNumber: number, capacity: _capacity);
      }
      Navigator.pop(context);
  }

  void _refresh() {
    setState(() {
      _tableNumberController.text = widget.table?.tableNumber.toString() ?? '';
      _capacity = widget.table?.capacity ?? 2;
      _tableNumberError = null;
    });
  }


}
