import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:putaway_app/flutter_gen/gen_l10n/app_localizations.dart';
import 'package:putaway_app/features/auth/domain/entities/user.dart';
import 'package:putaway_app/features/auth/presentation/providers/session_provider.dart';
import 'package:putaway_app/features/dashboard/data/repositories/task_repository_mock.dart';
import 'package:putaway_app/features/dashboard/domain/usecases/claim_task_usecase.dart';
import 'package:putaway_app/features/dashboard/domain/usecases/complete_task_usecase.dart';
import 'package:putaway_app/features/dashboard/domain/usecases/get_tasks_for_zone_usecase.dart';
import 'package:putaway_app/features/dashboard/domain/usecases/get_task_suggestion_usecase.dart';
import 'package:putaway_app/features/dashboard/domain/usecases/scan_adjustment_location_usecase.dart';
import 'package:putaway_app/features/dashboard/domain/usecases/save_cycle_count_progress_usecase.dart';
import 'package:putaway_app/features/dashboard/domain/usecases/submit_adjustment_count_usecase.dart';
import 'package:putaway_app/features/dashboard/domain/usecases/validate_task_location_usecase.dart';
import 'package:putaway_app/features/dashboard/presentation/controllers/worker_tasks_controller.dart';
import 'package:putaway_app/features/dashboard/presentation/pages/worker_home_page.dart';

void main() {
  setUp(TaskRepositoryMock.reset);

  testWidgets('available task card renders task image when provided',
      (tester) async {
    final session = SessionController();
    session.setUser(
      const User(
        id: '2bcf9d5d-1234-4f1d-8f6d-000000000007',
        name: 'Worker',
        role: 'worker',
        phone: '9990000000',
        zone: 'Z01',
      ),
    );

    final taskRepo = TaskRepositoryMock();
    TaskRepositoryMock.addAutoReceiveTask(
      itemId: 9001,
      itemName: 'Image Task',
      quantity: 1,
      createdBy: 'system',
      zone: 'Z01',
      toLocation: 'Z01-C09-L09-P09',
      itemImageUrl: 'https://example.com/task-image.png',
    );

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

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => MultiProvider(
            providers: [
              ChangeNotifierProvider<SessionController>.value(value: session),
              ChangeNotifierProvider<WorkerTasksController>.value(
                value: workerController,
              ),
            ],
            child: const WorkerHomePage(),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Image Task'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Image Task'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is NetworkImage &&
            (widget.image as NetworkImage).url ==
                'https://example.com/task-image.png' &&
            widget.fit == BoxFit.contain,
      ),
      findsOneWidget,
    );
  });

  testWidgets('lookup button opens scan popup on the same page',
      (tester) async {
    final session = SessionController();
    session.setUser(
      const User(
        id: '2bcf9d5d-1234-4f1d-8f6d-000000000007',
        name: 'Worker',
        role: 'worker',
        phone: '9990000000',
        zone: 'Z01',
      ),
    );

    final taskRepo = TaskRepositoryMock();
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

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => MultiProvider(
            providers: [
              ChangeNotifierProvider<SessionController>.value(value: session),
              ChangeNotifierProvider<WorkerTasksController>.value(
                value: workerController,
              ),
            ],
            child: const WorkerHomePage(),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ElevatedButton, 'Lookup'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Lookup'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byKey(const Key('scan_barcode_field')), findsOneWidget);
  });

  testWidgets('worker home shows lookup and adjust quick actions', (tester) async {
    final session = SessionController();
    session.setUser(
      const User(
        id: '2bcf9d5d-1234-4f1d-8f6d-000000000007',
        name: 'Worker',
        role: 'worker',
        phone: '9990000000',
        zone: 'Z01',
      ),
    );

    final taskRepo = TaskRepositoryMock();
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

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => MultiProvider(
            providers: [
              ChangeNotifierProvider<SessionController>.value(value: session),
              ChangeNotifierProvider<WorkerTasksController>.value(
                value: workerController,
              ),
            ],
            child: const WorkerHomePage(),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
    await tester.pumpAndSettle();

    final lookupButton = find.widgetWithText(ElevatedButton, 'Lookup');
    expect(lookupButton, findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Adjust'), findsOneWidget);
  });

  testWidgets('worker home exposes standalone adjust quick action',
      (tester) async {
    final session = SessionController();
    session.setUser(
      const User(
        id: '2bcf9d5d-1234-4f1d-8f6d-000000000007',
        name: 'Worker',
        role: 'worker',
        phone: '9990000000',
        zone: 'Z01',
      ),
    );

    final taskRepo = TaskRepositoryMock();
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

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => MultiProvider(
            providers: [
              ChangeNotifierProvider<SessionController>.value(value: session),
              ChangeNotifierProvider<WorkerTasksController>.value(
                value: workerController,
              ),
            ],
            child: const WorkerHomePage(),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ElevatedButton, 'Adjust'), findsOneWidget);
  });

  testWidgets('shared scan popup keeps scanner text input active',
      (tester) async {
    final session = SessionController();
    session.setUser(
      const User(
        id: '2bcf9d5d-1234-4f1d-8f6d-000000000007',
        name: 'Worker',
        role: 'worker',
        phone: '9990000000',
        zone: 'Z01',
      ),
    );

    final taskRepo = TaskRepositoryMock();
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

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => MultiProvider(
            providers: [
              ChangeNotifierProvider<SessionController>.value(value: session),
              ChangeNotifierProvider<WorkerTasksController>.value(
                value: workerController,
              ),
            ],
            child: const WorkerHomePage(),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Lookup'));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(
      find.byKey(const Key('scan_barcode_field')),
    );

    expect(field.keyboardType, TextInputType.visiblePassword);
  });
}
