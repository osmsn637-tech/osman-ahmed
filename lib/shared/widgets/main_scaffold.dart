import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/dashboard/presentation/pages/home_page.dart';
import '../l10n/l10n.dart';
import '../navigation/navigation_controller.dart';
import '../pages/account_page.dart';
import '../../features/auth/presentation/providers/session_provider.dart';
import '../../features/dashboard/presentation/pages/worker_home_page.dart';
import '../../features/inbound/presentation/pages/inbound_home_page.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key, this.initialTab});

  final AppTab? initialTab;

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _RoleAwareHomePage extends StatelessWidget {
  const _RoleAwareHomePage();

  @override
  Widget build(BuildContext context) {
    final user =
        context.select<SessionController, dynamic>((s) => s.state.user);
    if (user == null) return const HomePage();
    if (user.isInbound) return const InboundHomePage();
    return const WorkerHomePage();
  }
}

class _MainScaffoldState extends State<MainScaffold> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final nav = context.read<NavigationController>();
    nav.setTab(widget.initialTab ?? AppTab.home);
  }

  Widget _buildPage(AppTab tab) {
    switch (tab) {
      case AppTab.home:
        return const _RoleAwareHomePage();
      case AppTab.account:
        return const AccountPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationController>(
      builder: (context, nav, _) {
        final l10n = context.l10n;
        final tabs = <_TabDef>[
          _TabDef(
              tab: AppTab.home,
              label: l10n.tabHome,
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded),
          _TabDef(
              tab: AppTab.account,
              label: l10n.tabAccount,
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded),
        ];
        final currentIndex = tabs.indexWhere((t) => t.tab == nav.tab);
        final safeIndex = currentIndex >= 0 ? currentIndex : 0;
        final pages = tabs.map((t) => _buildPage(t.tab)).toList(growable: false);

        return Scaffold(
          body: IndexedStack(index: safeIndex, children: pages),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x170D3B66),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: NavigationBar(
                animationDuration: const Duration(milliseconds: 350),
                selectedIndex: safeIndex,
                onDestinationSelected: (idx) => nav.setTab(tabs[idx].tab),
                destinations: [
                  for (final t in tabs)
                    NavigationDestination(
                      icon: Icon(t.icon),
                      selectedIcon: Icon(t.activeIcon),
                      tooltip: '',
                      label: t.label,
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

class _TabDef {
  const _TabDef(
      {required this.tab,
      required this.label,
      required this.icon,
      required this.activeIcon});

  final AppTab tab;
  final String label;
  final IconData icon;
  final IconData activeIcon;
}
