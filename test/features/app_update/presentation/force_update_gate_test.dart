import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wherehouse/features/app_update/presentation/controllers/app_update_controller.dart';
import 'package:wherehouse/features/app_update/presentation/widgets/force_update_gate.dart';

void main() {
  testWidgets('renders versions, release notes, and update action',
      (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: ForceUpdateGate(
          state: const AppUpdateState(
            requiresForceUpdate: true,
            installedVersion: '1.2.0',
            minimumSupportedVersion: '1.2.1',
            latestVersion: '1.2.1',
            downloadUrl:
                'https://github.com/osmsn637-tech/osman-ahmed/releases/download/putaway/putaway_app.apk',
            releaseNotes: 'Force update to the latest Android build.',
          ),
          onUpdatePressed: () async {
            tapped = true;
            return true;
          },
        ),
      ),
    );

    expect(find.text('Update App'), findsOneWidget);
    expect(find.textContaining('1.2.0'), findsOneWidget);
    expect(find.textContaining('1.2.1'), findsWidgets);
    expect(
      find.text('Force update to the latest Android build.'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Update App'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('disables update action when the link is unavailable',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ForceUpdateGate(
          state: AppUpdateState(
            requiresForceUpdate: true,
            installedVersion: '1.2.0',
            minimumSupportedVersion: '1.2.1',
            latestVersion: '1.2.1',
          ),
        ),
      ),
    );

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Update App'),
    );

    expect(button.onPressed, isNull);
  });
}
