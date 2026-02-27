import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../theme.dart';

/// Urge Surfing: observe the urge like a wave. It rises, peaks, and passes.
/// Guided meditation with wave animation.
class UrgeSurfingScreen extends StatefulWidget {
  const UrgeSurfingScreen({super.key});

  @override
  State<UrgeSurfingScreen> createState() => _UrgeSurfingScreenState();
}

class _UrgeSurfingScreenState extends State<UrgeSurfingScreen>
    with SingleTickerProviderStateMixin {
  static const _phases = [
    _UrgeSurfPhase(
      duration: Duration(seconds: 15),
      title: 'Notice the urge',
      body: 'Close your eyes or soften your gaze. Bring your attention to the urge you are feeling right now. Where do you feel it in your body? Is it in your chest, your stomach, your throat?',
    ),
    _UrgeSurfPhase(
      duration: Duration(seconds: 20),
      title: 'Observe without judging',
      body: 'Do not try to fight the urge or push it away. Just notice it. What does it feel like? Is it warm or cold? Is it tight or loose? Does it pulse or stay steady?',
    ),
    _UrgeSurfPhase(
      duration: Duration(seconds: 20),
      title: 'Breathe into it',
      body: 'Take a slow breath in through your nose. Imagine you are breathing directly into the sensation. Let the breath soften the edges. You do not need to change anything.',
    ),
    _UrgeSurfPhase(
      duration: Duration(seconds: 20),
      title: 'Watch the wave',
      body: 'Like a wave in the ocean, the urge has already started to shift. It may feel stronger for a moment, but it will crest and begin to fall. You are riding it, not fighting it.',
    ),
    _UrgeSurfPhase(
      duration: Duration(seconds: 20),
      title: 'Let it pass',
      body: 'The wave is moving through you now. Notice how the intensity has changed since you started. You did not act on it. You simply watched it arrive, peak, and begin to fade.',
    ),
    _UrgeSurfPhase(
      duration: Duration(seconds: 15),
      title: 'Return to yourself',
      body: 'Take one more deep breath. Open your eyes. You just proved that you can feel an urge without acting on it. That is real strength.',
    ),
  ];

  late final AnimationController _waveController;
  int _currentPhase = -1; // -1 = not started
  Timer? _phaseTimer;
  int _secondsLeft = 0;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _waveController.dispose();
    super.dispose();
  }

  void _start() {
    setState(() => _currentPhase = 0);
    _startPhaseTimer();
  }

  void _startPhaseTimer() {
    _phaseTimer?.cancel();
    final phase = _phases[_currentPhase];
    _secondsLeft = phase.duration.inSeconds;
    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) {
          timer.cancel();
          if (_currentPhase < _phases.length - 1) {
            _currentPhase++;
            _startPhaseTimer();
          } else {
            _completed = true;
          }
        }
      });
    });
  }

  void _reset() {
    _phaseTimer?.cancel();
    setState(() {
      _currentPhase = -1;
      _secondsLeft = 0;
      _completed = false;
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
        title: const Text('URGE SURFING'),
        titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
          color: AppColors.white,
        ),
      ),
      body: SafeArea(
        child: _completed
            ? _buildCompleted(theme)
            : _currentPhase < 0
                ? _buildIntro(theme)
                : _buildPhase(theme),
      ),
    );
  }

  Widget _buildIntro(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Spacer(),
          // Wave animation
          SizedBox(
            height: 120,
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, _) => CustomPaint(
                size: const Size(double.infinity, 120),
                painter: _WavePainter(
                  progress: _waveController.value,
                  amplitude: 0.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Urge Surfing',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'An urge is like a wave. It builds, crests, and then passes. You do not need to act on it. You just need to ride it.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.white.withAlpha(180),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This exercise takes about 2 minutes.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.white.withAlpha(100),
            ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: _start,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
            child: const Text('Begin'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPhase(ThemeData theme) {
    final phase = _phases[_currentPhase];
    // Wave amplitude peaks at phases 2-3 and decreases
    final amplitude = _currentPhase <= 1
        ? 0.3 + 0.15 * _currentPhase
        : _currentPhase <= 3
            ? 0.6 - 0.05 * (_currentPhase - 2)
            : 0.3 - 0.1 * (_currentPhase - 4);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Progress dots
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_phases.length, (i) {
                return Container(
                  width: i == _currentPhase ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: i <= _currentPhase
                        ? Anchorage.accent
                        : AppColors.white.withAlpha(30),
                  ),
                );
              }),
            ),
          ),

          const Spacer(flex: 1),

          // Wave
          SizedBox(
            height: 100,
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, _) => CustomPaint(
                size: const Size(double.infinity, 100),
                painter: _WavePainter(
                  progress: _waveController.value,
                  amplitude: amplitude,
                ),
              ),
            ),
          ),

          const Spacer(flex: 1),

          // Phase content
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Column(
              key: ValueKey(_currentPhase),
              children: [
                Text(
                  phase.title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  phase.body,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.white.withAlpha(200),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(flex: 2),

          // Timer
          Text(
            '$_secondsLeft',
            style: theme.textTheme.displayLarge?.copyWith(
              color: AppColors.white.withAlpha(60),
              fontSize: 32,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCompleted(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Spacer(),
          SizedBox(
            height: 80,
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, _) => CustomPaint(
                size: const Size(double.infinity, 80),
                painter: _WavePainter(
                  progress: _waveController.value,
                  amplitude: 0.15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'The wave has passed.',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'You rode the urge without acting on it. Each time you do this, you build a stronger ability to choose your response.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.white.withAlpha(200),
            ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
            child: const Text('Done'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _reset,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.white.withAlpha(150),
            ),
            child: const Text('Do it again'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _UrgeSurfPhase {
  final Duration duration;
  final String title;
  final String body;

  const _UrgeSurfPhase({
    required this.duration,
    required this.title,
    required this.body,
  });
}

class _WavePainter extends CustomPainter {
  final double progress;
  final double amplitude;

  _WavePainter({required this.progress, required this.amplitude});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF1A6B72).withAlpha(60),
          const Color(0xFF1A6B72).withAlpha(30),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = const Color(0xFF1A6B72)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final linePath = Path();
    final midY = size.height / 2;
    final amp = size.height * amplitude * 0.4;

    path.moveTo(0, size.height);

    for (var x = 0.0; x <= size.width; x += 1) {
      final t = x / size.width;
      final y = midY +
          amp * math.sin(2 * math.pi * (t - progress)) +
          amp * 0.5 * math.sin(4 * math.pi * (t - progress * 0.7));
      if (x == 0) {
        path.lineTo(0, y);
        linePath.moveTo(0, y);
      } else {
        path.lineTo(x, y);
        linePath.lineTo(x, y);
      }
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.amplitude != amplitude;
}
