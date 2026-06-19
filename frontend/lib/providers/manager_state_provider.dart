import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_c01/core/tools/abstract_async_notifier.dart';
import 'package:prbd_2526_c01/models/manager_state.dart';
import 'package:prbd_2526_c01/models/reservation.dart';
import 'package:prbd_2526_c01/models/restaurant.dart';
import 'package:prbd_2526_c01/models/restaurant_tables.dart';
import 'package:prbd_2526_c01/models/service.dart';
import 'package:prbd_2526_c01/models/status.dart';
import 'package:prbd_2526_c01/providers/current_user_provider.dart';

final managerStateProvider = AsyncNotifierProvider<ManagerStateNotifier, ManagerState>(
      () => ManagerStateNotifier(),
);

class ManagerStateNotifier extends AbstractAsyncNotifier<ManagerState> {

  // Au démarrage charge les restaurants du manager
  @override
  FutureOr<ManagerState> build() async {
    ref.watch(currentUserProvider);
    final restaurants = await Restaurant.getMyRestaurants();
    return ManagerState(restaurants: restaurants);
  }

  // Sélectionne un restaurant et charge ses réservations
  Future<void> selectRestaurant(Restaurant restaurant) async {
    final currentState = state.value ?? ManagerState();
    state = AsyncValue.data(currentState.copyWith(currentRestaurant: restaurant));
    await getReservationsByRestaurant(restaurant.id, null);
  }

  // Recharge la liste des restaurants du manager
  Future<void> refreshRestaurants() async {
    try {
      final restaurants = await Restaurant.getMyRestaurants();
      final currentState = state.value ?? ManagerState();
      state = AsyncValue.data(currentState.copyWith(restaurants: restaurants));
    } catch (e, stackTrace) {
      state = AsyncValue.error("Erreur lors du chargement des restaurants.", stackTrace);
    }
  }

  // Reservations by restaurant
  Future<void> getReservationsByRestaurant(int restaurantId, String? status) async {
    final currentState = state.value ?? ManagerState();
    try {
      final reservations = await Reservation.getReservationsByRestaurant(restaurantId, status: status);
      state = AsyncValue.data(currentState.copyWith(
        reservations: reservations,
        reservationStatusFilter: status,
        clearReservationStatusFilter: status == null,
      ));
    }catch(e, stackTrace) {
      state = AsyncValue.error(
          "Something went wrong loading reservations!",
          stackTrace);
    }
  }

  // Refresh page restaurant management reservations
  @override
  Future<void> refresh() async {
    final restaurantId = state.value?.currentRestaurant?.id;
    if(restaurantId == null) return;
    return getReservationsByRestaurant(restaurantId, state.value?.reservationStatusFilter);
  }

  Future<void> getReservationDetailsManager(int reservationId) async {
    final currentState = state.value ?? ManagerState();
    try {
      final reservation = await Reservation.getReservationDetailsManager(reservationId);
      state = AsyncData(currentState.copyWith(
        currentReservation: reservation,
      ));
    } catch (e) {
      state = AsyncError(
        "Something went wrong!\nPlease try again later.",
        StackTrace.current,
      );
    }
  }

  // Refresh page details restaurant
  Future<void> refreshReservationDetailsManager() async {
    final reservationId = state.value?.currentReservation?.id;
    if (reservationId == null) return;

    await getReservationDetailsManager(reservationId);
  }

  List<Reservation> updateReservationInList(ManagerState currentState, Reservation newReservation){
    final updatedReservations = <Reservation>[];
    final filter = currentState.reservationStatusFilter;

    for (final reservation in currentState.reservations) {

      final reservationToShow = reservation.id == newReservation.id ? newReservation : reservation;

      if (filter == null || reservationToShow.status.name == filter) {
        updatedReservations.add(reservationToShow);
      }
    }
    return updatedReservations;
  }

  // on calcule si la reservation compte encore comme demande en attente ou pas
  int pendingCount(Reservation oldReservation, Reservation newReservation){
    final oldPending = oldReservation.status == Status.pending ? 1 : 0;
    final newPending = newReservation.status == Status.pending ? 1 : 0;

    // exemple : pending -> confirmed = 0 - 1 = -1 donc on enlève 1 demande en attente au restaurant
    return newPending - oldPending;
  }

  List<Restaurant> updateRestaurantsPendingCount(ManagerState currentState, Reservation oldReservation, Reservation newReservation){
    final count = pendingCount(oldReservation, newReservation);

    // si count vaut 0 le compteur ne doit pas changer
    if (count == 0) {
      return currentState.restaurants;
    }

    return currentState.restaurants.map((restaurant) {
      // on parcours chaque resto de la liste et si ce n'est pas le restaurant de la reservation on ne touche pas
      if (restaurant.id != newReservation.restaurant.id) return restaurant;

      final newPendingCount = (restaurant.pendingCount ?? 0) + count;

      // on recrée le même restaurant mais avec le compteur corrigé
      return restaurant.copyWith(
        pendingCount: newPendingCount < 0 ? 0 : newPendingCount,
      );
    }).toList();
  }

  Restaurant? updateCurrentRestaurantPendingCount(ManagerState currentState, Reservation oldReservation, Reservation newReservation){
    final currentRestaurant = currentState.currentRestaurant;
    final count = pendingCount(oldReservation, newReservation);

    if (currentRestaurant == null) {
      return null;
    }

    // si ce n'est pas le restaurant courant ou si rien ne change on garde pareil
    if (currentRestaurant.id != newReservation.restaurant.id || count == 0) {
      return currentRestaurant;
    }

    final newPendingCount = (currentRestaurant.pendingCount ?? 0) + count;

    return currentRestaurant.copyWith(
      pendingCount: newPendingCount < 0 ? 0 : newPendingCount,
    );
  }

  Future<bool> cancelReservationManager(Reservation reservation) async{
    final currentState = state.value ?? ManagerState();
    try{
      final newReservation = await Reservation.cancelReservationManager(reservation);
      final updatedReservations = updateReservationInList(currentState, newReservation);
      final updatedRestaurants = updateRestaurantsPendingCount(currentState, reservation, newReservation);
      final updatedCurrentRestaurant = updateCurrentRestaurantPendingCount(currentState, reservation, newReservation);

      state = AsyncData(
        currentState.copyWith(
          currentReservation: newReservation,
          reservations: updatedReservations,
          currentRestaurant: updatedCurrentRestaurant,
          restaurants: updatedRestaurants,
        ),
      );
      return true;
    }
    catch(e){
      state = AsyncValue.error(
          "Something went wrong!\nPlease try again later.",
          StackTrace.current
      );
      return false;
    }
  }

  Future<bool> completedReservationManager(Reservation reservation) async{
    final currentState = state.value ?? ManagerState();
    try{
      final newReservation = await Reservation.completedReservationManager(reservation);
      final updatedReservations = updateReservationInList(currentState, newReservation);

      state = AsyncData(
        currentState.copyWith(
          currentReservation: newReservation,
          reservations: updatedReservations,
        ),
      );
      return true;
    }
    catch(e){
      state = AsyncValue.error(
          "Something went wrong!\nPlease try again later.",
          StackTrace.current
      );
      return false;
    }
  }

  Future<bool> confirmedReservationManager(Reservation reservation, List<int> tableId) async{
    final currentState = state.value ?? ManagerState();
    try{
      final newReservation = await Reservation.confirmedReservationManager(reservation, tableId);
      final updatedReservations = updateReservationInList(currentState, newReservation);
      final updatedRestaurants = updateRestaurantsPendingCount(currentState, reservation,newReservation);
      final updatedCurrentRestaurant = updateCurrentRestaurantPendingCount(currentState, reservation, newReservation);

      state = AsyncData(
        currentState.copyWith(
          currentReservation: newReservation,
          reservations: updatedReservations,
          currentRestaurant: updatedCurrentRestaurant,
          restaurants: updatedRestaurants,
        ),
      );
      return true;
    }
    catch(e){
      state = AsyncValue.error(
          "Something went wrong!\nPlease try again later.",
          StackTrace.current
      );
      return false;
    }
  }

  Future<void> getTablesStatus(Reservation reservation) async{
    final currentState = state.value ?? ManagerState();
    state = const AsyncValue.loading();
    try{
      final tablesStatus = await RestaurantTables.getTablesStatus(reservation.id!);
      state = AsyncData(
        currentState.copyWith(restaurantTablesStatus: tablesStatus, currentReservation: reservation),
      );
    }
    catch(e){
      state = AsyncValue.error(
          "Something went wrong!\nPlease try again later.",
          StackTrace.current
      );
    }
  }

  // Refresh page assign table
  Future<void> refreshTablesStatus() async {
    final reservation = state.value?.currentReservation;
    if (reservation == null) return;

    await getTablesStatus(reservation);
  }

  Future<void>getServices(int restaurantId) async {
    final currentState = state.value ?? ManagerState();
    state = const AsyncLoading();
    try{
      final services = await Service.getServiceInfoByRestaurantId(restaurantId);


      final canDeleteServices = <int, bool>{};
      for (final service in services) {
        canDeleteServices[service.id] =
          await Service.canDeleteService(service.id);
      }
      state = AsyncData(currentState.copyWith(
        services: services,
        canDeleteServices: canDeleteServices,
      ));
    }catch(e){
      state = AsyncValue.error(
          "Something went wrong!\nPlease try again later.",
          StackTrace.current
      );
    }
  }


  Future<bool>canDeleteService(int serviceId) async{
    final canDelete = await Service.canDeleteService(serviceId);
    return canDelete;
  }

  Future<void>deleteService(int serviceId) async{
    final currentState = state.value ?? ManagerState();
    state = const AsyncLoading();

    try{
      await Service.deleteService(serviceId);

      final services = List<Service>.from(currentState.services);
      services.removeWhere((service) => service.id == serviceId);

      state = AsyncData(currentState.copyWith(services: services));
    }catch(e){
      state = AsyncValue.error(
          "Something went wrong!\nPlease try again later.",
          StackTrace.current
      );
    }
  }

  // Liste tables
  Future<void> getTablesByRestaurant(int restaurantId) async {
      final currentState = state.value ?? ManagerState();
      state = const AsyncValue.loading();
      try {
        final tables = await RestaurantTables.getTablesByRestaurant(restaurantId);
        state = AsyncValue.data(currentState.copyWith(
          tables : tables,
      ));

    }catch(e, stackTrace) {
      state = AsyncValue.error(
      "Something went wrong loading reservations!",
      stackTrace);
    }
  }

  // Refresh la liste des tables
  Future<void> refreshTables() async {
    final restaurantId = state.value?.currentRestaurant?.id;
    if(restaurantId == null) return;
    return getTablesByRestaurant(restaurantId);
  }

  // add table
  Future<void> addTable({
    required int tableNumber,
    required int capacity,
  }) async {
    final restaurantId = state.value?.currentRestaurant?.id;
    if (restaurantId == null) return;
    try {
      await RestaurantTables.addTable(
        restaurantId: restaurantId,
        tableNumber: tableNumber,
        capacity: capacity,
      );
      // recharge la liste
      await refreshTables();
    } catch (e, stackTrace) {
      state = AsyncValue.error("Something went wrong!", stackTrace);
    }
  }

  // update table
  Future<void> updateTable({
    required int tableId,
    required int tableNumber,
    required int capacity,
  }) async {
    try {
      await RestaurantTables.updateTable(
        tableId: tableId,
        tableNumber: tableNumber,
        capacity: capacity,
      );
      // recharge la liste
      await refreshTables();
    } catch (e, stackTrace) {
      state = AsyncValue.error("Something went wrong!", stackTrace);
    }
  }


  Future<String?> checkServiceBusinessRules(int restaurantId, int dayOfWeek, String startTime, String endTime, int? serviceId,) async {
    final error = await Service.checkServiceBusinessRules(
      restaurantId,
      dayOfWeek,
      startTime,
      endTime,
      serviceId,
    );

    return error;
  }

  Future<void> saveService(
      int? serviceId,
      int restaurantId,
      int dayOfWeek,
      String startTime,
      String endTime,
      ) async {
    await Service.saveService(
      serviceId,
      restaurantId,
      dayOfWeek,
      startTime,
      endTime,
    );
  }

}
