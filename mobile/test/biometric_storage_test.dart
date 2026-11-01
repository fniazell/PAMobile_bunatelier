import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/storage/secure_storage_service.dart';

void main() {
  final storage = SecureStorageService();

  setUp(() async {
    await storage.clearAll();
  });

  test(
    'biometric account remains available after logout clears the session',
    () async {
      final user = {
        'id': 'user-1',
        'fullName': 'Naya',
        'email': 'naya@mail.com',
      };
      await storage.setBiometricEnabled(true);
      await storage.saveBiometricUserData(user);
      await storage.saveAccessToken('session-user-1');
      await storage.saveUserData(user);

      await storage.clearAuthSession();

      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getUserData(), isNull);
      expect(await storage.isBiometricEnabled(), isTrue);
      expect(await storage.getBiometricUserData(), user);
    },
  );

  test('disabling biometric login removes the remembered account', () async {
    await storage.setBiometricEnabled(true);
    await storage.saveBiometricUserData({'id': 'user-1'});

    await storage.setBiometricEnabled(false);
    await storage.clearBiometricUserData();

    expect(await storage.isBiometricEnabled(), isFalse);
    expect(await storage.getBiometricUserData(), isNull);
  });
}
