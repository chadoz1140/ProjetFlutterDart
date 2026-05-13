import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prbd_2526_c01/core/tools/debounce.dart';
import 'package:prbd_2526_c01/core/widgets/data_error_widget.dart';
import 'package:prbd_2526_c01/models/client_search_restaurant_state.dart';
import 'package:prbd_2526_c01/providers/security_provider.dart';
import 'package:prbd_2526_c01/views/widgets/restaurant_card.dart';

import '../../providers/client_search_restaurant_provider.dart';

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
      text: ref.read(restaurantProvider).asData?.value.searchText ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);
    final asyncState = ref.watch(restaurantProvider);
    final notifier = ref.read(restaurantProvider.notifier);

    return asyncState.when(
        data: (state) => data(theme, state, notifier),
        error: (err, stackTrace) => DataErrorWidget(error: err, stackTrace: stackTrace, notifier: notifier),
        loading: () => data (
          theme,
          ClientSearchRestaurantState(searchText: '', restaurants: [], hasMoreResults: false),
          notifier,
          isLoading: true,
        )
    );
  }

  Widget data(
      ThemeData theme,
      ClientSearchRestaurantState state,
      ClientSearchRestaurantNotifier notifier,
      {isLoading = false}
      ){
    final restaurants = state.restaurants;
    final simulatedTime = DateTime(2024, 12, 4, 16, 0);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: (){}
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
          // IconButton(
          //     onPressed: (){
          //       _logout();
          //     },
          //     icon: Icon(Icons.logout),
          //
          // ),

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
                      .format(simulatedTime),
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
                    child: restaurants.isEmpty ? Center(
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
                        for(var restaurant in restaurants)
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

  void _refresh() async{
    await ref.read(restaurantProvider.notifier).refresh();
    _searchController.dispose();
    _debouncer.cancel();
    _searchController = TextEditingController(text: '');
  }


  // void _logout() {
  //   ref.read(securityProvider.notifier).logout();
  //   Navigator.pushReplacementNamed(context, '/login');
  // }
}