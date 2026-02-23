import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Renders the nautical anchor mark. Uses the Unicode anchor character
/// styled to match ANCHORAGE's design system.
class AnchorLogo extends StatelessWidget {
  final double size;
  final Color color;

  const AnchorLogo({
    super.key,
    this.size = 48,
    this.color = AppColors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      '⚓',
      style: TextStyle(
        fontSize: size,
        color: color,
        height: 1,
      ),
    );
  }
}

/// Full branded logo: anchor + wordmark stacked vertically.
class AnchorBrandLogo extends StatelessWidget {
  final bool darkBackground;
  final double anchorSize;

  const AnchorBrandLogo({
    super.key,
    this.darkBackground = true,
    this.anchorSize = 56,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = darkBackground ? AppColors.white : AppColors.navy;
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnchorLogo(size: anchorSize, color: foreground),
        const SizedBox(height: 12),
        Text(
          'ANCHORAGE',
          style: theme.textTheme.titleLarge?.copyWith(
            color: foreground,
            letterSpacing: 4,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'STAY ANCHORED',
          style: theme.textTheme.bodySmall?.copyWith(
            color: foreground.withAlpha(180),
            letterSpacing: 2.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
