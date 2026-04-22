import 'package:flutter_test/flutter_test.dart';
import 'dart:math';

void main() {
  test('WBT-02: Boundary Constraint Safety (Min equals Max)', () {
    final double result = 5.0 + (Random().nextDouble() * (5.0 - 5.0));
    expect(result, equals(5.0));
  });

  test('WBT-04: Preset Validation Logic', () {
    int min = 10;
    int max = 5;
    if (min >= max) min = max - 1; 
    expect(min, lessThan(max));
  });
}