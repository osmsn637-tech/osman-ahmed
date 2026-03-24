import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wherehouse/features/dashboard/domain/entities/task_entity.dart';
import 'package:wherehouse/features/dashboard/presentation/shared/dashboard_common_widgets.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  testWidgets('DashboardTypeBadge renders Putaway when requested', (tester) async {
    await tester.pumpWidget(
      wrap(
        const DashboardTypeBadge(
          TaskType.receive,
          isPutaway: true,
        ),
      ),
    );

    expect(find.text('PUTAWAY'), findsOneWidget);
  });

  testWidgets('DashboardTypeBadge still shows Receive by default', (tester) async {
    await tester.pumpWidget(
      wrap(
        const DashboardTypeBadge(TaskType.receive),
      ),
    );

    expect(find.text('RECEIVE'), findsOneWidget);
  });
}
