import 'package:florid/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class OnboardingPrimaryButton extends StatelessWidget {
  const OnboardingPrimaryButton({
    super.key,
    required this.currentPage,
    required this.isFinishing,
    required this.canProceed,
    required this.onNext,
    required this.onStartSetup,
  });

  final int currentPage;
  final bool isFinishing;
  final bool canProceed;
  final VoidCallback onNext;
  final VoidCallback onStartSetup;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isRepoStep = currentPage == 2;
    final isEnabled = !isFinishing && canProceed;

    final onPressed = !isEnabled
        ? null
        : () {
            if (isRepoStep) {
              onStartSetup();
            } else {
              onNext();
            }
          };

    final label = isRepoStep
        ? localizations.start_setup
        : localizations.continue_text;

    final button = isRepoStep
        ? FilledButton(onPressed: onPressed, child: Text(label))
        : FilledButton.tonal(onPressed: onPressed, child: Text(label));

    return button;
  }
}
