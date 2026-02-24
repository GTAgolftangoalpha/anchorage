import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'streak_service.dart';
import 'urge_log_service.dart';

class ExportService {
  ExportService._();

  static Future<void> exportStreakData() async {
    final streak = StreakService.instance.data.value;
    final buf = StringBuffer();
    buf.writeln('Metric,Value');
    buf.writeln('Current Streak,${streak.currentStreak}');
    buf.writeln('Longest Streak,${streak.longestStreak}');
    buf.writeln('Total Clean Days,${streak.totalCleanDays}');
    buf.writeln('Weekly Intercepts,${streak.weeklyIntercepts}');
    if (streak.lastActiveDate != null) {
      buf.writeln('Last Active,${_formatDate(streak.lastActiveDate!)}');
    }

    await _shareCSV('anchorage_streak.csv', buf.toString());
  }

  static Future<void> exportUrgeLog() async {
    final entries = UrgeLogService.instance.entries.value;
    final buf = StringBuffer();
    buf.writeln('Date,Time,Trigger,Notes');
    for (final e in entries) {
      final date = _formatDate(e.timestamp);
      final time = _formatTime(e.timestamp);
      final notes = _escapeCsv(e.notes);
      buf.writeln('$date,$time,${_escapeCsv(e.trigger)},$notes');
    }

    await _shareCSV('anchorage_urge_log.csv', buf.toString());
  }

  static Future<void> _shareCSV(String filename, String content) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsString(content);
      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      debugPrint('[ExportService] share error: $e');
    }
  }

  static String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  static String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  static String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
