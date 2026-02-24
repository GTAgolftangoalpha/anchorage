import 'dart:math';

import 'user_preferences_service.dart';

enum PromptCategory { defusion, valuesPrompt, urgeSurfing, presentMoment }

class InterceptPrompt {
  final PromptCategory category;
  final String title;
  final String body;

  const InterceptPrompt({
    required this.category,
    required this.title,
    required this.body,
  });
}

class InterceptPromptService {
  InterceptPromptService._();
  static final InterceptPromptService instance = InterceptPromptService._();

  final _random = Random();
  PromptCategory? _lastCategory;

  InterceptPrompt getPrompt() {
    final prefs = UserPreferencesService.instance;
    final name = prefs.firstName.isNotEmpty ? prefs.firstName : null;
    final values = prefs.values;

    // Pick a category different from the last one
    var categories = PromptCategory.values
        .where((c) => c != _lastCategory)
        .toList();

    // If values aren't set, exclude values category
    if (values.isEmpty) {
      categories =
          categories.where((c) => c != PromptCategory.valuesPrompt).toList();
    }

    if (categories.isEmpty) {
      categories = PromptCategory.values
          .where((c) => c != PromptCategory.valuesPrompt || values.isNotEmpty)
          .toList();
    }

    final category = categories[_random.nextInt(categories.length)];
    _lastCategory = category;

    final prompts = _getPrompts(category, name, values);
    return prompts[_random.nextInt(prompts.length)];
  }

  List<InterceptPrompt> _getPrompts(
    PromptCategory category,
    String? name,
    List<String> values,
  ) {
    final n = name ?? '';
    final hasName = n.isNotEmpty;

    switch (category) {
      case PromptCategory.defusion:
        return [
          InterceptPrompt(
            category: category,
            title: 'Notice the thought.',
            body: hasName
                ? "$n, you're having the thought that you need this right now. That's just a thought \u2014 not a command."
                : "You're having the thought that you need this right now. That's just a thought \u2014 not a command.",
          ),
          InterceptPrompt(
            category: category,
            title: 'Observe the urge.',
            body: hasName
                ? "Notice the urge, $n. You don't have to obey it."
                : "Notice the urge. You don't have to obey it.",
          ),
          InterceptPrompt(
            category: category,
            title: "It's just a story.",
            body:
                'Your mind is telling you a story right now. You get to choose whether to follow it.',
          ),
        ];
      case PromptCategory.valuesPrompt:
        final v1 = values.isNotEmpty ? values[0] : 'what matters';
        final v2 = values.length > 1 ? values[1] : 'your goals';
        final v3 = values.length > 2 ? values[2] : 'your future';
        return [
          InterceptPrompt(
            category: category,
            title: 'Remember your values.',
            body: hasName
                ? '$n, you said ${v1.toLowerCase()} matters to you. Does this move you closer to or further from that?'
                : 'You said ${v1.toLowerCase()} matters to you. Does this move you closer to or further from that?',
          ),
          InterceptPrompt(
            category: category,
            title: 'Who do you want to be?',
            body:
                'Think about ${v2.toLowerCase()} for a moment. What would that version of you do right now?',
          ),
          InterceptPrompt(
            category: category,
            title: 'Live your values.',
            body: hasName
                ? 'Your values are ${v1.toLowerCase()}, ${v2.toLowerCase()}, and ${v3.toLowerCase()}. This is a moment to live them, $n.'
                : 'Your values are ${v1.toLowerCase()}, ${v2.toLowerCase()}, and ${v3.toLowerCase()}. This is a moment to live them.',
          ),
        ];
      case PromptCategory.urgeSurfing:
        return [
          InterceptPrompt(
            category: category,
            title: 'Ride the wave.',
            body:
                "This urge will peak and pass \u2014 like a wave. You don't have to act on it.",
          ),
          InterceptPrompt(
            category: category,
            title: 'Breathe through it.',
            body: hasName
                ? 'Take three slow breaths, $n. The urge is already losing power.'
                : 'Take three slow breaths. The urge is already losing power.',
          ),
          InterceptPrompt(
            category: category,
            title: "You've survived every one.",
            body:
                "Urges last 15\u201320 minutes. You've survived every one so far.",
          ),
        ];
      case PromptCategory.presentMoment:
        return [
          InterceptPrompt(
            category: category,
            title: 'Name the feeling.',
            body:
                'What are you actually feeling right now \u2014 bored, stressed, lonely, tired? Name it.',
          ),
          InterceptPrompt(
            category: category,
            title: 'Pause and reflect.',
            body: hasName
                ? '$n, pause. What just happened in the last 10 minutes that brought you here?'
                : 'Pause. What just happened in the last 10 minutes that brought you here?',
          ),
          InterceptPrompt(
            category: category,
            title: 'Find the trigger.',
            body:
                "You're here because something triggered you. Can you identify what it was?",
          ),
        ];
    }
  }
}
