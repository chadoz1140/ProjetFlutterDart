
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class AbstractAsyncNotifier<T> extends AsyncNotifier<T> {
  Future<void> refresh();
}