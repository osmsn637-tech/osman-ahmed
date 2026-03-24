import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wherehouse/flutter_gen/gen_l10n/app_localizations.dart';
import 'package:wherehouse/features/auth/domain/entities/user.dart';
import 'package:wherehouse/features/auth/presentation/providers/session_provider.dart';
import 'package:wherehouse/features/dashboard/domain/entities/task_entity.dart';
import 'package:wherehouse/features/dashboard/domain/usecases/claim_task_usecase.dart';
import 'package:wherehouse/features/dashboard/domain/usecases/complete_task_usecase.dart';
import 'package:wherehouse/features/dashboard/domain/usecases/get_task_suggestion_usecase.dart';
import 'package:wherehouse/features/dashboard/domain/usecases/get_tasks_for_zone_usecase.dart';
import 'package:wherehouse/features/dashboard/domain/usecases/scan_adjustment_location_usecase.dart';
import 'package:wherehouse/features/dashboard/domain/usecases/save_cycle_count_progress_usecase.dart';
import 'package:wherehouse/features/dashboard/domain/usecases/submit_adjustment_count_usecase.dart';
import 'package:wherehouse/features/dashboard/domain/usecases/validate_task_location_usecase.dart';
import 'package:wherehouse/features/dashboard/presentation/controllers/worker_tasks_controller.dart';
import 'package:wherehouse/features/dashboard/presentation/pages/worker_home_page.dart';
import 'package:wherehouse/features/move/domain/usecases/lookup_item_by_barcode_usecase.dart';

import '../../../../support/fake_repositories.dart';

void main() {
  Future<void> pumpWorkerHome(
    WidgetTester tester, {
    required SessionController session,
    required WorkerTasksController workerController,
    Locale? locale,
  }) async {
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
              Provider<LookupItemByBarcodeUseCase>(
                create: (_) =>
                    LookupItemByBarcodeUseCase(const FakeItemRepository()),
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
        locale: locale,
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

  testWidgets('opened tasks assigned to the worker render before pending tasks',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

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

    final taskRepo = FakeTaskRepository();
    taskRepo.addTask(buildTestTask(
      id: 9200,
      itemId: 9200,
      itemName: 'Pending Task',
      quantity: 1,
      zone: 'Z01',
      status: TaskStatus.pending,
      assignedTo: null,
    ));
    taskRepo.addTask(buildTestTask(
      id: 9201,
      itemId: 9201,
      itemName: 'Opened Task',
      quantity: 1,
      zone: 'Z01',
      status: TaskStatus.inProgress,
      assignedTo: 'worker-1',
    ));

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

    await pumpWorkerHome(
      tester,
      session: session,
      workerController: workerController,
    );

    final openedTaskTitle = find.text('Opened Task');
    final pendingTaskTitle = find.text('Pending Task');

    expect(openedTaskTitle, findsOneWidget);
    expect(pendingTaskTitle, findsOneWidget);
    expect(tester.getTopLeft(openedTaskTitle).dy,
        lessThan(tester.getTopLeft(pendingTaskTitle).dy));
  });

  testWidgets('worker home task card shows quantity with unit', (tester) async {
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

    final taskRepo = FakeTaskRepository();
    taskRepo.addTask(buildTestTask(
      id: 9202,
      itemId: 9202,
      itemName: 'Unit Task',
      quantity: 7,
      unit: 'box',
      zone: 'Z01',
    ));

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

    await pumpWorkerHome(
      tester,
      session: session,
      workerController: workerController,
    );

    expect(find.text('Unit Task'), findsOneWidget);
    expect(find.text('Qty: 7 box'), findsOneWidget);
  });

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

    final taskRepo = FakeTaskRepository();
    taskRepo.addTask(buildTestTask(
      id: 9100,
      itemId: 9100,
      itemName: 'Flow Task',
      quantity: 2,
      zone: 'Z01',
      type: TaskType.move,
      fromLocation: 'Z01-C01-L01-P01',
      toLocation: 'Z01-C02-L02-P02',
      itemBarcode: 'FLOW-123',
    ));

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

    await pumpWorkerHome(
      tester,
      session: session,
      workerController: workerController,
    );
    await tester.scrollUntilVisible(
      find.text('Flow Task'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('My Active Tasks'), findsNothing);
    expect(find.text('Flow Task'), findsOneWidget);

    final flowTaskCard = find
        .ancestor(of: find.text('Flow Task'), matching: find.byType(Card))
        .first;
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
    await tester.scrollUntilVisible(
      find.text('Flow Task'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('My Active Tasks'), findsNothing);
    expect(find.text('Flow Task'), findsOneWidget);

    final reopenedFlowTaskCard = find
        .ancestor(of: find.text('Flow Task'), matching: find.byType(Card))
        .first;
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
    await tester.scrollUntilVisible(
      find.text('Flow Task'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Completed Tasks'), findsOneWidget);

    final completedFlowTaskCard = find
        .ancestor(of: find.text('Flow Task'), matching: find.byType(Card))
        .first;
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

  testWidgets(
      'worker queue does not include auto-seeded return or cycle count tasks',
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

    await pumpWorkerHome(
      tester,
      session: session,
      workerController: workerController,
    );

    expect(find.text('Return Tote RT-204'), findsNothing);
    expect(find.text('Count SKU in SHELF-01-01'), findsNothing);
    expect(find.text('Full Shelf Count - SHELF-09-03'), findsNothing);
  });

  testWidgets('worker home renders Arabic section labels', (tester) async {
    final session = SessionController();
    session.setUser(
      const User(
        id: 'worker-1',
        name: 'عامل',
        role: 'worker',
        phone: '9990000000',
        zone: 'Z01',
      ),
    );

    final taskRepo = FakeTaskRepository();
    taskRepo.addTask(buildTestTask(
      id: 9300,
      itemId: 9300,
      itemName: 'Arabic Task',
      quantity: 1,
      zone: 'Z01',
      status: TaskStatus.pending,
      assignedTo: null,
    ));

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

    await pumpWorkerHome(
      tester,
      session: session,
      workerController: workerController,
      locale: const Locale('ar'),
    );

    expect(find.text('المهام'), findsOneWidget);
    expect(find.text('فتح'), findsNothing);
    expect(find.text('بدء'), findsOneWidget);
  });
}
