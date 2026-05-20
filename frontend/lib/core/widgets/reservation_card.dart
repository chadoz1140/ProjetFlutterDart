
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prbd_2526_c01/models/reservation.dart';

class ReservationCard  extends ConsumerWidget{

  const ReservationCard({
    super.key,
    required this.reservation,
    this.onTap
  });

  final Reservation reservation;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              _buildStatusIcon(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reservation.restaurant.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          reservation.restaurant.city,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(reservation.dateTime),
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.people, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${reservation.numberOfGuests} convives',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );

  }

  Widget _buildStatusIcon() {
    switch (reservation.status) {
      case 'pending':
        return Tooltip(
          message: 'En attente',
          child: const Icon(Icons.pending, size: 32, color: Colors.orange),
        );
      case 'confirmed':
        return Tooltip(
          message: 'Confirmée',
          child: const Icon(Icons.check_circle, size: 32, color: Colors.green),
        );
      case 'completed':
        return Tooltip(
          message: 'Terminée',
          child: const Icon(Icons.event_available, size: 32, color: Colors.blue),
        );
      case 'cancelled':
        return Tooltip(
          message: 'Annulée',
          child: const Icon(Icons.cancel, size: 32, color: Colors.red),
        );
      default:
        return const Icon(Icons.list, size: 24);
    }
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat("EEE dd/MM/yyyy 'à' HH:mm", 'fr_FR').format(dateTime);
  }
}