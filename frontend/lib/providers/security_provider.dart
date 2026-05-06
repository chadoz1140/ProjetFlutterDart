

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_c01/models/security.dart';

import '../core/tools/Params.dart';

final securityProvider = AsyncNotifierProvider<SecurityNotifier, String?>(
      () => SecurityNotifier(),
);

class SecurityNotifier extends AsyncNotifier<String?> {
  @override
  FutureOr<String?> build() {
    state = AsyncData(Params.getValue('token'));
    return state.value;
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
      //await login(email, password);
      state = AsyncValue.data(Params.getValue('token'));
    } catch (e) {
      state= AsyncValue.error("Signup failed", StackTrace.current);
    }
  }

}