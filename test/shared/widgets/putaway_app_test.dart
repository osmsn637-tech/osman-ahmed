import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wherehouse/core/config/app_environment_controller.dart';
import 'package:wherehouse/features/app_update/domain/entities/app_update_config.dart';
import 'package:wherehouse/features/app_update/domain/repositories/app_update_repository.dart';
import 'package:wherehouse/features/app_update/domain/services/version_comparator.dart';
import 'package:wherehouse/features/app_update/presentation/controllers/app_update_controller.dart';
import 'package:wherehouse/features/auth/domain/entities/user.dart';
import 'package:wherehouse/features/auth/domain/entities/login_params.dart';
import 'package:wherehouse/features/auth/domain/repositories/auth_repository.dart';
import 'package:wherehouse/features/auth/presentation/providers/session_provider.dart';
import 'package:wherehouse/features/dashboard/domain/usecases/claim_task_usecase.dart';
import 'package:wherehouse/features/dashboard/domain/usecases/complete_task_usecase.dart';
import 'package:wherehouse/features/dashboard/domain/usecases/get_task_suggestion_usecase.dart';
import 'package:wherehouse/features/dashboard/domain/usecases/get_tasks_for_zone_usecase.dart';
import 'package:wherehouse/features/dashboard/domain/usecases/save_cycle_count_progress_usecase.dart';
import 'package:wherehouse/features/dashboard/domain/usecases/scan_adjustment_location_usecase.dart';
import 'package:wherehouse/features/dashboard/domain/usecases/submit_adjustment_count_usecase.dart';
import 'package:wherehouse/features/dashboard/domain/usecases/validate_task_location_usecase.dart';
import 'package:wherehouse/features/dashboard/presentation/controllers/worker_tasks_controller.dart';
import 'package:wherehouse/shared/navigation/navigation_controller.dart';
import 'package:wherehouse/shared/widgets/main_scaffold.dart';
import 'package:wherehouse/shared/providers/global_error_provider.dart';
import 'package:wherehouse/shared/providers/global_loading_provider.dart';
import 'package:wherehouse/shared/providers/locale_controller.dart';
import 'package:wherehouse/shared/widgets/putaway_app.dart';
import 'package:wherehouse/core/utils/result.dart';

import '../../support/fake_repositories.dart';

void main() {
  testWidgets(
      'putaway app replaces the current route with worker home when app resumes',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/account',
      routes: [
        GoRoute(
          path: '/account',
          builder: (context, state) => const Scaffold(
            body: Text('Account Page'),
          ),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(
            body: Text('Worker Home'),
          ),
        ),
      ],
    );
    final session = SessionController()
      ..setUser(
        const User(
          id: 'worker-1',
          name: 'Worker',
          role: 'worker',
          phone: '555',
          zone: 'A1',
        ),
      );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<GoRouter>.value(value: router),
          ChangeNotifierProvider<SessionController>.value(value: session),
          ChangeNotifierProvider<GlobalLoadingController>(
            create: (_) => GlobalLoadingController(),
          ),
          ChangeNotifierProvider<GlobalErrorController>(
            create: (_) => GlobalErrorController(),
          ),
          ChangeNotifierProvider<LocaleController>(
            create: (_) => LocaleController(),
          ),
        ],
        child: const PutawayApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Account Page'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/account');

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text('Worker Home'), findsOneWidget);
    expect(find.text('Account Page'), findsNothing);
    expect(router.routeInformationProvider.value.uri.path, '/home');
  });

  testWidgets('account tab stays tappable after app resumes on worker home',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const MainScaffold(),
        ),
      ],
    );
    final session = SessionController()
      ..setUser(
        const User(
          id: 'worker-2',
          name: 'Worker',
          role: 'worker',
          phone: '555',
          zone: 'A',
        ),
      );
    final taskRepo = FakeTaskRepository();
    final workerController = WorkerTasksController(
      getTasksForZone: GetTasksForZoneUseCase(taskRepo),
      claimTask: ClaimTaskUseCase(taskRepo),
      completeTask: CompleteTaskUseCase(taskRepo),
      getTaskSuggestion: GetTaskSuggestionUseCase(taskRepo),
      scanAdjustmentLocation: ScanAdjustmentLocationUseCase(taskRepo),
      saveCycleCountProgress: SaveCycleCountProgressUseCase(taskRepo),
      submitAdjustmentCount: SubmitAdjustmentCountUseCase(taskRepo),
      validateTaskLocation: ValidateTaskLocationUseCase(taskRepo),
      session: session,
    );
    await workerController.load();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<GoRouter>.value(value: router),
          Provider<AuthRepository>.value(value: _FakeAuthRepository()),
          ChangeNotifierProvider<SessionController>.value(value: session),
          ChangeNotifierProvider<NavigationController>(
            create: (_) => NavigationController(),
          ),
          ChangeNotifierProvider<WorkerTasksController>.value(
            value: workerController,
          ),
          ChangeNotifierProvider<GlobalLoadingController>(
            create: (_) => GlobalLoadingController(),
          ),
          ChangeNotifierProvider<GlobalErrorController>(
            create: (_) => GlobalErrorController(),
          ),
          ChangeNotifierProvider<LocaleController>(
            create: (_) => LocaleController(),
          ),
        ],
        child: const PutawayApp(),
      ),
    );
    await tester.pumpAndSettle();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();

    expect(find.text('Sign Out'), findsOneWidget);
  });

  testWidgets('putaway app blocks routed content when force update is active',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/account',
      routes: [
        GoRoute(
          path: '/account',
          builder: (context, state) => const Scaffold(
            body: Text('Account Page'),
          ),
        ),
      ],
    );
    final controller = AppUpdateController(
      repository: _FakeAppUpdateRepository(
        result: const Success<AppUpdateConfig>(
          AppUpdateConfig(
            latestVersion: '1.2.1',
            minSupportedVersion: '1.2.1',
            downloadUrl:
                'https://github.com/osmsn637-tech/osman-ahmed/releases/download/putaway/putaway_app.apk',
            releaseNotes: 'Install the latest Android build.',
          ),
        ),
      ),
      versionComparator: const VersionComparator(),
      platformInfo: const _FakePlatformInfo(isAndroid: true),
      installedAppVersionProvider:
          const _FakeInstalledAppVersionProvider('1.2.0'),
      updateUrlLauncher: _FakeUpdateUrlLauncher(),
    );
    await controller.checkForUpdates();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<GoRouter>.value(value: router),
          ChangeNotifierProvider<AppUpdateController>.value(value: controller),
          ChangeNotifierProvider<SessionController>(
            create: (_) => SessionController(),
          ),
          ChangeNotifierProvider<GlobalLoadingController>(
            create: (_) => GlobalLoadingController(),
          ),
          ChangeNotifierProvider<GlobalErrorController>(
            create: (_) => GlobalErrorController(),
          ),
          ChangeNotifierProvider<LocaleController>(
            create: (_) => LocaleController(),
          ),
        ],
        child: const PutawayApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Update App'), findsOneWidget);
    expect(find.text('Account Page'), findsNothing);
  });

  testWidgets('putaway app rechecks updates when app resumes', (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(
            body: Text('Worker Home'),
          ),
        ),
      ],
    );
    final repository = _FakeAppUpdateRepository(
      result: const Success<AppUpdateConfig>(
        AppUpdateConfig(
          latestVersion: '1.2.1',
          minSupportedVersion: '1.2.1',
          downloadUrl:
              'https://github.com/osmsn637-tech/osman-ahmed/releases/download/putaway/putaway_app.apk',
        ),
      ),
    );
    final controller = AppUpdateController(
      repository: repository,
      versionComparator: const VersionComparator(),
      platformInfo: const _FakePlatformInfo(isAndroid: true),
      installedAppVersionProvider:
          const _FakeInstalledAppVersionProvider('1.2.1'),
      updateUrlLauncher: _FakeUpdateUrlLauncher(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<GoRouter>.value(value: router),
          ChangeNotifierProvider<AppUpdateController>.value(value: controller),
          ChangeNotifierProvider<SessionController>(
            create: (_) => SessionController(),
          ),
          ChangeNotifierProvider<GlobalLoadingController>(
            create: (_) => GlobalLoadingController(),
          ),
          ChangeNotifierProvider<GlobalErrorController>(
            create: (_) => GlobalErrorController(),
          ),
          ChangeNotifierProvider<LocaleController>(
            create: (_) => LocaleController(),
          ),
        ],
        child: const PutawayApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.fetchCount, 0);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(repository.fetchCount, 1);
  });

  testWidgets('putaway app supports Urdu locale in the app shell',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(
            body: Text('Worker Home'),
          ),
        ),
      ],
    );
    final localeController = LocaleController()..setLocale('ur');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<GoRouter>.value(value: router),
          ChangeNotifierProvider<SessionController>(
            create: (_) => SessionController(),
          ),
          ChangeNotifierProvider<GlobalLoadingController>(
            create: (_) => GlobalLoadingController(),
          ),
          ChangeNotifierProvider<GlobalErrorController>(
            create: (_) => GlobalErrorController(),
          ),
          ChangeNotifierProvider<LocaleController>.value(
            value: localeController,
          ),
        ],
        child: const PutawayApp(),
      ),
    );
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale, const Locale('ur'));
    expect(app.supportedLocales, contains(const Locale('ur')));
  });

  testWidgets('putaway app shows a yellow DEV ribbon in the top left in development mode',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(
            body: Text('Worker Home'),
          ),
        ),
      ],
    );
    final environmentController = _FakeAppEnvironmentController(
      AppEnvironment.development,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<GoRouter>.value(value: router),
          ChangeNotifierProvider<AppEnvironmentController>.value(
            value: environmentController,
          ),
          ChangeNotifierProvider<SessionController>(
            create: (_) => SessionController(),
          ),
          ChangeNotifierProvider<GlobalLoadingController>(
            create: (_) => GlobalLoadingController(),
          ),
          ChangeNotifierProvider<GlobalErrorController>(
            create: (_) => GlobalErrorController(),
          ),
          ChangeNotifierProvider<LocaleController>(
            create: (_) => LocaleController(),
          ),
        ],
        child: const PutawayApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DEV'), findsOneWidget);

    final ribbon = tester.widget<DecoratedBox>(find.byKey(const Key('dev-ribbon')));
    final decoration = ribbon.decoration as BoxDecoration;
    expect(decoration.color, const Color(0xFFF2C94C));

    final positioned = tester.widget<Positioned>(
      find.ancestor(
        of: find.byKey(const Key('dev-ribbon')),
        matching: find.byType(Positioned),
      ),
    );
    expect(positioned.left, isNotNull);
    expect(positioned.right, isNull);

    expect(
      find.ancestor(
        of: find.byKey(const Key('dev-ribbon')),
        matching: find.byType(Transform),
      ),
      findsOneWidget,
    );
  });

  testWidgets('putaway app hides DEV badge in production mode',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(
            body: Text('Worker Home'),
          ),
        ),
      ],
    );
    final environmentController = _FakeAppEnvironmentController(
      AppEnvironment.production,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<GoRouter>.value(value: router),
          ChangeNotifierProvider<AppEnvironmentController>.value(
            value: environmentController,
          ),
          ChangeNotifierProvider<SessionController>(
            create: (_) => SessionController(),
          ),
          ChangeNotifierProvider<GlobalLoadingController>(
            create: (_) => GlobalLoadingController(),
          ),
          ChangeNotifierProvider<GlobalErrorController>(
            create: (_) => GlobalErrorController(),
          ),
          ChangeNotifierProvider<LocaleController>(
            create: (_) => LocaleController(),
          ),
        ],
        child: const PutawayApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DEV'), findsNothing);
  });
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return const Success<void>(null);
  }

  @override
  Future<Result<User>> login(LoginParams params) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<User?>> loadPersistedSession() async {
    return const Success<User?>(null);
  }

  @override
  Future<Result<void>> logout() async {
    return const Success<void>(null);
  }
}

class _FakeAppUpdateRepository implements AppUpdateRepository {
  _FakeAppUpdateRepository({required this.result});

  final Result<AppUpdateConfig> result;
  int fetchCount = 0;

  @override
  Future<Result<AppUpdateConfig>> fetchRemoteConfig() async {
    fetchCount++;
    return result;
  }
}

class _FakePlatformInfo implements PlatformInfo {
  const _FakePlatformInfo({required this.isAndroid});

  @override
  final bool isAndroid;
}

class _FakeInstalledAppVersionProvider implements InstalledAppVersionProvider {
  const _FakeInstalledAppVersionProvider(this.version);

  final String version;

  @override
  Future<String> getVersion() async => version;
}

class _FakeUpdateUrlLauncher implements UpdateUrlLauncher {
  @override
  Future<bool> open(String url) async => true;
}

class _FakeAppEnvironmentController extends AppEnvironmentController {
  _FakeAppEnvironmentController(AppEnvironment environment)
      : _environment = environment,
        super(initialEnvironment: environment);

  final AppEnvironment _environment;

  @override
  AppEnvironment get environment => _environment;

  @override
  bool get isDevelopment => _environment == AppEnvironment.development;
}
