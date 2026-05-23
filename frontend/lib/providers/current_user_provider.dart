import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_c01/core/tools/params.dart';
import 'package:prbd_2526_c01/models/security.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

final currentUserProvider = AsyncNotifierProvider<CurrentUserNotifier, String?>(
      () => CurrentUserNotifier(),
);

class CurrentUserNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    state = AsyncData(Params.getValue('token'));
    return state.value;
  }

  Future<void>login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      var token = await Security.login(email, password);
      Params.setValue('token', token);
      state = AsyncData(token);
    } catch (e) {
      state = AsyncError(
          "Something went wrong!\nPlease try again later.",
          StackTrace.current
      );
    }
  }

  void logout(){
    Params.clearValue('token');
    state = AsyncData(null);
  }

  Future<void>resetDatabase() async {
    state = AsyncValue.loading();
    try {
      await Security.resetDatabase();
      Params.clearValue('token');
      state = const AsyncData(null);
    }catch(e){
      state = AsyncError(
          'Failed to reset database',
          StackTrace.current
      );
    }
  }

  bool get isLoggedIn => loggedUser != null;

  String? get loggedUser{
    return _getUserFromToken(state.value);
  }

  static String? _getUserFromToken(String? token){
    if(token == null) return null;
    try {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      return decodedToken['name'];
    }catch(e){
      return null;
    }
  }

  Future<void> signup({
    required String email,
    required String fullName,
    required String password,
    String? phone,
  }) async {
    state = const AsyncValue.loading();
    try {
      await Security.signup(
          email: email,
          fullName: fullName,
          password: password,
          phone: phone,
      );
      await login(email, password);
      state = AsyncValue.data(Params.getValue('token'));
    } catch (e) {
      state= AsyncValue.error("Signup failed", StackTrace.current);
    }
  }

}