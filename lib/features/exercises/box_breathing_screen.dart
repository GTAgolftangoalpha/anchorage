import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../theme.dart';

/// Box Breathing: 4 seconds inhale, 4 hold, 4 exhale, 4 hold.
/// A square animation traces the breathing pattern with pauses at corners
/// during hold phases.
class BoxBreathingScreen extends StatefulWidget {
  const BoxBreathingScreen({super.key});

  @override
  State<BoxBreathingScreen> createState() => _BoxBreathingScreenState();
}

class _BoxBreathingScreenState extends State<BoxBreathingScreen>
    with SingleTickerProviderStateMixin {
  static const _cycleDuration = Duration(seconds: 16);
  static const _phases = ['Inhale', 'Hold', 'Exhale', 'Hold'];
  static const _totalCycles = 4;

  late final AnimationController _controller;
  int _completedCycles = 0;
  bool _isRunning = false;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _cycleDuration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _completedCycles++;
            if (_completedCycles >= _totalCycles) {
              _isRunning = false;
              _isComplete = true;
            } else {
              _controller.forward(from: 0);
            }
          });
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _currentPhaseIndex {
    final progress = _controller.value * 4;
    return progress.floor().clamp(0, 3);
  }

  String get _currentPhase {
    if (!_isRunning) return 'Ready';
    return _phases[_currentPhaseIndex];
  }

  bool get _isHoldPhase =>
      _isRunning && (_currentPhaseIndex == 1 || _currentPhaseIndex == 3);

  int get _phaseSeconds {
    if (!_isRunning) return 4;
    final progress = _controller.value * 4;
    final phaseProgress = progress - progress.floor();
    if (_isHoldPhase) {
      // Count up: 1, 2, 3, 4
      return (phaseProgress * 4).floor() + 1;
    }
    // Count down: 4, 3, 2, 1
    return (4 - (phaseProgress * 4)).ceil().clamp(1, 4);
  }

  void _toggleRunning() {
    setState(() {
      if (_isRunning) {
        _controller.stop();
        _isRunning = false;
      } else {
        _isRunning = true;
        _controller.forward(from: _controller.value);
      }
    });
  }

  void _reset() {
    setState(() {
      _controller.reset();
      _isRunning = false;
      _isComplete = false;
      _completedCycles = 0;
    });
  }

  void _restart() {
    setState(() {
      _controller.reset();
      _completedCycles = 0;
      _isComplete = false;
      _isRunning = true;
      _controller.forward(from: 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isComplete) return _buildCompletionScreen();
    return _buildExerciseScreen();
  }

  Widget _buildCompletionScreen() {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('BOX BREATHING'),
        titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
          color: AppColors.white,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(),
              Text(
                'Exercise complete',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Notice how you feel right now compared to before you started. That difference is real.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.white.withAlpha(180),
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _restart,
                  style: FilledButton.styleFrom(
                    backgroundColor: Anchorage.accent,
                    foregroundColor: AppColors.white,
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'GO AGAIN',
                    style: TextStyle(
                      letterSpacing: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.white,
                    side: BorderSide(color: AppColors.white.withAlpha(60)),
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "I'M DONE",
                    style: TextStyle(
                      letterSpacing: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseScreen() {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('BOX BREATHING'),
        titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
          color: AppColors.white,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Text(
              'Breathe in a square pattern',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.darkBackgroundTeal,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '4 seconds per side',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.darkBackgroundTeal,
                fontSize: 16,
              ),
            ),

            // Square animation
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Phase label
                        Text(
                          _currentPhase,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: AppColors.darkBackgroundTeal,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_isRunning)
                          Text(
                            '$_phaseSeconds',
                            style: theme.textTheme.displayLarge?.copyWith(
                              color: _isHoldPhase
                                  ? AppColors.white
                                  : AppColors.darkBackgroundTeal,
                              fontSize: 48,
                            ),
                          ),
                        const SizedBox(height: 32),

                        // Square with tracer dot
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: CustomPaint(
                            painter: _BoxPainter(
                              progress: _controller.value,
                              isRunning: _isRunning,
                              cycle: _completedCycles,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Cycle counter (2 animation cycles = 1 full square)
                        Text(
                          '${(_completedCycles / 2).floor()} of ${_totalCycles ~/ 2} cycles completed',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.darkBackgroundTeal,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
              child: Row(
                children: [
                  if (_isRunning || _completedCycles > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _reset,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.white,
                          side: BorderSide(
                            color: AppColors.white.withAlpha(60),
                          ),
                          minimumSize: const Size(0, 52),
                        ),
                        child: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: FilledButton(
                      onPressed: _toggleRunning,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 52),
                      ),
                      child: Text(_isRunning ? 'Pause' : 'Start'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoxPainter extends CustomPainter {
  final double progress;
  final bool isRunning;
  final int cycle;

  _BoxPainter({
    required this.progress,
    required this.isRunning,
    required this.cycle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final boxPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withAlpha(40)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final activePaint = Paint()
      ..color = AppColors.darkBackgroundTeal
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = AppColors.darkBackgroundTeal
      ..style = PaintingStyle.fill;

    const padding = 20.0;
    final rect = Rect.fromLTWH(
      padding,
      padding,
      size.width - padding * 2,
      size.height - padding * 2,
    );

    // Draw the box outline
    canvas.drawRect(rect, boxPaint);

    if (!isRunning) return;

    // Corner positions
    final bl = Offset(rect.left, rect.bottom);
    final tl = Offset(rect.left, rect.top);
    final tr = Offset(rect.right, rect.top);
    final br = Offset(rect.right, rect.bottom);

    final totalProgress = progress * 4;
    final phase = totalProgress.floor().clamp(0, 3);
    final t = totalProgress - phase;

    final isEvenCycle = cycle % 2 == 0;

    // Dot position: movement during Inhale/Exhale, pause during Hold
    Offset dot;
    if (isEvenCycle) {
      // Even: Inhale BL->TL, Hold@TL, Exhale TL->TR, Hold@TR
      switch (phase) {
        case 0:
          dot = Offset.lerp(bl, tl, t)!;
        case 1:
          dot = tl;
        case 2:
          dot = Offset.lerp(tl, tr, t)!;
        case 3:
          dot = tr;
        default:
          dot = bl;
      }
    } else {
      // Odd: Inhale TR->BR, Hold@BR, Exhale BR->BL, Hold@BL
      switch (phase) {
        case 0:
          dot = Offset.lerp(tr, br, t)!;
        case 1:
          dot = br;
        case 2:
          dot = Offset.lerp(br, bl, t)!;
        case 3:
          dot = bl;
        default:
          dot = tr;
      }
    }

    // Draw the traced path
    final path = Path();
    if (isEvenCycle) {
      switch (phase) {
        case 0:
          path.moveTo(bl.dx, bl.dy);
          path.lineTo(dot.dx, dot.dy);
        case 1:
          path.moveTo(bl.dx, bl.dy);
          path.lineTo(tl.dx, tl.dy);
        case 2:
          path.moveTo(bl.dx, bl.dy);
          path.lineTo(tl.dx, tl.dy);
          path.lineTo(dot.dx, dot.dy);
        case 3:
          path.moveTo(bl.dx, bl.dy);
          path.lineTo(tl.dx, tl.dy);
          path.lineTo(tr.dx, tr.dy);
      }
    } else {
      // Odd cycle: include previous cycle trace (left + top)
      switch (phase) {
        case 0:
          path.moveTo(bl.dx, bl.dy);
          path.lineTo(tl.dx, tl.dy);
          path.lineTo(tr.dx, tr.dy);
          path.lineTo(dot.dx, dot.dy);
        case 1:
          path.moveTo(bl.dx, bl.dy);
          path.lineTo(tl.dx, tl.dy);
          path.lineTo(tr.dx, tr.dy);
          path.lineTo(br.dx, br.dy);
        case 2:
          path.moveTo(bl.dx, bl.dy);
          path.lineTo(tl.dx, tl.dy);
          path.lineTo(tr.dx, tr.dy);
          path.lineTo(br.dx, br.dy);
          path.lineTo(dot.dx, dot.dy);
        case 3:
          path.moveTo(bl.dx, bl.dy);
          path.lineTo(tl.dx, tl.dy);
          path.lineTo(tr.dx, tr.dy);
          path.lineTo(br.dx, br.dy);
          path.lineTo(bl.dx, bl.dy);
      }
    }
    canvas.drawPath(path, activePaint);

    // Draw the dot
    canvas.drawCircle(dot, 8, dotPaint);
    canvas.drawCircle(
      dot,
      12,
      Paint()
        ..color = AppColors.darkBackgroundTeal.withAlpha(60)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_BoxPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.isRunning != isRunning ||
      oldDelegate.cycle != cycle;
}
