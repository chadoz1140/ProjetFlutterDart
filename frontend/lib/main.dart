import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_c01/app/my_app.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:prbd_2526_c01/core/tools/Params.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  await Params.init();
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

