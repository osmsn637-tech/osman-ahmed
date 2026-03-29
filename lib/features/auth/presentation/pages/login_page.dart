import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:wherehouse/shared/providers/locale_controller.dart';
import 'package:wherehouse/shared/theme/app_theme.dart';
import 'package:wherehouse/shared/widgets/app_logo.dart';

import '../providers/login_form_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  static const _arLabel =
      '\u0627\u0644\u0639\u0631\u0628\u064a\u0629'; // العربية
  static const _urLabel = 'বাংলা';
  static const _arWarehouseSystem =
      '\u0646\u0638\u0627\u0645 \u0625\u062f\u0627\u0631\u0629 \u0627\u0644\u0645\u0633\u062a\u0648\u062f\u0639\u0627\u062a'; // نظام إدارة المستودعات
  static const _urWarehouseSystem = 'গুদাম ব্যবস্থাপনা সিস্টেম';
  static const _arMobile =
      '\u0631\u0642\u0645 \u0627\u0644\u062c\u0648\u0627\u0644'; // رقم الجوال
  static const _urMobile = 'মোবাইল নম্বর';
  static const _arPassword =
      '\u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631'; // كلمة المرور
  static const _urPassword = 'পাসওয়ার্ড';
  static const _arSignIn =
      '\u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062f\u062e\u0648\u0644'; // تسجيل الدخول
  static const _urSignIn = 'সাইন ইন করুন';
  static const List<String> _supportedLanguages = ['en', 'ar', 'bn'];

  String _version = '';
  String _lang = 'en';
  bool _obscure = true;
  late final AnimationController _introController;
  late final Animation<double> _introAnimation;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  LoginFormController? _formController;

  @override
  void initState() {
    super.initState();
    _lang = context.read<LocaleController>().locale.languageCode;
    final formController = context.read<LoginFormController>();
    formController.reset();
    _usernameController =
        TextEditingController(text: formController.state.username);
    _passwordController =
        TextEditingController(text: formController.state.password);
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _introAnimation = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOutCubic,
    );
    _introController.forward();
    _loadVersion();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final formController = context.read<LoginFormController>();
    if (identical(_formController, formController)) {
      return;
    }

    _formController?.removeListener(_syncFormFields);
    _formController = formController;
    _formController!.addListener(_syncFormFields);
    _syncFormFields();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _version = info.version);
    } catch (_) {}
  }

  @override
  void dispose() {
    _formController?.removeListener(_syncFormFields);
    _usernameController.dispose();
    _passwordController.dispose();
    _introController.dispose();
    super.dispose();
  }

  void _syncFormFields() {
    final formState = _formController?.state;
    if (formState == null) return;

    _syncTextController(_usernameController, formState.username);
    _syncTextController(_passwordController, formState.password);
  }

  void _syncTextController(TextEditingController controller, String value) {
    if (controller.text == value) return;

    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<LoginFormController>();
    final formState = context.watch<LoginFormController>().state;
    final localeController = context.read<LocaleController>();
    final direction = _lang == 'ar' ? TextDirection.rtl : TextDirection.ltr;
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableAnimations && _introController.value != 1.0) {
      _introController.value = 1.0;
    }

    return Scaffold(
      body: Directionality(
        textDirection: direction,
        child: Localizations.override(
          context: context,
          locale: Locale(_lang),
          child: SafeArea(
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.98, end: 1.0).animate(
                disableAnimations
                    ? const AlwaysStoppedAnimation<double>(1.0)
                    : _introAnimation,
              ),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.98, end: 1.0).animate(
                  disableAnimations
                      ? const AlwaysStoppedAnimation<double>(1.0)
                      : _introAnimation,
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      Align(
                        alignment: AlignmentDirectional.topStart,
                        child: Material(
                          color: Colors.transparent,
                          child: PopupMenuButton<String>(
                            initialValue: _lang,
                            onSelected: (value) {
                              setState(() => _lang = value);
                              localeController.setLocale(value);
                            },
                            itemBuilder: (context) => _supportedLanguages
                                .map(
                                  (code) => PopupMenuItem<String>(
                                    value: code,
                                    child: Text(_languageLabel(code)),
                                  ),
                                )
                                .toList(),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.language,
                                      size: 18, color: AppTheme.accent),
                                  const SizedBox(width: 6),
                                  Text(
                                    _languageLabel(_lang),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.accent,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const AppLogo(size: 88),
                                const SizedBox(height: 18),
                                Text(
                                  'QEU Putaway',
                                  textAlign: TextAlign.center,
                                  style:
                                      Theme.of(context).textTheme.headlineLarge,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _tr(
                                    english: 'Warehouse Management System',
                                    arabic: _arWarehouseSystem,
                                    urdu: _urWarehouseSystem,
                                  ),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 30),
                                TextField(
                                  controller: _usernameController,
                                  enabled: !formState.isSubmitting,
                                  decoration: InputDecoration(
                                    labelText: _tr(
                                      english: 'Mobile Number',
                                      arabic: _arMobile,
                                      urdu: _urMobile,
                                    ),
                                    prefixIcon:
                                        const Icon(Icons.phone_outlined),
                                  ),
                                  keyboardType: TextInputType.phone,
                                  style: const TextStyle(
                                    color: Color(0xFF1E293B),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  cursorColor: AppTheme.accent,
                                  onChanged: controller.usernameChanged,
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 14),
                                TextField(
                                  controller: _passwordController,
                                  enabled: !formState.isSubmitting,
                                  decoration: InputDecoration(
                                    labelText: _tr(
                                      english: 'Password',
                                      arabic: _arPassword,
                                      urdu: _urPassword,
                                    ),
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: GestureDetector(
                                      onTap: () =>
                                          setState(() => _obscure = !_obscure),
                                      child: Icon(
                                        _obscure
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                    ),
                                  ),
                                  obscureText: _obscure,
                                  style: const TextStyle(
                                    color: Color(0xFF1E293B),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  cursorColor: AppTheme.accent,
                                  onChanged: controller.passwordChanged,
                                  onSubmitted: (_) => controller.submit(),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  height: 52,
                                  child: Consumer<LoginFormController>(
                                    builder: (context, formController, _) {
                                      final state = formController.state;
                                      return ElevatedButton(
                                        onPressed:
                                            state.isValid && !state.isSubmitting
                                                ? controller.submit
                                                : null,
                                        child: Text(
                                          _tr(
                                            english: 'Sign In',
                                            arabic: _arSignIn,
                                            urdu: _urSignIn,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'v${_version.isEmpty ? '--' : _version}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _languageLabel(String code) {
    return switch (code) {
      'ar' => _arLabel,
      'bn' => _urLabel,
      _ => 'English',
    };
  }

  String _tr({
    required String english,
    required String arabic,
    required String urdu,
  }) {
    return switch (_lang) {
      'ar' => arabic,
      'bn' => urdu,
      _ => english,
    };
  }
}
