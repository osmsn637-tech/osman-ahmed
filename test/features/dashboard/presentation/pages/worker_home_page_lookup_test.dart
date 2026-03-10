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
import 'package:putaway_app/features/dashboard/domain/usecases/validate_task_location_usecase.dart';
import 'package:putaway_app/features/dashboard/presentation/controllers/worker_tasks_controller.dart';
import 'package:putaway_app/features/dashboard/presentation/pages/worker_home_page.dart';

void main() {
  setUp(TaskRepositoryMock.reset);

  testWidgets('available task card renders task image when provided', (tester) async {
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

    expect(find.text('Image Task'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is NetworkImage &&
            (widget.image as NetworkImage).url == 'https://example.com/task-image.png' &&
            widget.fit == BoxFit.contain,
      ),
      findsOneWidget,
    );
  });

  testWidgets('lookup button opens scan popup on the same page', (tester) async {
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

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byKey(const Key('scan_barcode_field')), findsOneWidget);
  });
}
