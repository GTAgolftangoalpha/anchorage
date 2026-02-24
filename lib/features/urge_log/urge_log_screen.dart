import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/premium_service.dart';
import '../../services/urge_log_service.dart';

class UrgeLogScreen extends StatefulWidget {
  const UrgeLogScreen({super.key});

  @override
  State<UrgeLogScreen> createState() => _UrgeLogScreenState();
}

class _UrgeLogScreenState extends State<UrgeLogScreen> {
  String? _selectedTrigger;
  final _notesController = TextEditingController();
  bool _saving = false;
  int _formResetKey = 0;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    if (_selectedTrigger == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a trigger first'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    await UrgeLogService.instance.addEntry(
      trigger: _selectedTrigger!,
      notes: _notesController.text.trim(),
    );
    if (!mounted) return;
    _notesController.clear();
    setState(() {
      _selectedTrigger = null;
      _saving = false;
      _formResetKey++;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Entry logged. You\'re doing the right thing.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('URGE LOG')),
      body: SafeArea(
        child: ValueListenableBuilder<bool>(
          valueListenable: PremiumService.instance.isPremium,
          builder: (context, isPaid, _) {
            return ValueListenableBuilder<List<UrgeEntry>>(
              valueListenable: UrgeLogService.instance.entries,
              builder: (context, allEntries, _) {
                final visible =
                    UrgeLogService.instance.visibleEntries(isPaid: isPaid);
                final hasMore = !isPaid && allEntries.length > 7;

            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // ── Explainer ─────────────────────────────────────
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
                        'Track your triggers',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Logging urges helps you understand patterns. '
                        'This data stays on your device — it\'s never '
                        'shared or uploaded.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.white.withAlpha(180),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── New entry form ────────────────────────────────
                Text(
                  'LOG AN URGE',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                // Trigger dropdown
                DropdownButtonFormField<String>(
                  key: ValueKey(_formResetKey),
                  initialValue: _selectedTrigger,
                  decoration: const InputDecoration(
                    labelText: 'What triggered this?',
                    prefixIcon: Icon(Icons.psychology_outlined),
                  ),
                  items: UrgeLogService.triggers
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedTrigger = v),
                ),

                const SizedBox(height: 12),

                // Notes
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'What were you doing? How did you feel?',
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 48),
                      child: Icon(Icons.notes),
                    ),
                    alignLabelWithHint: true,
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _saveEntry,
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
                            'LOG ENTRY',
                            style: TextStyle(
                              color: AppColors.white,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── History ───────────────────────────────────────
                Text(
                  'RECENT ENTRIES',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                if (visible.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.edit_note,
                            size: 48,
                            color: AppColors.slate,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No entries yet',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  ...visible.map((entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _EntryCard(entry: entry),
                      )),
                  if (hasMore)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withAlpha(15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.gold.withAlpha(60)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_outline,
                              color: AppColors.gold, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${allEntries.length - 7} more entries — '
                              'upgrade to view full history',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _EntryCard extends StatelessWidget {
  final UrgeEntry entry;

  const _EntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = _formatTime(entry.timestamp);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.midGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.navy.withAlpha(15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  entry.trigger,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                time,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          if (entry.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              entry.notes,
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

  String _formatTime(DateTime dt) {
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
