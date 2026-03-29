import 'package:flutter/material.dart';
import 'package:wherehouse/flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_environment_controller.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/result.dart';
import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/providers/session_provider.dart';
import '../l10n/l10n.dart';
import '../providers/locale_controller.dart';
import '../theme/app_theme.dart';
import '../utils/location_codes.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  int _zoneTapCount = 0;

  Future<void> _handleZoneTap() async {
    final environmentController = context.read<AppEnvironmentController?>();
    if (environmentController == null) {
      return;
    }

    _zoneTapCount += 1;
    if (_zoneTapCount < 5) {
      return;
    }
    _zoneTapCount = 0;

    final pinAccepted = await _showDeveloperModeDialog(context);
    if (pinAccepted != true || !mounted) {
      return;
    }

    await environmentController.toggleEnvironment();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sessionState = context.watch<SessionController>().state;
    final user = sessionState.user;
    final locale = context.watch<LocaleController>().locale.languageCode;
    final name = user?.name ?? 'User';
    final role = user?.canonicalRole ?? 'worker';
    final phone = user?.phone ?? '966533333333';
    final direction = switch (locale) {
      'ar' => TextDirection.rtl,
      _ => TextDirection.ltr,
    };
    final zone = formatZoneForDisplay(user?.zone);

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
                    zone: zone,
                    l10n: l10n,
                    onZoneTap: _handleZoneTap,
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
    required this.zone,
    required this.l10n,
    required this.onZoneTap,
  });

  final String phone;
  final String role;
  final String zone;
  final AppLocalizations l10n;
  final VoidCallback onZoneTap;

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
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: l10n.accountZone,
            value: zone,
            rowKey: const Key('account-zone-row'),
            onTap: onZoneTap,
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
          const SizedBox(width: 10),
          Expanded(
            child: _LangButton(
              label: l10n.accountUrdu,
              selected: locale == 'bn',
              onTap: () => controller.setLocale('bn'),
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
              onPressed: () => _showChangePasswordDialog(context, l10n),
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
              onPressed: () => _signOut(context),
              icon: const Icon(Icons.logout_rounded),
              label: Text(l10n.accountSignOut),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final repository = context.read<AuthRepository>();
    final session = context.read<SessionController>();
    final result = await repository.logout();

    switch (result) {
      case Success<void>():
        session.clear();
      case Failure<void>(error: final error):
        messenger.showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
    }
  }
}

Future<void> _showChangePasswordDialog(
  BuildContext context,
  AppLocalizations l10n,
) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => _ChangePasswordDialog(l10n: l10n),
  );
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog({required this.l10n});

  final AppLocalizations l10n;

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;

  bool _isSubmitting = false;
  String? _errorMessage;

  String get _requiredFieldsMessage => context.trText(
        english: 'Both password fields are required',
        arabic: 'حقلا كلمة المرور مطلوبان',
        urdu: 'দুটি পাসওয়ার্ড ক্ষেত্রই আবশ্যক',
      );

  String get _passwordUpdatedMessage => context.trText(
        english: 'Password updated successfully',
        arabic: 'تم تحديث كلمة المرور بنجاح',
        urdu: 'পাসওয়ার্ড সফলভাবে আপডেট হয়েছে',
      );

  String get _currentPasswordLabel => context.trText(
        english: 'Current Password',
        arabic: 'كلمة المرور الحالية',
        urdu: 'বর্তমান পাসওয়ার্ড',
      );

  String get _newPasswordLabel => context.trText(
        english: 'New Password',
        arabic: 'كلمة المرور الجديدة',
        urdu: 'নতুন পাসওয়ার্ড',
      );

  String get _cancelLabel => context.trText(
        english: 'Cancel',
        arabic: 'إلغاء',
        urdu: 'বাতিল',
      );

  String get _updatePasswordLabel => context.trText(
        english: 'Update Password',
        arabic: 'تحديث كلمة المرور',
        urdu: 'পাসওয়ার্ড আপডেট করুন',
      );

  @override
  void initState() {
    super.initState();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    if (currentPassword.isEmpty || newPassword.isEmpty) {
      setState(() {
        _errorMessage = _requiredFieldsMessage;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final result = await context.read<AuthRepository>().changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        );

    if (!mounted) return;

    switch (result) {
      case Success<void>():
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_passwordUpdatedMessage),
          ),
        );
      case Failure<void>(error: final error):
        setState(() {
          _isSubmitting = false;
          _errorMessage =
              error is AppException ? error.message : error.toString();
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.l10n.accountChangePassword),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _currentPasswordController,
            enabled: !_isSubmitting,
            obscureText: true,
            decoration: InputDecoration(
              labelText: _currentPasswordLabel,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newPasswordController,
            enabled: !_isSubmitting,
            obscureText: true,
            decoration: InputDecoration(
              labelText: _newPasswordLabel,
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: AppTheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(_cancelLabel),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_updatePasswordLabel),
        ),
      ],
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
    this.rowKey,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Key? rowKey;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: rowKey,
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
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
      ),
    );
  }
}

Future<bool?> _showDeveloperModeDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => const _DeveloperModeDialog(),
  );
}

class _DeveloperModeDialog extends StatefulWidget {
  const _DeveloperModeDialog();

  @override
  State<_DeveloperModeDialog> createState() => _DeveloperModeDialogState();
}

class _DeveloperModeDialogState extends State<_DeveloperModeDialog> {
  static const _secretPin = '564238';

  late final TextEditingController _pinController;
  String? _errorMessage;

  String get _title => context.trText(
        english: 'Developer Mode',
        arabic: 'وضع المطور',
        urdu: 'ডেভেলপার মোড',
      );

  String get _prompt => context.trText(
        english: 'Enter the PIN to switch environments',
        arabic: 'أدخل الرمز للتبديل بين البيئات',
        urdu: 'পরিবেশ পরিবর্তনের জন্য পিন লিখুন',
      );

  String get _pinLabel => context.trText(
        english: 'PIN',
        arabic: 'الرمز',
        urdu: 'পিন',
      );

  String get _cancelLabel => context.trText(
        english: 'Cancel',
        arabic: 'إلغاء',
        urdu: 'বাতিল',
      );

  String get _switchLabel => context.trText(
        english: 'Switch',
        arabic: 'تبديل',
        urdu: 'সুইচ',
      );

  String get _incorrectPinLabel => context.trText(
        english: 'Incorrect PIN',
        arabic: 'الرمز غير صحيح',
        urdu: 'ভুল পিন',
      );

  @override
  void initState() {
    super.initState();
    _pinController = TextEditingController();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_pinController.text.trim() != _secretPin) {
      setState(() {
        _errorMessage = _incorrectPinLabel;
      });
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_prompt),
          const SizedBox(height: 12),
          TextField(
            controller: _pinController,
            autofocus: true,
            keyboardType: TextInputType.number,
            obscureText: true,
            decoration: InputDecoration(
              labelText: _pinLabel,
            ),
            onSubmitted: (_) => _submit(),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: AppTheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(_cancelLabel),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(_switchLabel),
        ),
      ],
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : const Color(0xFFF3F7FC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primary : const Color(0xFFD8E4F1),
          ),
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            maxLines: 1,
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
