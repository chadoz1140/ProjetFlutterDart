import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prbd_2526_c01/models/restaurant.dart';

class RestaurantCard extends StatelessWidget{
  final Restaurant restaurant;

  const RestaurantCard({
    super.key,
    required this.restaurant
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: const Icon(Icons.restaurant, size: 40),
        title: Text(restaurant.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(restaurant.city),
                const SizedBox(width: 12),
                const Icon(Icons.star,
                    size: 14, color: Colors.amber),
                const SizedBox(width: 2),
                Text(
                  '${restaurant.rating}',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 12),
                Text(
                  '€€',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if(restaurant.lastReservationDatetime != null)
              Row(
                children: [
                  const Icon(Icons.access_time,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),

                    Text(
                      'Dernière réservation: ${_formatDate(restaurant.lastReservationDatetime!)}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[600]),
                    ),
                ],
              ),
            const SizedBox(height: 4),
            if(restaurant.pendingCount! > 0)
              Row(
                children: [
                  const Icon(Icons.pending,
                      size: 14, color: Colors.orange),
                  const SizedBox(width: 4),

                    Text(
                      '${restaurant.pendingCount} demande en attente',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.pushReplacementNamed(context, '/test');
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEE dd/MM/yyyy', 'fr_FR').format(date);
  }

}