import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/storage/secure_storage_service.dart';
import 'package:mobile/features/auth/auth_service.dart';

void main() {
  group('AuthService Profile Edit Unit Tests', () {
    test('isValidUsername enforces rules: 3-20 chars, letters, digits, dot, underscore', () {
      expect(AuthService.isValidUsername('john_doe'), isTrue);
      expect(AuthService.isValidUsername('user.123'), isTrue);
      expect(AuthService.isValidUsername('abc'), isTrue); // min 3
      expect(AuthService.isValidUsername('a' * 20), isTrue); // max 20

      // Invalid
      expect(AuthService.isValidUsername('ab'), isFalse); // < 3
      expect(AuthService.isValidUsername('a' * 21), isFalse); // > 20
      expect(AuthService.isValidUsername('john doe'), isFalse); // space
      expect(AuthService.isValidUsername('john@doe'), isFalse); // @
      expect(AuthService.isValidUsername('john!'), isFalse); // !
      expect(AuthService.isValidUsername(''), isFalse);
    });

    test('normalizeUsername trims and lowercases', () {
      expect(AuthService.normalizeUsername('  John_Doe  '), 'john_doe');
      expect(AuthService.normalizeUsername('ALICE.99'), 'alice.99');
    });

    test('isValidPhone accepts Indonesian formats (08..., 62..., +62...)', () {
      expect(AuthService.isValidPhone('08123456789'), isTrue);
      expect(AuthService.isValidPhone('628123456789'), isTrue);
      expect(AuthService.isValidPhone('+628123456789'), isTrue);
      expect(AuthService.isValidPhone('0812-3456-789'), isTrue);
      expect(AuthService.isValidPhone('+62 812 3456 789'), isTrue);

      // Invalid
      expect(AuthService.isValidPhone('1234567'), isFalse); // not 08 or 62
      expect(AuthService.isValidPhone('0812'), isFalse); // too short
      expect(
        AuthService.isValidPhone('081234567890123456'),
        isFalse,
      ); // too long (>15 digits)
      expect(AuthService.isValidPhone('abcdefghijk'), isFalse);
    });

    test('normalizePhone converts to E.164 (+62...) and formatPhone formats for display', () {
      expect(AuthService.normalizePhone('0812-3456-789'), '+628123456789');
      expect(AuthService.normalizePhone('+62 812 3456 789'), '+628123456789');
      expect(AuthService.formatPhone('+628123456789'), '0812-3456-789');
    });

    test('isValidEmail validates standard email addresses', () {
      expect(AuthService.isValidEmail('user@bunatelier.com'), isTrue);
      expect(AuthService.isValidEmail('test.name+tag@domain.co.id'), isTrue);

      expect(AuthService.isValidEmail('invalid-email'), isFalse);
      expect(AuthService.isValidEmail('@domain.com'), isFalse);
      expect(AuthService.isValidEmail('user@'), isFalse);
    });
  });

  group('AuthService login tests', () {
    test('malformed email is rejected before looking up an account', () async {
      final authService = AuthService(SecureStorageService());

      final (:result, :account) = await authService.login(
        email: 'radit*gmail.com',
        password: '123456',
      );

      expect(result, LoginResult.invalidEmailFormat);
      expect(account, isNull);
    });

    test('valid username is not rejected as a malformed email', () async {
      final authService = AuthService(SecureStorageService());

      final (:result, :account) = await authService.login(
        email: 'radit',
        password: '123456',
      );

      expect(result, LoginResult.emailNotFound);
      expect(account, isNull);
    });

    test('admin login continues to use the local account', () async {
      final authService = AuthService(SecureStorageService());

      final (:result, :account) = await authService.login(
        email: AuthService.initialAdminEmail,
        password: AuthService.initialAdminPassword,
      );

      expect(result, LoginResult.success);
      expect(account?.role, 'admin');
    });

    test(
      'customer registration fails explicitly when Supabase is unavailable',
      () async {
        final authService = AuthService(SecureStorageService());

        final result = await authService.register(
          fullName: 'Test Customer',
          email: 'auth-unavailable@example.com',
          password: 'secure-password',
        );

        expect(result, RegisterResult.serviceError);
      },
    );
  });
}
