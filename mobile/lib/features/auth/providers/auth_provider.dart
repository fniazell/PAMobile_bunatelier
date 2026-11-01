import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/storage/secure_storage_service.dart';
import '../auth_service.dart';

// ─── AuthUser (UI-facing, no passwordHash) ────────────────────────────────────

class AuthUser {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String username;
  final DateTime? usernameChangedAt;
  final String phone;
  final String? avatarPath;

  const AuthUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.role = 'CUSTOMER',
    this.username = '',
    this.usernameChangedAt,
    this.phone = '',
    this.avatarPath,
  });

  bool get isAdmin => role.toLowerCase() == 'admin';

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'role': role,
    'username': username,
    'usernameChangedAt': usernameChangedAt?.toIso8601String(),
    'phone': phone,
    'avatarPath': avatarPath,
  };

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'] as String? ?? '',
    fullName: json['fullName'] as String? ?? '',
    email: json['email'] as String? ?? '',
    role: json['role'] as String? ?? 'CUSTOMER',
    username: json['username'] as String? ?? '',
    usernameChangedAt: json['usernameChangedAt'] != null
        ? DateTime.tryParse(json['usernameChangedAt'] as String)
        : null,
    phone: json['phone'] as String? ?? '',
    avatarPath: json['avatarPath'] as String?,
  );

  factory AuthUser.fromRecord(AccountRecord r) => AuthUser(
    id: r.id,
    fullName: r.fullName,
    email: r.email,
    role: r.role,
    username: r.username,
    usernameChangedAt: r.usernameChangedAt,
    phone: r.phone,
    avatarPath: r.avatarPath,
  );

  AuthUser copyWith({
    String? fullName,
    String? email,
    String? username,
    Object? usernameChangedAt = _sentinel,
    String? phone,
    Object? avatarPath = _sentinel,
  }) => AuthUser(
    id: id,
    fullName: fullName ?? this.fullName,
    email: email ?? this.email,
    role: role,
    username: username ?? this.username,
    usernameChangedAt: usernameChangedAt == _sentinel
        ? this.usernameChangedAt
        : usernameChangedAt as DateTime?,
    phone: phone ?? this.phone,
    avatarPath: avatarPath == _sentinel
        ? this.avatarPath
        : avatarPath as String?,
  );
}

const _sentinel = Object();

// ─── AuthState ────────────────────────────────────────────────────────────────

class AuthState {
  final bool isAuthenticated;
  final AuthUser? user;
  final bool isLoading;
  final String? errorMessage;
  final bool biometricAvailable;

  const AuthState({
    this.isAuthenticated = false,
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.biometricAvailable = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    AuthUser? user,
    bool? isLoading,
    String? errorMessage,
    bool? biometricAvailable,
  }) => AuthState(
    isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    user: user ?? this.user,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: errorMessage,
    biometricAvailable: biometricAvailable ?? this.biometricAvailable,
  );
}

// ─── AuthNotifier ─────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final SecureStorageService _storage = SecureStorageService();
  final LocalAuthentication _localAuth = LocalAuthentication();
  late final AuthService _authService = AuthService(_storage);
  AuthService get authService => _authService;

  AuthNotifier() : super(const AuthState()) {
    _checkSavedSession();
  }

  // ── Session restore ───────────────────────────────────────────────────────

  Future<void> _checkSavedSession() async {
    state = state.copyWith(isLoading: true);
    try {
      bool hasBio = false;
      if (!kIsWeb) {
        try {
          final supported = await _localAuth.isDeviceSupported();
          final available = await _localAuth.getAvailableBiometrics();
          hasBio = supported && available.isNotEmpty;
        } catch (_) {}
      }

      final token = await _storage.getAccessToken();
      final savedUser = await _storage.getUserData();

      if (token != null && savedUser != null) {
        state = state.copyWith(
          isAuthenticated: true,
          user: AuthUser.fromJson(savedUser),
          biometricAvailable: hasBio,
          isLoading: false,
        );
        return;
      }

      state = state.copyWith(
        isAuthenticated: false,
        biometricAvailable: hasBio,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, isAuthenticated: false);
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<LoginResult> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await Future.delayed(const Duration(milliseconds: 350));

    final (:result, :account) = await _authService.login(
      email: email,
      password: password,
    );

    switch (result) {
      case LoginResult.success:
        final user = AuthUser.fromRecord(account!);
        if (await _storage.isBiometricEnabled()) {
          await _storage.saveBiometricUserData(user.toJson());
        }
        state = state.copyWith(
          isAuthenticated: true,
          user: user,
          isLoading: false,
        );

      case LoginResult.emailNotFound:
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          errorMessage: 'Silakan mendaftar akun terlebih dahulu.',
        );

      case LoginResult.wrongPassword:
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          errorMessage: 'Email atau password salah.',
        );

      case LoginResult.validationError:
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          errorMessage: 'Masukkan email dan password terlebih dahulu.',
        );
    }

    return result;
  }

  // ── Register ──────────────────────────────────────────────────────────────

  Future<RegisterResult> register(
    String fullName,
    String email,
    String password,
  ) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await Future.delayed(const Duration(milliseconds: 350));

    final result = await _authService.register(
      fullName: fullName,
      email: email,
      password: password,
    );

    switch (result) {
      case RegisterResult.success:
        state = state.copyWith(isLoading: false, errorMessage: null);
      case RegisterResult.emailAlreadyExists:
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Email sudah terdaftar. Silakan masuk.',
        );
      case RegisterResult.validationError:
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Password minimal 6 karakter.',
        );
    }

    return result;
  }

  // ── Biometric ─────────────────────────────────────────────────────────────

  Future<bool> setBiometricLoginEnabled(bool enabled) async {
    if (!enabled) {
      await _storage.setBiometricEnabled(false);
      await _storage.clearBiometricUserData();
      state = state.copyWith(errorMessage: null);
      return true;
    }

    final user = state.user;
    if (user == null) {
      state = state.copyWith(
        errorMessage:
            'Silakan login terlebih dahulu untuk mengaktifkan biometrik.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      if (kIsWeb || !await _localAuth.isDeviceSupported()) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Perangkat ini tidak mendukung autentikasi biometrik.',
        );
        return false;
      }

      final available = await _localAuth.getAvailableBiometrics();
      if (available.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Daftarkan sidik jari atau Face Unlock di pengaturan perangkat terlebih dahulu.',
        );
        return false;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason:
            'Verifikasi biometrik untuk mengaktifkan login Bun Atelier',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (!authenticated) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Verifikasi biometrik dibatalkan atau gagal.',
        );
        return false;
      }

      await _storage.saveBiometricUserData(user.toJson());
      await _storage.setBiometricEnabled(true);
      state = state.copyWith(isLoading: false, biometricAvailable: true);
      return true;
    } on PlatformException {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Verifikasi biometrik gagal. Periksa pengaturan biometrik perangkat.',
      );
      return false;
    } on MissingPluginException {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Autentikasi biometrik tidak tersedia pada aplikasi ini.',
      );
      return false;
    }
  }

  Future<bool> loginWithBiometrics() async {
    if (!await _storage.isBiometricEnabled()) {
      state = state.copyWith(
        errorMessage: 'Aktifkan login biometrik dari Profil setelah login dengan password.',
      );
      return false;
    }

    final savedUser = await _storage.getBiometricUserData();
    if (savedUser == null) {
      state = state.copyWith(
        errorMessage: 'Tidak ada akun biometrik tersimpan. Login dengan password lalu aktifkan biometrik dari Profil.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      if (kIsWeb || !await _localAuth.isDeviceSupported()) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Perangkat ini tidak mendukung autentikasi biometrik.',
        );
        return false;
      }

      final available = await _localAuth.getAvailableBiometrics();
      if (available.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          errorMessage:
              'Sidik jari atau Face Unlock belum terdaftar di perangkat.',
        );
        return false;
      }

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Pindai sidik jari / wajah untuk membuka Bun Atelier',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (didAuthenticate) {
        final user = AuthUser.fromJson(savedUser);
        await _storage.saveAccessToken('bun_session_${user.id}');
        await _storage.saveUserData(user.toJson());
        state = state.copyWith(
          isAuthenticated: true,
          user: user,
          isLoading: false,
        );
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Verifikasi biometrik dibatalkan atau gagal.',
      );
      return false;
    } on PlatformException {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'Autentikasi biometrik gagal. Coba lagi atau gunakan password.',
      );
      return false;
    } on MissingPluginException {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Autentikasi biometrik tidak tersedia pada aplikasi ini.',
      );
      return false;
    }
  }

  // ── Update Profile ────────────────────────────────────────────────────────

  /// Returns (result, cooldownUntil).
  /// cooldownUntil is non-null only when result == usernameCooldown.
  Future<({UpdateProfileResult result, DateTime? cooldownUntil})>
  updateProfile({String? fullName, String? username, String? phone}) async {
    final userId = state.user?.id;
    if (userId == null) {
      return (result: UpdateProfileResult.notFound, cooldownUntil: null);
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _authService.updateProfile(
      userId: userId,
      fullName: fullName,
      username: username,
      phone: phone,
    );

    // Determine cooldown date for UI
    DateTime? cooldownUntil;
    if (result == UpdateProfileResult.usernameCooldown) {
      final changedAt = state.user?.usernameChangedAt;
      if (changedAt != null) {
        cooldownUntil = changedAt.add(const Duration(days: 30));
      }
    }

    if (result == UpdateProfileResult.success) {
      // Reload session from storage so UI reflects changes
      final saved = await _storage.getUserData();
      if (saved != null) {
        final user = AuthUser.fromJson(saved);
        await _syncBiometricUser(user);
        state = state.copyWith(
          isLoading: false,
          user: user,
          errorMessage: null,
        );
      } else {
        state = state.copyWith(isLoading: false, errorMessage: null);
      }
    } else {
      state = state.copyWith(isLoading: false);
    }

    return (result: result, cooldownUntil: cooldownUntil);
  }

  // ── Change Email ──────────────────────────────────────────────────────────

  Future<EmailChangeResult> changeEmail({
    required String newEmail,
    required String currentPassword,
  }) async {
    final userId = state.user?.id;
    if (userId == null) return EmailChangeResult.notFound;

    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _authService.changeEmail(
      userId: userId,
      newEmail: newEmail,
      currentPassword: currentPassword,
    );

    if (result == EmailChangeResult.success) {
      final saved = await _storage.getUserData();
      if (saved != null) {
        final user = AuthUser.fromJson(saved);
        await _syncBiometricUser(user);
        state = state.copyWith(
          isLoading: false,
          user: user,
          errorMessage: null,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } else {
      state = state.copyWith(isLoading: false);
    }

    return result;
  }

  // ── Update Avatar ─────────────────────────────────────────────────────────

  Future<bool> updateAvatar(String? newPath) async {
    final userId = state.user?.id;
    if (userId == null) return false;

    state = state.copyWith(isLoading: true);

    final ok = await _authService.updateAvatar(
      userId: userId,
      newPath: newPath,
    );

    if (ok) {
      final saved = await _storage.getUserData();
      if (saved != null) {
        final user = AuthUser.fromJson(saved);
        await _syncBiometricUser(user);
        state = state.copyWith(isLoading: false, user: user);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } else {
      state = state.copyWith(isLoading: false);
    }

    return ok;
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _storage.clearAuthSession();
    state = const AuthState();
  }

  Future<void> _syncBiometricUser(AuthUser user) async {
    if (await _storage.isBiometricEnabled()) {
      await _storage.saveBiometricUserData(user.toJson());
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
