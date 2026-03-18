import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../theme.dart';

/// 5-4-3-2-1 Grounding: use your senses to anchor in the present.
/// 5 things you see, 4 you touch, 3 you hear, 2 you smell, 1 you taste.
class GroundingScreen extends StatefulWidget {
  const GroundingScreen({super.key});

  @override
  State<GroundingScreen> createState() => _GroundingScreenState();
}

class _GroundingScreenState extends State<GroundingScreen> {
  static const _steps = [
    _GroundingStep(
      count: 5,
      sense: 'SEE',
      icon: Icons.visibility,
      instruction: 'Look around you. Name 5 things you can see right now.',
      hint: 'A lamp, a tree outside, your phone, the ceiling, a colour on the wall...',
    ),
    _GroundingStep(
      count: 4,
      sense: 'TOUCH',
      icon: Icons.touch_app,
      instruction: 'Notice 4 things you can physically feel.',
      hint: 'The chair beneath you, your feet on the floor, fabric on your skin, air on your face...',
    ),
    _GroundingStep(
      count: 3,
      sense: 'HEAR',
      icon: Icons.hearing,
      instruction: 'Listen carefully. Name 3 sounds you can hear.',
      hint: 'Traffic outside, a fan humming, your own breathing...',
    ),
    _GroundingStep(
      count: 2,
      sense: 'SMELL',
      icon: Icons.air,
      instruction: 'Notice 2 things you can smell.',
      hint: 'Coffee, laundry, fresh air, soap on your hands...',
    ),
    _GroundingStep(
      count: 1,
      sense: 'TASTE',
      icon: Icons.restaurant,
      instruction: 'Name 1 thing you can taste right now.',
      hint: 'Toothpaste, water, gum, the inside of your mouth...',
    ),
  ];

  int _currentStep = 0;
  final List<List<bool>> _checked = List.generate(
    5,
    (i) => List.filled(_steps[i].count, false),
  );
  bool _completed = false;

  int get _checkedCount => _checked[_currentStep].where((c) => c).length;

  bool get _stepDone => _checkedCount >= _steps[_currentStep].count;

  void _toggleItem(int index) {
    setState(() {
      _checked[_currentStep][index] = !_checked[_currentStep][index];
    });
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      setState(() => _completed = true);
    }
  }

  void _reset() {
    setState(() {
      _currentStep = 0;
      for (var list in _checked) {
        list.fillRange(0, list.length, false);
      }
      _completed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_completed) return _buildCompletionScreen();
    return _buildStepScreen();
  }

  Widget _buildStepScreen() {
    final theme = Theme.of(context);
    final step = _steps[_currentStep];

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('5-4-3-2-1 GROUNDING'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: List.generate(5, (i) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: i < 4 ? 4 : 0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: i <= _currentStep
                            ? Anchorage.accent
                            : AppColors.midGray,
                      ),
                    ),
                  );
                }),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Big number
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Anchorage.accentLight,
                        border: Border.all(color: Anchorage.accent, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          '${step.count}',
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontSize: 36,
                            color: Anchorage.accent,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Sense label
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(step.icon, color: Anchorage.accent, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          step.sense,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Anchorage.accent,
                            letterSpacing: 3,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Text(
                      step.instruction,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 8),
                    Text(
                      step.hint,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Check items
                    ...List.generate(step.count, (i) {
                      final checked = _checked[_currentStep][i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () => _toggleItem(i),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: checked
                                  ? Anchorage.accentLight
                                  : AppColors.lightGray,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: checked
                                    ? Anchorage.accent
                                    : AppColors.midGray,
                              ),
                            ),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: checked
                                        ? Anchorage.accent
                                        : AppColors.white,
                                    border: Border.all(
                                      color: checked
                                          ? Anchorage.accent
                                          : AppColors.midGray,
                                      width: 2,
                                    ),
                                  ),
                                  child: checked
                                      ? const Icon(
                                          Icons.check,
                                          size: 14,
                                          color: AppColors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  'Thing ${i + 1}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: checked
                                        ? Anchorage.accent
                                        : AppColors.slate,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    const Spacer(),

                    // Next button
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _stepDone ? _nextStep : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: Anchorage.accent,
                            foregroundColor: AppColors.white,
                            disabledBackgroundColor: AppColors.midGray,
                            disabledForegroundColor: AppColors.slate,
                            minimumSize: const Size(0, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _currentStep < _steps.length - 1
                                ? 'Next Sense'
                                : 'Complete',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
        title: const Text('5-4-3-2-1 GROUNDING'),
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
                'You just brought yourself back to the present moment using all five senses. The urge may still be there, but you are grounded.',
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
                  onPressed: _reset,
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
}

class _GroundingStep {
  final int count;
  final String sense;
  final IconData icon;
  final String instruction;
  final String hint;

  const _GroundingStep({
    required this.count,
    required this.sense,
    required this.icon,
    required this.instruction,
    required this.hint,
  });
}
