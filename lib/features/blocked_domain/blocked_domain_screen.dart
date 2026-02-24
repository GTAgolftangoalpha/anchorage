import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../services/intercept_prompt_service.dart';
import '../../shared/widgets/anchor_logo.dart';

class BlockedDomainScreen extends StatefulWidget {
  final String domain;

  const BlockedDomainScreen({super.key, required this.domain});

  @override
  State<BlockedDomainScreen> createState() => _BlockedDomainScreenState();
}

class _BlockedDomainScreenState extends State<BlockedDomainScreen> {
  late final InterceptPrompt _prompt;

  @override
  void initState() {
    super.initState();
    _prompt = InterceptPromptService.instance.getPrompt();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white.withAlpha(15),
                  border: Border.all(
                    color: AppColors.white.withAlpha(60),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: AnchorLogo(size: 40, color: AppColors.white),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'This site is blocked.',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              if (widget.domain.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '${widget.domain} is blocked by ANCHORAGE.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.white.withAlpha(200),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 32),

              // ACT prompt card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white.withAlpha(15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.white.withAlpha(30)),
                ),
                child: Column(
                  children: [
                    Text(
                      _prompt.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.seafoam,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _prompt.body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.white.withAlpha(180),
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
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
                    'GO BACK',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.navy,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => context.push('/sos'),
                icon: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFFFAAAA),
                  size: 18,
                ),
                label: Text(
                  'Get Support',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFFFAAAA),
                    letterSpacing: 0.5,
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
