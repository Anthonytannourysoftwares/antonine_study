import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_state_provider.dart';
import '../../../core/widgets/ant_button.dart';

class IdVerificationScreen extends ConsumerWidget {
  const IdVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxxl),
              Icon(
                PhosphorIconsBold.identificationCard,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Verify Your Identity',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Scan your Antonine University student ID to get started. Your data stays on this device.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              // Phase 2 will implement full camera + OCR + classifier
              // For now, manual entry fallback
              AntButton(
                label: 'Scan Student ID',
                onPressed: () {
                  // Phase 2: Camera capture + ML pipeline
                  _showManualEntry(context, ref);
                },
                icon: PhosphorIconsBold.camera,
                expand: true,
                size: AntButtonSize.large,
              ),
              const SizedBox(height: AppSpacing.md),
              AntButton(
                label: 'Enter Manually',
                onPressed: () => _showManualEntry(context, ref),
                variant: AntButtonVariant.outlined,
                expand: true,
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  void _showManualEntry(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
            MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Manual Entry',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Your account will be flagged for review.',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xl),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  hintText: 'Enter your first name',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: AppSpacing.xl),
              AntButton(
                label: 'Continue',
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;
                  Navigator.of(ctx).pop();
                  ref
                      .read(appStateProvider.notifier)
                      .completeIdVerification(name);
                  context.go(AppRoutes.profileSetup);
                },
                expand: true,
              ),
            ],
          ),
        );
      },
    );
  }
}
