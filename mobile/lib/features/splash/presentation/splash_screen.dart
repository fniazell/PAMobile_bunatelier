import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  final bool autoNavigate;
  const SplashScreen({super.key, this.autoNavigate = true});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    if (widget.autoNavigate) {
      _navigateToNext();
    }
  }

  bool _hasNavigated = false;

  Future<void> _navigateToNext() async {
    // Minimum splash duration: 4.5 seconds (around 4-5s) so the eating animation
    // plays fully and clearly (including bite, chew, and loop).
    await Future.delayed(const Duration(milliseconds: 4500));
    if (!mounted || _hasNavigated) return;

    // Wait until the auth session check is complete (isLoading == false)
    var authState = ref.read(authProvider);
    while (authState.isLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted || _hasNavigated) return;
      authState = ref.read(authProvider);
    }

    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    if (authState.isAuthenticated) {
      if (authState.user?.isAdmin == true) {
        context.go('/admin');
      } else {
        context.go('/main');
      }
    } else {
      context.go('/welcome');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Mascot Character Logo (Eating Burger Animation)
                const AnimatedEatingMascotLogo(size: 156),
                const SizedBox(height: 24),

                // Editorial Wordmark
                Text(
                  'BUN ATELIER',
                  style: textTheme.displayLarge?.copyWith(
                    letterSpacing: 3.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.espresso,
                    fontSize: 36,
                  ),
                ),
                const SizedBox(height: 10),

                // Tagline Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.forestGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'WORTH THE MESS.',
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.butterYellow,
                      letterSpacing: 2.0,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // Loading Indicator
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.coral,
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

/// Animated 5-Frame Bun Atelier Boy Mascot Logo Eating Burger
/// - Frame 1: Burger utuh (Mascot holding whole burger with gentle smile)
/// - Frame 2: Karakter mulai menggigit (Mouth opens, hands bring burger to lips)
/// - Frame 3: Burger digigit (Chomp! Joyful closed eyes with excitement marks)
/// - Frame 4: Burger sudah tergigit (Clear semi-circular bite mark visible)
/// - Frame 5: Mengunyah nikmat (Puffed cheeks, subtle chew bob, loops back to 1)
class AnimatedEatingMascotLogo extends StatefulWidget {
  final double size;
  const AnimatedEatingMascotLogo({super.key, this.size = 156});

  @override
  State<AnimatedEatingMascotLogo> createState() => _AnimatedEatingMascotLogoState();
}

class _AnimatedEatingMascotLogoState extends State<AnimatedEatingMascotLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _eatController;

  static const List<String> _frames = [
    'assets/images/splash/splash_frame_1.png',
    'assets/images/splash/splash_frame_2.png',
    'assets/images/splash/splash_frame_3.png',
    'assets/images/splash/splash_frame_4.png',
    'assets/images/splash/splash_frame_5.png',
  ];

  @override
  void initState() {
    super.initState();
    _eatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2250),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final path in _frames) {
      precacheImage(AssetImage(path), context);
    }
  }

  @override
  void dispose() {
    _eatController.stop();
    _eatController.dispose();
    super.dispose();
  }

  int _currentFrameIndex(double progress) {
    if (progress < 0.22) return 0; // Frame 1: Burger utuh
    if (progress < 0.40) return 1; // Frame 2: Mulai menggigit
    if (progress < 0.60) return 2; // Frame 3: Gigit (chomp!)
    if (progress < 0.80) return 3; // Frame 4: Burger sudah tergigit
    return 4;                      // Frame 5: Mengunyah
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _eatController,
      builder: (context, child) {
        final progress = _eatController.value;
        final frameIdx = _currentFrameIndex(progress);

        double scale = 1.0;
        double rotation = 0.0;
        double offsetY = 0.0;

        if (frameIdx == 2) {
          // Frame 3: Chomp impact punch
          scale = 1.035;
          rotation = -0.015;
        } else if (frameIdx == 4) {
          // Frame 5: Natural rhythmic chewing motion
          final chewPhase = (progress - 0.80) / 0.20;
          offsetY = math.sin(chewPhase * math.pi * 4) * 2.0;
        }

        return Transform.translate(
          offset: Offset(0, offsetY),
          child: Transform.rotate(
            angle: rotation,
            child: Transform.scale(
              scale: scale,
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: Image.asset(
                  _frames[frameIdx],
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

