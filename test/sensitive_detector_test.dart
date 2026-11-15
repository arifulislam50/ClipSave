import 'package:clipsave/core/utils/sensitive_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SensitiveDetector flags', () {
    final cases = <String, SensitiveReason>{
      '482913': SensitiveReason.otp,
      '1234': SensitiveReason.otp,
      'Your verification code is 739201': SensitiveReason.otp,
      'G-482913 is your Google verification code': SensitiveReason.otp,
      '4111 1111 1111 1111': SensitiveReason.card,
      '4111-1111-1111-1111': SensitiveReason.card,
      'Tr0ub4dor&3': SensitiveReason.password,
      'P@ssw0rd!': SensitiveReason.password,
      'ghp_abcdefghijklmnopqrstuvwxyz0123456789': SensitiveReason.secretKey,
      'AKIAIOSFODNN7EXAMPLE': SensitiveReason.secretKey,
      '-----BEGIN RSA PRIVATE KEY-----\nMIIE...': SensitiveReason.secretKey,
      'a8f5f167f44f4964e6c998dee827110c4b3e7c1d2e9f': SensitiveReason.secretKey,
    };
    cases.forEach((input, reason) {
      test(input.split('\n').first, () {
        expect(SensitiveDetector.detect(input), reason);
      });
    });
  });

  group('SensitiveDetector ignores', () {
    const safe = [
      '',
      'Hello world',
      'Meet at 5pm near the station',
      'https://example.com/Path?Query=1&x=2',
      'someone@example.com',
      'grocery list: milk, eggs',
      'hello',
      '123', // too short for an OTP
      '4111 1111 1111 1112', // fails Luhn
      'Order shipped. Tracking number 1Z999AA10123456784 arrives Monday',
      'file_name.txt',
    ];
    for (final input in safe) {
      test('"$input"', () => expect(SensitiveDetector.detect(input), isNull));
    }
  });

  test('luhnValid', () {
    expect(SensitiveDetector.luhnValid('4111111111111111'), isTrue);
    expect(SensitiveDetector.luhnValid('4111111111111112'), isFalse);
    expect(SensitiveDetector.luhnValid('12345'), isFalse);
  });
}
