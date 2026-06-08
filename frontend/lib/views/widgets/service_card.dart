import 'package:prbd_2526_c01/models/service.dart';
import 'package:flutter/material.dart';

import '../../core/widgets/dialog_box.dart';

class ServiceCard extends StatelessWidget{
  final int dayOfWeek;
  final List<Service> services;
  final Map<int, bool>canDeleteServices;
  final Future<void>Function(int) onDelete;


  const ServiceCard({
    super.key,
    required this.dayOfWeek,
    required this.services,
    required this.canDeleteServices,
    required this.onDelete
  });


  @override
  Widget build(BuildContext context){

    final hours = services
        .map((service) =>
    '${service.startTime.substring(0, 5)} - '
        '${service.endTime.substring(0, 5)}')
        .join(', ');

    if( services.isEmpty) {
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        color: Colors.grey[100],
        child: ListTile(
          leading: const Icon(Icons.schedule, color: Colors.grey),
          title: Text(
            _getDayName(dayOfWeek),
            style: TextStyle(color: Colors.grey[600]),
          ),
          subtitle: const Text(
            'Aucun service',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    if(services.length == 1){
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: ListTile(
          leading: const Icon(Icons.schedule),
          title: Text(_getDayName(dayOfWeek)),
          subtitle: Text(hours),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {},
              ),
              if(canDeleteServices[services.first.id] == true)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    final service = services.first;

                    final result = await DialogBox(
                      title: 'Supprimer le service',
                      message:
                      'Êtes-vous sûr de vouloir supprimer le service du '
                          '${_getDayName(service.dayOfWeek)} '
                          '(${service.startTime.substring(0, 5)} - '
                          '${service.endTime.substring(0, 5)}) ?',
                      actions: ['Annuler', 'Supprimer'],
                    ).show(context);

                    if (result == 'Supprimer') {
                      await onDelete(service.id);
                    }
                  },
                  tooltip: 'Supprimer le service',
                )
              else
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.grey[400]),
                  onPressed: null,
                  tooltip:
                  'Impossible de supprimer : des réservations non annulées utilisent ce service',
                ),
            ],
          ),
        ),

      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: const Icon(Icons.schedule),
        title: Text(_getDayName(dayOfWeek)),
        subtitle: Text(hours),
        children: [
          for(var service in services)
            ListTile(
              title: Text('${service.startTime.substring(0, 5)} - '
                  '${service.endTime.substring(0, 5)}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {},
                  ),
                  if(canDeleteServices[service.id] == true)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final result = await DialogBox(
                          title: 'Supprimer le service',
                          message:
                          'Êtes-vous sûr de vouloir supprimer le service du '
                              '${_getDayName(service.dayOfWeek)} '
                              '(${service.startTime.substring(0, 5)} - '
                              '${service.endTime.substring(0, 5)}) ?',
                          actions: ['Annuler', 'Supprimer'],
                        ).show(context);

                        if (result == 'Supprimer') {
                          await onDelete(service.id);
                        }
                      },
                      tooltip: 'Supprimer le service',
                    )
                  else
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.grey[400]),
                      onPressed: null,
                      tooltip:
                      'Impossible de supprimer : des réservations non annulées utilisent ce service',
                    ),
                ],
              ),
            ),
        ],
      ),
    );




    
  }
  String _getDayName(int day) {
    const days = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];

    return days[day - 1];
  }
}