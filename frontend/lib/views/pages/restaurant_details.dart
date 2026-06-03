import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prbd_2526_c01/core/widgets/data.error.widget.dart';
import 'package:prbd_2526_c01/models/service.dart';
import 'package:prbd_2526_c01/providers/client_state_provider.dart';
import 'package:prbd_2526_c01/providers/reference_time_provider.dart';

class RestaurantDetails extends ConsumerStatefulWidget {
  const RestaurantDetails({super.key});
  @override
  ConsumerState<RestaurantDetails> createState() => RestaurantDetailsState();
}

class RestaurantDetailsState extends ConsumerState<RestaurantDetails> {

  @override
  void initState(){
    super.initState();
    Future.microtask(() {
      final restaurantId = ModalRoute.of(context)!.settings.arguments as int;
      ref.read(clientStateProvider.notifier).getRestaurantDetails(restaurantId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final clientState = ref.watch(clientStateProvider);
    final clientNotifier = ref.read(clientStateProvider.notifier);
    final now = ref.watch(referenceTimeProvider);
    const List<String> days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    final theme = Theme.of(context);

    return clientState.when(
      error: (err, _) => DataErrorWidget(
        error: err,
        stackTrace: StackTrace.current,
        notifier: clientNotifier,
      ),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      data: (state) {
        final restaurant = state.currentRestaurant;
        if (restaurant == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Grouper les services par jour
        final Map<int, List<Service>> groupedServices = {};
        for (var service in restaurant.services) {
          groupedServices.putIfAbsent(service.dayOfWeek, () => []).add(service);
        }

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pushReplacementNamed(context, '/searchRestaurants')
            ),
            title: const Text('Détails du restaurant'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Rafraîchir les données',
                onPressed: () => clientNotifier.refreshRestaurantDetails(),
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
                    message: 'Date/heure simulée utilisée pour les tests.\nCliquez pour modifier.',
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(restaurant.rating?.toStringAsFixed(1) ?? 'N/A'),
                      const SizedBox(width: 16),
                      Text('€' * 3),
                      const SizedBox(width: 16),
                      const Icon(Icons.location_on, size: 16),
                      const SizedBox(width: 4),
                      Text(restaurant.city),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.place, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          restaurant.address,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(restaurant.description),
                  const SizedBox(height: 24),
                  const Text(
                    'Horaires',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Colonne gauche — lundi à jeudi
                      Expanded(
                        child: Column(
                          children: [
                            for (var day in groupedServices.keys.where((d) => d <= 4))
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 90,
                                      child: Text(
                                        days[day - 1],
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        groupedServices[day]!
                                            .map((s) => '${s.startTime.substring(0, 5)} - ${s.endTime.substring(0, 5)}')
                                            .join('\n'),
                                        style: const TextStyle(fontFamily: 'monospace'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Colonne droite — vendredi à dimanche
                      Expanded(
                        child: Column(
                          children: [
                            for (var day in groupedServices.keys.where((d) => d >= 5))
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 90,
                                      child: Text(
                                        days[day - 1],
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        groupedServices[day]!
                                            .map((s) => '${s.startTime.substring(0, 5)} - ${s.endTime.substring(0, 5)}')
                                            .join('\n'),
                                        style: const TextStyle(fontFamily: 'monospace'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                    onPressed: () async {
                        await clientNotifier.loadNewReservationForm(restaurant.id);
                        if (!mounted) return;
                        Navigator.pushReplacementNamed(context, '/new_reservation');
                    },
                      icon: const Icon(Icons.add),
                      label: const Text('Réserver'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}