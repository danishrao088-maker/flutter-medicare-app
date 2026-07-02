import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:medicare/theme.dart';
import 'package:medicare/utils/validators.dart';

void main() {
  group('Validators', () {
    test('name requires at least 2 characters', () {
      expect(Validators.name(''), isNotNull);
      expect(Validators.name('A'), isNotNull);
      expect(Validators.name('Alice'), isNull);
    });

    test('email must be well-formed', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email('user@example.com'), isNull);
    });

    test('password requires letters and a digit, 6+ chars', () {
      expect(Validators.password('short'), isNotNull);
      expect(Validators.password('alllowercase'), isNotNull);
      expect(Validators.password('letters1'), isNull);
    });

    test('confirmPassword must match the original', () {
      expect(Validators.confirmPassword('abc', 'abc'), isNull);
      expect(Validators.confirmPassword('abc', 'def'), isNotNull);
    });
  });

  group('passwordStrength', () {
    test('empty string is 0', () {
      expect(passwordStrength(''), 0);
    });

    test('short letters-only is weak (<= 2)', () {
      expect(passwordStrength('hello'), lessThanOrEqualTo(2));
    });

    test('long mixed password is strong (>= 3)', () {
      expect(passwordStrength('GoodPass1!'), greaterThanOrEqualTo(3));
    });
  });

  test('AppTheme exposes a Material 3 dark theme', () {
    final t = AppTheme.darkTheme;
    expect(t.useMaterial3, isTrue);
    expect(t.brightness, Brightness.dark);
  });
}
