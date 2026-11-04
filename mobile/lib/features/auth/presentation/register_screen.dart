import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../auth_service.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  String? _localError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    setState(() => _localError = null);

    // ── Local validation ──────────────────────────────────────────────────
    if (_nameController.text.trim().isEmpty) {
      setState(() => _localError = 'Masukkan nama lengkap kamu.');
      return;
    }
    final emailRaw = _emailController.text.trim();
    if (emailRaw.isEmpty || !emailRaw.contains('@')) {
      setState(() => _localError = 'Masukkan alamat email yang valid.');
      return;
    }
    if (_passwordController.text.trim().length < 6) {
      setState(() => _localError = 'Password minimal 6 karakter.');
      return;
    }
    if (_passwordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      setState(() => _localError = 'Password tidak cocok.');
      return;
    }

    // ── Call register (no session created inside) ─────────────────────────
    final result = await ref
        .read(authProvider.notifier)
        .register(
          _nameController.text.trim(),
          emailRaw,
          _passwordController.text.trim(),
        );

    if (!mounted) return;

    switch (result) {
      case RegisterResult.success:
        // ✅ Show success notification
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: AppColors.forestGreen,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: const Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.butterYellow,
                  size: 22,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Registrasi berhasil! Silakan masuk.',
                    style: TextStyle(
                      color: AppColors.cream,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted) {
            messenger.hideCurrentSnackBar();
          }
        });

        // ✅ Navigate to Login (NOT /main). Pass the email so the user
        //    only needs to type their password.
        //    Use go() to replace the register page so Back doesn't return here.
        context.go('/login', extra: emailRaw);

      case RegisterResult.emailConfirmationRequired:
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: AppColors.forestGreen,
            behavior: SnackBarBehavior.floating,
            content: const Text(
              'Registrasi berhasil. Periksa email untuk verifikasi sebelum masuk.',
              style: TextStyle(color: AppColors.cream, fontSize: 13),
            ),
          ),
        );
        context.go('/login', extra: emailRaw);

      case RegisterResult.emailAlreadyExists:
        // Provider already set errorMessage; nothing extra to do here.
        break;

      case RegisterResult.validationError:
        setState(
          () => _localError = 'Periksa kembali format email dan password kamu.',
        );
      case RegisterResult.serviceError:
        // Provider already set errorMessage.
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final authState = ref.watch(authProvider);

    // Combine local and provider errors
    final displayError = _localError ?? authState.errorMessage;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create\nAccount.',
                style: textTheme.displayLarge?.copyWith(
                  height: 1.1,
                  fontSize: 38,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bergabunglah dengan Bun Atelier culinary club.',
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(height: 28),

              // Error Banner
              if (displayError != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          displayError,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Full Name
              Text(
                'NAMA LENGKAP',
                style: textTheme.labelLarge?.copyWith(
                  letterSpacing: 1.0,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'e.g. Raditya Dika',
                  prefixIcon: Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.mutedText,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Email
              Text(
                'EMAIL ADDRESS',
                style: textTheme.labelLarge?.copyWith(
                  letterSpacing: 1.0,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'raditya@example.com',
                  prefixIcon: Icon(
                    Icons.mail_outline_rounded,
                    color: AppColors.mutedText,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Password
              Text(
                'PASSWORD',
                style: textTheme.labelLarge?.copyWith(
                  letterSpacing: 1.0,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Min. 6 karakter',
                  prefixIcon: const Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.mutedText,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.mutedText,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Confirm Password
              Text(
                'KONFIRMASI PASSWORD',
                style: textTheme.labelLarge?.copyWith(
                  letterSpacing: 1.0,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscurePassword,
                decoration: const InputDecoration(
                  hintText: 'Ulangi password',
                  prefixIcon: Icon(
                    Icons.lock_reset_rounded,
                    color: AppColors.mutedText,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Sign Up Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: authState.isLoading ? null : _handleRegister,
                  child: authState.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text('BUAT AKUN'),
                ),
              ),
              const SizedBox(height: 24),

              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Sudah punya akun? ',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Text(
                        'Masuk',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.coral,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
