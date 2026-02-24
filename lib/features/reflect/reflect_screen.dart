import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../services/reflect_service.dart';
import '../../services/user_preferences_service.dart';

/// Reflection / journaling screen shown after an intercept or on demand.
class ReflectScreen extends StatefulWidget {
  const ReflectScreen({super.key});

  @override
  State<ReflectScreen> createState() => _ReflectScreenState();
}

class _ReflectScreenState extends State<ReflectScreen> {
  final _controller = TextEditingController();
  String? _selectedMood;

  static const _moods = [
    ('\uD83D\uDCAA', 'Strong'),
    ('\uD83D\uDE0C', 'Calm'),
    ('\uD83D\uDE24', 'Frustrated'),
    ('\uD83D\uDE30', 'Anxious'),
    ('\uD83D\uDE14', 'Down'),
  ];

  late final List<String> _userValues;
  late final Map<String, String> _valuesAlignment;

  @override
  void initState() {
    super.initState();
    _userValues = UserPreferencesService.instance.values;
    _valuesAlignment = {
      for (final v in _userValues) v: '',
    };
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _saving = false;

  Future<void> _save() async {
    if (_selectedMood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Select how you're feeling first."),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    // Build alignment map with only filled-in values
    final alignment = <String, String>{};
    for (final entry in _valuesAlignment.entries) {
      if (entry.value.isNotEmpty) {
        alignment[entry.key] = entry.value;
      }
    }

    await ReflectService.instance.addEntry(
      mood: _selectedMood!,
      journal: _controller.text.trim(),
      valuesAlignment: alignment,
    );
    if (!mounted) return;
    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reflection saved. Stay anchored.'),
        backgroundColor: AppColors.success,
      ),
    );
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) context.go('/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('REFLECT'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: const [],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How are you feeling?',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),

              // Mood selector
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _moods.map((mood) {
                  final isSelected = _selectedMood == mood.$2;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedMood = mood.$2),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? AppColors.navy : AppColors.lightGray,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.navy
                              : AppColors.midGray,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            mood.$1,
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            mood.$2,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isSelected
                                  ? AppColors.white
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              Text('Write it out', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'What triggered this moment? What are you grateful for right now?',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _controller,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText:
                      'I noticed I was feeling... I chose to stay anchored because...',
                ),
              ),

              // Values alignment section
              if (_userValues.isNotEmpty) ...[
                const SizedBox(height: 32),
                Text(
                  'How aligned were your actions today with your values?',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                ..._userValues.map((value) => _ValueAlignmentRow(
                      value: value,
                      selected: _valuesAlignment[value] ?? '',
                      onSelect: (alignment) {
                        setState(() {
                          _valuesAlignment[value] = alignment;
                        });
                      },
                    )),
              ],

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Text('SAVE REFLECTION'),
                ),
              ),

              const SizedBox(height: 24),

              Center(
                child: TextButton(
                  onPressed: () => context.push('/relapse-log'),
                  child: Text(
                    'Had a setback? Log it here \u2192',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValueAlignmentRow extends StatelessWidget {
  final String value;
  final String selected;
  final ValueChanged<String> onSelect;

  static const _options = ['Not aligned', 'Somewhat', 'Fully aligned'];

  const _ValueAlignmentRow({
    required this.value,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: _options.map((option) {
              final isSelected = selected == option;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: option != _options.last ? 8 : 0,
                  ),
                  child: GestureDetector(
                    onTap: () => onSelect(option),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.navy
                            : AppColors.lightGray,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.navy
                              : AppColors.midGray,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          option,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isSelected
                                ? AppColors.white
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
