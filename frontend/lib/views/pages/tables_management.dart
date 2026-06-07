import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prbd_2526_c01/providers/manager_state_provider.dart';
import 'package:prbd_2526_c01/providers/reference_time_provider.dart';
import 'package:prbd_2526_c01/views/widgets/manager_bottom_navigation.dart';

import '../../core/widgets/data.error.widget.dart';
import '../../models/manager_state.dart';


class RestaurantManagementTables extends ConsumerStatefulWidget {
  const RestaurantManagementTables({super.key});
  @override
  ConsumerState<RestaurantManagementTables> createState() => _RestaurantManagementTablesState();
}

class _RestaurantManagementTablesState extends ConsumerState<RestaurantManagementTables> {

  @override
  void initState() {
    super.initState();
    Future(() {
      final restaurantId = ref.read(managerStateProvider).value?.currentRestaurant?.id;
      if (restaurantId == null) return;
      ref.read(managerStateProvider.notifier).getTablesByRestaurant(restaurantId);
    });
  }

  @override
  Widget build(BuildContext context) {

    final managerState = ref.watch(managerStateProvider);
    final managerNotifier = ref.read(managerStateProvider.notifier);


    final theme = Theme.of(context);
    final now = ref.watch(referenceTimeProvider);

    return managerState.when(
        data: (state) => data(state, managerNotifier, theme, now),
        error: (err, _) =>
            DataErrorWidget(
              error: err,
              stackTrace: StackTrace.current,
              notifier: managerNotifier
            ),
      loading: () => data(managerState.value ?? ManagerState(), managerNotifier, theme, now, isLoading: true),
    );
  }
  Widget data(ManagerState state, ManagerStateNotifier notifier, ThemeData theme, DateTime now, {isLoading = false}) {
    final restaurant = state.currentRestaurant;
    if(restaurant == null) {
      return const Scaffold(
        body: Center(child : CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(restaurant.name),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir les données',
            onPressed: () => notifier.refreshTables(),
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
        child: Stack(
          children: [
            if (state.tables.isEmpty)
              const Center(
                child: Text(
                  'Aucune table configurée.\nAppuyez sur + pour en ajouter une.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
            else
             ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                for(var table in state.tables)
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.table_restaurant, size: 40),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Table ${table.tableNumber}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.people, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${table.capacity} personnes',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () =>Navigator.pushNamed(
                              context,
                              '/add_edit_table',
                              arguments: table).then((_) => notifier.refreshTables()),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'tables_fab',
                onPressed: () =>Navigator.pushNamed(context, '/add_edit_table').then((_) => notifier.refreshTables()),
                child: const Icon(Icons.add),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ManagerBottomNavigation(currentIndex: 2, context: context),
    );
  }
}
