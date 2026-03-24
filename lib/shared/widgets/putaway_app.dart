import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:wherehouse/flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

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
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      theme: AppTheme.light(),
      locale: localeController.locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) => GlobalLoadingListener(
        child: GlobalErrorListener(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
