import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/auth_provider.dart';

void main() {
  group('extractApiErrorMessage', () {
    test('returns first item from non_field_errors list', () {
      final message = extractApiErrorMessage(
        {
          'non_field_errors': [
            'This password is too common.',
            'This password is entirely numeric.',
          ],
        },
        keys: const ['detail', 'non_field_errors'],
        fallback: 'fallback',
      );

      expect(message, 'This password is too common.');
    });

    test('respects key priority order', () {
      final message = extractApiErrorMessage(
        {
          'email': ['Email inválido'],
          'detail': 'Mensaje principal',
        },
        keys: const ['detail', 'email'],
        fallback: 'fallback',
      );

      expect(message, 'Mensaje principal');
    });

    test('falls back when payload has no expected keys', () {
      final message = extractApiErrorMessage(
        {'unexpected': 'value'},
        keys: const ['detail', 'email'],
        fallback: 'fallback',
      );

      expect(message, 'fallback');
    });
  });
}
