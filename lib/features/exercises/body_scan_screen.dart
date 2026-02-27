import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../theme.dart';

/// Body Scan: progressive relaxation from head to toe.
/// Guided timed exercise with body region focus.
class BodyScanScreen extends StatefulWidget {
  const BodyScanScreen({super.key});

  @override
  State<BodyScanScreen> createState() => _BodyScanScreenState();
}

class _BodyScanScreenState extends State<BodyScanScreen> {
  static const _regions = [
    _BodyRegion(
      name: 'Head and face',
      icon: Icons.face,
      duration: Duration(seconds: 20),
      instruction:
          'Bring your attention to the top of your head. Notice any tension in your forehead, around your eyes, your jaw. Let it soften. Unclench your teeth. Relax the muscles around your eyes.',
    ),
    _BodyRegion(
      name: 'Neck and shoulders',
      icon: Icons.accessibility_new,
      duration: Duration(seconds: 20),
      instruction:
          'Move your attention down to your neck and shoulders. These hold so much tension. Let your shoulders drop away from your ears. Feel the weight release.',
    ),
    _BodyRegion(
      name: 'Chest and upper back',
      icon: Icons.favorite_outline,
      duration: Duration(seconds: 20),
      instruction:
          'Notice your chest rising and falling with each breath. Feel your upper back against whatever is supporting it. Let your breathing be slow and natural.',
    ),
    _BodyRegion(
      name: 'Arms and hands',
      icon: Icons.back_hand_outlined,
      duration: Duration(seconds: 15),
      instruction:
          'Scan down through your arms to your fingertips. Notice any tension in your biceps, forearms, or fists. Open your hands gently. Let them rest.',
    ),
    _BodyRegion(
      name: 'Stomach and lower back',
      icon: Icons.self_improvement,
      duration: Duration(seconds: 20),
      instruction:
          'Bring your focus to your stomach and lower back. Notice if you are holding tension here. Let your belly be soft. Feel your lower back release.',
    ),
    _BodyRegion(
      name: 'Hips and thighs',
      icon: Icons.airline_seat_recline_normal,
      duration: Duration(seconds: 15),
      instruction:
          'Move your attention to your hips and upper legs. Feel the weight of your body settling downward. Let go of any tightness in your hip flexors or thighs.',
    ),
    _BodyRegion(
      name: 'Legs and feet',
      icon: Icons.do_not_step,
      duration: Duration(seconds: 20),
      instruction:
          'Scan down through your calves, ankles, and feet. Feel the ground beneath you. Notice the contact points between your body and the floor. You are held. You are here.',
    ),
  ];

  int _currentRegion = -1; // -1 = not started
  Timer? _timer;
  int _secondsLeft = 0;
  bool _completed = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() => _currentRegion = 0);
    _startRegionTimer();
  }

  void _startRegionTimer() {
    _timer?.cancel();
    final region = _regions[_currentRegion];
    _secondsLeft = region.duration.inSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) {
          timer.cancel();
          if (_currentRegion < _regions.length - 1) {
            _currentRegion++;
            _startRegionTimer();
          } else {
            _completed = true;
          }
        }
      });
    });
  }

  void _skip() {
    _timer?.cancel();
    if (_currentRegion < _regions.length - 1) {
      setState(() {
        _currentRegion++;
        _startRegionTimer();
      });
    } else {
      setState(() => _completed = true);
    }
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _currentRegion = -1;
      _secondsLeft = 0;
      _completed = false;
    });
  }

  double get _overallProgress {
    if (_currentRegion < 0) return 0;
    return (_currentRegion + 1) / _regions.length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.white,
        title: const Text('BODY SCAN'),
        titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
          color: AppColors.white,
        ),
      ),
      body: SafeArea(
        child: _completed
            ? _buildCompleted(theme)
            : _currentRegion < 0
                ? _buildIntro(theme)
                : _buildRegion(theme),
      ),
    );
  }

  Widget _buildIntro(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Spacer(),
          Icon(
            Icons.accessibility_new,
            size: 64,
            color: Anchorage.accent.withAlpha(180),
          ),
          const SizedBox(height: 24),
          Text(
            'Body Scan',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'A progressive relaxation exercise. You will move your attention through each part of your body, noticing and releasing tension as you go.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.white.withAlpha(180),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '7 regions. About 2 and a half minutes.',
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

  Widget _buildRegion(ThemeData theme) {
    final region = _regions[_currentRegion];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Overall progress
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _overallProgress,
                backgroundColor: AppColors.white.withAlpha(20),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Anchorage.accent),
                minHeight: 4,
              ),
            ),
          ),

          // Region indicator
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${_currentRegion + 1} of ${_regions.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.white.withAlpha(100),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(flex: 1),

          // Body part visualization
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Column(
              key: ValueKey(_currentRegion),
              children: [
                // Icon with glow
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Anchorage.accent.withAlpha(30),
                    border: Border.all(
                      color: Anchorage.accent.withAlpha(80),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    region.icon,
                    size: 36,
                    color: Anchorage.accent,
                  ),
                ),
                const SizedBox(height: 24),

                // Region name
                Text(
                  region.name,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 20),

                // Instruction
                Text(
                  region.instruction,
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

          // Timer and skip
          Text(
            '$_secondsLeft',
            style: theme.textTheme.displayLarge?.copyWith(
              color: AppColors.white.withAlpha(50),
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _skip,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.white.withAlpha(120),
            ),
            child: const Text('Skip'),
          ),
          const SizedBox(height: 16),
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
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Anchorage.accent.withAlpha(180),
          ),
          const SizedBox(height: 24),
          Text(
            'Scan complete.',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'You just moved your attention through your entire body. Notice how you feel now compared to when you started. Your body is a resource you always have access to.',
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

class _BodyRegion {
  final String name;
  final IconData icon;
  final Duration duration;
  final String instruction;

  const _BodyRegion({
    required this.name,
    required this.icon,
    required this.duration,
    required this.instruction,
  });
}
