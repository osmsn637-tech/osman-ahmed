import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_environment_controller.dart';
import '../providers/app_providers.dart';
import 'putaway_app.dart';

class AppBootstrap extends StatelessWidget {
  const AppBootstrap({
    super.key,
    required this.environmentController,
  });

  final AppEnvironmentController environmentController;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppEnvironmentController>.value(
      value: environmentController,
      child: AnimatedBuilder(
        animation: environmentController,
        builder: (context, _) => MultiProvider(
          key: ValueKey(environmentController.environment),
          providers: appProviders(environmentController.config),
          child: const PutawayApp(),
        ),
      ),
    );
  }
}
