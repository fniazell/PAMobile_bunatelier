import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/storage/secure_storage_service.dart';
import '../../data/remote/supabase_service.dart';

// ─── Normalization ────────────────────────────────────────────────────────────

String normalizeEmail(String email) => email.trim().toLowerCase();

String normalizeUsername(String u) => u.trim().toLowerCase();

// ─── Password hashing ─────────────────────────────────────────────────────────

String hashPassword(String password) {
  const salt = 'bun_atelier_2024_salt';
  final bytes = utf8.encode('$salt:${password.trim()}');
  return sha256.convert(bytes).toString();
}

bool verifyPassword(String plainPassword, String storedHash) =>
    hashPassword(plainPassword) == storedHash;

// ─── Result types ─────────────────────────────────────────────────────────────

enum RegisterResult {
  success,
  emailConfirmationRequired,
  emailAlreadyExists,
  validationError,
  serviceError,
}

enum LoginResult {
  success,
  invalidEmailFormat,
  emailNotFound,
  emailNotConfirmed,
  wrongPassword,
  validationError,
  serviceError,
}

enum UpdateProfileResult {
  success,
  usernameTaken,
  usernameCooldown,
  validationError,
  notFound,
}

enum EmailChangeResult {
  success,
  wrongPassword,
  emailTaken,
  validationError,
  notFound,
}

// ─── AccountRecord ────────────────────────────────────────────────────────────

class AccountRecord {
  final String id;
  final String fullName;
  final String email; // always normalised
  final String role;
  final String passwordHash;
  final String username; // always normalised (lowercase)
  final DateTime? usernameChangedAt; // null = never changed
  final String phone; // E.164-ish (+62…), may be empty
  final String? avatarPath; // local file path, null = no photo

  const AccountRecord({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.passwordHash,
    required this.username,
    this.usernameChangedAt,
    this.phone = '',
    this.avatarPath,
  });

  // ── Serialization ──────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'role': role,
    'passwordHash': passwordHash,
    'username': username,
    'usernameChangedAt': usernameChangedAt?.toIso8601String(),
    'phone': phone,
    'avatarPath': avatarPath,
  };

  factory AccountRecord.fromJson(Map<String, dynamic> json) => AccountRecord(
    id: json['id'] as String? ?? '',
    fullName: json['fullName'] as String? ?? '',
    email: json['email'] as String? ?? '',
    role: (json['role'] as String?) ?? 'CUSTOMER',
    passwordHash: json['passwordHash'] as String? ?? '',
    username: json['username'] as String? ?? '',
    usernameChangedAt: json['usernameChangedAt'] != null
        ? DateTime.tryParse(json['usernameChangedAt'] as String)
        : null,
    phone: json['phone'] as String? ?? '',
    avatarPath: json['avatarPath'] as String?,
  );

  AccountRecord copyWith({
    String? fullName,
    String? email,
    String? role,
    String? passwordHash,
    String? username,
    Object? usernameChangedAt = _sentinel,
    String? phone,
    Object? avatarPath = _sentinel,
  }) {
    return AccountRecord(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      passwordHash: passwordHash ?? this.passwordHash,
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
}

// sentinel to distinguish "not passed" from "explicitly null"
const _sentinel = Object();

class AdminAccountSeed {
  final String id;
  final String username;
  final String email;
  final String password;
  final String fullName;
  final String phone;

  const AdminAccountSeed({
    required this.id,
    required this.username,
    required this.email,
    required this.password,
    required this.fullName,
    this.phone = '+6281288882727',
  });
}

// ─── AuthService ──────────────────────────────────────────────────────────────

class AuthService {
  final SecureStorageService _storage;
  AuthService(this._storage);

  // Initial Administrator Account Specification
  static const String initialAdminUsername = 'bunatelier.admin';
  static const String initialAdminPassword = 'BunAtelier#Admin27';
  static const String initialAdminEmail = 'admin@bunatelier.com';
  static const String initialAdminRole = 'admin';

  // Configured Administrator Accounts
  static const List<AdminAccountSeed> configuredAdmins = [
    AdminAccountSeed(
      id: 'usr-admin-01',
      username: 'bunatelier.admin',
      email: 'admin@bunatelier.com',
      password: 'BunAtelier#Admin27',
      fullName: 'Bun Atelier Administrator',
      phone: '+6281288882727',
    ),
    AdminAccountSeed(
      id: 'usr-admin-02',
      username: 'fania.admin',
      email: 'fania.admin@bunatelier.com',
      password: '124240161',
      fullName: 'Fania (Administrator)',
      phone: '+6281288882728',
    ),
    AdminAccountSeed(
      id: 'usr-admin-03',
      username: 'azzahra.admin',
      email: 'azzahra.admin@bunatelier.com',
      password: '124240171',
      fullName: 'Azzahra (Administrator)',
      phone: '+6281288882729',
    ),
    AdminAccountSeed(
      id: 'usr-admin-04',
      username: 'devita.admin',
      email: 'devita.admin@bunatelier.com',
      password: '124240176',
      fullName: 'Devita (Administrator)',
      phone: '+6281288882730',
    ),
  ];

  // ── Account list helpers ──────────────────────────────────────────────────

  Future<List<AccountRecord>> _getAccounts() async {
    final raw = await _storage.getRegisteredAccounts();
    var records = raw.map(AccountRecord.fromJson).toList();
    records = _migrate(records);

    bool changed = false;
    for (final admin in configuredAdmins) {
      final adminNormUser = admin.username.toLowerCase();
      final adminNormEmail = admin.email.toLowerCase();

      final adminIndex = records.indexWhere(
        (a) =>
            a.username.toLowerCase() == adminNormUser ||
            a.email.toLowerCase() == adminNormEmail,
      );

      final desiredHash = hashPassword(admin.password);

      if (adminIndex < 0) {
        records.insert(
          0,
          AccountRecord(
            id: admin.id,
            fullName: admin.fullName,
            email: admin.email,
            role: 'admin',
            passwordHash: desiredHash,
            username: admin.username,
            phone: admin.phone,
          ),
        );
        changed = true;
      } else {
        final existing = records[adminIndex];
        if (existing.role != 'admin' || existing.passwordHash != desiredHash) {
          records[adminIndex] = existing.copyWith(
            role: 'admin',
            passwordHash: desiredHash,
            fullName: admin.fullName,
          );
          changed = true;
        }
      }
    }

    if (changed) {
      await _saveAccounts(records);
    }

    return records;
  }

  Future<void> _saveAccounts(List<AccountRecord> accounts) async {
    await _storage.saveRegisteredAccounts(
      accounts.map((a) => a.toJson()).toList(),
    );
  }

  /// Get list of registered customers for Admin Customers screen
  Future<List<AccountRecord>> getAllCustomers() async {
    final accounts = await _getAccounts();
    return accounts.where((a) => a.role.toLowerCase() != 'admin').toList();
  }

  /// Auto-generate unique username from email prefix
  String _generateUsername(String email, List<AccountRecord> existing) {
    final existingNames = existing.map((a) => a.username).toSet();
    final base = normalizeUsername(
      email.split('@').first.replaceAll(RegExp(r'[^a-z0-9._]'), '_'),
    );
    final candidate = base.isEmpty ? 'user' : base;
    if (!existingNames.contains(candidate)) return candidate;
    var i = 1;
    while (existingNames.contains('$candidate$i')) {
      i++;
    }
    return '$candidate$i';
  }

  /// Lazy migration: give auto-username to any account missing one
  List<AccountRecord> _migrate(List<AccountRecord> records) {
    bool changed = false;
    final result = <AccountRecord>[];
    for (final r in records) {
      if (r.username.isEmpty) {
        final gen = _generateUsername(r.email, result + records);
        result.add(r.copyWith(username: gen));
        changed = true;
      } else {
        result.add(r);
      }
    }
    // Persist if we changed anything (fire-and-forget)
    if (changed) _saveAccounts(result);
    return result;
  }

  Future<AccountRecord?> findById(String id) async {
    final accounts = await _getAccounts();
    try {
      return accounts.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<AccountRecord?> findByEmail(String email) async {
    final norm = normalizeEmail(email);
    final accounts = await _getAccounts();
    try {
      return accounts.firstWhere((a) => a.email == norm);
    } catch (_) {
      return null;
    }
  }

  Future<AccountRecord?> findByUsername(String username) async {
    final norm = normalizeUsername(username);
    final accounts = await _getAccounts();
    try {
      return accounts.firstWhere((a) => a.username == norm);
    } catch (_) {
      return null;
    }
  }

  // ── Register ──────────────────────────────────────────────────────────────

  Future<RegisterResult> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final trimmedName = fullName.trim();
    final normEmail = normalizeEmail(email);
    final trimmedPw = password.trim();

    if (trimmedName.isEmpty ||
        !isValidEmail(normEmail) ||
        trimmedPw.length < 6) {
      return RegisterResult.validationError;
    }

    // Cegah registrasi menggunakan kredensial admin
    for (final admin in configuredAdmins) {
      if (normEmail == admin.email ||
          normEmail.contains(admin.username) ||
          normEmail.contains('admin')) {
        return RegisterResult.emailAlreadyExists;
      }
    }

    if (await findByEmail(normEmail) != null) {
      return RegisterResult.emailAlreadyExists;
    }

    try {
      final accounts = await _getAccounts();
      final username = _generateUsername(normEmail, accounts);
      final response = await SupabaseService.instance.client.auth.signUp(
        email: normEmail,
        password: trimmedPw,
        data: {
          'full_name': trimmedName,
          'username': username,
          'role': 'CUSTOMER',
        },
      );
      final user = response.user;
      if (user == null) return RegisterResult.serviceError;

      final account = AccountRecord(
        id: user.id,
        fullName: trimmedName,
        email: normEmail,
        role: 'CUSTOMER',
        passwordHash: '',
        username: username,
      );
      await _saveAccount(account);

      final accessToken = response.session?.accessToken;
      if (accessToken != null) {
        await _syncAccount(account, accessToken);
        return RegisterResult.success;
      }

      return RegisterResult.emailConfirmationRequired;
    } on AuthException catch (e) {
      final message = e.message.toLowerCase();
      if (message.contains('already') || message.contains('registered')) {
        return RegisterResult.emailAlreadyExists;
      }
      if (message.contains('password') || message.contains('email')) {
        return RegisterResult.validationError;
      }
      return RegisterResult.serviceError;
    } catch (e) {
      debugPrint('Supabase registration failed: $e');
      return RegisterResult.serviceError;
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<({LoginResult result, AccountRecord? account})> login({
    required String email,
    required String password,
  }) async {
    final normInput = email.trim().toLowerCase();
    final trimmedPw = password.trim();

    if (normInput.isEmpty || trimmedPw.isEmpty) {
      return (result: LoginResult.validationError, account: null);
    }

    if (!isValidEmail(normInput) && !isValidUsername(normInput)) {
      return (result: LoginResult.invalidEmailFormat, account: null);
    }

    final localAccount =
        await findByEmail(normInput) ?? await findByUsername(normInput);

    if (localAccount == null && !isValidEmail(normInput)) {
      return (result: LoginResult.emailNotFound, account: null);
    }

    if (localAccount?.role.toLowerCase() == 'admin') {
      if (!verifyPassword(trimmedPw, localAccount!.passwordHash)) {
        return (result: LoginResult.wrongPassword, account: null);
      }
      await _writeSession(localAccount);
      return (result: LoginResult.success, account: localAccount);
    }

    final authEmail = localAccount?.email ?? normInput;
    if (!isValidEmail(authEmail)) {
      return (result: LoginResult.invalidEmailFormat, account: null);
    }

    try {
      final response = await SupabaseService.instance.client.auth
          .signInWithPassword(email: authEmail, password: trimmedPw);
      final user = response.user;
      final accessToken = response.session?.accessToken;
      if (user == null || accessToken == null) {
        return (result: LoginResult.emailNotConfirmed, account: null);
      }
      final account = await _saveAuthenticatedAccount(
        user,
        fallback: localAccount,
      );
      await _syncAccount(account, accessToken);
      await _writeSession(
        account,
        accessToken: accessToken,
        refreshToken: response.session?.refreshToken,
      );
      return (result: LoginResult.success, account: account);
    } on AuthException catch (e) {
      final message = e.message.toLowerCase();
      if (message.contains('not confirmed') ||
          message.contains('confirm your email')) {
        return (result: LoginResult.emailNotConfirmed, account: null);
      }
      if (message.contains('invalid login credentials') &&
          localAccount != null &&
          localAccount.passwordHash.isNotEmpty &&
          verifyPassword(trimmedPw, localAccount.passwordHash)) {
        return _migrateLegacyAccount(localAccount, trimmedPw);
      }
      if (message.contains('invalid login credentials')) {
        return (result: LoginResult.wrongPassword, account: null);
      }
      return (result: LoginResult.serviceError, account: null);
    } catch (e) {
      debugPrint('Supabase login failed: $e');
      return (result: LoginResult.serviceError, account: null);
    }
  }

  Future<({LoginResult result, AccountRecord? account})> _migrateLegacyAccount(
    AccountRecord legacy,
    String password,
  ) async {
    try {
      final response = await SupabaseService.instance.client.auth.signUp(
        email: legacy.email,
        password: password,
        data: {
          'full_name': legacy.fullName,
          'username': legacy.username,
          'role': 'CUSTOMER',
        },
      );
      final user = response.user;
      final accessToken = response.session?.accessToken;
      if (user == null) {
        return (result: LoginResult.serviceError, account: null);
      }
      final account = await _saveAuthenticatedAccount(user, fallback: legacy);
      if (accessToken == null) {
        return (result: LoginResult.emailNotConfirmed, account: null);
      }
      await _syncAccount(account, accessToken);
      await _writeSession(
        account,
        accessToken: accessToken,
        refreshToken: response.session?.refreshToken,
      );
      return (result: LoginResult.success, account: account);
    } on AuthException catch (e) {
      final message = e.message.toLowerCase();
      if (message.contains('not confirmed') ||
          message.contains('confirm your email')) {
        return (result: LoginResult.emailNotConfirmed, account: null);
      }
      if (message.contains('already') || message.contains('registered')) {
        return (result: LoginResult.wrongPassword, account: null);
      }
      return (result: LoginResult.serviceError, account: null);
    } catch (e) {
      debugPrint('Legacy account migration failed: $e');
      return (result: LoginResult.serviceError, account: null);
    }
  }

  Future<AccountRecord> _saveAuthenticatedAccount(
    User user, {
    AccountRecord? fallback,
  }) async {
    final email = user.email;
    if (email == null || email.isEmpty) {
      throw StateError('Authenticated account has no email.');
    }
    final existing = fallback ?? await findByEmail(email);
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final accounts = await _getAccounts();
    final account = AccountRecord(
      id: user.id,
      fullName:
          existing?.fullName ??
          (metadata['full_name'] as String?) ??
          email.split('@').first,
      email: normalizeEmail(email),
      role: 'CUSTOMER',
      passwordHash: '',
      username:
          existing?.username ??
          (metadata['username'] as String?) ??
          _generateUsername(email, accounts),
      usernameChangedAt: existing?.usernameChangedAt,
      phone: existing?.phone ?? '',
      avatarPath: existing?.avatarPath,
    );
    await _saveAccount(account);
    return account;
  }

  Future<void> _saveAccount(AccountRecord account) async {
    final accounts = await _getAccounts();
    final index = accounts.indexWhere(
      (item) => item.email == account.email || item.id == account.id,
    );
    if (index >= 0) {
      accounts[index] = account;
    } else {
      accounts.add(account);
    }
    await _saveAccounts(accounts);
  }

  Future<void> _syncAccount(AccountRecord account, String accessToken) async {
    await SupabaseService.instance.syncUserToCloud(
      id: account.id,
      fullName: account.fullName,
      email: account.email,
      role: account.role,
      username: account.username,
      phone: account.phone,
      accessToken: accessToken,
    );
  }

  Future<void> _syncAccountWithCurrentSession(AccountRecord account) async {
    final service = SupabaseService.instance;
    if (account.role.toLowerCase() == 'admin' || !service.isInitialized) {
      return;
    }
    final accessToken = service.client.auth.currentSession?.accessToken;
    if (accessToken != null) {
      await _syncAccount(account, accessToken);
    }
  }

  // ── Update Profile (name, username, phone) ────────────────────────────────

  /// Updates name, username, and/or phone for the given user.
  /// Username may be null to leave unchanged.
  Future<UpdateProfileResult> updateProfile({
    required String userId,
    String? fullName,
    String? username,
    String? phone,
  }) async {
    final accounts = await _getAccounts();
    final idx = accounts.indexWhere((a) => a.id == userId);
    if (idx < 0) return UpdateProfileResult.notFound;

    final current = accounts[idx];
    AccountRecord updated = current;

    // ── Name ────────────────────────────────────────────────────────────────
    if (fullName != null) {
      final trimmed = fullName.trim();
      if (trimmed.isEmpty || trimmed.length > 50) {
        return UpdateProfileResult.validationError;
      }
      updated = updated.copyWith(fullName: trimmed);
    }

    // ── Username ─────────────────────────────────────────────────────────────
    if (username != null) {
      final norm = normalizeUsername(username);
      // Validate format: 3–20 chars, only letters/digits/dot/underscore
      if (!RegExp(r'^[a-z0-9._]{3,20}$').hasMatch(norm)) {
        return UpdateProfileResult.validationError;
      }
      // Unique check (excluding self)
      final clash = accounts.firstWhere(
        (a) => a.username == norm && a.id != userId,
        orElse: () => accounts[idx], // dummy
      );
      if (clash.id != userId && clash.username == norm) {
        return UpdateProfileResult.usernameTaken;
      }
      // 30-day cooldown (only after first change; null = never changed → allowed)
      final changedAt = current.usernameChangedAt;
      if (changedAt != null) {
        final daysSince = DateTime.now().difference(changedAt).inDays;
        if (daysSince < 30) {
          return UpdateProfileResult.usernameCooldown;
        }
      }
      final now = (norm == current.username)
          ? current.usernameChangedAt
          : DateTime.now();
      updated = updated.copyWith(username: norm, usernameChangedAt: now);
    }

    // ── Phone ─────────────────────────────────────────────────────────────────
    if (phone != null) {
      final normalized = normalizePhone(phone);
      if (normalized == null && phone.trim().isNotEmpty) {
        return UpdateProfileResult.validationError;
      }
      updated = updated.copyWith(phone: normalized ?? '');
    }

    accounts[idx] = updated;
    await _saveAccounts(accounts);
    await _syncAccountWithCurrentSession(updated);
    await _refreshSession(updated);
    return UpdateProfileResult.success;
  }

  // ── Change Email ──────────────────────────────────────────────────────────

  Future<EmailChangeResult> changeEmail({
    required String userId,
    required String newEmail,
    required String currentPassword,
  }) async {
    final normNew = normalizeEmail(newEmail);
    if (!normNew.contains('@') || normNew.isEmpty) {
      return EmailChangeResult.validationError;
    }

    final accounts = await _getAccounts();
    final idx = accounts.indexWhere((a) => a.id == userId);
    if (idx < 0) return EmailChangeResult.notFound;

    final current = accounts[idx];

    // Uniqueness check (excluding self)
    final clash = accounts.firstWhere(
      (a) => a.email == normNew && a.id != userId,
      orElse: () => accounts[idx],
    );
    if (clash.id != userId && clash.email == normNew) {
      return EmailChangeResult.emailTaken;
    }

    var emailToSave = normNew;
    if (current.role.toLowerCase() == 'admin') {
      if (!verifyPassword(currentPassword, current.passwordHash)) {
        return EmailChangeResult.wrongPassword;
      }
    } else {
      try {
        final auth = SupabaseService.instance.client.auth;
        final authResponse = await auth.signInWithPassword(
          email: current.email,
          password: currentPassword,
        );
        final session = authResponse.session;
        if (session != null) {
          await _storage.saveAccessToken(session.accessToken);
          final refreshToken = session.refreshToken;
          if (refreshToken != null) {
            await _storage.saveRefreshToken(refreshToken);
          }
        }
        final response = await auth.updateUser(UserAttributes(email: normNew));
        if (response.user == null) return EmailChangeResult.validationError;
        if (response.user!.email != normNew) {
          emailToSave = current.email;
        }
      } on AuthException catch (e) {
        final message = e.message.toLowerCase();
        if (message.contains('invalid login credentials')) {
          return EmailChangeResult.wrongPassword;
        }
        if (message.contains('already') || message.contains('registered')) {
          return EmailChangeResult.emailTaken;
        }
        return EmailChangeResult.validationError;
      } catch (e) {
        debugPrint('Supabase email update failed: $e');
        return EmailChangeResult.validationError;
      }
    }

    final updated = current.copyWith(email: emailToSave);
    accounts[idx] = updated;
    await _saveAccounts(accounts);
    await _syncAccountWithCurrentSession(updated);
    await _refreshSession(updated);
    return EmailChangeResult.success;
  }

  // ── Update Avatar ─────────────────────────────────────────────────────────

  /// Set a new avatar path (or null to remove). Caller must delete old file.
  Future<bool> updateAvatar({
    required String userId,
    required String? newPath,
  }) async {
    final accounts = await _getAccounts();
    final idx = accounts.indexWhere((a) => a.id == userId);
    if (idx < 0) return false;

    final updated = accounts[idx].copyWith(avatarPath: newPath);
    accounts[idx] = updated;
    await _saveAccounts(accounts);
    await _syncAccountWithCurrentSession(updated);
    await _refreshSession(updated);
    return true;
  }

  // ── Session helpers ───────────────────────────────────────────────────────

  Future<void> _writeSession(
    AccountRecord a, {
    String? accessToken,
    String? refreshToken,
  }) async {
    await _storage.saveAccessToken(accessToken ?? 'bun_session_${a.id}');
    if (refreshToken != null) {
      await _storage.saveRefreshToken(refreshToken);
    }
    await _storage.saveUserData(_toSessionMap(a));
  }

  Future<void> signOut() async {
    if (SupabaseService.instance.isInitialized) {
      await SupabaseService.instance.client.auth.signOut();
    }
  }

  /// Update the session userData without touching the token.
  Future<void> _refreshSession(AccountRecord a) async {
    await _storage.saveUserData(_toSessionMap(a));
  }

  Map<String, dynamic> _toSessionMap(AccountRecord a) => {
    'id': a.id,
    'fullName': a.fullName,
    'email': a.email,
    'role': a.role,
    'username': a.username,
    'usernameChangedAt': a.usernameChangedAt?.toIso8601String(),
    'phone': a.phone,
    'avatarPath': a.avatarPath,
  };

  // ── Validation & normalization helpers ────────────────────────────────────

  static bool isValidUsername(String u) {
    final trimmed = u.trim();
    return RegExp(r'^[a-zA-Z0-9._]{3,20}$').hasMatch(trimmed);
  }

  static String normalizeUsername(String u) => u.trim().toLowerCase();

  static bool isValidEmail(String email) {
    final trimmed = email.trim();
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(trimmed);
  }

  /// Returns E.164 (+62…) or null if invalid.
  static String? normalizePhone(String raw) {
    final digits = raw.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    if (digits.isEmpty) return ''; // allow empty
    if (RegExp(r'^\+62\d{7,12}$').hasMatch(digits)) return digits;
    if (RegExp(r'^08\d{7,12}$').hasMatch(digits)) {
      return '+62${digits.substring(1)}';
    }
    if (RegExp(r'^62\d{7,12}$').hasMatch(digits)) return '+$digits';
    return null; // invalid
  }

  static bool isValidPhone(String raw) {
    final norm = normalizePhone(raw);
    return norm != null && norm.isNotEmpty;
  }

  /// Format +62… to a human-readable "08xx-xxxx-xxxx"
  static String formatPhone(String e164) {
    if (e164.isEmpty) return '';
    if (e164.startsWith('+62')) {
      final local = '0${e164.substring(3)}';
      if (local.length >= 10) {
        return '${local.substring(0, 4)}-${local.substring(4, 8)}-${local.substring(8)}';
      }
      return local;
    }
    if (e164.startsWith('08') && e164.length >= 10) {
      return '${e164.substring(0, 4)}-${e164.substring(4, 8)}-${e164.substring(8)}';
    }
    return e164;
  }
}
