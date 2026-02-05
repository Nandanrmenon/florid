import 'package:flutter/material.dart';

class OnboardingPrimaryButton extends StatelessWidget {
  const OnboardingPrimaryButton({
    super.key,
    required this.currentPage,
    required this.isFinishing,
    required this.canProceedFromRepos,
    required this.onNext,
    required this.onStartSetup,
  });

  final int currentPage;
  final bool isFinishing;
  final bool canProceedFromRepos;
  final VoidCallback onNext;
  final VoidCallback onStartSetup;

  @override
  Widget build(BuildContext context) {
    final isRepoStep = currentPage == 2;
    final isEnabled = !isFinishing && (!isRepoStep || canProceedFromRepos);

    final onPressed = !isEnabled
        ? null
        : () {
            if (isRepoStep) {
              onStartSetup();
            } else {
              onNext();
            }
          };

    final label = isRepoStep ? 'Start Setup' : 'Continue';

    final button = isRepoStep
        ? FilledButton(onPressed: onPressed, child: Text(label))
        : FilledButton.tonal(onPressed: onPressed, child: Text(label));

    return button;
  }
}
