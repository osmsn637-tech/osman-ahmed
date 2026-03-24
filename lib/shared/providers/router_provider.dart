import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/providers/session_provider.dart';
import '../../features/dashboard/presentation/pages/exceptions_page.dart';
import '../../features/move/domain/usecases/adjust_stock_usecase.dart';
import '../../features/move/presentation/controllers/item_adjustment_controller.dart';
import '../../features/move/domain/usecases/lookup_item_by_barcode_usecase.dart';
import '../../features/move/presentation/controllers/item_lookup_controller.dart';
import '../../features/move/presentation/pages/item_lookup_result_page.dart';
import '../../features/move/presentation/pages/move_item_page.dart';
import '../../features/move/presentation/pages/stock_adjustment_page.dart';
import '../../features/inbound/presentation/pages/create_inbound_page.dart';
import '../../features/inbound/domain/entities/inbound_entities.dart';
import '../../features/inbound/presentation/controllers/inbound_receipt_controller.dart';
import '../../features/inbound/presentation/pages/inbound_receipt_page.dart';
import '../../features/inbound/domain/repositories/inbound_repository.dart';
import '../../features/receive/presentation/pages/receive_page.dart';
import '../../shared/widgets/main_scaffold.dart';
import '../pages/account_page.dart';

GoRouter buildRouter(
    BuildContext context, SessionController sessionController) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshNotifier(sessionController),
    redirect: (context, state) {
      final subloc = state.uri.path;
      final loggingIn = subloc == '/login';
      final isAuthenticated = sessionController.state.isAuthenticated;

      if (!isAuthenticated && !loggingIn) {
        return '/login';
      }
      if (isAuthenticated && loggingIn) {
        return '/home';
      }

      final isAdminRoute = subloc == '/admin';
      if (isAdminRoute && sessionController.state.user?.isWorker == true) {
        return '/receive';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainScaffold(),
      ),
      // Direct feature routes without tabs
      GoRoute(
        path: '/receive',
        builder: (context, state) => ReceivePage(
          initialBarcode: state.uri.queryParameters['barcode'],
        ),
      ),
      GoRoute(
        path: '/inbound/create',
        builder: (context, state) => CreateInboundPage(
          initialDocumentNumber: state.uri.queryParameters['po'],
          initialSupplier: state.uri.queryParameters['supplier'],
        ),
      ),
      GoRoute(
        path: '/inbound/receipt/:id',
        builder: (context, state) {
          final receiptId = Uri.decodeComponent(
            state.pathParameters['id'] ?? '',
          );
          final initialScanResult = state.extra is InboundReceiptScanResult
              ? state.extra as InboundReceiptScanResult
              : null;
          return ChangeNotifierProvider<InboundReceiptController>(
            create: (_) => InboundReceiptController(
              context.read<InboundRepository>(),
              receiptId: receiptId,
              initialScanResult: initialScanResult,
            ),
            child: InboundReceiptPage(receiptId: receiptId),
          );
        },
      ),
      GoRoute(
        path: '/move',
        builder: (context, state) => const MoveItemPage(),
      ),
      GoRoute(
        path: '/adjustment',
        builder: (context, state) => const StockAdjustmentPage(),
      ),
      GoRoute(
        path: '/item-lookup/result/:barcode',
        builder: (context, state) {
          final barcode = Uri.decodeComponent(
            state.pathParameters['barcode'] ?? '',
          );
          final mode = switch (state.uri.queryParameters['mode']) {
            'adjust' => ItemLookupPageMode.adjust,
            _ => ItemLookupPageMode.lookup,
          };
          return MultiProvider(
            providers: [
              ChangeNotifierProvider<ItemLookupController>(
                create: (_) => ItemLookupController(
                  lookupItemByBarcode:
                      context.read<LookupItemByBarcodeUseCase>(),
                ),
              ),
              ChangeNotifierProvider<ItemAdjustmentController>(
                create: (_) => ItemAdjustmentController(
                  adjustStock: context.read<AdjustStockUseCase>().call,
                  session: context.read<SessionController>(),
                ),
              ),
            ],
            child: ItemLookupResultPage(
              barcode: barcode,
              mode: mode,
            ),
          );
        },
      ),
      GoRoute(
        path: '/exceptions-tab',
        builder: (context, state) => const ExceptionsPage(),
      ),
      GoRoute(
        path: '/exceptions',
        builder: (context, state) => const ExceptionsPage(),
      ),
      GoRoute(
        path: '/account',
        builder: (context, state) => const AccountPage(),
      ),
    ],
  );
}

class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(ChangeNotifier listenable) {
    void onChange() => notifyListeners();
    listenable.addListener(onChange);
    _remove = () => listenable.removeListener(onChange);
  }

  late final VoidCallback _remove;

  @override
  void dispose() {
    _remove();
    super.dispose();
  }
}
