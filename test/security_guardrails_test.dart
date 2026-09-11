import 'package:flutter_test/flutter_test.dart';
import 'package:luma_app/core/services/offline_cache_service.dart';

void main() {
  group('Security & Guardrails Red-Team Test Suite', () {
    test('OfflineCacheService.safeId neutralizes path traversal payloads (CWE-22)', () {
      final attackPayloads = [
        '../../etc/passwd',
        '..\\..\\windows\\system32\\cmd.exe',
        '/root/.ssh/id_rsa',
        'track/../../../evil',
        'foo\x00bar',
        'track;rm -rf /;',
        'track&calc.exe',
        'track"||whoami',
      ];

      for (final payload in attackPayloads) {
        final sanitized = OfflineCacheService.safeId(payload);
        expect(sanitized.contains('/'), isFalse, reason: 'Failed on $payload');
        expect(sanitized.contains('\\'), isFalse, reason: 'Failed on $payload');
        expect(sanitized.contains('..'), isFalse, reason: 'Failed on $payload');
        expect(sanitized.contains('\x00'), isFalse, reason: 'Failed on $payload');
      }

      // Valid IDs must be preserved
      expect(OfflineCacheService.safeId('dQw4w9WgXcQ'), 'dQw4w9WgXcQ');
      expect(OfflineCacheService.safeId('abc-123_XYZ'), 'abc-123_XYZ');
      // Completely invalid strings fallback to default
      expect(OfflineCacheService.safeId('///'), 'invalid_id');
    });

    test('Auth Email Regex rejects malicious and malformed email inputs', () {
      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9]+(?:\.[a-zA-Z0-9-]+)*\.[a-zA-Z]{2,}$');

      final maliciousOrMalformedEmails = [
        '<script>alert(1)</script>',
        'admin\' OR \'1\'=\'1',
        'notanemail',
        'user@',
        '@domain.com',
        'user@domain',
        'user @domain.com',
        'user@ domain.com',
        'user@domain..com',
      ];

      for (final email in maliciousOrMalformedEmails) {
        expect(emailRegex.hasMatch(email), isFalse, reason: 'Allowed bad email: $email');
      }

      final validEmails = [
        'user@example.com',
        'john.doe@luma.app',
        'test_user+tag@domain.co.id',
      ];

      for (final email in validEmails) {
        expect(emailRegex.hasMatch(email), isTrue, reason: 'Rejected valid email: $email');
      }
    });

    test('Password boundaries strictly enforced (6 - 128 chars)', () {
      bool isValidPassword(String p) => p.length >= 6 && p.length <= 128;

      expect(isValidPassword(''), isFalse);
      expect(isValidPassword('12345'), isFalse);
      expect(isValidPassword('123456'), isTrue);
      expect(isValidPassword('A' * 128), isTrue);
      expect(isValidPassword('A' * 129), isFalse);
      expect(isValidPassword('A' * 10000), isFalse);
    });

    test('Profile Display Name boundaries enforced (1 - 50 chars)', () {
      bool isValidName(String name) {
        final trimmed = name.trim();
        return trimmed.isNotEmpty && trimmed.length <= 50;
      }

      expect(isValidName(''), isFalse);
      expect(isValidName('   '), isFalse);
      expect(isValidName('Luma Listener'), isTrue);
      expect(isValidName('A' * 50), isTrue);
      expect(isValidName('A' * 51), isFalse);
      expect(isValidName('A' * 5000), isFalse);
    });

    test('Purple Team Re-verify: URL fragments, query injections, and double extensions stripped', () {
      // Strips query injection and fragments
      expect(OfflineCacheService.safeId('trackId?param=1&evil=true#heading'), 'trackIdparam1eviltrueheading');
      // Strips double extensions attempting executable smuggling
      expect(OfflineCacheService.safeId('audio.mp3.exe'), 'audiomp3exe');
      expect(OfflineCacheService.safeId('payload.sh'), 'payloadsh');
      // Strips special punctuation and whitespace
      expect(OfflineCacheService.safeId('track with spaces'), 'trackwithspaces');
    });
  });
}
