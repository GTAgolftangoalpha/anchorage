import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../theme.dart';

/// Psychoeducation content cards for the home screen.
/// Each card is expandable to show the full text.

class PsychoeducationData {
  final String title;
  final String summary;
  final String body;
  final IconData icon;

  const PsychoeducationData({
    required this.title,
    required this.summary,
    required this.body,
    required this.icon,
  });

  static const cards = [
    PsychoeducationData(
      title: 'Urges Are Waves',
      summary: 'They feel permanent, but they always pass.',
      body:
          'The average urge lasts 20 to 30 minutes. It builds in intensity, '
          'peaks, and then fades on its own. You do not need to fight it or '
          'give in to it. You just need to ride it out. Every time you do, '
          'the next wave gets a little smaller.',
      icon: Icons.waves,
    ),
    PsychoeducationData(
      title: 'Not a Character Flaw',
      summary: 'This is a learned behaviour, not a moral failure.',
      body:
          'Compulsive pornography use is a learned behaviour reinforced by '
          'dopamine. Your brain built a habit loop: trigger, craving, '
          'behaviour, reward. Understanding this is the first step to '
          'rewiring it. You are not broken. Your brain is doing exactly '
          'what it was trained to do.',
      icon: Icons.psychology,
    ),
    PsychoeducationData(
      title: 'Shame vs Guilt',
      summary: 'One keeps you stuck. The other helps you grow.',
      body:
          'Shame says "I am bad." Guilt says "I did something I do not want '
          'to repeat." Shame keeps you stuck in a cycle because it attacks '
          'your identity. Guilt motivates change because it targets the '
          'behaviour. When you slip, practice guilt without shame. '
          'Acknowledge what happened, learn from it, and move forward.',
      icon: Icons.balance,
    ),
    PsychoeducationData(
      title: 'Why Willpower Is Not Enough',
      summary: 'Structure beats motivation every time.',
      body:
          'Willpower is a limited resource. It depletes under stress, '
          'fatigue, and hunger. That is why you are most vulnerable late '
          'at night or after a hard day. The solution is not more willpower. '
          'It is building systems, blockers, and habits that protect you '
          'when willpower runs low. That is what ANCHORAGE is for.',
      icon: Icons.battery_alert,
    ),
    PsychoeducationData(
      title: 'What Aroused Means Here',
      summary: 'A physiological response, not a command.',
      body:
          'Feeling aroused is a normal physiological response. It does not '
          'mean you have to act on it. Arousal can be triggered by stress, '
          'boredom, loneliness, or habit, not just attraction. When you '
          'notice it, name it without judgement: "I am feeling aroused." '
          'Then choose what you do next. The feeling is not the problem. '
          'The automatic reaction is.',
      icon: Icons.lightbulb_outline,
    ),
  ];
}

/// A single expandable psychoeducation card.
class PsychoeducationCard extends StatefulWidget {
  final PsychoeducationData data;

  const PsychoeducationCard({super.key, required this.data});

  @override
  State<PsychoeducationCard> createState() => _PsychoeducationCardState();
}

class _PsychoeducationCardState extends State<PsychoeducationCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = widget.data;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _expanded ? Anchorage.accentLight : AppColors.lightGray,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _expanded ? Anchorage.accent : AppColors.midGray,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _expanded
                        ? Anchorage.accent.withAlpha(20)
                        : AppColors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    data.icon,
                    size: 18,
                    color: _expanded ? Anchorage.accent : AppColors.navy,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (!_expanded)
                        Text(
                          data.summary,
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.slate,
                  size: 20,
                ),
              ],
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  data.body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal scrollable list of psychoeducation cards for the home screen.
class PsychoeducationSection extends StatelessWidget {
  const PsychoeducationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: PsychoeducationData.cards.map((card) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: PsychoeducationCard(data: card),
        );
      }).toList(),
    );
  }
}
