import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../services/intercept_event_service.dart';
import '../../services/premium_service.dart';
import '../../services/reflect_service.dart';
import '../../services/streak_service.dart';
import '../../services/urge_log_service.dart';
import 'pdf_generator.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  late DateTime _from;
  late DateTime _to;
  final _notesController = TextEditingController();
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _to = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _from = _to.subtract(const Duration(days: 30));
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? _from : _to;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isFrom) {
          _from = picked;
          if (_from.isAfter(_to)) _to = _from;
        } else {
          _to = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
          if (_to.isBefore(_from)) _from = _to;
        }
      });
    }
  }

  Future<void> _generateAndShare() async {
    setState(() => _generating = true);

    try {
      final streak = StreakService.instance.data.value;
      final urges = UrgeLogService.instance.entries.value
          .where((e) =>
              !e.timestamp.isBefore(_from) && !e.timestamp.isAfter(_to))
          .toList();
      final reflections = ReflectService.instance.entries.value
          .where((e) =>
              !e.timestamp.isBefore(_from) && !e.timestamp.isAfter(_to))
          .toList();
      final intercepts =
          InterceptEventService.instance.eventsInRange(_from, _to);
      final emotionCounts =
          InterceptEventService.instance.emotionCounts(from: _from, to: _to);

      final pdfBytes = await PdfGenerator.generate(
        from: _from,
        to: _to,
        streakData: streak,
        urges: urges,
        reflections: reflections,
        intercepts: intercepts,
        emotionCounts: emotionCounts,
        notes: _notesController.text.trim(),
      );

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/anchor_report_${_formatFileDate(_from)}_${_formatFileDate(_to)}.pdf',
      );
      await file.writeAsBytes(pdfBytes);

      if (mounted) {
        await Share.shareXFiles([XFile(file.path)]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate report: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';

  String _formatFileDate(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('EXPORT MY DATA')),
      body: SafeArea(
        child: ValueListenableBuilder<bool>(
          valueListenable: PremiumService.instance.isPremium,
          builder: (context, isPremium, _) {
            if (!isPremium) {
              return _buildPaywall(theme);
            }
            return _buildForm(theme);
          },
        ),
      ),
    );
  }

  Widget _buildPaywall(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 48,
              color: AppColors.slate,
            ),
            const SizedBox(height: 16),
            Text(
              'Premium Feature',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Export your data as a styled PDF report to share with your therapist or counsellor. Upgrade to ANCHORAGE+ to unlock.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Anchor Report',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          'Generate a PDF summary of your progress to share with a therapist, counsellor, or accountability partner.',
          style: theme.textTheme.bodyMedium,
        ),

        const SizedBox(height: 24),

        // Date range
        Text(
          'DATE RANGE',
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _DateButton(
                label: 'From',
                value: _formatDate(_from),
                onTap: () => _pickDate(isFrom: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DateButton(
                label: 'To',
                value: _formatDate(_to),
                onTap: () => _pickDate(isFrom: false),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Notes for therapist
        Text(
          'NOTES FOR THERAPIST',
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _notesController,
          maxLines: 4,
          maxLength: 500,
          decoration: const InputDecoration(
            hintText: 'Add any context or notes you want included in the report...',
          ),
        ),

        const SizedBox(height: 24),

        // What's included
        Text(
          'INCLUDED IN REPORT',
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        _IncludedItem(label: 'Overview (streak, clean days, intercepts)'),
        _IncludedItem(label: 'Emotional patterns from intercepts'),
        _IncludedItem(label: 'Urge log entries with triggers'),
        _IncludedItem(label: 'Reflection journal entries'),
        _IncludedItem(label: 'Your notes above'),

        const SizedBox(height: 32),

        // Generate button
        FilledButton.icon(
          onPressed: _generating ? null : _generateAndShare,
          icon: _generating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.white,
                  ),
                )
              : const Icon(Icons.picture_as_pdf),
          label: Text(_generating ? 'Generating...' : 'Generate & Share PDF'),
        ),
      ],
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.lightGray,
          borderRadius: BorderRadius.circular(12),
          border: const Border.fromBorderSide(
            BorderSide(color: AppColors.midGray),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IncludedItem extends StatelessWidget {
  final String label;

  const _IncludedItem({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
