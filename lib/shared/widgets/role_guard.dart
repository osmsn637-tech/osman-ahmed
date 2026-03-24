import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/presentation/providers/session_provider.dart';
import '../pages/access_denied_page.dart';

class RoleGuard extends StatelessWidget {
  const RoleGuard({super.key, required this.allowedRoles, required this.child});

  final List<String> allowedRoles;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final user = context.select<SessionController, String?>(
      (s) => s.state.user?.canonicalRole,
    );
    if (user == null) {
      return const AccessDeniedPage();
    }
    final canonicalAllowedRoles =
        allowedRoles.map(User.canonicalizeRole).toSet();
    if (allowedRoles.isEmpty || canonicalAllowedRoles.contains(user)) {
      return child;
    }
    return const AccessDeniedPage();
  }
}
