import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prbd_2526_c01/models/restaurant.dart';

class MyRestaurantCard extends StatelessWidget {
  const MyRestaurantCard({
    super.key,
    required this.restaurant,
    this.onTap,
  });

  final Restaurant restaurant;
  final VoidCallback? onTap;

  String _priceRangeLabel(int? range) {
    if (range == null) return '';
    return '€' * range;
  }

  @override
  Widget build(BuildContext context) {
    final lastResa = restaurant.lastReservationDatetime;
    final pending = restaurant.pendingCount ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.restaurant, size: 40),
        title: Text(restaurant.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(restaurant.city),
                if (restaurant.rating != null) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 2),
                  Text(
                    restaurant.rating!.toStringAsFixed(1),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
                if (restaurant.priceRange != null) ...[
                  const SizedBox(width: 12),
                  Text(
                    _priceRangeLabel(restaurant.priceRange),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
            if (lastResa != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Dernière réservation: ${DateFormat('EEE dd/MM/yyyy', 'fr_BE').format(lastResa)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            if (pending > 0) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.pending, size: 14, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    pending == 1
                        ? '1 demande en attente'
                        : '$pending demandes en attente',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
