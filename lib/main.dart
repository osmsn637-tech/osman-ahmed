import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'shared/providers/app_providers.dart';
import 'shared/widgets/putaway_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = await AppConfig.load();

  runApp(
    MultiProvider(
      providers: appProviders(config),
      child: const PutawayApp(),
    ),
  );
}
