import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// MOKUSO Design System
// Scandi-Japani: warm, minimal, purposeful
// ═══════════════════════════════════════════════════════════════════════════════

// ── Colours ──────────────────────────────────────────────────────────────────

class Mokuso {
  Mokuso._();

  // Backgrounds
  static const Color bgPrimary = Color(0xFFF7F4F0);
  static const Color bgCard = Color(0xFFFBF9F6);

  // Text
  static const Color textPrimary = Color(0xFF1E1E1E);
  static const Color textSecond = Color(0xFF6B6560);
  static const Color textHint = Color(0xFFABA49D);

  // Borders
  static const Color borderLight = Color(0xFFE2DDD8);
  static const Color borderMid = Color(0xFFCFC5B8);

  // Accent
  static const Color accent = Color(0xFF2D6A4F);
  static const Color accentLight = Color(0xFFE8F0EB);

  // Semantic
  static const Color danger = Color(0xFFB04A3A);
}

// ── Typography helpers ───────────────────────────────────────────────────────

class MokusoType {
  MokusoType._();

  // Headings — DM Serif Display
  static TextStyle displayLarge({Color? color}) => GoogleFonts.dmSerifDisplay(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: color ?? Mokuso.textPrimary,
      );

  static TextStyle headingMedium({Color? color}) => GoogleFonts.dmSerifDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        color: color ?? Mokuso.textPrimary,
      );

  static TextStyle headingSmall({Color? color}) => GoogleFonts.dmSerifDisplay(
        fontSize: 20,
        fontWeight: FontWeight.w400,
        color: color ?? Mokuso.textPrimary,
      );

  // Body — DM Sans
  static TextStyle bodyLarge({Color? color}) => GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color ?? Mokuso.textSecond,
        height: 1.6,
      );

  static TextStyle bodyMedium({Color? color}) => GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color ?? Mokuso.textSecond,
        height: 1.5,
      );

  static TextStyle bodySmall({Color? color}) => GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color ?? Mokuso.textHint,
      );

  // Labels
  static TextStyle label({Color? color}) => GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color ?? Mokuso.textHint,
        letterSpacing: 1.5,
      );

  static TextStyle labelMedium({Color? color}) => GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color ?? Mokuso.textSecond,
        letterSpacing: 0.5,
      );

  // Buttons
  static TextStyle button({Color? color}) => GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: color ?? Mokuso.textPrimary,
        letterSpacing: 0.5,
      );

  // Nav
  static TextStyle navLabel({Color? color}) => GoogleFonts.dmSans(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: color ?? Mokuso.textHint,
        letterSpacing: 1.2,
      );
}

// ── ThemeData ────────────────────────────────────────────────────────────────

class MokusoTheme {
  MokusoTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: Mokuso.accent,
        onPrimary: Color(0xFFFBF9F6),
        primaryContainer: Mokuso.accentLight,
        onPrimaryContainer: Mokuso.accent,
        secondary: Mokuso.borderMid,
        onSecondary: Mokuso.textPrimary,
        surface: Mokuso.bgPrimary,
        onSurface: Mokuso.textPrimary,
        surfaceContainerHighest: Mokuso.borderLight,
        error: Mokuso.danger,
        onError: Color(0xFFFBF9F6),
      ),
      scaffoldBackgroundColor: Mokuso.bgPrimary,
    );

    final textTheme = GoogleFonts.dmSansTextTheme(base.textTheme).copyWith(
      displayLarge: MokusoType.displayLarge(),
      displayMedium: GoogleFonts.dmSerifDisplay(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        color: Mokuso.textPrimary,
      ),
      headlineLarge: GoogleFonts.dmSerifDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        color: Mokuso.textPrimary,
      ),
      headlineMedium: MokusoType.headingMedium(),
      headlineSmall: MokusoType.headingSmall(),
      titleLarge: GoogleFonts.dmSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Mokuso.textPrimary,
      ),
      titleMedium: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Mokuso.textPrimary,
      ),
      titleSmall: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Mokuso.textSecond,
        letterSpacing: 0.5,
      ),
      bodyLarge: MokusoType.bodyLarge(),
      bodyMedium: MokusoType.bodyMedium(),
      bodySmall: MokusoType.bodySmall(),
      labelLarge: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      labelMedium: MokusoType.labelMedium(),
      labelSmall: MokusoType.label(),
    );

    return base.copyWith(
      textTheme: textTheme,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: Mokuso.bgPrimary,
        foregroundColor: Mokuso.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Mokuso.textPrimary,
          letterSpacing: 2.0,
        ),
        iconTheme: const IconThemeData(color: Mokuso.textPrimary, size: 22),
      ),

      // Filled Button (primary)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Mokuso.accent,
          foregroundColor: const Color(0xFFFBF9F6),
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
          backgroundColor: Mokuso.accent,
          foregroundColor: const Color(0xFFFBF9F6),
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
          foregroundColor: Mokuso.textPrimary,
          side: const BorderSide(color: Mokuso.borderMid, width: 1),
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
          foregroundColor: Mokuso.accent,
          textStyle: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        color: Mokuso.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Mokuso.borderLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Mokuso.bgCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Mokuso.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Mokuso.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Mokuso.accent, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.dmSans(
          color: Mokuso.textHint,
          fontSize: 14,
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: Mokuso.borderLight,
        thickness: 1,
        space: 1,
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Mokuso.bgPrimary,
        selectedItemColor: Mokuso.accent,
        unselectedItemColor: Mokuso.textHint,
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
        backgroundColor: Mokuso.bgPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        dragHandleColor: Mokuso.borderMid,
        dragHandleSize: Size(40, 4),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: Mokuso.bgPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFFFBF9F6);
          }
          return Mokuso.textHint;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Mokuso.accent;
          }
          return Mokuso.borderLight;
        }),
      ),
    );
  }
}

// ── Reusable Widgets ─────────────────────────────────────────────────────────

/// Standard card widget for the Mokuso design system.
class MokusoCard extends StatelessWidget {
  const MokusoCard({
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
          color: selected ? Mokuso.accentLight : Mokuso.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Mokuso.accent : Mokuso.borderLight,
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
        color: active ? Mokuso.accent : Mokuso.borderLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        active ? 'ON' : 'OFF',
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: active ? const Color(0xFFFBF9F6) : Mokuso.textHint,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

/// Footer widget for bottom of scrollable screens.
class MokusoFooter extends StatelessWidget {
  const MokusoFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'MOKUSO',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Mokuso.textHint,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pause. Breathe. Do What Matters.',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: Mokuso.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section header in label style.
class MokusoSectionHeader extends StatelessWidget {
  const MokusoSectionHeader(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        text.toUpperCase(),
        style: MokusoType.label(),
      ),
    );
  }
}

/// Settings-style row with icon, title, optional subtitle — no chevron.
class MokusoSettingsRow extends StatelessWidget {
  const MokusoSettingsRow({
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
            Icon(icon, color: Mokuso.accent, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: MokusoType.bodyMedium(color: Mokuso.textPrimary)),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(subtitle!, style: MokusoType.bodySmall()),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
