import 'package:flutter_test/flutter_test.dart';
import 'package:anchorage/services/intercept_prompt_service.dart';

void main() {
  group('InterceptPromptService', () {
    late InterceptPromptService service;

    setUp(() {
      service = InterceptPromptService.instance;
    });

    group('getPromptForEmotion() returns non-empty prompt for each emotion',
        () {
      const emotions = [
        'bored',
        'stressed',
        'lonely',
        'tired',
        'anxious',
        'down',
        'angry',
        'aroused',
        'numb',
        'rewarding',
      ];

      for (final emotion in emotions) {
        test('$emotion returns a non-empty prompt', () {
          final prompt = service.getPromptForEmotion(emotion);
          expect(prompt.title, isNotEmpty,
              reason: '$emotion should produce a non-empty title');
          expect(prompt.body, isNotEmpty,
              reason: '$emotion should produce a non-empty body');
        });
      }
    });

    group('not_sure / unsure returns values clarification prompt', () {
      test('not_sure returns a general values clarification prompt', () {
        final prompt = service.getPromptForEmotion('not_sure');
        expect(prompt.title, isNotEmpty);
        expect(prompt.body, isNotEmpty);
        // The not_sure opening is "You paused to check in. That matters."
        expect(prompt.title, 'You paused to check in. That matters.');
      });

      test('not sure (with space) returns same prompt type', () {
        final prompt = service.getPromptForEmotion('not sure');
        expect(prompt.title, 'You paused to check in. That matters.');
        expect(prompt.body, isNotEmpty);
      });
    });

    group('emotion-to-opening mappings', () {
      test('bored maps to Boredom opening', () {
        final prompt = service.getPromptForEmotion('bored');
        expect(prompt.title, 'Boredom brought you here.');
      });

      test('stressed maps to Stress opening', () {
        final prompt = service.getPromptForEmotion('stressed');
        expect(prompt.title, 'Stress brought you here.');
      });

      test('lonely maps to Loneliness opening', () {
        final prompt = service.getPromptForEmotion('lonely');
        expect(prompt.title, 'Loneliness brought you here.');
      });

      test('tired maps to Being tired opening', () {
        final prompt = service.getPromptForEmotion('tired');
        expect(prompt.title, 'Being tired brought you here.');
      });

      test('anxious maps to Anxiety opening', () {
        final prompt = service.getPromptForEmotion('anxious');
        expect(prompt.title, 'Anxiety brought you here.');
      });

      test('down maps to Feeling down opening', () {
        final prompt = service.getPromptForEmotion('down');
        expect(prompt.title, 'Feeling down brought you here.');
      });

      test('angry maps to Anger opening', () {
        final prompt = service.getPromptForEmotion('angry');
        expect(prompt.title, 'Anger brought you here.');
      });

      test('aroused maps to noticed feeling aroused', () {
        final prompt = service.getPromptForEmotion('aroused');
        expect(prompt.title, 'You noticed feeling aroused.');
      });

      test('numb maps to noticed feeling numb', () {
        final prompt = service.getPromptForEmotion('numb');
        expect(prompt.title, 'You noticed feeling numb.');
      });

      test('rewarding maps to desire to reward yourself', () {
        final prompt = service.getPromptForEmotion('rewarding');
        expect(prompt.title, 'You noticed the desire to reward yourself.');
      });

      test('rewarding myself also maps correctly', () {
        final prompt = service.getPromptForEmotion('rewarding myself');
        expect(prompt.title, 'You noticed the desire to reward yourself.');
      });
    });

    group('body phrase pools', () {
      test('not_sure body comes from reduced pool', () {
        // The not_sure pool has only 2 phrases
        final validBodies = {
          'You can choose what happens next.',
          'This feeling will pass. What matters to you right now?',
        };
        // Run multiple times to increase confidence
        for (var i = 0; i < 20; i++) {
          final prompt = service.getPromptForEmotion('not_sure');
          expect(validBodies, contains(prompt.body),
              reason: 'not_sure body should come from reduced pool');
        }
      });

      test('known emotions use full phrase pool', () {
        final validBodies = {
          'You can choose what happens next.',
          "Notice it. You don't have to follow it.",
          'This feeling will pass. What matters to you right now?',
          'There is space between this feeling and what you do next.',
          "You don't have to act on it.",
        };
        for (var i = 0; i < 30; i++) {
          final prompt = service.getPromptForEmotion('bored');
          expect(validBodies, contains(prompt.body),
              reason: 'bored body should come from full pool');
        }
      });
    });

    group('getPrompt() (no emotion)', () {
      test('returns a valid prompt', () {
        final prompt = service.getPrompt();
        expect(prompt.title, 'You paused to check in. That matters.');
        expect(prompt.body, isNotEmpty);
      });
    });

    group('case insensitivity', () {
      test('BORED maps same as bored', () {
        final prompt = service.getPromptForEmotion('BORED');
        expect(prompt.title, 'Boredom brought you here.');
      });

      test('Stressed maps same as stressed', () {
        final prompt = service.getPromptForEmotion('Stressed');
        expect(prompt.title, 'Stress brought you here.');
      });
    });
  });
}
