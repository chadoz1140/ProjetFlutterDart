import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prbd_2526_c01/core/tools/debounce.dart';
import 'package:prbd_2526_c01/core/widgets/data_error_widget.dart';
import 'package:prbd_2526_c01/models/client_state.dart';
import 'package:prbd_2526_c01/providers/client_state_provider.dart';
import 'package:prbd_2526_c01/providers/reference_time_provider.dart';
import 'package:prbd_2526_c01/views/widgets/restaurant_card.dart';

class SearchRestaurantsPage extends ConsumerStatefulWidget{
  @override
  ConsumerState<SearchRestaurantsPage>createState() => _SearchRestaurantsPageState();
}

class _SearchRestaurantsPageState extends ConsumerState<SearchRestaurantsPage>{
  late TextEditingController _searchController;
  final Debouncer _debouncer = Debouncer();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(clientStateProvider).asData?.value.searchText ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);
    final clientState = ref.watch(clientStateProvider);
    final clientNotifier = ref.read(clientStateProvider.notifier);

    return clientState.when(
        data: (state) => data(theme, state, clientNotifier),
        error: (err, stackTrace) => DataErrorWidget(error: err, stackTrace: stackTrace, notifier: clientNotifier),
        loading: () => data(
          theme,
          ClientState(
            searchText: _searchController.text,
            restaurants: [],
            hasMoreResults: false,
          ),
          clientNotifier,
          isLoading: true,
        )
    );
  }

  Widget data(
      ThemeData theme,
      ClientState state,
      ClientStateNotifier notifier,
      {isLoading = false}
      ){
    final restaurants = state.restaurants;
    final now = ref.watch(referenceTimeProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pushReplacementNamed(context, '/home')
        ),
        title: const Text('Rechercher un restaurant'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir les données',
            onPressed: (){
              _refresh();
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
        child: Column(
          children: [
            // if (isLoading)
            //   const LinearProgressIndicator(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                autofocus: true,
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Rechercher par nom, ville, description...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged:  (text){
                  _debouncer.call((){
                    notifier.search(text);
                  });
                },
              ),
            ),
            Expanded(
              child: Column(
                children: [

                  if(state.hasMoreResults)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 16.0,
                      ),
                      color: Colors.orange.shade50,
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: Colors.orange.shade800,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Trop de résultats trouvés. Veuillez affiner votre recherche pour voir plus de restaurants.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.orange.shade900,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  Expanded(
                    child: state.restaurants.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.restaurant,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun restaurant disponible',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        for(var restaurant in state.restaurants)
                          RestaurantCard(restaurant: restaurant)
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose(){
    _searchController.dispose();
    _debouncer.cancel();
    super.dispose();
  }

  void _refresh() async {
    _searchController.clear();
    _debouncer.cancel();

    await ref.read(clientStateProvider.notifier).refreshRestaurants();
  }
}