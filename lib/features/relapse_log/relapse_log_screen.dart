import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../services/premium_service.dart';
import '../../services/relapse_service.dart';

class RelapseLogScreen extends StatefulWidget {
  const RelapseLogScreen({super.key});

  @override
  State<RelapseLogScreen> createState() => _RelapseLogScreenState();
}

class _RelapseLogScreenState extends State<RelapseLogScreen> {
  final _whatHappenedController = TextEditingController();
  final _whatTriggeredController = TextEditingController();
  final _whatLearnedController = TextEditingController();
  final _nextTimeController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _whatHappenedController.dispose();
    _whatTriggeredController.dispose();
    _whatLearnedController.dispose();
    _nextTimeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_whatHappenedController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tell us what happened first.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    await RelapseService.instance.addEntry(
      whatHappened: _whatHappenedController.text.trim(),
      whatTriggered: _whatTriggeredController.text.trim(),
      whatLearned: _whatLearnedController.text.trim(),
      nextTime: _nextTimeController.text.trim(),
    );
    if (!mounted) return;

    _whatHappenedController.clear();
    _whatTriggeredController.clear();
    _whatLearnedController.clear();
    _nextTimeController.clear();
    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logged. Every setback is a lesson. Keep going.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RELAPSE LOG'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ValueListenableBuilder<bool>(
          valueListenable: PremiumService.instance.isPremium,
          builder: (context, isPremium, _) {
            return ValueListenableBuilder<List<RelapseEntry>>(
              valueListenable: RelapseService.instance.entries,
              builder: (context, entries, _) {
                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Explainer
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.navy,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'A setback is not failure',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Reflecting on what happened builds self-awareness. '
                            'This stays on your device only — completely private.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.white.withAlpha(180),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    if (!isPremium) ...[
                      // Premium gate
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withAlpha(15),
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: AppColors.gold.withAlpha(60)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.lock_outline,
                                color: AppColors.gold, size: 32),
                            const SizedBox(height: 12),
                            Text(
                              'Relapse Log is an ANCHORAGE+ feature',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Upgrade to track setbacks and build self-awareness.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () => context.push('/paywall'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.gold,
                              ),
                              child: const Text(
                                'UPGRADE',
                                style: TextStyle(
                                  color: AppColors.navy,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Guided prompts
                      Text(
                        'GUIDED REFLECTION',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _PromptField(
                        controller: _whatHappenedController,
                        label: 'What happened?',
                        hint: 'Describe what happened honestly...',
                      ),
                      const SizedBox(height: 12),
                      _PromptField(
                        controller: _whatTriggeredController,
                        label: 'What triggered it?',
                        hint: 'Boredom, stress, loneliness...',
                      ),
                      const SizedBox(height: 12),
                      _PromptField(
                        controller: _whatLearnedController,
                        label: 'What did you learn?',
                        hint:
                            'What insight can you take from this experience?',
                      ),
                      const SizedBox(height: 12),
                      _PromptField(
                        controller: _nextTimeController,
                        label: 'What will you do differently next time?',
                        hint: 'One concrete action you can take...',
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.navy,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.white,
                                  ),
                                )
                              : const Text(
                                  'SAVE REFLECTION',
                                  style: TextStyle(
                                    color: AppColors.white,
                                    letterSpacing: 1,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // History
                    if (entries.isNotEmpty) ...[
                      Text(
                        'PAST ENTRIES',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...entries.map((entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _EntryCard(entry: entry),
                          )),
                    ],
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _PromptField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;

  const _PromptField({
    required this.controller,
    required this.label,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: 3,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: true,
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final RelapseEntry entry;

  const _EntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = _formatDate(entry.timestamp);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.midGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            date,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          if (entry.whatHappened.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'What happened:',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              entry.whatHappened,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          if (entry.whatTriggered.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'What triggered it:',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              entry.whatTriggered,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          if (entry.whatLearned.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'What I learned:',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              entry.whatLearned,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          if (entry.nextTime.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Next time I will:',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              entry.nextTime,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDate = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(entryDate).inDays;

    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    final timeStr = '$hour:$minute $ampm';

    if (diff == 0) return 'Today, $timeStr';
    if (diff == 1) return 'Yesterday, $timeStr';
    return '${dt.day}/${dt.month}, $timeStr';
  }
}
