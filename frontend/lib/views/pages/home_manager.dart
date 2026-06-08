import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prbd_2526_c01/models/manager_state.dart';
import 'package:prbd_2526_c01/providers/current_user_provider.dart';
import 'package:prbd_2526_c01/providers/manager_state_provider.dart';
import 'package:prbd_2526_c01/providers/reference_time_provider.dart';
import 'package:prbd_2526_c01/views/widgets/my_restaurant_card.dart';

import '../widgets/simulated_time_dialog.dart';

class HomeManager extends ConsumerWidget {
  const HomeManager({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final managerState = ref.watch(managerStateProvider);
    final managerNotifier = ref.read(managerStateProvider.notifier);
    final theme = Theme.of(context);
    final now = ref.watch(referenceTimeProvider);

    return managerState.when(
      data: (state) => _buildPage(context, ref, state, managerNotifier, theme, now),
      error: (err, _) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                err.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => managerNotifier.refreshRestaurants(),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
      loading: () => _buildPage(
        context, ref,
        managerState.value ?? ManagerState(),
        managerNotifier, theme, now,
        isLoading: true,
      ),
    );
  }

  Widget _buildPage(
      BuildContext context,
      WidgetRef ref,
      ManagerState state,
      ManagerStateNotifier notifier,
      ThemeData theme,
      DateTime now, {
        bool isLoading = false,
      }) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes restaurants'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir les données',
            onPressed: () => notifier.refreshRestaurants(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () {
              ref.read(currentUserProvider.notifier).logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
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
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.restaurants.isEmpty
            ? const Center(child: Text('Aucun restaurant trouvé.'))
            : ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            for (var restaurant in state.restaurants)
              MyRestaurantCard(
                restaurant: restaurant,
                onTap: () {
                  notifier.selectRestaurant(restaurant);
                  Navigator.pushNamed(context, '/myRestaurantReservations')
                      .then((_) => notifier.refreshRestaurants());
                },
              ),
          ],
        ),
      ),
    );
  }
}
