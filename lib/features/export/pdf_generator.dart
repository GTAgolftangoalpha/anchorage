import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../services/intercept_event_service.dart';
import '../../services/reflect_service.dart';
import '../../services/relapse_service.dart';
import '../../services/streak_service.dart';
import '../../services/urge_log_service.dart';

class PdfGenerator {
  PdfGenerator._();

  static const _navy = PdfColor.fromInt(0xFF0D2B45);
  static const _teal = PdfColor.fromInt(0xFF1A6B72);
  static const _lightBg = PdfColor.fromInt(0xFFF5F8FA);
  static const _border = PdfColor.fromInt(0xFFE1E8ED);
  static const _textSecond = PdfColor.fromInt(0xFF3D5A6E);

  static Future<Uint8List> generate({
    required DateTime from,
    required DateTime to,
    required String userName,
    required StreakData streakData,
    required List<UrgeEntry> urges,
    required List<ReflectEntry> reflections,
    required List<InterceptEvent> intercepts,
    required List<RelapseEntry> lapses,
    required Map<String, int> emotionCounts,
    required String notes,
  }) async {
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(),
    );

    final headerStyle = pw.TextStyle(
      fontSize: 22,
      fontWeight: pw.FontWeight.bold,
      color: _navy,
    );

    final sectionStyle = pw.TextStyle(
      fontSize: 14,
      fontWeight: pw.FontWeight.bold,
      color: _teal,
    );

    final bodyStyle = pw.TextStyle(
      fontSize: 10,
      color: _navy,
    );

    final smallStyle = pw.TextStyle(
      fontSize: 9,
      color: _textSecond,
    );

    final dateRange = '${_formatDate(from)} to ${_formatDate(to)}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) =>
            _buildHeader(headerStyle, smallStyle, userName, dateRange),
        footer: (context) => _buildFooter(smallStyle, context),
        build: (context) => [
          // Section 1: Overview
          _sectionTitle('1. Overview', sectionStyle),
          pw.SizedBox(height: 8),
          _overviewTable(
            streakData,
            intercepts.length,
            reflections.length,
            lapses.length,
            urges.length,
            bodyStyle,
          ),
          pw.SizedBox(height: 20),

          // Section 2: Emotional Pattern
          _sectionTitle('2. Emotional Pattern', sectionStyle),
          pw.SizedBox(height: 8),
          if (emotionCounts.isEmpty)
            pw.Text(
              'No emotional data recorded in this period.',
              style: smallStyle,
            )
          else ...[
            _emotionTable(emotionCounts, bodyStyle, smallStyle),
            pw.SizedBox(height: 8),
            ..._triggerPatterns(intercepts, bodyStyle, smallStyle),
          ],
          pw.SizedBox(height: 20),

          // Section 3: Urge Log
          _sectionTitle('3. Urge Log', sectionStyle),
          pw.SizedBox(height: 8),
          if (urges.isEmpty)
            pw.Text(
              'No urge log entries in this period.',
              style: smallStyle,
            )
          else
            _urgeTable(urges, bodyStyle, smallStyle),
          pw.SizedBox(height: 20),

          // Section 4: Reflect Entries
          _sectionTitle('4. Reflection Entries', sectionStyle),
          pw.SizedBox(height: 8),
          if (reflections.isEmpty)
            pw.Text(
              'No reflection entries in this period.',
              style: smallStyle,
            )
          else
            _reflectTable(reflections, bodyStyle, smallStyle),
          pw.SizedBox(height: 20),

          // Section 5: Notes
          if (notes.isNotEmpty) ...[
            _sectionTitle('5. Notes', sectionStyle),
            pw.SizedBox(height: 8),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: _lightBg,
                border: pw.Border.all(color: _border),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(notes, style: bodyStyle),
            ),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(
    pw.TextStyle headerStyle,
    pw.TextStyle smallStyle,
    String userName,
    String dateRange,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Anchor Report', style: headerStyle),
            pw.Text(
              'ANCHORAGE',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: _teal,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          [
            if (userName.isNotEmpty) userName,
            dateRange,
          ].join(' | '),
          style: pw.TextStyle(fontSize: 10, color: _textSecond),
        ),
        pw.Divider(color: _teal, thickness: 2),
        pw.SizedBox(height: 8),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.TextStyle style, pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(color: _border),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Text(
                'Generated by Anchorage | This is user-reported data, not clinical assessment | findahelpline.com',
                style: style,
              ),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: style,
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _sectionTitle(String title, pw.TextStyle style) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const pw.BoxDecoration(
        color: _lightBg,
        border: pw.Border(bottom: pw.BorderSide(color: _teal, width: 1.5)),
      ),
      child: pw.Text(title, style: style),
    );
  }

  static pw.Widget _overviewTable(
    StreakData streak,
    int interceptCount,
    int reflectCount,
    int lapseCount,
    int urgeCount,
    pw.TextStyle bodyStyle,
  ) {
    return pw.TableHelper.fromTextArray(
      headerAlignment: pw.Alignment.centerLeft,
      cellAlignment: pw.Alignment.centerLeft,
      headerStyle: bodyStyle.copyWith(fontWeight: pw.FontWeight.bold),
      cellStyle: bodyStyle,
      headerDecoration: const pw.BoxDecoration(color: _lightBg),
      cellPadding: const pw.EdgeInsets.all(6),
      headers: ['Metric', 'Value'],
      data: [
        ['Current streak', '${streak.currentStreak} days'],
        ['Longest streak', '${streak.longestStreak} days'],
        ['Total anchored days', '${streak.totalCleanDays}'],
        ['Total intercepts', '$interceptCount'],
        ['Reflections completed', '$reflectCount'],
        ['White flags raised', '$lapseCount'],
        ['Urges logged', '$urgeCount'],
      ],
    );
  }

  static pw.Widget _emotionTable(
    Map<String, int> counts,
    pw.TextStyle bodyStyle,
    pw.TextStyle smallStyle,
  ) {
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = sorted.fold<int>(0, (sum, e) => sum + e.value);

    return pw.TableHelper.fromTextArray(
      headerAlignment: pw.Alignment.centerLeft,
      cellAlignment: pw.Alignment.centerLeft,
      headerStyle: bodyStyle.copyWith(fontWeight: pw.FontWeight.bold),
      cellStyle: bodyStyle,
      headerDecoration: const pw.BoxDecoration(color: _lightBg),
      cellPadding: const pw.EdgeInsets.all(6),
      headers: ['Emotional State', 'Count', '% of Total'],
      data: sorted
          .map((e) => [
                _capitalize(e.key),
                '${e.value}',
                '${(e.value / total * 100).round()}%',
              ])
          .toList(),
    );
  }

  /// Compute most common trigger time of day and day of week from intercepts.
  static List<pw.Widget> _triggerPatterns(
    List<InterceptEvent> intercepts,
    pw.TextStyle bodyStyle,
    pw.TextStyle smallStyle,
  ) {
    if (intercepts.isEmpty) return [];

    // Time of day buckets
    final timeLabels = ['Morning (6-12)', 'Afternoon (12-18)', 'Evening (18-24)', 'Night (0-6)'];
    final timeBuckets = [0, 0, 0, 0];
    for (final e in intercepts) {
      final h = e.timestamp.hour;
      if (h >= 6 && h < 12) {
        timeBuckets[0]++;
      } else if (h >= 12 && h < 18) {
        timeBuckets[1]++;
      } else if (h >= 18) {
        timeBuckets[2]++;
      } else {
        timeBuckets[3]++;
      }
    }
    final maxTime = timeBuckets.reduce((a, b) => a > b ? a : b);
    final peakTimeIdx = timeBuckets.indexOf(maxTime);

    // Day of week
    final dayLabels = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dayBuckets = List<int>.filled(7, 0);
    for (final e in intercepts) {
      dayBuckets[e.timestamp.weekday - 1]++;
    }
    final maxDay = dayBuckets.reduce((a, b) => a > b ? a : b);
    final peakDayIdx = dayBuckets.indexOf(maxDay);

    return [
      pw.Text(
        'Most common trigger time: ${timeLabels[peakTimeIdx]} ($maxTime intercepts)',
        style: bodyStyle,
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        'Most common trigger day: ${dayLabels[peakDayIdx]} ($maxDay intercepts)',
        style: bodyStyle,
      ),
    ];
  }

  static pw.Widget _urgeTable(
    List<UrgeEntry> urges,
    pw.TextStyle bodyStyle,
    pw.TextStyle smallStyle,
  ) {
    return pw.TableHelper.fromTextArray(
      headerAlignment: pw.Alignment.centerLeft,
      cellAlignment: pw.Alignment.centerLeft,
      headerStyle: bodyStyle.copyWith(fontWeight: pw.FontWeight.bold),
      cellStyle: bodyStyle,
      headerDecoration: const pw.BoxDecoration(color: _lightBg),
      cellPadding: const pw.EdgeInsets.all(6),
      headers: ['Date', 'Time', 'Trigger', 'Notes'],
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(4),
      },
      data: urges
          .map((u) => [
                _formatDate(u.timestamp),
                _formatTime(u.timestamp),
                u.trigger,
                u.notes.isEmpty ? '-' : u.notes,
              ])
          .toList(),
    );
  }

  static pw.Widget _reflectTable(
    List<ReflectEntry> reflections,
    pw.TextStyle bodyStyle,
    pw.TextStyle smallStyle,
  ) {
    return pw.TableHelper.fromTextArray(
      headerAlignment: pw.Alignment.centerLeft,
      cellAlignment: pw.Alignment.centerLeft,
      headerStyle: bodyStyle.copyWith(fontWeight: pw.FontWeight.bold),
      cellStyle: bodyStyle,
      headerDecoration: const pw.BoxDecoration(color: _lightBg),
      cellPadding: const pw.EdgeInsets.all(6),
      headers: ['Date', 'Mood', 'Trigger', 'Journal'],
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(4),
      },
      data: reflections
          .map((r) => [
                _formatDate(r.timestamp),
                r.mood,
                r.trigger.isEmpty ? '-' : r.trigger,
                r.journal.isEmpty
                    ? '-'
                    : r.journal.length > 100
                        ? '${r.journal.substring(0, 100)}...'
                        : r.journal,
              ])
          .toList(),
    );
  }

  static String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';

  static String _formatTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
