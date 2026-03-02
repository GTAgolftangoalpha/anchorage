import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../psychoeducation/psychoeducation_cards.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('LEARN')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Short reads on the science behind change. No jargon.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            const PsychoeducationSection(),
          ],
        ),
      ),
    );
  }
}
