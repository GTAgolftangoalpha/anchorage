import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../theme.dart';

/// Box Breathing: 4 seconds inhale, 4 hold, 4 exhale, 4 hold.
/// A square animation traces the breathing pattern.
class BoxBreathingScreen extends StatefulWidget {
  const BoxBreathingScreen({super.key});

  @override
  State<BoxBreathingScreen> createState() => _BoxBreathingScreenState();
}

class _BoxBreathingScreenState extends State<BoxBreathingScreen>
    with SingleTickerProviderStateMixin {
  static const _cycleDuration = Duration(seconds: 16);
  static const _phases = ['Inhale', 'Hold', 'Exhale', 'Hold'];

  late final AnimationController _controller;
  int _completedCycles = 0;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _cycleDuration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _completedCycles++;
          _controller.forward(from: 0);
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _currentPhase {
    if (!_isRunning) return 'Ready';
    final progress = _controller.value * 4;
    final index = progress.floor().clamp(0, 3);
    return _phases[index];
  }

  int get _phaseSeconds {
    if (!_isRunning) return 4;
    final progress = _controller.value * 4;
    final phaseProgress = progress - progress.floor();
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
      _completedCycles = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.white,
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
                color: AppColors.white.withAlpha(180),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '4 seconds per side',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.white.withAlpha(120),
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
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_isRunning)
                          Text(
                            '$_phaseSeconds',
                            style: theme.textTheme.displayLarge?.copyWith(
                              color: Anchorage.accent,
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
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Cycle counter
                        Text(
                          '$_completedCycles cycle${_completedCycles == 1 ? '' : 's'} completed',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.white.withAlpha(120),
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

  _BoxPainter({required this.progress, required this.isRunning});

  @override
  void paint(Canvas canvas, Size size) {
    final boxPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withAlpha(40)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final activePaint = Paint()
      ..color = const Color(0xFF1A6B72)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = const Color(0xFF1A6B72)
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

    // Draw phase labels at corners
    final labelStyle = TextStyle(
      color: const Color(0xFFFFFFFF).withAlpha(80),
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );
    final labels = ['Inhale', 'Hold', 'Exhale', 'Hold'];
    final labelPositions = [
      Offset(rect.left, rect.bottom + 12), // bottom-left: Inhale (going up)
      Offset(rect.left, rect.top - 20), // top-left: Hold (going right)
      Offset(rect.right, rect.top - 20), // top-right: Exhale (going down)
      Offset(rect.right, rect.bottom + 12), // bottom-right: Hold (going left)
    ];

    for (var i = 0; i < 4; i++) {
      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final offset = i >= 2
          ? Offset(labelPositions[i].dx - tp.width, labelPositions[i].dy)
          : labelPositions[i];
      tp.paint(canvas, offset);
    }

    if (!isRunning) return;

    // Compute dot position along the square path
    // Phase 0: bottom-left to top-left (inhale - up)
    // Phase 1: top-left to top-right (hold - right)
    // Phase 2: top-right to bottom-right (exhale - down)
    // Phase 3: bottom-right to bottom-left (hold - left)
    final totalProgress = progress * 4;
    final phase = totalProgress.floor().clamp(0, 3);
    final t = totalProgress - phase;

    Offset dot;
    switch (phase) {
      case 0: // up left side
        dot = Offset(rect.left, rect.bottom - t * rect.height);
      case 1: // across top
        dot = Offset(rect.left + t * rect.width, rect.top);
      case 2: // down right side
        dot = Offset(rect.right, rect.top + t * rect.height);
      case 3: // across bottom (right to left)
        dot = Offset(rect.right - t * rect.width, rect.bottom);
      default:
        dot = Offset(rect.left, rect.bottom);
    }

    // Draw the traced path for current phase
    final path = Path();
    switch (phase) {
      case 0:
        path.moveTo(rect.left, rect.bottom);
        path.lineTo(rect.left, rect.bottom - t * rect.height);
      case 1:
        path.moveTo(rect.left, rect.bottom);
        path.lineTo(rect.left, rect.top);
        path.lineTo(rect.left + t * rect.width, rect.top);
      case 2:
        path.moveTo(rect.left, rect.bottom);
        path.lineTo(rect.left, rect.top);
        path.lineTo(rect.right, rect.top);
        path.lineTo(rect.right, rect.top + t * rect.height);
      case 3:
        path.moveTo(rect.left, rect.bottom);
        path.lineTo(rect.left, rect.top);
        path.lineTo(rect.right, rect.top);
        path.lineTo(rect.right, rect.bottom);
        path.lineTo(rect.right - t * rect.width, rect.bottom);
    }
    canvas.drawPath(path, activePaint);

    // Draw the dot
    canvas.drawCircle(dot, 8, dotPaint);
    canvas.drawCircle(
      dot,
      12,
      Paint()
        ..color = const Color(0xFF1A6B72).withAlpha(60)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_BoxPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isRunning != isRunning;
}
