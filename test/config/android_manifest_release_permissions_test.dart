import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release manifest declares INTERNET permission', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml');
    final content = manifest.readAsStringSync();

    expect(
      content,
      contains('android.permission.INTERNET'),
      reason: 'Release builds need INTERNET permission for API calls.',
    );
  });
}
