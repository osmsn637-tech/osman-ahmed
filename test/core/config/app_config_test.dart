import 'package:flutter_test/flutter_test.dart';
import 'package:wherehouse/core/config/app_config.dart';

void main() {
  test('load uses the GitHub release asset for android version metadata',
      () async {
    final config = await AppConfig.load();

    expect(
      config.androidVersionMetadataUrl,
      'https://github.com/osmsn637-tech/osman-ahmed/releases/download/putaway/version.json',
    );
  });
}
