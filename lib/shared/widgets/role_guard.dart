import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/presentation/providers/session_provider.dart';
import '../pages/access_denied_page.dart';

class RoleGuard extends StatelessWidget {
  const RoleGuard({super.key, required this.allowedRoles, required this.child});

  final List<String> allowedRoles;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final user = context.select<SessionController, String?>((s) => s.state.user?.role.toLowerCase());
    if (user == null) {
      return const AccessDeniedPage();
    }
    if (allowedRoles.isEmpty || allowedRoles.map((r) => r.toLowerCase()).contains(user)) {
      return child;
    }
    return const AccessDeniedPage();
  }
}
