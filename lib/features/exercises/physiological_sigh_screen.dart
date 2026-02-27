import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../theme.dart';

/// Physiological Sigh: double inhale (2s + 1s) then long exhale (6s).
/// Fastest evidence-based technique for real-time stress reduction.
class PhysiologicalSighScreen extends StatefulWidget {
  const PhysiologicalSighScreen({super.key});

  @override
  State<PhysiologicalSighScreen> createState() =>
      _PhysiologicalSighScreenState();
}

class _PhysiologicalSighScreenState extends State<PhysiologicalSighScreen>
    with TickerProviderStateMixin {
  // Phase durations in milliseconds
  static const _inhale1Ms = 2000;
  static const _inhale2Ms = 1000;
  static const _exhaleMs = 6000;
  static const _pauseMs = 1000;
  static const _totalMs = _inhale1Ms + _inhale2Ms + _exhaleMs + _pauseMs;

  late final AnimationController _breathController;
  late final AnimationController _scaleController;

  int _completedCycles = 0;
  bool _isRunning = false;
  String _phase = 'Ready';
  Timer? _phaseTimer;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _totalMs),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && _isRunning) {
          _completedCycles++;
          _breathController.forward(from: 0);
        }
      });

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _totalMs),
    );

    _breathController.addListener(_updatePhase);
  }

  void _updatePhase() {
    if (!_isRunning) return;
    final ms = (_breathController.value * _totalMs).round();
    String newPhase;
    if (ms < _inhale1Ms) {
      newPhase = 'Inhale';
    } else if (ms < _inhale1Ms + _inhale2Ms) {
      newPhase = 'Inhale deeper';
    } else if (ms < _inhale1Ms + _inhale2Ms + _exhaleMs) {
      newPhase = 'Exhale slowly';
    } else {
      newPhase = 'Rest';
    }
    if (newPhase != _phase) {
      setState(() => _phase = newPhase);
    }
  }

  double get _targetScale {
    if (!_isRunning) return 0.6;
    final ms = (_breathController.value * _totalMs).round();
    if (ms < _inhale1Ms) {
      // First inhale: 0.6 -> 0.8
      return 0.6 + 0.2 * (ms / _inhale1Ms);
    } else if (ms < _inhale1Ms + _inhale2Ms) {
      // Second inhale: 0.8 -> 1.0
      final t = (ms - _inhale1Ms) / _inhale2Ms;
      return 0.8 + 0.2 * t;
    } else if (ms < _inhale1Ms + _inhale2Ms + _exhaleMs) {
      // Exhale: 1.0 -> 0.5
      final t = (ms - _inhale1Ms - _inhale2Ms) / _exhaleMs;
      return 1.0 - 0.5 * t;
    } else {
      // Pause at 0.5 -> 0.6
      final t = (ms - _inhale1Ms - _inhale2Ms - _exhaleMs) / _pauseMs;
      return 0.5 + 0.1 * t;
    }
  }

  void _toggleRunning() {
    setState(() {
      if (_isRunning) {
        _breathController.stop();
        _isRunning = false;
        _phase = 'Paused';
      } else {
        _isRunning = true;
        _breathController.forward(from: _breathController.value);
      }
    });
  }

  void _reset() {
    setState(() {
      _breathController.reset();
      _isRunning = false;
      _completedCycles = 0;
      _phase = 'Ready';
    });
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _breathController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.white,
        title: const Text('PHYSIOLOGICAL SIGH'),
        titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
          color: AppColors.white,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Text(
              'Double inhale, long exhale',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.white.withAlpha(180),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The fastest way to calm your nervous system in real time',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.white.withAlpha(120),
              ),
            ),

            // Breathing circle
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _breathController,
                  builder: (context, _) {
                    final scale = _targetScale;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _phase,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Pulsing circle
                        SizedBox(
                          width: 220,
                          height: 220,
                          child: Center(
                            child: Container(
                              width: 200 * scale,
                              height: 200 * scale,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Anchorage.accent.withAlpha(40),
                                border: Border.all(
                                  color: Anchorage.accent,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Anchorage.accent.withAlpha(
                                      (30 * scale).round(),
                                    ),
                                    blurRadius: 40 * scale,
                                    spreadRadius: 10 * scale,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Anchorage.accent,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Pattern guide
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _PatternStep(
                              label: 'In',
                              seconds: '2s',
                              active: _phase == 'Inhale',
                            ),
                            _PatternDivider(),
                            _PatternStep(
                              label: 'In',
                              seconds: '1s',
                              active: _phase == 'Inhale deeper',
                            ),
                            _PatternDivider(),
                            _PatternStep(
                              label: 'Out',
                              seconds: '6s',
                              active: _phase == 'Exhale slowly',
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
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

class _PatternStep extends StatelessWidget {
  final String label;
  final String seconds;
  final bool active;

  const _PatternStep({
    required this.label,
    required this.seconds,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active
            ? Anchorage.accent.withAlpha(40)
            : AppColors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? Anchorage.accent : AppColors.white.withAlpha(30),
          width: active ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: active ? Anchorage.accent : AppColors.white.withAlpha(150),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            seconds,
            style: TextStyle(
              color: AppColors.white.withAlpha(80),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _PatternDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Icon(
        Icons.arrow_forward,
        size: 14,
        color: AppColors.white.withAlpha(40),
      ),
    );
  }
}
