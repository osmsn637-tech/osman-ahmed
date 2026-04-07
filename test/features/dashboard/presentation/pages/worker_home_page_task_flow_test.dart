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
    expect(find.text('Qty 7 box'), findsOneWidget);
  });

  testWidgets('worker home shows a one-row current task type filter',
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
      id: 9203,
      itemId: 9203,
      itemName: 'Move Filter Task',
      quantity: 1,
      zone: 'Z01',
      type: TaskType.move,
    ));
    taskRepo.addTask(buildTestTask(
      id: 9204,
      itemId: 9204,
      itemName: 'Return Filter Task',
      quantity: 1,
      zone: 'Z01',
      type: TaskType.returnTask,
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

    final filterRow = find.byKey(const Key('current-task-filter-row'));
    expect(filterRow, findsOneWidget);
    expect(
      find.descendant(of: filterRow, matching: find.text('ALL')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: filterRow, matching: find.text('MOVE')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: filterRow, matching: find.text('RETURN')),
      findsOneWidget,
    );

    final allY = tester.getCenter(find.byKey(const Key('task-filter-all'))).dy;
    final moveY =
        tester.getCenter(find.byKey(const Key('task-filter-move'))).dy;
    final returnY =
        tester.getCenter(find.byKey(const Key('task-filter-return'))).dy;

    expect(allY, closeTo(moveY, 0.01));
    expect(returnY, closeTo(moveY, 0.01));
  });

  testWidgets(
      'current task filter reloads the queue so overview and completed tasks match the selected type',
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
      id: 9205,
      itemId: 9205,
      itemName: 'Move Current Task',
      quantity: 1,
      zone: 'Z01',
      type: TaskType.move,
      status: TaskStatus.pending,
    ));
    taskRepo.addTask(buildTestTask(
      id: 9206,
      itemId: 9206,
      itemName: 'Return Current Task',
      quantity: 1,
      zone: 'Z01',
      type: TaskType.returnTask,
      status: TaskStatus.pending,
    ));
    taskRepo.addTask(buildTestTask(
      id: 9207,
      itemId: 9207,
      itemName: 'Completed Move Task',
      quantity: 1,
      zone: 'Z01',
      type: TaskType.move,
      status: TaskStatus.completed,
    ));
    taskRepo.addTask(buildTestTask(
      id: 9208,
      itemId: 9208,
      itemName: 'Completed Return Task',
      quantity: 1,
      zone: 'Z01',
      type: TaskType.returnTask,
      status: TaskStatus.completed,
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

    expect(taskRepo.lastRequestedTaskType, isNull);

    await tester.tap(find.byKey(const Key('task-filter-return')));
    await tester.pumpAndSettle();

    expect(taskRepo.lastRequestedTaskType, 'return');
    expect(find.text('Return Current Task'), findsOneWidget);
    expect(find.text('Move Current Task'), findsNothing);
    expect(find.byKey(const Key('overview-metric-Available')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('overview-metric-Available'))),
      isA<Text>().having((widget) => widget.data, 'value', '1'),
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('overview-metric-Done'))),
      isA<Text>().having((widget) => widget.data, 'value', '1'),
    );

    await tester.scrollUntilVisible(
      find.text('Completed Return Task'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Completed Tasks'), findsOneWidget);
    expect(find.text('Completed Return Task'), findsOneWidget);
    expect(find.text('Completed Move Task'), findsNothing);
  });

  testWidgets('current task filter sends API task names for mapped types',
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
      id: 9209,
      itemId: 9209,
      itemName: 'Putaway API Task',
      quantity: 1,
      zone: 'Z01',
      type: TaskType.receive,
      apiTaskType: 'putaway',
    ));
    taskRepo.addTask(buildTestTask(
      id: 9210,
      itemId: 9210,
      itemName: 'Cycle Count API Task',
      quantity: 1,
      zone: 'Z01',
      type: TaskType.cycleCount,
      apiTaskType: 'cycle count',
    ));
    taskRepo.addTask(buildTestTask(
      id: 9211,
      itemId: 9211,
      itemName: 'Refill API Task',
      quantity: 1,
      zone: 'Z01',
      type: TaskType.refill,
      apiTaskType: 'restock',
    ));
    taskRepo.addTask(buildTestTask(
      id: 9212,
      itemId: 9212,
      itemName: 'Return API Task',
      quantity: 1,
      zone: 'Z01',
      type: TaskType.returnTask,
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

    await tester.tap(find.byKey(const Key('task-filter-putaway')));
    await tester.pumpAndSettle();
    expect(taskRepo.lastRequestedTaskType, 'putaway');
    expect(find.text('Putaway API Task'), findsOneWidget);
    expect(find.text('Cycle Count API Task'), findsNothing);

    await tester.tap(find.byKey(const Key('task-filter-all')));
    await tester.pumpAndSettle();
    expect(taskRepo.lastRequestedTaskType, isNull);

    await tester.tap(find.byKey(const Key('task-filter-cycle-count')));
    await tester.pumpAndSettle();
    expect(taskRepo.lastRequestedTaskType, 'cycle count');
    expect(find.text('Cycle Count API Task'), findsOneWidget);
    expect(find.text('Refill API Task'), findsNothing);

    await tester.tap(find.byKey(const Key('task-filter-all')));
    await tester.pumpAndSettle();
    expect(taskRepo.lastRequestedTaskType, isNull);

    await tester.tap(find.byKey(const Key('task-filter-refill')));
    await tester.pumpAndSettle();
    expect(taskRepo.lastRequestedTaskType, 'restock');
    expect(find.text('Refill API Task'), findsOneWidget);
    expect(find.text('Return API Task'), findsNothing);

    await tester.tap(find.byKey(const Key('task-filter-all')));
    await tester.pumpAndSettle();
    expect(taskRepo.lastRequestedTaskType, isNull);

    await tester.tap(find.byKey(const Key('task-filter-return')));
    await tester.pumpAndSettle();
    expect(taskRepo.lastRequestedTaskType, 'return');
    expect(find.text('Return API Task'), findsOneWidget);
    expect(find.text('Putaway API Task'), findsNothing);
  });

  testWidgets('worker home hides tasks assigned to another worker everywhere',
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
      id: 9210,
      itemId: 9210,
      itemName: 'Visible Pending Task',
      quantity: 1,
      zone: 'Z01',
      status: TaskStatus.pending,
      assignedTo: null,
    ));
    taskRepo.addTask(buildTestTask(
      id: 9211,
      itemId: 9211,
      itemName: 'Visible Open Task',
      quantity: 1,
      zone: 'Z01',
      status: TaskStatus.inProgress,
      assignedTo: 'worker-1',
    ));
    taskRepo.addTask(buildTestTask(
      id: 9212,
      itemId: 9212,
      itemName: 'Hidden Other Worker Task',
      quantity: 1,
      zone: 'Z01',
      status: TaskStatus.inProgress,
      assignedTo: 'worker-2',
    ));
    taskRepo.addTask(buildTestTask(
      id: 9213,
      itemId: 9213,
      itemName: 'Hidden Other Worker Completed Task',
      quantity: 1,
      zone: 'Z01',
      status: TaskStatus.completed,
      assignedTo: 'worker-2',
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

    expect(find.text('Visible Pending Task'), findsOneWidget);
    expect(find.text('Visible Open Task'), findsOneWidget);
    expect(find.text('Hidden Other Worker Task'), findsNothing);
    expect(find.text('Hidden Other Worker Completed Task'), findsNothing);
    expect(
      tester.widget<Text>(find.byKey(const Key('overview-metric-Available'))),
      isA<Text>().having((widget) => widget.data, 'value', '1'),
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('overview-metric-Active'))),
      isA<Text>().having((widget) => widget.data, 'value', '1'),
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('overview-metric-Done'))),
      isA<Text>().having((widget) => widget.data, 'value', '0'),
    );
  });

  testWidgets('worker home shows task status labels on visible cards',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
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
      id: 9214,
      itemId: 9214,
      itemName: 'Pending Status Task',
      quantity: 1,
      zone: 'Z01',
      status: TaskStatus.pending,
      assignedTo: null,
    ));
    taskRepo.addTask(buildTestTask(
      id: 9215,
      itemId: 9215,
      itemName: 'Open Status Task',
      quantity: 1,
      zone: 'Z01',
      status: TaskStatus.inProgress,
      assignedTo: 'worker-1',
    ));
    taskRepo.addTask(buildTestTask(
      id: 9216,
      itemId: 9216,
      itemName: 'Completed Status Task',
      quantity: 1,
      zone: 'Z01',
      status: TaskStatus.completed,
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

    final completedTaskCard = find
        .ancestor(
          of: find.text('Completed Status Task'),
          matching: find.byType(Card),
        )
        .first;

    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('In Progress'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(
      find.descendant(
        of: completedTaskCard,
        matching: find.text('Done'),
      ),
      findsNothing,
    );
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
        matching: find.text('Completed'),
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
      'reopening a receive task keeps it on page 2 after page 1 was done',
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
      id: 9101,
      itemId: 9101,
      itemName: 'Receive Resume Task',
      quantity: 2,
      zone: 'Z01',
      type: TaskType.receive,
      status: TaskStatus.inProgress,
      assignedTo: 'worker-1',
      fromLocation: null,
      toLocation: 'BULK-01-02',
      itemBarcode: '123456789012',
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
      find.text('Receive Resume Task'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final taskCard = find
        .ancestor(
          of: find.text('Receive Resume Task'),
          matching: find.byType(Card),
        )
        .first;
    await tester.tap(find.descendant(
      of: taskCard,
      matching: find.widgetWithText(ElevatedButton, 'Open'),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('product-validate-field')),
      '123456789012',
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.text('Bulk Location'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Receive Resume Task'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final reopenedTaskCard = find
        .ancestor(
          of: find.text('Receive Resume Task'),
          matching: find.byType(Card),
        )
        .first;
    await tester.tap(find.descendant(
      of: reopenedTaskCard,
      matching: find.widgetWithText(ElevatedButton, 'Open'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Bulk Location'), findsOneWidget);
    expect(find.byKey(const Key('location-validate-field')), findsOneWidget);
    expect(find.byKey(const Key('product-validate-field')), findsNothing);
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
