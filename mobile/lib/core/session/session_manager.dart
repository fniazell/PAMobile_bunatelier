import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../routing/app_router.dart';

class SessionTimeoutListener extends ConsumerStatefulWidget {
  final Widget child;
  final Duration timeout;

  const SessionTimeoutListener({
    super.key,
    required this.child,
    this.timeout = const Duration(minutes: 5), // 5 Minutes Inactivity
  });

  @override
  ConsumerState<SessionTimeoutListener> createState() => _SessionTimeoutListenerState();
}

class _SessionTimeoutListenerState extends ConsumerState<SessionTimeoutListener> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _resetTimer() {
    _timer?.cancel();

    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) return;

    _timer = Timer(widget.timeout, _handleTimeout);
  }

  Future<void> _handleTimeout() async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) return;

    // Trigger logout
    await ref.read(authProvider.notifier).logout();

    // Redirect to login
    AppRouter.router.go('/login');

    // Show expiration alert
    final context = AppRouter.router.routerDelegate.navigatorKey.currentContext;
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFE85D43),
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              Icon(Icons.timer_off_rounded, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Sesi Anda telah berakhir karena tidak ada aktivitas selama 5 menit.',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for authentication changes to start/stop the timer
    ref.listen(authProvider, (previous, next) {
      if (next.isAuthenticated) {
        _resetTimer();
      } else {
        _timer?.cancel();
      }
    });

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetTimer(),
      onPointerMove: (_) => _resetTimer(),
      child: widget.child,
    );
  }
}
