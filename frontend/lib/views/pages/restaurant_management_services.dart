import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prbd_2526_c01/models/service.dart';
import '../../core/widgets/data.error.widget.dart';
import '../../models/manager_state.dart';
import '../../providers/manager_state_provider.dart';
import '../../providers/reference_time_provider.dart';
import 'package:prbd_2526_c01/views/widgets/service_card.dart';

import '../widgets/manager_bottom_navigation.dart';
import 'add_edit_service.dart';

class RestaurantManagementServices extends ConsumerStatefulWidget {
  @override
  ConsumerState<RestaurantManagementServices> createState() =>
      _RestaurantManagmentServicesState();

}



class _RestaurantManagmentServicesState extends ConsumerState<RestaurantManagementServices>{
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      final state = ref.read(managerStateProvider).value;
      final restaurant = state?.currentRestaurant;

      if (restaurant != null) {
        ref.read(managerStateProvider.notifier).getServices(restaurant.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final managerState = ref.watch(managerStateProvider);
    final managerNotifier = ref.read(managerStateProvider.notifier);

    return managerState.when(
        data: (state) => data(theme, state, managerNotifier),
        error: (err, stackTrace) => DataErrorWidget(
          error: err,
          stackTrace: stackTrace,
          notifier: managerNotifier,
        ),
        loading: () => data(
          theme,
          managerState.value ?? ManagerState(),
          managerNotifier,
          isLoading: true,
        ),
    );
  }

  Widget data(ThemeData theme,
      ManagerState state,
      ManagerStateNotifier notifier,{
              bool isLoading = false
      })
  {
    final restaurant = state.currentRestaurant;
    final services = state.services;
    final now = ref.watch(referenceTimeProvider);
    final Map<int, List<Service>> servicesByDay = {};

    for (final service in services) {
      servicesByDay
          .putIfAbsent(service.dayOfWeek, () => [])
          .add(service);
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(restaurant!.name),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir les données',
            onPressed: () {
              notifier.getServices(restaurant.id);
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
              if (services.isEmpty)
                const Center(
                  child: Text(
                    'Aucun service.\nUtilisez le bouton + pour en ajouter un.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                )
              else
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (var day = 1; day <= 7; day++)
                      ServiceCard(
                        dayOfWeek: day,
                        services: servicesByDay[day] ?? [],
                        canDeleteServices: state.canDeleteServices,
                        onDelete: notifier.deleteService,
                        onEdit: (service) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddEditService(service: service),
                            ),
                          ).then((_) => notifier.getServices(restaurant.id));
                        },
                      ),
                  ],
                ),

              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
                  heroTag: 'services_fab',
                  onPressed: () {
                    Navigator.pushNamed(context, '/add_edit_service')
                        .then((_) => notifier.getServices(restaurant.id));
                  },
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          ),
      ),
      bottomNavigationBar: ManagerBottomNavigation(currentIndex: 1 , context: context),
    );

    
  }
}