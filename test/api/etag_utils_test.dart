import 'package:flutter_test/flutter_test.dart';
import 'package:gympad/services/api/etag_utils.dart';

void main() {
  group('ETagUtils', () {
    group('isValid', () {
      test('accepts strong ETag with valid format', () {
        expect(ETagUtils.isValid('"abc123"'), isTrue);
        expect(ETagUtils.isValid('"e1da54-557e0-54e82e8e8a801"'), isTrue);
      });

      test('accepts weak ETag with valid format', () {
        expect(ETagUtils.isValid('W/"abc123"'), isTrue);
        expect(ETagUtils.isValid('W/"e1da54-557e0-54e82e8e8a801"'), isTrue);
      });

      test('rejects invalid formats', () {
        expect(ETagUtils.isValid('abc123'), isFalse); // Missing quotes
        expect(ETagUtils.isValid('"abc123'), isFalse); // Unmatched quote
        expect(ETagUtils.isValid('abc123"'), isFalse); // Unmatched quote
        expect(
          ETagUtils.isValid('W/abc123'),
          isFalse,
        ); // Missing quotes after W/
        expect(ETagUtils.isValid(''), isFalse);
        expect(ETagUtils.isValid(null), isFalse);
      });
    });

    group('isWeak', () {
      test('identifies weak ETags', () {
        expect(ETagUtils.isWeak('W/"abc123"'), isTrue);
        expect(ETagUtils.isWeak('W/"any-value"'), isTrue);
      });

      test('identifies strong ETags as not weak', () {
        expect(ETagUtils.isWeak('"abc123"'), isFalse);
        expect(ETagUtils.isWeak('"e1da54-557e0-54e82e8e8a801"'), isFalse);
      });

      test('returns false for null or invalid', () {
        expect(ETagUtils.isWeak(null), isFalse);
        expect(ETagUtils.isWeak(''), isFalse);
        expect(ETagUtils.isWeak('invalid'), isFalse);
      });
    });

    group('isStrong', () {
      test('identifies strong ETags', () {
        expect(ETagUtils.isStrong('"abc123"'), isTrue);
        expect(ETagUtils.isStrong('"e1da54-557e0-54e82e8e8a801"'), isTrue);
      });

      test('identifies weak ETags as not strong', () {
        expect(ETagUtils.isStrong('W/"abc123"'), isFalse);
        expect(ETagUtils.isStrong('W/"any-value"'), isFalse);
      });

      test('returns false for null or invalid', () {
        expect(ETagUtils.isStrong(null), isFalse);
        expect(ETagUtils.isStrong(''), isFalse);
        expect(ETagUtils.isStrong('invalid'), isFalse);
      });
    });

    group('extractValue', () {
      test('extracts value from strong ETag', () {
        expect(ETagUtils.extractValue('"abc123"'), equals('abc123'));
        expect(
          ETagUtils.extractValue('"e1da54-557e0-54e82e8e8a801"'),
          equals('e1da54-557e0-54e82e8e8a801'),
        );
      });

      test('extracts value from weak ETag', () {
        expect(ETagUtils.extractValue('W/"abc123"'), equals('abc123'));
        expect(
          ETagUtils.extractValue('W/"e1da54-557e0-54e82e8e8a801"'),
          equals('e1da54-557e0-54e82e8e8a801'),
        );
      });

      test('returns null for invalid ETag', () {
        expect(ETagUtils.extractValue('invalid'), isNull);
        expect(ETagUtils.extractValue('abc123'), isNull);
        expect(ETagUtils.extractValue(null), isNull);
      });
    });

    group('getIfNoneMatchHeader', () {
      test('accepts strong ETag for If-None-Match', () {
        expect(ETagUtils.getIfNoneMatchHeader('"abc123"'), equals('"abc123"'));
      });

      test('accepts weak ETag for If-None-Match', () {
        expect(
          ETagUtils.getIfNoneMatchHeader('W/"abc123"'),
          equals('W/"abc123"'),
        );
      });

      test('returns null for invalid ETag', () {
        expect(ETagUtils.getIfNoneMatchHeader('invalid'), isNull);
        expect(ETagUtils.getIfNoneMatchHeader(''), isNull);
        expect(ETagUtils.getIfNoneMatchHeader(null), isNull);
      });
    });

    group('getIfMatchHeader', () {
      test('accepts strong ETag for If-Match', () {
        expect(ETagUtils.getIfMatchHeader('"abc123"'), equals('"abc123"'));
      });

      test('rejects weak ETag for If-Match', () {
        expect(ETagUtils.getIfMatchHeader('W/"abc123"'), isNull);
        expect(ETagUtils.getIfMatchHeader('W/"any-value"'), isNull);
      });

      test('returns null for invalid ETag', () {
        expect(ETagUtils.getIfMatchHeader('invalid'), isNull);
        expect(ETagUtils.getIfMatchHeader(''), isNull);
        expect(ETagUtils.getIfMatchHeader(null), isNull);
      });
    });

    group('normalizeForStorage', () {
      test('accepts and returns strong ETag', () {
        expect(ETagUtils.normalizeForStorage('"abc123"'), equals('"abc123"'));
      });

      test('rejects weak ETag for storage', () {
        expect(ETagUtils.normalizeForStorage('W/"abc123"'), isNull);
      });

      test('rejects invalid ETag', () {
        expect(ETagUtils.normalizeForStorage('invalid'), isNull);
        expect(ETagUtils.normalizeForStorage(''), isNull);
        expect(ETagUtils.normalizeForStorage(null), isNull);
      });
    });

    group('getValidationErrorMessage', () {
      test('provides specific message for weak ETag', () {
        final message = ETagUtils.getValidationErrorMessage('W/"abc123"');
        expect(message, contains('Weak ETag'));
        expect(message, contains('cannot be used for modification'));
      });

      test('provides specific message for invalid format', () {
        final message = ETagUtils.getValidationErrorMessage('invalid');
        expect(message, contains('Invalid ETag format'));
      });

      test('provides message for null', () {
        final message = ETagUtils.getValidationErrorMessage(null);
        expect(message, contains('null'));
      });

      test('provides message for empty', () {
        final message = ETagUtils.getValidationErrorMessage('');
        expect(message, contains('empty'));
      });
    });
  });
}
