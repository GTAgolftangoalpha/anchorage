import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../services/intercept_prompt_service.dart';
import '../../shared/widgets/anchor_logo.dart';
import '../../shared/widgets/white_flag_dialog.dart';

class BlockedDomainScreen extends StatefulWidget {
  final String domain;

  const BlockedDomainScreen({super.key, required this.domain});

  @override
  State<BlockedDomainScreen> createState() => _BlockedDomainScreenState();
}

class _BlockedDomainScreenState extends State<BlockedDomainScreen> {
  String? _selectedEmotion;
  InterceptPrompt? _prompt;
  List<String> _pickedSuggestions = [];

  static const _emotions = [
    'Bored',
    'Stressed',
    'Lonely',
    'Tired',
    'Anxious',
    'Down',
    'Angry',
    'Aroused',
    'Numb',
    'Rewarding Myself',
    'Not sure',
  ];

  static const _suggestions = {
    'Bored': [
      'Go for a 10-minute walk. No destination needed.',
      'Make a cup of tea or coffee. Focus on the process.',
      'Text someone you have not spoken to this week.',
      'Do 20 push-ups, sit-ups, or stretches.',
      'Pick up a book or article and read for 5 minutes.',
      'Tidy one small area. A desk, a shelf, a drawer.',
      'Put on a playlist and listen to 3 songs start to finish.',
    ],
    'Stressed': [
      'Step outside for 2 minutes. Just breathe the air.',
      'Write down 3 things stressing you. Get them out of your head.',
      'Put on a song you like at full volume.',
      'Splash cold water on your face and wrists.',
      'Drop your shoulders. Unclench your jaw. Take 3 slow breaths.',
      'Set a timer for 10 minutes and do nothing. Actually nothing.',
      'Call someone and talk about anything other than what is stressing you.',
    ],
    'Lonely': [
      'Call or text one person right now. Anyone.',
      'Go somewhere with other people. A cafe, a shop, a park.',
      'Write in your journal about what you are missing.',
      'Listen to a podcast or audiobook. A human voice helps.',
      'Message an old friend you have lost touch with.',
      'Go for a walk in a busy area. Being around people counts.',
    ],
    'Tired': [
      'Set a 20-minute nap timer and actually lie down.',
      'Go to bed. Put the phone in another room.',
      'Have a glass of water and a small snack.',
      'Do a gentle 5-minute stretch.',
      'Splash cold water on your face to reset.',
    ],
    'Anxious': [
      'Write down the worry. Getting it on paper takes it out of the loop.',
      'Walk around the block once. Movement interrupts the spiral.',
      'Call someone you trust and tell them you are feeling on edge.',
      'Hold something cold. Ice cube, cold drink, frozen peas.',
      'Reorganise something. A drawer, your desk, your bag. Small control helps.',
      'Make a cup of tea. Focus on every step of making it.',
    ],
    'Down': [
      'Have a shower or change your clothes. A small physical reset.',
      'Go outside for even 2 minutes. Daylight matters.',
      'Write one thing you did today, no matter how small.',
      'Listen to music that matches your mood. Not to fix it, just to be with it.',
      'Eat something. Low blood sugar makes everything harder.',
    ],
    'Angry': [
      'Walk fast for 10 minutes. Let your body burn it off.',
      'Cold water on your face and wrists.',
      'Write down what you are angry about. Do not send it to anyone.',
      'Do push-ups, squats, or anything physical until you feel the edge drop.',
      'Put on loud music. Scream along if you need to.',
    ],
    'Aroused': [
      'Set a 20-minute timer. Do literally anything else until it goes off.',
      'Get out of the room you are in. Change your physical environment.',
      'Do something physical. Walk, exercise, cold shower.',
      'Call or text your partner or a friend.',
      'Go outside. Fresh air and a change of scenery.',
    ],
    'Numb': [
      'Hold something cold. An ice cube or a cold glass.',
      'Step outside barefoot for 30 seconds. Feel the ground.',
      'Splash cold water on your face.',
      'Do 10 jumping jacks or star jumps. Shock the system gently.',
      'Put on a song that used to make you feel something.',
      'Eat something with a strong flavour. Lemon, chilli, mint.',
    ],
    'Rewarding Myself': [
      'You had a good day. Protect it. Choose a reward that matches your values.',
      'What would Future You thank you for doing right now?',
      'Go out for food. Treat yourself to something you actually enjoy.',
      'Call someone and share the good news.',
      'Write down what went well today. Savour it properly.',
    ],
    'Not sure': [
      'Go for a walk. Movement helps when you cannot name what you feel.',
      'Write down whatever comes to mind. No filter, just get it out.',
      'Call or text someone. Connection can help you figure out what you need.',
      'Do something physical. Walk, stretch, cold water on your face.',
      'Step outside for 2 minutes. A change of environment can bring clarity.',
    ],
  };

  void _selectEmotion(String emotion) {
    final prompt = InterceptPromptService.instance.getPromptForEmotion(emotion);
    final allSuggestions = _suggestions[emotion] ?? [];
    final shuffled = List<String>.from(allSuggestions)..shuffle(Random());
    setState(() {
      _selectedEmotion = emotion;
      _prompt = prompt;
      _pickedSuggestions = shuffled.take(2).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: _selectedEmotion == null
            ? _buildEmotionPhase(theme)
            : _buildPromptPhase(theme),
      ),
    );
  }

  Widget _buildEmotionPhase(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.white.withAlpha(15),
              border: Border.all(
                color: AppColors.white.withAlpha(60),
                width: 2,
              ),
            ),
            child: const Center(
              child: AnchorLogo(size: 36, color: AppColors.white),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'HOLD ON',
            style: theme.textTheme.displaySmall?.copyWith(
              color: AppColors.white,
              letterSpacing: 4,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (widget.domain.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${widget.domain} is blocked by ANCHORAGE',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.white.withAlpha(200),
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'How are you feeling right now?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.white.withAlpha(180),
            ),
          ),
          const SizedBox(height: 16),
          _buildEmotionGrid(theme),
        ],
      ),
    );
  }

  Widget _buildEmotionGrid(ThemeData theme) {
    final items = _emotions;
    final rows = <Widget>[];

    for (var i = 0; i < items.length; i += 2) {
      final left = items[i];
      final right = (i + 1 < items.length) ? items[i + 1] : null;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(child: _emotionButton(left, theme)),
              const SizedBox(width: 8),
              Expanded(
                child: right != null
                    ? _emotionButton(right, theme)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _emotionButton(String emotion, ThemeData theme) {
    final isNotSure = emotion == 'Not sure';
    return GestureDetector(
      onTap: () => _selectEmotion(emotion),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isNotSure
              ? AppColors.white.withAlpha(8)
              : AppColors.white.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isNotSure
                ? AppColors.white.withAlpha(40)
                : AppColors.white.withAlpha(25),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          emotion,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isNotSure
                ? AppColors.white.withAlpha(150)
                : AppColors.white.withAlpha(220),
          ),
        ),
      ),
    );
  }

  Widget _buildPromptPhase(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // ACT prompt card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white.withAlpha(12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.white.withAlpha(30)),
            ),
            child: Column(
              children: [
                Text(
                  _prompt!.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.seafoam,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _prompt!.body,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.white.withAlpha(180),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Suggestions
          if (_pickedSuggestions.isNotEmpty) ...[
            Text(
              'TRY THIS INSTEAD',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.white.withAlpha(130),
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            ..._pickedSuggestions.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.white.withAlpha(10),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppColors.white.withAlpha(20)),
                    ),
                    child: Text(
                      s,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.white.withAlpha(200),
                        height: 1.4,
                      ),
                    ),
                  ),
                )),
          ],

          const SizedBox(height: 12),

          // Start exercise button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.push('/exercises'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.seafoam,
                side: const BorderSide(color: AppColors.seafoam),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'START AN EXERCISE',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.seafoam,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Action buttons
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.seafoam,
                foregroundColor: AppColors.navy,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'STAY ANCHORED',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.navy,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.pushReplacement('/reflect'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.white,
                side: BorderSide(color: AppColors.white.withAlpha(80)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'REFLECT ON THIS MOMENT',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () async {
              final navigator = GoRouter.of(context);
              final confirmed = await showWhiteFlagConfirmation(
                context,
                blockedTarget: widget.domain,
              );
              if (!mounted) return;
              if (confirmed) navigator.pop();
            },
            icon:
                const Text('\u{1F3F3}', style: TextStyle(fontSize: 18)),
            label: Text(
              'White Flag',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.white.withAlpha(140),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
