import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../../app/theme/app_colors.dart';
import '../../rewards/data/reward_repository.dart';
import '../../rewards/providers/rewards_provider.dart';

enum _GameType { stackBun, trayRush }

enum _GamePhase { ready, playing, dropping, gameOver, victory }

class BurgerLayer {
  const BurgerLayer({
    required this.name,
    required this.color,
    required this.x,
    required this.top,
    required this.width,
    required this.height,
    required this.assetPath,
    this.isBun = false,
  });

  final String name;
  final Color color;
  final double x;
  final double top;
  final double width;
  final double height;
  final String assetPath;
  final bool isBun;

  BurgerLayer copyWith({
    double? x,
    double? top,
    double? width,
    double? height,
    String? assetPath,
  }) {
    return BurgerLayer(
      name: name,
      color: color,
      x: x ?? this.x,
      top: top ?? this.top,
      width: width ?? this.width,
      height: height ?? this.height,
      assetPath: assetPath ?? this.assetPath,
      isBun: isBun,
    );
  }
}

class _Ingredient {
  const _Ingredient(
    this.name,
    this.color,
    this.width,
    this.height, {
    required this.assetPath,
    this.isBun = false,
  });

  final String name;
  final Color color;
  final double width;
  final double height;
  final String assetPath;
  final bool isBun;
}

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with TickerProviderStateMixin {
  static const int _targetLayers = 15;

  // Selected game mode
  _GameType _selectedGameType = _GameType.stackBun;

  // Sensors Subscriptions & State
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  bool _sensorsAvailable = true;
  bool _useMotionSensors = true; // Toggle for user
  double _rawAccelX = 0.0;
  double _rawGyroY = 0.0;
  double _stackWobble = 0.0; // Gyroscope induced wobble in radians

  // Tray Rush Game State
  double _trayProgress = 0.0; // 0.0 to 100.0 (meters to Table 7)
  double _trayBalanceX = 0.0; // -1.0 to 1.0 (tray tilt)
  double _trayBalanceY = 0.0; // -1.0 to 1.0 (tray tilt)
  double _trayDangerTimer = 0.0; // seconds near spill
  int _trayScore = 0;

  // Stack Bun State
  final List<BurgerLayer> _stackedLayers = [];
  final List<_Ingredient> _ingredients = const [
    _Ingredient(
      'Angus Patty',
      Color(0xFF59362B),
      172,
      38,
      assetPath: 'assets/images/game/patty_beef.png',
    ),
    _Ingredient(
      'Cheddar Cheese',
      Color(0xFFF2B82F),
      166,
      28,
      assetPath: 'assets/images/game/cheese.png',
    ),
    _Ingredient(
      'Red Onion Rings',
      Color(0xFF9B5577),
      164,
      28,
      assetPath: 'assets/images/game/onion.png',
    ),
    _Ingredient(
      'Crispy Bacon',
      Color(0xFF8B3A2B),
      166,
      30,
      assetPath: 'assets/images/game/bacon.png',
    ),
    _Ingredient(
      'Fresh Lettuce',
      Color(0xFF59A66E),
      174,
      32,
      assetPath: 'assets/images/game/lettuce.png',
    ),
    _Ingredient(
      'Juicy Tomato',
      Color(0xFFD84C3F),
      162,
      32,
      assetPath: 'assets/images/game/tomato.png',
    ),
    _Ingredient(
      'Tangy Pickles',
      Color(0xFF77A94A),
      160,
      26,
      assetPath: 'assets/images/game/pickles.png',
    ),
    _Ingredient(
      'Crispy Chicken',
      Color(0xFFD48B38),
      168,
      38,
      assetPath: 'assets/images/game/crispy_chicken.png',
    ),
    _Ingredient(
      'Cheddar Cheese',
      Color(0xFFF2B82F),
      162,
      28,
      assetPath: 'assets/images/game/cheese.png',
    ),
    _Ingredient(
      'Angus Beef Patty',
      Color(0xFF59362B),
      166,
      38,
      assetPath: 'assets/images/game/patty_beef.png',
    ),
    _Ingredient(
      'Crispy Bacon',
      Color(0xFF8B3A2B),
      162,
      30,
      assetPath: 'assets/images/game/bacon.png',
    ),
    _Ingredient(
      'Fresh Lettuce',
      Color(0xFF59A66E),
      168,
      32,
      assetPath: 'assets/images/game/lettuce.png',
    ),
    _Ingredient(
      'Juicy Tomato',
      Color(0xFFD84C3F),
      158,
      32,
      assetPath: 'assets/images/game/tomato.png',
    ),
    _Ingredient(
      'Cheddar Cheese',
      Color(0xFFF2B82F),
      154,
      28,
      assetPath: 'assets/images/game/cheese.png',
    ),
    _Ingredient(
      'Brioche Top Bun',
      Color(0xFFECC475),
      170,
      56,
      assetPath: 'assets/images/game/bun_top.png',
      isBun: true,
    ),
  ];

  late final Ticker _ticker;
  late final AnimationController _dropController;
  _GamePhase _phase = _GamePhase.ready;
  BurgerLayer? _pendingLayer;
  int _score = 0;
  int _highScore = 0;
  double _arenaWidth = 360;
  double _arenaHeight = 420;
  double _activeX = 0;
  double _direction = 1;
  double _dropStartX = 0;
  double _dropStartY = 0;
  double _dropTargetY = 0;
  double _dropTargetX = 0;
  double _dropTargetWidth = 0;
  double _speed = 100;
  Duration _lastTick = Duration.zero;
  bool _arenaSyncScheduled = false;
  String? _sessionId;
  int _precisionHits = 0;
  int? _rewardPointsAwarded;
  String? _rewardError;
  bool _rewardSubmitStarted = false;

  int get _placedCount => math.max(0, _stackedLayers.length - 1);
  _Ingredient get _nextIngredient =>
      _ingredients[_placedCount.clamp(0, _targetLayers - 1)];
  double get _activeWidth =>
      math.min(_nextIngredient.width, math.max(1, _arenaWidth - 20));
  double get _activeHeight => _nextIngredient.height;
  bool get _isFinished =>
      _phase == _GamePhase.gameOver || _phase == _GamePhase.victory;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _dropController =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 550),
          )
          ..addListener(_onDropAnimationTick)
          ..addStatusListener(_onDropAnimationStatus);

    _initSensors();
  }

  void _initSensors() {
    try {
      _accelSub =
          accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval)
              .listen(
                (event) {
                  if (!mounted) return;
                  _onAccelerometer(event);
                },
                onError: (_) {
                  if (mounted) setState(() => _sensorsAvailable = false);
                },
              );

      _gyroSub =
          gyroscopeEventStream(samplingPeriod: SensorInterval.gameInterval)
              .listen((event) {
                if (!mounted) return;
                _onGyroscope(event);
              }, onError: (_) {});
    } catch (_) {
      _sensorsAvailable = false;
    }
  }

  void _onAccelerometer(AccelerometerEvent event) {
    _rawAccelX = event.x;

    if (!_useMotionSensors || _phase != _GamePhase.playing) return;

    if (_selectedGameType == _GameType.stackBun) {
      // In portrait: tilting phone left gives positive X, tilting right gives negative X
      // We steer the active ingredient smoothly with tilt
      final tilt = -event.x;
      if (tilt.abs() > 0.4) {
        final minX = -_activeWidth * 0.45;
        final maxX = _arenaWidth - _activeWidth * 0.55;
        setState(() {
          _activeX = (_activeX + tilt * 3.6).clamp(minX, maxX);
        });
      }
    } else if (_selectedGameType == _GameType.trayRush) {
      // Accelerometer steers waiter forward/sideways
      final forwardLean = (event.y - 4.5).clamp(0.0, 5.0); // Tilting forward
      final sideLean = -event.x; // Tilting left/right

      setState(() {
        _trayBalanceX = (_trayBalanceX + sideLean * 0.08).clamp(-1.2, 1.2);
        _trayBalanceY = (_trayBalanceY + (event.y - 5.0) * 0.08).clamp(
          -1.2,
          1.2,
        );

        // Forward movement
        if (forwardLean > 0.5) {
          _trayProgress += forwardLean * 0.12;
        } else {
          _trayProgress += 0.08; // Base walk speed
        }
      });
    }
  }

  void _onGyroscope(GyroscopeEvent event) {
    _rawGyroY = event.y;

    if (!_useMotionSensors || _phase != _GamePhase.playing) return;

    if (_selectedGameType == _GameType.stackBun) {
      // If the burger has more than 3 layers, device rotation causes stack wobble!
      if (_placedCount >= 3) {
        final rotVelocity = event.y.abs() + event.z.abs();
        if (rotVelocity > 0.3) {
          setState(() {
            _stackWobble = (_stackWobble + event.y * 0.035).clamp(-0.25, 0.25);
          });
        }
      }
    } else if (_selectedGameType == _GameType.trayRush) {
      // Gyroscope rotation accelerates the drink & burger sliding on the tray!
      setState(() {
        _trayBalanceX = (_trayBalanceX + event.z * 0.06).clamp(-1.2, 1.2);
        _trayBalanceY = (_trayBalanceY + event.y * 0.06).clamp(-1.2, 1.2);
      });
    }
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _ticker.dispose();
    _dropController.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_phase != _GamePhase.playing) return;
    final delta = elapsed - _lastTick;
    _lastTick = elapsed;
    final seconds = (delta.inMicroseconds / Duration.microsecondsPerSecond)
        .clamp(0.0, 0.05)
        .toDouble();

    if (_selectedGameType == _GameType.stackBun) {
      // Damping stack wobble back to stable upright
      if (_stackWobble.abs() > 0.001) {
        _stackWobble *= 0.93;
      }

      // If motion sensors are OFF, oscillate automatically across arena
      if (!_useMotionSensors) {
        final minX = -_activeWidth * 0.35;
        final maxX = _arenaWidth - _activeWidth * 0.65;
        setState(() {
          _activeX += _direction * _speed * seconds;
          if (_activeX >= maxX) {
            _activeX = maxX;
            _direction = -1;
          } else if (_activeX <= minX) {
            _activeX = minX;
            _direction = 1;
          }
        });
      } else {
        // In sensor mode, a slight natural drift keeps player engaged
        final minX = -_activeWidth * 0.45;
        final maxX = _arenaWidth - _activeWidth * 0.55;
        setState(() {
          _activeX = (_activeX + _direction * 18 * seconds).clamp(minX, maxX);
          if (_activeX >= maxX) _direction = -1;
          if (_activeX <= minX) _direction = 1;
        });
      }
    } else if (_selectedGameType == _GameType.trayRush) {
      // Tray Rush Loop
      final tiltMagnitude = math.sqrt(
        _trayBalanceX * _trayBalanceX + _trayBalanceY * _trayBalanceY,
      );

      setState(() {
        if (tiltMagnitude > 0.85) {
          _trayDangerTimer += seconds;
          if (_trayDangerTimer > 2.2) {
            // Spilled! Game Over
            _phase = _GamePhase.gameOver;
            _ticker.stop();
            _saveFinishedSession(victory: false);
          }
        } else {
          _trayDangerTimer = math.max(0.0, _trayDangerTimer - seconds * 1.5);
          _trayScore += (seconds * 15).round();
        }

        if (_trayProgress >= 100.0) {
          // Reached Table 7! Victory!
          _phase = _GamePhase.victory;
          _score = _trayScore + 500;
          _highScore = math.max(_highScore, _score);
          _ticker.stop();
          _saveFinishedSession(victory: true);
        }
      });
    }
  }

  void _startGame() {
    _ticker.stop();
    _dropController
      ..stop()
      ..reset();

    final baseWidth = math.min(176.0, _arenaWidth - 20);
    const baseHeight = 44.0;

    setState(() {
      _stackedLayers
        ..clear()
        ..add(
          BurgerLayer(
            name: 'Brioche Base',
            color: const Color(0xFFD99A52),
            x: (_arenaWidth - baseWidth) / 2,
            top: _arenaHeight - 20 - baseHeight,
            width: baseWidth,
            height: baseHeight,
            assetPath: 'assets/images/game/bun_bottom.png',
            isBun: true,
          ),
        );
      _score = 0;
      _phase = _GamePhase.playing;
      _pendingLayer = null;
      _activeX = (_arenaWidth - baseWidth) / 2;
      _direction = 1;
      _speed = 100;
      _stackWobble = 0.0;
      _sessionId = createRewardSessionId();
      _precisionHits = 0;
      _rewardPointsAwarded = null;
      _rewardError = null;
      _rewardSubmitStarted = false;

      // Tray state reset
      _trayProgress = 0.0;
      _trayBalanceX = 0.0;
      _trayBalanceY = 0.0;
      _trayDangerTimer = 0.0;
      _trayScore = 0;
    });
    _startTicker();
  }

  void _startTicker() {
    _lastTick = Duration.zero;
    if (!_ticker.isActive) _ticker.start();
  }

  void _nudgeActive(double direction) {
    if (_phase != _GamePhase.playing) return;
    final minX = -_activeWidth * 0.45;
    final maxX = _arenaWidth - _activeWidth * 0.55;
    setState(() {
      _direction = direction;
      _activeX = (_activeX + direction * math.max(22, _arenaWidth * 0.10))
          .clamp(minX, maxX)
          .toDouble();
    });
  }

  void _dropNextIngredient() {
    if (_phase != _GamePhase.playing || _stackedLayers.isEmpty) return;

    _ticker.stop();
    final ingredient = _nextIngredient;
    final width = _activeWidth;
    final topLayer = _stackedLayers.last;
    final topCenterX = topLayer.x + topLayer.width / 2;
    final activeCenterX = _activeX + width / 2;
    final centerDiff = (activeCenterX - topCenterX).abs();

    final overlapLeft = math.max(_activeX, topLayer.x);
    final overlapRight = math.min(
      _activeX + width,
      topLayer.x + topLayer.width,
    );
    final overlapWidth = math.max(0.0, overlapRight - overlapLeft);
    final minRequiredOverlap = topLayer.width * 0.42;
    final maxAllowedCenterDiff = topLayer.width * 0.45;
    final isValid = overlapWidth >= minRequiredOverlap && centerDiff <= maxAllowedCenterDiff;
    final cameraOffset = _cameraOffset(_arenaHeight);
    final stackTopOnScreen = topLayer.top - cameraOffset;

    _dropStartX = _activeX;
    _dropStartY = _activeY;
    _dropTargetX = _activeX;
    _dropTargetWidth = width;
    _dropTargetY = isValid
        ? stackTopOnScreen - ingredient.height + 6
        : _arenaHeight + ingredient.height + 60;
    _pendingLayer = isValid
        ? BurgerLayer(
            name: ingredient.name,
            color: ingredient.color,
            x: _activeX,
            top: topLayer.top - ingredient.height + 6,
            width: width,
            height: ingredient.height,
            assetPath: ingredient.assetPath,
            isBun: ingredient.isBun,
          )
        : null;

    final distance = (_dropTargetY - _dropStartY).abs();
    _dropController.duration = Duration(
      milliseconds: (360 + distance * 0.6).round().clamp(360, 750),
    );
    setState(() => _phase = _GamePhase.dropping);
    _dropController.forward(from: 0);
  }

  void _onDropAnimationTick() {
    if (_phase == _GamePhase.dropping && mounted) {
      setState(() {});
    }
  }

  void _onDropAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _phase != _GamePhase.dropping) {
      return;
    }

    final landedLayer = _pendingLayer;
    if (landedLayer == null) {
      setState(() => _phase = _GamePhase.gameOver);
      _saveFinishedSession(victory: false);
      return;
    }

    final overlapRatio =
        landedLayer.width / math.min(_activeWidth, _stackedLayers.last.width);
    final isPrecise = overlapRatio >= 0.88;
    final points = 100 + (isPrecise ? 120 : 0);
    setState(() {
      _stackedLayers.add(landedLayer);
      _score += points;
      if (isPrecise) _precisionHits++;
      _highScore = math.max(_highScore, _score);
      _pendingLayer = null;
      if (_placedCount >= _targetLayers) {
        _phase = _GamePhase.victory;
      } else {
        _phase = _GamePhase.playing;
        _speed = 100 + _placedCount * 14;
        _activeX = _activeX.clamp(
          0.0,
          math.max(0.0, _arenaWidth - _activeWidth),
        );
        _direction = _direction >= 0 ? -1 : 1;
      }
    });

    if (_phase == _GamePhase.playing) {
      _startTicker();
    } else if (_phase == _GamePhase.victory) {
      _saveFinishedSession(victory: true);
    }
  }

  Future<void> _saveFinishedSession({required bool victory}) async {
    final sessionId = _sessionId;
    if (_rewardSubmitStarted || sessionId == null) return;

    final userId = ref.read(currentRewardUserIdProvider);
    if (userId == null || userId.isEmpty) {
      setState(() {
        _rewardError = 'Login diperlukan untuk menyimpan poin mini-game.';
      });
      return;
    }

    _rewardSubmitStarted = true;
    setState(() {
      _rewardError = null;
    });
    try {
      final result = await ref
          .read(rewardsProvider(userId).notifier)
          .recordGameResult(
            RewardGameResult(
              sessionId: sessionId,
              score: _score,
              stackedIngredients: _placedCount,
              precisionHits: _precisionHits,
              victory: victory,
              playedAt: DateTime.now(),
            ),
          );
      if (!mounted) return;
      setState(() {
        _rewardPointsAwarded = result.pointsAwarded;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _rewardError = 'Poin belum tersimpan. Coba lagi. ($error)';
        _rewardSubmitStarted = false;
      });
    }
  }

  double get _activeY {
    if (_stackedLayers.isEmpty) return 34;
    final topLayer = _stackedLayers.last;
    final cameraOffset = _cameraOffset(_arenaHeight);
    final landingY = topLayer.top - cameraOffset - _activeHeight;
    return math.max(16, math.min(_arenaHeight * 0.22, landingY - 50));
  }

  double _cameraOffset(double height) {
    if (_stackedLayers.isEmpty) return 0;
    final topLayerTop = _stackedLayers.last.top;
    final targetY = height * 0.40;
    if (topLayerTop < targetY) {
      return topLayerTop - targetY;
    }
    return 0;
  }

  void _syncArenaSize(double width, double height) {
    if (_arenaSyncScheduled ||
        ((width - _arenaWidth).abs() < 1 &&
            (height - _arenaHeight).abs() < 1)) {
      return;
    }

    _arenaSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final widthScale = width / _arenaWidth;
      final heightDelta = height - _arenaHeight;
      setState(() {
        for (var index = 0; index < _stackedLayers.length; index++) {
          final layer = _stackedLayers[index];
          final scaledWidth = math.min(layer.width * widthScale, width - 12);
          final scaledX = (layer.x * widthScale).clamp(
            0.0,
            width - scaledWidth,
          );
          _stackedLayers[index] = layer.copyWith(
            x: scaledX.toDouble(),
            top: layer.top + heightDelta,
            width: scaledWidth,
          );
        }
        final maxActiveWidth = math.min(_nextIngredient.width, width - 20);
        _activeX = (_activeX * widthScale)
            .clamp(0.0, math.max(0.0, width - maxActiveWidth))
            .toDouble();
        if (_phase == _GamePhase.dropping) {
          _dropStartY += heightDelta;
          _dropTargetY += heightDelta;
        }
        _arenaWidth = width;
        _arenaHeight = height;
        _arenaSyncScheduled = false;
      });
    });
  }

  void _showHowToPlay() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1B3526),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DUAL-SENSOR RESTAURANT PHYSICS 🍔',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: AppColors.butterYellow,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 14),
              _buildSensorGuideItem(
                icon: Icons.screen_rotation_rounded,
                title: 'Accelerometer (Phone Tilt Steering)',
                desc: 'Miringkan HP ke kiri atau kanan untuk mengarahkan bahan burger / langkah pelayan secara presisi.',
              ),
              const SizedBox(height: 12),
              _buildSensorGuideItem(
                icon: Icons.balance_rounded,
                title: 'Gyroscope (Rotation & Stack Balance)',
                desc: 'Mendeteksi stabilitas sudut. Jaga HP tetap tenang agar tumpukan burger tinggi tidak bergoyang miring / nampan tidak tumpah!',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.coral,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'SIAP MAIN! 🚀',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSensorGuideItem({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.butterYellow, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF162E20),
      body: SafeArea(
        child: _phase == _GamePhase.ready
            ? _buildReadyView()
            : _selectedGameType == _GameType.stackBun
            ? _buildActiveStackGameView()
            : _buildActiveTrayGameView(),
      ),
    );
  }

  // -------------------------------------------------------------
  // READY VIEW: MODE SELECTION & SENSOR TOGGLE
  // -------------------------------------------------------------
  Widget _buildReadyView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        children: [
          // Header with back button, sensor indicator, help button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _iconButton(
                Icons.arrow_back_ios_new_rounded,
                () => context.pop(),
              ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _sensorsAvailable
                        ? const Color(0xFF294B35)
                        : Colors.red.shade900,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _useMotionSensors
                            ? Icons.sensors_rounded
                            : Icons.touch_app_rounded,
                        size: 14,
                        color: AppColors.butterYellow,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _useMotionSensors
                              ? 'SENSORS ON (Tilt & Gyro)'
                              : 'TOUCH MODE',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.butterYellow,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _iconButton(Icons.help_outline_rounded, _showHowToPlay),
            ],
          ),
          const SizedBox(height: 14),

          // Game Mode Selector Segmented Tabs
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF0C241B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () =>
                        setState(() => _selectedGameType = _GameType.stackBun),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedGameType == _GameType.stackBun
                            ? AppColors.forestGreen
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🍔', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Stack Your Bun',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _selectedGameType == _GameType.stackBun
                                    ? AppColors.butterYellow
                                    : Colors.white60,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () =>
                        setState(() => _selectedGameType = _GameType.trayRush),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedGameType == _GameType.trayRush
                            ? AppColors.forestGreen
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🧑‍🍳', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Chef Tray Rush',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _selectedGameType == _GameType.trayRush
                                    ? AppColors.butterYellow
                                    : Colors.white60,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_selectedGameType == _GameType.stackBun)
            _buildStackBunIntroContent()
          else
            _buildTrayRushReadyContent(),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // STACK YOUR BUN INTRO CONTENT (GOOGLE STITCH REFERENCE)
  // -------------------------------------------------------------
  Widget _buildStackBunIntroContent() {
    return Column(
      children: [
        // Official Bun Atelier Mascot Badge
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF7EEDD),
            border: Border.all(color: AppColors.butterYellow, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(6),
          child: Image.asset(
            'assets/images/splash/splash_frame_1.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 10),

        // Brand Name
        Text(
          'BUN ATELIER',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.cream,
            letterSpacing: 2.5,
          ),
        ),
        Text(
          'PREMIUM BURGERS',
          style: GoogleFonts.dmSans(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: AppColors.butterYellow,
            letterSpacing: 3.5,
          ),
        ),
        const SizedBox(height: 12),

        // Bubbly Retro Title
        Text(
          'STACK\nYOUR BUN',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 44,
            height: 0.95,
            color: const Color(0xFFFBF8EE),
            letterSpacing: -0.5,
            shadows: const [
              Shadow(
                color: Color(0xFF071B11),
                offset: Offset(0, 4),
                blurRadius: 4,
              ),
              Shadow(
                color: Color(0xFF1E462E),
                offset: Offset(0, 2),
                blurRadius: 0,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Tagline
        Text(
          'Build it tall. Don\'t let it fall.',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.butterYellow,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),

        // Hero Restaurant Storefront Illustration
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            height: 230,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF335D43), width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/game/bun_intro_storefront.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildFallbackBurger(),
                ),
                Positioned(
                  bottom: 10,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'HIGH SCORE: $_highScore PTS',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.butterYellow,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Sensor Mode Switcher Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0C241B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.screen_rotation_rounded,
                      color: AppColors.coral,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sensor Gerak & Giroskop',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _useMotionSensors
                                ? 'Miringkan & seimbangkan HP'
                                : 'Gunakan tombol sentuh manual',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: _useMotionSensors,
                activeThumbColor: AppColors.butterYellow,
                activeTrackColor: AppColors.coral,
                onChanged: (val) {
                  setState(() => _useMotionSensors = val);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Big Coral Red Play Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF25842),
              foregroundColor: Colors.white,
              elevation: 6,
              shadowColor: const Color(0xFFF25842).withValues(alpha: 0.55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            onPressed: _startGame,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "LET'S PLAY",
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 22),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Subtle Burger Icon Footer
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 44, height: 1.5, color: Colors.white24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text('🍔', style: TextStyle(fontSize: 16)),
            ),
            Container(width: 44, height: 1.5, color: Colors.white24),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'READY TO STACK 15 DELICIOUS LAYERS',
          style: GoogleFonts.dmSans(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: Colors.white38,
            letterSpacing: 1.8,
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // CHEF TRAY RUSH READY CONTENT (GAME 2 - UNTOUCHED)
  // -------------------------------------------------------------
  Widget _buildTrayRushReadyContent() {
    return Column(
      children: [
        Container(
          width: 200,
          height: 156,
          decoration: BoxDecoration(
            color: const Color(0xFF0C241B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text('🍽️ 🍔 🥤', style: TextStyle(fontSize: 40)),
              SizedBox(height: 8),
              Text(
                'ANTAR PESANAN KE MEJA #7',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.butterYellow,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        Text(
          'Pemain membawa nampan berisi burger & soda melintasi restoran! Gunakan Accelerometer untuk melangkah dan Gyroscope untuk menyeimbangkan nampan.',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 12.5,
            color: AppColors.cream.withValues(alpha: 0.85),
            height: 1.45,
          ),
        ),
        const SizedBox(height: 18),

        // Sensor Mode Switcher Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0C241B),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.screen_rotation_rounded,
                      color: AppColors.coral,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sensor Gerak & Giroskop',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _useMotionSensors
                                ? 'Miringkan & seimbangkan HP'
                                : 'Gunakan tombol sentuh manual',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: _useMotionSensors,
                activeThumbColor: AppColors.butterYellow,
                activeTrackColor: AppColors.coral,
                onChanged: (val) {
                  setState(() => _useMotionSensors = val);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // High Score Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0C241B),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HIGH SCORE',
                      style: GoogleFonts.dmSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.butterYellow,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      '$_highScore PTS',
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 26,
                        color: AppColors.cream,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onPressed: _startGame,
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: Text(
                  'MULAI MAIN',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // GAMEPLAY 1: STACK THE BUN VIEW (ACCELEROMETER + GYROSCOPE)
  // -------------------------------------------------------------
  Widget _buildActiveStackGameView() {
    final tiltDegrees = ((-_rawAccelX) * 7.5).clamp(-45.0, 45.0);
    final balancePercent = math
        .max(0, (100 - (_stackWobble.abs() * 320)).toInt())
        .clamp(0, 100);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Atmospheric Restaurant Interior Background
        Positioned.fill(
          child: Image.asset(
            'assets/images/game/gameplay_restaurant_bg.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Container(color: const Color(0xFF13281C)),
          ),
        ),
        // Subtle dark vignette overlay for game contrast
        Positioned.fill(
          child: Container(color: Colors.black.withValues(alpha: 0.38)),
        ),

        Column(
          children: [
            // Top HUD Bar matching Stitch Reference 2
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 16, 4),
              child: Row(
                children: [
                  _iconButton(Icons.arrow_back_ios_new_rounded, () {
                    _ticker.stop();
                    setState(() => _phase = _GamePhase.ready);
                  }),
                  const Spacer(),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'STACK YOUR BUN',
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppColors.butterYellow,
                          letterSpacing: 2.2,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '$_score PTS',
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 28,
                          color: AppColors.cream,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B3B28).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF3B6B4C),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      '$_placedCount/$_targetLayers',
                      style: GoogleFonts.dmSans(
                        color: AppColors.butterYellow,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Live Sensors Status Strip
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              color: Colors.black.withValues(alpha: 0.45),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Accelerometer Tilt Indicator
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_android_rounded,
                        size: 14,
                        color: AppColors.butterYellow,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Tilt: ${tiltDegrees.toStringAsFixed(1)}°',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Gyroscope Wobble / Stability Indicator
                  Row(
                    children: [
                      Icon(
                        _stackWobble.abs() > 0.08
                            ? Icons.warning_amber_rounded
                            : Icons.balance_rounded,
                        size: 14,
                        color: _stackWobble.abs() > 0.08
                            ? AppColors.coral
                            : Colors.greenAccent,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Balance: $balancePercent%',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _stackWobble.abs() > 0.08
                              ? AppColors.coral
                              : Colors.greenAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Arena
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF13281C).withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      _syncArenaSize(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      );
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _phase == _GamePhase.playing
                            ? _dropNextIngredient
                            : null,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: _buildArena(
                            constraints.maxWidth,
                            constraints.maxHeight,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Controls Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_useMotionSensors) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _phase == _GamePhase.playing
                                ? () => _nudgeActive(-1)
                                : null,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.cream,
                              side: const BorderSide(color: Colors.white24),
                              minimumSize: const Size(0, 42),
                            ),
                            icon: const Icon(Icons.arrow_left_rounded),
                            label: const Text('Geser Kiri'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _phase == _GamePhase.playing
                                ? () => _nudgeActive(1)
                                : null,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.cream,
                              side: const BorderSide(color: Colors.white24),
                              minimumSize: const Size(0, 42),
                            ),
                            icon: const Icon(Icons.arrow_right_rounded),
                            label: const Text('Geser Kanan'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ] else ...[
                    // Sensor Motion Hint
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.screen_rotation_rounded,
                          size: 14,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Tilt your phone to move the ingredient, then drop it!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Big Drop Button and Next Ingredient Preview Row
                  Row(
                    children: [
                      // Big Coral Red Drop Button
                      Expanded(
                        child: SizedBox(
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: _phase == _GamePhase.playing
                                ? _dropNextIngredient
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF25842),
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: const Color(0xFFF25842)
                                  .withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(
                              Icons.arrow_downward_rounded,
                              size: 20,
                            ),
                            label: Text(
                              _phase == _GamePhase.dropping
                                  ? 'DROPPING...'
                                  : 'DROP INGREDIENT',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Next Ingredient Circular Preview
                      _buildNextIngredientPreview(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        if (_isFinished) _buildResultOverlay(),
      ],
    );
  }

  // -------------------------------------------------------------
  // NEXT INGREDIENT CIRCULAR PREVIEW (MATCHING STITCH)
  // -------------------------------------------------------------
  Widget _buildNextIngredientPreview() {
    final nextIndex = _placedCount + 1;
    if (nextIndex >= _targetLayers) {
      return const SizedBox.shrink();
    }
    final nextItem = _ingredients[nextIndex];
    final shortName = nextItem.name
        .replaceAll('Angus ', '')
        .replaceAll('Cheddar ', '')
        .replaceAll('Red ', '')
        .replaceAll('Crispy ', '')
        .replaceAll('Fresh ', '')
        .replaceAll('Juicy ', '')
        .replaceAll('Brioche ', '');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1B3B28),
            border: Border.all(color: const Color(0xFF3B6B4C), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(5),
          child: Image.asset(
            nextItem.assetPath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.fastfood_rounded,
              color: AppColors.butterYellow,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Next:\n$shortName',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: Colors.white70,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // GAMEPLAY 2: CHEF TRAY RUSH VIEW  // -------------------------------------------------------------
  // GAMEPLAY 2: CHEF TRAY RUSH VIEW (ACCELEROMETER + GYROSCOPE)
  // -------------------------------------------------------------
  Widget _buildActiveTrayGameView() {
    final tiltMagnitude = math.sqrt(
      _trayBalanceX * _trayBalanceX + _trayBalanceY * _trayBalanceY,
    );
    final isDanger = tiltMagnitude > 0.85;

    return Stack(
      children: [
        Column(
          children: [
            // Top HUD Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 16, 4),
              child: Row(
                children: [
                  _iconButton(Icons.arrow_back_rounded, () {
                    _ticker.stop();
                    setState(() => _phase = _GamePhase.ready);
                  }),
                  const Spacer(),
                  Column(
                    children: [
                      Text(
                        'TRAY RUSH SCORE',
                        style: GoogleFonts.dmSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.butterYellow,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        '$_trayScore PTS',
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 24,
                          color: AppColors.cream,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF294B35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_trayProgress.toInt()}% / 100m',
                      style: const TextStyle(
                        color: AppColors.butterYellow,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Live Sensor HUD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              color: Colors.black38,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '📱 Tilt: ${_trayBalanceX.toStringAsFixed(2)} | Gyro: ${_rawGyroY.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    isDanger
                        ? '⚠️ AWAS TUMPAH! (${(2.2 - _trayDangerTimer).toStringAsFixed(1)}s)'
                        : '🟢 NAMPAN SEIMBANG',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: isDanger ? AppColors.coral : Colors.greenAccent,
                    ),
                  ),
                ],
              ),
            ),

            // Tray Simulation Arena
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF13281C),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDanger ? AppColors.coral : Colors.white12,
                      width: isDanger ? 2 : 1,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Floor perspective grid lines
                      Positioned(
                        top: 14,
                        child: Text(
                          'LORONG RESTORAN BUN ATELIER ➔ MENUJU MEJA #7',
                          style: GoogleFonts.dmSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white24,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),

                      // Progress Bar on floor
                      Positioned(
                        top: 36,
                        left: 20,
                        right: 20,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (_trayProgress / 100.0).clamp(0.0, 1.0),
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.butterYellow,
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ),

                      // Circular Wooden Tray Visual
                      Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF4A3319),
                          border: Border.all(
                            color: isDanger
                                ? AppColors.coral
                                : const Color(0xFF8B6434),
                            width: 6,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black45,
                              blurRadius: 18,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 190,
                            height: 190,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white12,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Sliding Burger & Soda on Tray based on Accelerometer & Gyroscope
                      Transform.translate(
                        offset: Offset(_trayBalanceX * 85, _trayBalanceY * 85),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text('🍔', style: TextStyle(fontSize: 42)),
                                SizedBox(width: 8),
                                Text('🥤', style: TextStyle(fontSize: 38)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Pesanan Table #7',
                                style: GoogleFonts.dmSans(
                                  fontSize: 9,
                                  color: AppColors.butterYellow,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Balance Target Center Marker
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDanger
                              ? Colors.redAccent.withValues(alpha: 0.5)
                              : Colors.greenAccent.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Tray controls / hint
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDanger
                      ? AppColors.coral.withValues(alpha: 0.2)
                      : const Color(0xFF0C241B),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDanger ? AppColors.coral : Colors.white12,
                  ),
                ),
                child: Text(
                  isDanger
                      ? '🚨 AWAS! Miringkan HP kembali ke posisi datar agar pesanan tidak jatuh!'
                      : '📱 Tahan HP tetap seimbang dan miringkan sedikit ke depan untuk mempercepat langkah.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDanger ? Colors.white : AppColors.cream,
                  ),
                ),
              ),
            ),
          ],
        ),

        if (_isFinished) _buildResultOverlay(),
      ],
    );
  }

  // -------------------------------------------------------------
  // ARENA RENDERING (STACK BUN)
  // -------------------------------------------------------------
  Widget _buildArena(double width, double height) {
    if (_stackedLayers.isEmpty) return const SizedBox.expand();
    final cameraOffset = _cameraOffset(height);
    final activeY = _phase == _GamePhase.dropping
        ? _dropStartY +
              (_dropTargetY - _dropStartY) *
                  Curves.easeInCubic.transform(_dropController.value)
        : _activeY;
    final activeX = _phase == _GamePhase.dropping
        ? _dropStartX +
              (_dropTargetX - _dropStartX) *
                  Curves.easeInCubic.transform(_dropController.value)
        : _activeX;
    final activeWidth = _phase == _GamePhase.dropping
        ? _activeWidth +
              (_dropTargetWidth - _activeWidth) *
                  Curves.easeInCubic.transform(_dropController.value)
        : _activeWidth;

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        // Wooden Counter Table at bottom of arena
        Positioned(
          left: 12,
          right: 12,
          bottom: 4,
          height: 18,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF8E5A35),
                  Color(0xFF5A341B),
                  Color(0xFF3B200E),
                ],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
              border: Border.all(color: const Color(0xFFA56F42), width: 1.5),
            ),
          ),
        ),

        // Stacked Layers with Gyroscope Wobble
        for (var i = 0; i < _stackedLayers.length; i++) ...[
          Builder(
            builder: (ctx) {
              final layer = _stackedLayers[i];
              final swayMultiplier = (i / _targetLayers).clamp(0.0, 1.0);
              final swayX =
                  math.sin(i * 0.45) * _stackWobble * 55 * swayMultiplier;
              final tiltAngle = _stackWobble * 0.22 * swayMultiplier;

              return Positioned(
                left: layer.x,
                top: layer.top - cameraOffset,
                width: layer.width,
                height: layer.height,
                child: Transform.rotate(
                  angle: tiltAngle,
                  child: Transform.translate(
                    offset: Offset(swayX, 0),
                    child: _layerVisual(
                      layer.name,
                      layer.color,
                      layer.width,
                      layer.height,
                      layer.assetPath,
                      layer.isBun,
                    ),
                  ),
                ),
              );
            },
          ),
        ],

        // Floating/Dropping Active Ingredient
        if (_phase == _GamePhase.playing || _phase == _GamePhase.dropping)
          Positioned(
            left: activeX,
            top: activeY,
            width: activeWidth,
            height: _activeHeight,
            child: _layerVisual(
              _phase == _GamePhase.dropping && _pendingLayer != null
                  ? _pendingLayer!.name
                  : _nextIngredient.name,
              _phase == _GamePhase.dropping && _pendingLayer != null
                  ? _pendingLayer!.color
                  : _nextIngredient.color,
              activeWidth,
              _activeHeight,
              _phase == _GamePhase.dropping && _pendingLayer != null
                  ? _pendingLayer!.assetPath
                  : _nextIngredient.assetPath,
              _phase == _GamePhase.dropping && _pendingLayer != null
                  ? _pendingLayer!.isBun
                  : _nextIngredient.isBun,
            ),
          ),

        if (_phase == _GamePhase.dropping)
          const Positioned(
            top: 24,
            left: 0,
            right: 0,
            child: Icon(
              Icons.south_rounded,
              color: AppColors.butterYellow,
              size: 24,
            ),
          ),
      ],
    );
  }

  Widget _layerVisual(
    String name,
    Color color,
    double width,
    double height,
    String assetPath,
    bool isBun,
  ) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            assetPath,
            width: width,
            height: height,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(isBun ? height / 2 : 4),
                ),
                alignment: Alignment.center,
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
          Opacity(
            opacity: 0.0,
            child: SizedBox(width: 0, height: 0, child: Text(name)),
          ),
        ],
      ),
    );
  }

  Widget _buildResultOverlay() {
    final won = _phase == _GamePhase.victory;
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.78),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF1B3526),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  won ? '🎉 VICTORY!' : '💔 GAME OVER',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 32,
                    color: won ? AppColors.butterYellow : AppColors.coral,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  won
                      ? _selectedGameType == _GameType.stackBun
                            ? 'Kamu berhasil menyusun 15 lapis burger sempurna!'
                            : 'Pesanan Meja #7 sukses diantar tanpa tumpah!'
                      : _selectedGameType == _GameType.stackBun
                      ? 'Bahan terjatuh keluar dari tumpukan burger.'
                      : 'Nampan terlalu miring dan pesanan tumpah!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C241B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'TOTAL SCORE: $_score PTS',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.butterYellow,
                    ),
                  ),
                ),
                if (_rewardPointsAwarded != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF294B35),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '🎁 +$_rewardPointsAwarded Poin Loyalty Ditambahkan ke Akun!',
                      style: GoogleFonts.dmSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
                if (_rewardError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _rewardError!,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 10.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() => _phase = _GamePhase.ready);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white38),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('MENU'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _startGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.coral,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'MAIN LAGI 🔄',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: 42,
      height: 42,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: AppColors.cream),
        style: IconButton.styleFrom(
          side: const BorderSide(color: Colors.white24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
    );
  }

  Widget _buildFallbackBurger() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: const [
        _BurgerPiece(
          width: 172,
          height: 38,
          color: Color(0xFFECC475),
          bun: true,
        ),
        _BurgerPiece(width: 188, height: 12, color: Color(0xFF59A66E)),
        _BurgerPiece(width: 174, height: 16, color: Color(0xFFF2B82F)),
        _BurgerPiece(width: 180, height: 24, color: Color(0xFF59362B)),
        _BurgerPiece(
          width: 172,
          height: 30,
          color: Color(0xFFD99A52),
          bun: true,
        ),
      ],
    );
  }
}

class _BurgerPiece extends StatelessWidget {
  const _BurgerPiece({
    required this.width,
    required this.height,
    required this.color,
    this.bun = false,
  });

  final double width;
  final double height;
  final Color color;
  final bool bun;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.symmetric(vertical: 1.5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(bun ? height / 2 : 4),
      ),
    );
  }
}
