import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wherehouse/training/main_adjust_training.dart';

void main() {
  test('training locale helpers include Bengali support', () {
    expect(trainingSupportedLocales, contains(const Locale('bn')));
    expect(resolveTrainingLocale('bn'), const Locale('bn'));
    expect(trainingIsRtl(const Locale('bn')), isFalse);
    expect(
      trainingText(
        locale: const Locale('bn'),
        en: 'Adjust Item Training',
        ar: 'تدريب تعديل الصنف',
        ur: 'আইটেম সমন্বয় প্রশিক্ষণ',
      ),
      'আইটেম সমন্বয় প্রশিক্ষণ',
    );
  });
}
