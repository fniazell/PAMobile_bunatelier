import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../auth_service.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  /// Optional: pre-fill the email field (e.g. after registration).
  final String? initialEmail;
  const LoginScreen({super.key, this.initialEmail});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Clear any previous error before calling login
    final result = await ref.read(authProvider.notifier).login(
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    if (result == LoginResult.success) {
      final user = ref.read(authProvider).user;
      if (user?.isAdmin == true) {
        context.go('/admin');
      } else {
        context.go('/main');
      }
      return;
    }

    // "Email not found" → show SnackBar with "Daftar" action
    if (result == LoginResult.emailNotFound) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.espresso,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Text(
            'Silakan mendaftar akun terlebih dahulu.',
            style: TextStyle(color: AppColors.cream, fontSize: 13),
          ),
          action: SnackBarAction(
            label: 'DAFTAR',
            textColor: AppColors.butterYellow,
            onPressed: () {
              messenger.clearSnackBars();
              if (mounted) context.push('/register');
            },
          ),
        ),
      );
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          messenger.hideCurrentSnackBar();
        }
      });
    }
    // Other errors (wrong password, validation) are shown inline via authState.errorMessage
  }

  Future<void> _handleBiometricLogin() async {
    final success = await ref.read(authProvider.notifier).loginWithBiometrics();
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.forestGreen,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Row(
            children: [
              Icon(Icons.fingerprint_rounded, color: AppColors.butterYellow),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Autentikasi Biometrik Berhasil!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.cream,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      final user = ref.read(authProvider).user;
      if (user?.isAdmin == true) {
        context.go('/admin');
      } else {
        context.go('/main');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.coral,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.lunch_dining_rounded,
                        color: AppColors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'BUN ATELIER',
                      style: textTheme.titleMedium?.copyWith(
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.espresso,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                Text(
                  'Welcome\nBack.',
                  style: textTheme.displayLarge?.copyWith(
                    height: 1.1,
                    fontSize: 38,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Sign in to order your messy, glorious artisan burger.',
                  style: textTheme.bodyLarge?.copyWith(color: AppColors.mutedText),
                ),
                const SizedBox(height: 36),

                // Inline error banner (wrong password / validation)
                if (authState.errorMessage != null &&
                    authState.errorMessage != 'Silakan mendaftar akun terlebih dahulu.') ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            authState.errorMessage!,
                            style: const TextStyle(color: AppColors.error, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Email / Username Field
                Text(
                  'EMAIL ATAU USERNAME',
                  style: textTheme.labelLarge?.copyWith(
                    letterSpacing: 1.0,
                    fontSize: 12,
                    color: AppColors.espresso,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'e.g. foodlover@bunatelier.com atau bunatelier.admin',
                    prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.mutedText),
                  ),
                ),
                const SizedBox(height: 20),

                // Password Field
                Text(
                  'PASSWORD',
                  style: textTheme.labelLarge?.copyWith(
                    letterSpacing: 1.0,
                    fontSize: 12,
                    color: AppColors.espresso,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.mutedText),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.mutedText,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Sign In Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _handleLogin,
                    child: authState.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: AppColors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text('SIGN IN'),
                  ),
                ),
                const SizedBox(height: 16),

                // Biometrics Unlock Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: authState.isLoading ? null : _handleBiometricLogin,
                    icon: const Icon(Icons.fingerprint_rounded, size: 24),
                    label: const Text('BIOMETRIC UNLOCK'),
                  ),
                ),
                const SizedBox(height: 28),

                // Register Link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: textTheme.bodyMedium?.copyWith(color: AppColors.mutedText),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/register'),
                        child: Text(
                          'Register here',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.coral,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
