import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wherehouse/training/main_adjust_training.dart';

void main() {
  test('training locale helpers include Urdu support', () {
    expect(trainingSupportedLocales, contains(const Locale('ur')));
    expect(resolveTrainingLocale('ur'), const Locale('ur'));
    expect(trainingIsRtl(const Locale('ur')), isTrue);
    expect(
      trainingText(
        locale: const Locale('ur'),
        en: 'Adjust Item Training',
        ar: 'تدريب تعديل الصنف',
        ur: 'آئٹم ایڈجسٹمنٹ ٹریننگ',
      ),
      'آئٹم ایڈجسٹمنٹ ٹریننگ',
    );
  });
}
