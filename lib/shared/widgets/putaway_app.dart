import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:wherehouse/flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_environment_controller.dart';
import '../../features/app_update/presentation/controllers/app_update_controller.dart';
import '../../features/app_update/presentation/widgets/force_update_gate.dart';
import '../../features/auth/presentation/providers/session_provider.dart';
import '../theme/app_theme.dart';
import 'global_error_listener.dart';
import 'global_loading_listener.dart';
import '../l10n/l10n.dart';
import '../providers/locale_controller.dart';

class PutawayApp extends StatefulWidget {
  const PutawayApp({super.key});

  @override
  State<PutawayApp> createState() => _PutawayAppState();
}

class _PutawayAppState extends State<PutawayApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) {
      return;
    }
    context.read<AppUpdateController?>()?.checkForUpdates();
    _redirectWorkerHomeIfNeeded();
  }

  void _redirectWorkerHomeIfNeeded() {
    final session = context.read<SessionController>().state;
    if (!session.isAuthenticated || session.user?.isWorker != true) {
      return;
    }
    final router = context.read<GoRouter>();
    if (router.routeInformationProvider.value.uri.path == '/home') {
      return;
    }
    router.replace('/home');
  }

  @override
  Widget build(BuildContext context) {
    final router = context.watch<GoRouter>();
    final localeController = context.watch<LocaleController>();
    final appUpdateController = context.watch<AppUpdateController?>();
    final environmentController = context.watch<AppEnvironmentController?>();
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      theme: AppTheme.light(),
      locale: localeController.locale,
      supportedLocales: const [Locale('en'), Locale('ar'), Locale('ur')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) {
        final childContent =
            appUpdateController?.state.requiresForceUpdate == true
                ? ForceUpdateGate(
                    state: appUpdateController!.state,
                    onUpdatePressed: appUpdateController.openUpdate,
                  )
                : child ?? const SizedBox.shrink();
        return GlobalLoadingListener(
          child: GlobalErrorListener(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Stack(
                children: [
                  childContent,
                  if (environmentController?.isDevelopment == true)
                    const Positioned(
                      top: 18,
                      left: -18,
                      child: _DevModeBadge(),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DevModeBadge extends StatelessWidget {
  const _DevModeBadge();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Transform.rotate(
        angle: -0.75,
        child: DecoratedBox(
          key: const Key('dev-ribbon'),
          decoration: BoxDecoration(
            color: const Color(0xFFF2C94C),
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: Text(
              'DEV',
              style: TextStyle(
                color: Color(0xFF4A3B00),
                fontWeight: FontWeight.w900,
                fontSize: 10,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
