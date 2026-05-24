

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../models/status.dart';

class StatusIcon extends StatelessWidget {
  final Status status;
  final double size;

  const StatusIcon({
    super.key,
    required this.status,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case Status.pending:
        return const Tooltip(
          message: 'En attente',
          child: Icon(Icons.pending, size: 32, color: Colors.orange),
        );

      case Status.confirmed:
        return const Tooltip(
          message: 'Confirmée',
          child: Icon(Icons.check_circle, size: 32, color: Colors.green),
        );

      case Status.completed:
        return const Tooltip(
          message: 'Terminée',
          child: Icon(Icons.event_available, size: 32, color: Colors.blue),
        );

      case Status.cancelled:
        return const Tooltip(
          message: 'Annulée',
          child: Icon(Icons.cancel, size: 32, color: Colors.red),
        );
    }
  }
}