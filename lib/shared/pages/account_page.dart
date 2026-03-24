import 'package:flutter/material.dart';
import 'package:wherehouse/flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/presentation/providers/session_provider.dart';
import '../l10n/l10n.dart';
import '../providers/locale_controller.dart';
import '../theme/app_theme.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sessionState = context.watch<SessionController>().state;
    final user = sessionState.user;
    final locale = context.watch<LocaleController>().locale.languageCode;
    final name = user?.name ?? 'User';
    final role = user?.canonicalRole ?? 'worker';
    final phone = user?.phone ?? '966533333333';
    final direction = locale == 'ar' ? TextDirection.rtl : TextDirection.ltr;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountMyAccount)),
      body: Directionality(
        textDirection: direction,
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFDDE9F8), AppTheme.surface],
                  stops: [0.0, 0.35],
                ),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                children: [
                  _HeroPanel(name: name, role: role),
                  const SizedBox(height: 14),
                  _InfoPanel(
                    phone: phone,
                    role: role,
                    l10n: l10n,
                  ),
                  const SizedBox(height: 14),
                  _LanguagePanel(locale: locale, l10n: l10n),
                  const SizedBox(height: 14),
                  _ActionsPanel(l10n: l10n),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.name,
    required this.role,
  });

  final String name;
  final String role;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final roleLabel = _roleLabel(l10n, role);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D3B66), Color(0xFF184E77)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2A0D3B66),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  name.isEmpty ? 'U' : name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      roleLabel,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.phone,
    required this.role,
    required this.l10n,
  });

  final String phone;
  final String role;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: l10n.accountDetails,
      icon: Icons.badge_outlined,
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.phone_outlined,
            label: l10n.accountPhone,
            value: phone,
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.manage_accounts_outlined,
            label: l10n.accountRole,
            value: _roleLabel(l10n, role),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

String _roleLabel(AppLocalizations l10n, String role) {
  return switch (User.canonicalizeRole(role)) {
    'supervisor' => l10n.roleSupervisor,
    'inbound' => l10n.roleInbound,
    _ => l10n.roleWorker,
  };
}

class _LanguagePanel extends StatelessWidget {
  const _LanguagePanel({required this.locale, required this.l10n});

  final String locale;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<LocaleController>();
    return _Panel(
      title: l10n.accountLanguage,
      icon: Icons.language_rounded,
      child: Row(
        children: [
          Expanded(
            child: _LangButton(
              label: l10n.accountArabic,
              selected: locale == 'ar',
              onTap: () => controller.setLocale('ar'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _LangButton(
              label: l10n.accountEnglish,
              selected: locale == 'en',
              onTap: () => controller.setLocale('en'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionsPanel extends StatelessWidget {
  const _ActionsPanel({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: l10n.accountActions,
      icon: Icons.tune_rounded,
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.accountComingSoon)),
                );
              },
              icon: const Icon(Icons.lock_outline_rounded),
              label: Text(l10n.accountChangePassword),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
              ),
              onPressed: () => context.read<SessionController>().clear(),
              icon: const Icon(Icons.logout_rounded),
              label: Text(l10n.accountSignOut),
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDBE7F3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120D3B66),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2ECF7)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LangButton extends StatelessWidget {
  const _LangButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : const Color(0xFFF3F7FC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primary : const Color(0xFFD8E4F1),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}
