import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:putaway_app/flutter_gen/gen_l10n/app_localizations.dart';
import 'package:putaway_app/features/auth/domain/entities/user.dart';
import 'package:putaway_app/features/auth/presentation/providers/session_provider.dart';
import 'package:putaway_app/features/dashboard/data/repositories/task_repository_mock.dart';
import 'package:putaway_app/features/dashboard/domain/entities/task_entity.dart';
import 'package:putaway_app/features/dashboard/domain/usecases/claim_task_usecase.dart';
import 'package:putaway_app/features/dashboard/domain/usecases/complete_task_usecase.dart';
import 'package:putaway_app/features/dashboard/domain/usecases/get_task_suggestion_usecase.dart';
import 'package:putaway_app/features/dashboard/domain/usecases/get_tasks_for_zone_usecase.dart';
import 'package:putaway_app/features/dashboard/domain/usecases/validate_task_location_usecase.dart';
import 'package:putaway_app/features/dashboard/presentation/controllers/worker_tasks_controller.dart';
import 'package:putaway_app/features/dashboard/presentation/pages/worker_home_page.dart';

void main() {
  setUp(TaskRepositoryMock.reset);

  Future<void> pumpWorkerHome(
    WidgetTester tester, {
    required SessionController session,
    required WorkerTasksController workerController,
  }) async {
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
  }

  testWidgets(
      'started tasks auto-open, stay in the main list as Open, and move to completed tasks after completion',
      (tester) async {
    final session = SessionController();
    session.setUser(
      const User(
        id: 'worker-1',
        name: 'Worker',
        role: 'worker',
        phone: '9990000000',
        zone: 'Z01',
      ),
    );

    final taskRepo = TaskRepositoryMock();
    TaskRepositoryMock.addAutoReceiveTask(
      itemId: 9100,
      itemName: 'Flow Task',
      quantity: 2,
      createdBy: 'system',
      zone: 'Z01',
      type: TaskType.move,
      fromLocation: 'Z01-C01-L01-P01',
      toLocation: 'Z01-C02-L02-P02',
      itemBarcode: 'FLOW-123',
    );

    final workerController = WorkerTasksController(
      getTasksForZone: GetTasksForZoneUseCase(taskRepo),
      claimTask: ClaimTaskUseCase(taskRepo),
      completeTask: CompleteTaskUseCase(taskRepo),
      getTaskSuggestion: GetTaskSuggestionUseCase(taskRepo),
      validateTaskLocation: ValidateTaskLocationUseCase(taskRepo),
      session: session,
    );

    await pumpWorkerHome(
      tester,
      session: session,
      workerController: workerController,
    );

    expect(find.text('My Active Tasks'), findsNothing);
    expect(find.text('Flow Task'), findsOneWidget);

    final flowTaskCard =
        find.ancestor(of: find.text('Flow Task'), matching: find.byType(Card)).first;
    final startButton = find.descendant(
      of: flowTaskCard,
      matching: find.widgetWithText(ElevatedButton, 'Start'),
    );

    await tester.tap(startButton);
    await tester.pumpAndSettle();

    expect(find.text('Task Details'), findsOneWidget);
    expect(find.text('Flow Task'), findsWidgets);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('My Active Tasks'), findsNothing);
    expect(find.text('Flow Task'), findsOneWidget);

    final reopenedFlowTaskCard =
        find.ancestor(of: find.text('Flow Task'), matching: find.byType(Card)).first;
    expect(
      find.descendant(
        of: reopenedFlowTaskCard,
        matching: find.widgetWithText(ElevatedButton, 'Open'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: reopenedFlowTaskCard,
        matching: find.byIcon(Icons.open_in_new_rounded),
      ),
      findsNothing,
    );

    await tester.tap(find.descendant(
      of: reopenedFlowTaskCard,
      matching: find.widgetWithText(ElevatedButton, 'Open'),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('complete-task-button')));
    await tester.pumpAndSettle();

    expect(find.text('Completed Tasks'), findsOneWidget);

    final completedFlowTaskCard =
        find.ancestor(of: find.text('Flow Task'), matching: find.byType(Card)).first;
    expect(
      find.descendant(
        of: completedFlowTaskCard,
        matching: find.text('Done'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: completedFlowTaskCard,
        matching: find.widgetWithText(ElevatedButton, 'Open'),
      ),
      findsNothing,
    );
  });
}
