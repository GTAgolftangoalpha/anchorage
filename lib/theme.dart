import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ANCHORAGE Design System
// Clean, purposeful, maritime-inspired
// ═══════════════════════════════════════════════════════════════════════════════

// ── Colours ──────────────────────────────────────────────────────────────────

class Anchorage {
  Anchorage._();

  // Backgrounds
  static const Color bgPrimary = Color(0xFFFFFFFF);
  static const Color bgCard = Color(0xFFF5F8FA);

  // Text
  static const Color textPrimary = Color(0xFF0D2B45);
  static const Color textSecond = Color(0xFF3D5A6E);
  static const Color textHint = Color(0xFF8FA3B1);

  // Borders
  static const Color borderLight = Color(0xFFE1E8ED);
  static const Color borderMid = Color(0xFFC4D0D8);

  // Accent — deep teal
  static const Color accent = Color(0xFF1A6B72);
  static const Color accentLight = Color(0xFFE5F0F1);

  // Semantic
  static const Color danger = Color(0xFFC0392B);
}

// ── Typography helpers ───────────────────────────────────────────────────────

class AnchorageType {
  AnchorageType._();

  // Headings — DM Serif Display
  static TextStyle displayLarge({Color? color}) => GoogleFonts.dmSerifDisplay(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: color ?? Anchorage.textPrimary,
      );

  static TextStyle headingMedium({Color? color}) => GoogleFonts.dmSerifDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        color: color ?? Anchorage.textPrimary,
      );

  static TextStyle headingSmall({Color? color}) => GoogleFonts.dmSerifDisplay(
        fontSize: 20,
        fontWeight: FontWeight.w400,
        color: color ?? Anchorage.textPrimary,
      );

  // Body — DM Sans
  static TextStyle bodyLarge({Color? color}) => GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color ?? Anchorage.textSecond,
        height: 1.6,
      );

  static TextStyle bodyMedium({Color? color}) => GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color ?? Anchorage.textSecond,
        height: 1.5,
      );

  static TextStyle bodySmall({Color? color}) => GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color ?? Anchorage.textHint,
      );

  // Labels
  static TextStyle label({Color? color}) => GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color ?? Anchorage.textHint,
        letterSpacing: 1.5,
      );

  static TextStyle labelMedium({Color? color}) => GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color ?? Anchorage.textSecond,
        letterSpacing: 0.5,
      );

  // Buttons
  static TextStyle button({Color? color}) => GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: color ?? Anchorage.textPrimary,
        letterSpacing: 0.5,
      );

  // Nav
  static TextStyle navLabel({Color? color}) => GoogleFonts.dmSans(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: color ?? Anchorage.textHint,
        letterSpacing: 1.2,
      );
}

// ── ThemeData ────────────────────────────────────────────────────────────────

class AnchorageTheme {
  AnchorageTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: Anchorage.accent,
        onPrimary: Color(0xFFFFFFFF),
        primaryContainer: Anchorage.accentLight,
        onPrimaryContainer: Anchorage.accent,
        secondary: Anchorage.borderMid,
        onSecondary: Anchorage.textPrimary,
        surface: Anchorage.bgPrimary,
        onSurface: Anchorage.textPrimary,
        surfaceContainerHighest: Anchorage.borderLight,
        error: Anchorage.danger,
        onError: Color(0xFFFFFFFF),
      ),
      scaffoldBackgroundColor: Anchorage.bgPrimary,
    );

    final textTheme = GoogleFonts.dmSansTextTheme(base.textTheme).copyWith(
      displayLarge: AnchorageType.displayLarge(),
      displayMedium: GoogleFonts.dmSerifDisplay(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        color: Anchorage.textPrimary,
      ),
      headlineLarge: GoogleFonts.dmSerifDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        color: Anchorage.textPrimary,
      ),
      headlineMedium: AnchorageType.headingMedium(),
      headlineSmall: AnchorageType.headingSmall(),
      titleLarge: GoogleFonts.dmSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Anchorage.textPrimary,
      ),
      titleMedium: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Anchorage.textPrimary,
      ),
      titleSmall: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Anchorage.textSecond,
        letterSpacing: 0.5,
      ),
      bodyLarge: AnchorageType.bodyLarge(),
      bodyMedium: AnchorageType.bodyMedium(),
      bodySmall: AnchorageType.bodySmall(),
      labelLarge: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      labelMedium: AnchorageType.labelMedium(),
      labelSmall: AnchorageType.label(),
    );

    return base.copyWith(
      textTheme: textTheme,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: Anchorage.bgPrimary,
        foregroundColor: Anchorage.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Anchorage.textPrimary,
          letterSpacing: 2.0,
        ),
        iconTheme: const IconThemeData(color: Anchorage.textPrimary, size: 22),
      ),

      // Filled Button (primary)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Anchorage.accent,
          foregroundColor: const Color(0xFFFFFFFF),
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Elevated Button → redirect to filled style
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Anchorage.accent,
          foregroundColor: const Color(0xFFFFFFFF),
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Outlined Button (secondary)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Anchorage.textPrimary,
          side: const BorderSide(color: Anchorage.borderMid, width: 1),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Anchorage.accent,
          textStyle: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        color: Anchorage.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Anchorage.borderLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Anchorage.bgCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Anchorage.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Anchorage.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Anchorage.accent, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.dmSans(
          color: Anchorage.textHint,
          fontSize: 14,
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: Anchorage.borderLight,
        thickness: 1,
        space: 1,
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Anchorage.bgPrimary,
        selectedItemColor: Anchorage.accent,
        unselectedItemColor: Anchorage.textHint,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
        unselectedLabelStyle: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),

      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Anchorage.bgPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        dragHandleColor: Anchorage.borderMid,
        dragHandleSize: Size(40, 4),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: Anchorage.bgPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFFFFFFFF);
          }
          return Anchorage.textHint;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Anchorage.accent;
          }
          return Anchorage.borderLight;
        }),
      ),
    );
  }
}

// ── Reusable Widgets ─────────────────────────────────────────────────────────

/// Standard card widget for the Anchorage design system.
class AnchorageCard extends StatelessWidget {
  const AnchorageCard({
    super.key,
    required this.child,
    this.onTap,
    this.selected = false,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool selected;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: padding,
        decoration: BoxDecoration(
          color: selected ? Anchorage.accentLight : Anchorage.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Anchorage.accent : Anchorage.borderLight,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Status badge widget (ON/OFF display — no toggle).
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? Anchorage.accent : Anchorage.borderLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        active ? 'ON' : 'OFF',
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: active ? const Color(0xFFFFFFFF) : Anchorage.textHint,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

/// Footer widget for bottom of scrollable screens.
class AnchorageFooter extends StatelessWidget {
  const AnchorageFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'ANCHORAGE',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Anchorage.textHint,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Stay anchored. Stay free.',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: Anchorage.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section header in label style.
class AnchorageSectionHeader extends StatelessWidget {
  const AnchorageSectionHeader(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        text.toUpperCase(),
        style: AnchorageType.label(),
      ),
    );
  }
}

/// Settings-style row with icon, title, optional subtitle — no chevron.
class AnchorageSettingsRow extends StatelessWidget {
  const AnchorageSettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: Anchorage.accent, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AnchorageType.bodyMedium(color: Anchorage.textPrimary)),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(subtitle!, style: AnchorageType.bodySmall()),
                    ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
