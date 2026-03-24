import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/token_repository.dart';
import '../../core/config/app_config.dart';
import '../../core/errors/error_mapper.dart';
import '../../core/network/api_client.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/token_refresh_handler.dart';
import '../../core/storage/secure_token_storage.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/dashboard/domain/repositories/task_repository.dart';
import '../../features/dashboard/domain/usecases/get_dashboard_tasks_usecase.dart';
import '../../features/dashboard/domain/usecases/get_tasks_for_zone_usecase.dart';
import '../../features/dashboard/domain/usecases/get_tasks_for_worker_usecase.dart';
import '../../features/dashboard/domain/usecases/complete_task_usecase.dart';
import '../../features/dashboard/domain/usecases/claim_task_usecase.dart';
import '../../features/dashboard/domain/usecases/get_task_suggestion_usecase.dart';
import '../../features/dashboard/domain/usecases/report_task_issue_usecase.dart';
import '../../features/dashboard/domain/usecases/save_cycle_count_progress_usecase.dart';
import '../../features/dashboard/domain/usecases/scan_adjustment_location_usecase.dart';
import '../../features/dashboard/domain/usecases/skip_task_usecase.dart';
import '../../features/dashboard/domain/usecases/submit_adjustment_count_usecase.dart';
import '../../features/dashboard/domain/usecases/validate_task_location_usecase.dart';
import '../../features/dashboard/presentation/controllers/dashboard_controller.dart';
import '../../features/dashboard/presentation/controllers/worker_tasks_controller.dart';
import '../../features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import '../../features/dashboard/data/datasources/task_remote_data_source.dart';
import '../../features/dashboard/data/repositories/task_repository_impl.dart';
import '../../features/move/domain/usecases/get_item_locations_usecase.dart';
import '../../features/move/domain/usecases/lookup_item_by_barcode_usecase.dart';
import '../../features/move/domain/usecases/adjust_stock_usecase.dart';
import '../../features/move/domain/usecases/move_item_usecase.dart';
import '../../features/move/data/datasources/item_remote_data_source.dart';
import '../../features/move/data/repositories/item_repository_impl.dart';
import '../../features/receive/domain/usecases/receive_item_usecase.dart';
import '../../features/receive/presentation/controllers/receive_controller.dart';
import '../../features/move/presentation/controllers/move_controller.dart';
import '../../features/move/domain/repositories/item_repository.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/presentation/providers/auth_controller.dart';
import '../../features/auth/presentation/providers/login_form_provider.dart';
import '../../features/auth/presentation/providers/session_provider.dart';
import '../navigation/navigation_controller.dart';
import '../../features/inbound/data/datasources/inbound_remote_data_source.dart';
import '../../features/inbound/data/repositories/inbound_repository_impl.dart';
import '../../features/inbound/domain/repositories/inbound_repository.dart';
import '../../features/inbound/domain/usecases/scan_inbound_receipt_usecase.dart';
import '../../features/inbound/presentation/controllers/inbound_controller.dart';
import '../providers/router_provider.dart';
import '../providers/global_error_provider.dart';
import '../providers/global_loading_provider.dart';
import 'locale_controller.dart';
import '../scanner/scanner_provider.dart';

typedef Logger = void Function(String message);

List<SingleChildWidget> appProviders(AppConfig config) {
  return [
    Provider<AppConfig>.value(value: config),
    Provider<ErrorMapper>(create: (_) => const ErrorMapper()),
    Provider<SecureTokenStorage>(create: (_) => SecureTokenStorage()),
    Provider<Logger>(create: (_) => (msg) => print(msg)),
    ProxyProvider<SecureTokenStorage, TokenRepository>(
      update: (_, storage, __) => TokenRepository(storage),
    ),
    ProxyProvider4<AppConfig, ErrorMapper, SecureTokenStorage, Logger,
        TokenRefreshHandler>(
      update: (_, cfg, mapper, storage, logger, __) => TokenRefreshHandler(
        baseUrl: cfg.apiBaseUrl,
        errorMapper: mapper,
        tokenStorage: storage,
        logger: logger,
      ),
    ),
    ProxyProvider5<AppConfig, ErrorMapper, TokenRepository, TokenRefreshHandler,
        Logger, DioClient>(
      update: (_, cfg, mapper, tokenRepo, refreshHandler, logger, __) =>
          DioClient(
        baseUrl: cfg.apiBaseUrl,
        enableLogging: cfg.enableNetworkLogging,
        tokenRepository: tokenRepo,
        tokenRefreshHandler: refreshHandler,
        errorMapper: mapper,
        onRefreshFailure: () {},
        logger: logger,
      ),
    ),
    ProxyProvider2<DioClient, ErrorMapper, ApiClient>(
      update: (_, dio, mapper, __) => ApiClient(dio.dio, mapper),
    ),
    ProxyProvider2<ApiClient, TokenRepository, AuthRepository>(
      update: (_, client, tokenRepo, __) => AuthRepositoryImpl(
        remoteDataSource: AuthRemoteDataSourceImpl(client),
        tokenRepository: tokenRepo,
      ),
    ),
    ProxyProvider<AuthRepository, LoginUseCase>(
      update: (_, repo, __) => LoginUseCase(repo),
    ),
    ProxyProvider<ApiClient, DashboardRemoteDataSource>(
      update: (_, client, __) => DashboardRemoteDataSource(client),
    ),
    ProxyProvider<ApiClient, TaskRemoteDataSource>(
      update: (_, client, __) => TaskRemoteDataSource(client),
    ),
    ProxyProvider2<DashboardRemoteDataSource, TaskRemoteDataSource,
        TaskRepository>(
      update: (_, dashboardRemote, taskRemote, __) => TaskRepositoryImpl(
        dashboardRemote,
        taskRemote,
      ),
    ),
    ProxyProvider<TaskRepository, GetDashboardTasksUseCase>(
      update: (_, repo, __) => GetDashboardTasksUseCase(repo),
    ),
    ProxyProvider<TaskRepository, GetTasksForZoneUseCase>(
      update: (_, repo, __) => GetTasksForZoneUseCase(repo),
    ),
    ProxyProvider<TaskRepository, GetTasksForWorkerUseCase>(
      update: (_, repo, __) => GetTasksForWorkerUseCase(repo),
    ),
    ProxyProvider<TaskRepository, CompleteTaskUseCase>(
      update: (_, repo, __) => CompleteTaskUseCase(repo),
    ),
    ProxyProvider<TaskRepository, ClaimTaskUseCase>(
      update: (_, repo, __) => ClaimTaskUseCase(repo),
    ),
    ProxyProvider<TaskRepository, GetTaskSuggestionUseCase>(
      update: (_, repo, __) => GetTaskSuggestionUseCase(repo),
    ),
    ProxyProvider<TaskRepository, ReportTaskIssueUseCase>(
      update: (_, repo, __) => ReportTaskIssueUseCase(repo),
    ),
    ProxyProvider<TaskRepository, SaveCycleCountProgressUseCase>(
      update: (_, repo, __) => SaveCycleCountProgressUseCase(repo),
    ),
    ProxyProvider<TaskRepository, SkipTaskUseCase>(
      update: (_, repo, __) => SkipTaskUseCase(repo),
    ),
    ProxyProvider<TaskRepository, ScanAdjustmentLocationUseCase>(
      update: (_, repo, __) => ScanAdjustmentLocationUseCase(repo),
    ),
    ProxyProvider<TaskRepository, SubmitAdjustmentCountUseCase>(
      update: (_, repo, __) => SubmitAdjustmentCountUseCase(repo),
    ),
    ProxyProvider<TaskRepository, ValidateTaskLocationUseCase>(
      update: (_, repo, __) => ValidateTaskLocationUseCase(repo),
    ),
    ProxyProvider<ApiClient, ItemRemoteDataSource>(
      update: (_, client, __) => ItemRemoteDataSourceImpl(client),
    ),
    ProxyProvider<ItemRemoteDataSource, ItemRepository>(
      update: (_, remote, __) => ItemRepositoryImpl(remote),
    ),
    ProxyProvider<ItemRepository, GetItemLocationsUseCase>(
      update: (_, repo, __) => GetItemLocationsUseCase(repo),
    ),
    ProxyProvider<ItemRepository, LookupItemByBarcodeUseCase>(
      update: (_, repo, __) => LookupItemByBarcodeUseCase(repo),
    ),
    ProxyProvider<ItemRepository, AdjustStockUseCase>(
      update: (_, repo, __) => AdjustStockUseCase(repo),
    ),
    ProxyProvider<ItemRepository, MoveItemUseCase>(
      update: (_, repo, __) => MoveItemUseCase(repo),
    ),
    ProxyProvider<ItemRepository, ReceiveItemUseCase>(
      update: (_, repo, __) => ReceiveItemUseCase(repo),
    ),
    ChangeNotifierProvider<SessionController>(
        create: (_) => SessionController()),
    ChangeNotifierProvider<GlobalErrorController>(
        create: (_) => GlobalErrorController()),
    ChangeNotifierProvider<GlobalLoadingController>(
        create: (_) => GlobalLoadingController()),
    ChangeNotifierProvider<LocaleController>(create: (_) => LocaleController()),
    ChangeNotifierProvider<NavigationController>(
        create: (_) => NavigationController()),
    ChangeNotifierProvider<ScannerProvider>(create: (_) => ScannerProvider()),
    ChangeNotifierProvider<ReceiveController>(
      create: (context) => ReceiveController(
        getItemLocationsUseCase: context.read<GetItemLocationsUseCase>(),
        receiveItemUseCase: context.read<ReceiveItemUseCase>(),
        session: context.read<SessionController>(),
      ),
    ),
    ChangeNotifierProvider<MoveController>(
      create: (context) => MoveController(
        getItemLocationsUseCase: context.read<GetItemLocationsUseCase>(),
        moveItemUseCase: context.read<MoveItemUseCase>(),
        session: context.read<SessionController>(),
      ),
    ),
    ChangeNotifierProvider<AuthController>(
      create: (context) {
        final controller = AuthController(
          loginUseCase: context.read<LoginUseCase>(),
          authRepository: context.read<AuthRepository>(),
          session: context.read<SessionController>(),
        );
        controller.init();
        return controller;
      },
    ),
    ChangeNotifierProvider<LoginFormController>(
      create: (context) => LoginFormController(
        loginUseCase: context.read<LoginUseCase>(),
        errors: context.read<GlobalErrorController>(),
        loading: context.read<GlobalLoadingController>(),
        session: context.read<SessionController>(),
        tokenRepository: context.read<TokenRepository>(),
      ),
    ),
    ChangeNotifierProvider<DashboardController>(
      create: (context) => DashboardController(
        getTasksUseCase: context.read<GetDashboardTasksUseCase>(),
        taskRepository: context.read<TaskRepository>(),
      )..load(),
    ),
    ChangeNotifierProvider<WorkerTasksController>(
      create: (context) => WorkerTasksController(
        getTasksForZone: context.read<GetTasksForZoneUseCase>(),
        claimTask: context.read<ClaimTaskUseCase>(),
        completeTask: context.read<CompleteTaskUseCase>(),
        getTaskSuggestion: context.read<GetTaskSuggestionUseCase>(),
        reportTaskIssue: context.read<ReportTaskIssueUseCase>(),
        scanAdjustmentLocation: context.read<ScanAdjustmentLocationUseCase>(),
        saveCycleCountProgress: context.read<SaveCycleCountProgressUseCase>(),
        skipTask: context.read<SkipTaskUseCase>(),
        submitAdjustmentCount: context.read<SubmitAdjustmentCountUseCase>(),
        validateTaskLocation: context.read<ValidateTaskLocationUseCase>(),
        session: context.read<SessionController>(),
      )..load(),
    ),
    ProxyProvider<ApiClient, InboundRemoteDataSource>(
      update: (_, client, __) => InboundRemoteDataSource(client),
    ),
    ProxyProvider<InboundRemoteDataSource, InboundRepository>(
      update: (_, remote, __) => InboundRepositoryImpl(remote),
    ),
    ProxyProvider<InboundRepository, ScanInboundReceiptUseCase>(
      update: (_, repo, __) => ScanInboundReceiptUseCase(repo),
    ),
    ChangeNotifierProvider<InboundController>(
      create: (context) => InboundController(context.read<InboundRepository>()),
    ),
    ProxyProvider<SessionController, GoRouter>(
      update: (context, session, __) => buildRouter(context, session),
    ),
  ];
}
