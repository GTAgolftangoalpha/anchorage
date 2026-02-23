import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

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
    ('💪', 'Strong'),
    ('😌', 'Calm'),
    ('😤', 'Frustrated'),
    ('😰', 'Anxious'),
    ('😔', 'Down'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    // TODO: persist to Firestore
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('placeholder text'),
        backgroundColor: AppColors.navy,
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
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
                        color: isSelected ? AppColors.navy : AppColors.lightGray,
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

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('SAVE REFLECTION'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
