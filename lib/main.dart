import 'package:flutter/material.dart';

import 'core/config/app_environment_controller.dart';
import 'shared/widgets/app_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final environmentController = AppEnvironmentController();
  await environmentController.load();

  runApp(AppBootstrap(environmentController: environmentController));
}
