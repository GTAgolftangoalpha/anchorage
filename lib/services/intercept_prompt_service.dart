import 'dart:math';

class InterceptPrompt {
  final String title;
  final String body;

  const InterceptPrompt({
    required this.title,
    required this.body,
  });
}

class InterceptPromptService {
  InterceptPromptService._();
  static final InterceptPromptService instance = InterceptPromptService._();

  final _random = Random();

  static const _fullPhrasePool = [
    'You can choose what happens next.',
    'Notice it. You don\'t have to follow it.',
    'This feeling will pass. What matters to you right now?',
    'There is space between this feeling and what you do next.',
    'You don\'t have to act on it.',
  ];

  static const _notSurePhrasePool = [
    'You can choose what happens next.',
    'This feeling will pass. What matters to you right now?',
  ];

  /// Emotion-to-opening-line mappings.
  static const Map<String, String> _emotionOpenings = {
    'bored': 'Boredom brought you here.',
    'stressed': 'Stress brought you here.',
    'lonely': 'Loneliness brought you here.',
    'tired': 'Being tired brought you here.',
    'anxious': 'Anxiety brought you here.',
    'down': 'Feeling down brought you here.',
    'angry': 'Anger brought you here.',
    'aroused': 'You noticed feeling aroused.',
    'numb': 'You noticed feeling numb.',
    'rewarding': 'You noticed the desire to reward yourself.',
    'rewarding myself': 'You noticed the desire to reward yourself.',
    'not_sure': 'You paused to check in. That matters.',
    'not sure': 'You paused to check in. That matters.',
  };

  /// Get a prompt matched to the given emotional state.
  InterceptPrompt getPromptForEmotion(String emotion) {
    final lower = emotion.toLowerCase();
    final normalised = lower.replaceAll(' ', '_');

    final opening = _emotionOpenings[lower] ??
        _emotionOpenings[normalised] ??
        'You paused to check in. That matters.';

    final isNotSure = normalised == 'not_sure';
    final pool = isNotSure ? _notSurePhrasePool : _fullPhrasePool;
    final phrase = pool[_random.nextInt(pool.length)];

    return InterceptPrompt(
      title: opening,
      body: phrase,
    );
  }

  /// Get a random prompt (no emotion context).
  InterceptPrompt getPrompt() {
    final phrase = _fullPhrasePool[_random.nextInt(_fullPhrasePool.length)];
    return InterceptPrompt(
      title: 'You paused to check in. That matters.',
      body: phrase,
    );
  }
}
