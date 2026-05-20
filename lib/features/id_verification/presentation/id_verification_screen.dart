import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_state_provider.dart';
import '../../../core/widgets/ant_button.dart';
import '../../guide/presentation/walkthrough_screen.dart';
import '../domain/id_validator.dart';

class IdVerificationScreen extends ConsumerStatefulWidget {
  const IdVerificationScreen({super.key});

  @override
  ConsumerState<IdVerificationScreen> createState() =>
      _IdVerificationScreenState();
}

enum _VerifyStage { intro, capturing, processing, success, failed }

class _IdVerificationScreenState extends ConsumerState<IdVerificationScreen> {
  _VerifyStage _stage = _VerifyStage.intro;
  final _validator = IdValidator();
  final _picker = ImagePicker();
  VerificationResult? _result;
  String? _errorMessage;

  Future<void> _captureAndVerify() async {
    setState(() => _stage = _VerifyStage.capturing);

    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
      );

      if (photo == null) {
        setState(() => _stage = _VerifyStage.intro);
        return;
      }

      setState(() => _stage = _VerifyStage.processing);

      final imageFile = File(photo.path);
      // Use a device-specific salt; in production derive from secure storage
      const deviceSalt = 'antonine-study-device-salt';
      final result = await _validator.verify(imageFile, deviceSalt);

      setState(() {
        _result = result;
        if (result.status == VerificationStatus.success) {
          _stage = _VerifyStage.success;
        } else {
          _stage = _VerifyStage.failed;
          _errorMessage = result.errorMessage;
        }
      });

      // Clean up: don't keep the ID image on disk
      if (await imageFile.exists()) {
        await imageFile.delete();
      }
    } catch (e) {
      setState(() {
        _stage = _VerifyStage.failed;
        _errorMessage = 'Camera error: $e';
      });
    }
  }

  Future<void> _onSuccess() async {
    final name = _result?.studentName ?? 'Student';
    final firstName = name.split(' ').first;
    await ref.read(appStateProvider.notifier).completeIdVerification(firstName);
    if (!mounted) return;
    // Check if walkthrough has been seen
    final seen = await WalkthroughScreen.hasBeenSeen();
    if (!mounted) return;
    if (!seen) {
      context.go(AppRoutes.walkthrough);
    } else {
      context.go(AppRoutes.profileSetup);
    }
  }

  void _showManualEntry() {
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

  @override
  void dispose() {
    _validator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: switch (_stage) {
            _VerifyStage.intro => _buildIntro(theme),
            _VerifyStage.capturing => _buildIntro(theme),
            _VerifyStage.processing => _buildProcessing(theme),
            _VerifyStage.success => _buildSuccess(theme),
            _VerifyStage.failed => _buildFailed(theme),
          },
        ),
      ),
    );
  }

  Widget _buildIntro(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xxxl),
        Icon(
          PhosphorIconsBold.identificationCard,
          size: 64,
          color: theme.colorScheme.primary,
        )
            .animate()
            .fadeIn(duration: 400.ms)
            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Verify Your Identity',
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Scan your Antonine University student ID to get started. '
          'Your data stays on this device.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
        const SizedBox(height: AppSpacing.xxl),
        // ID card frame preview
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderRadiusLg,
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
              width: 2,
            ),
            color: theme.colorScheme.surfaceContainerLow,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  PhosphorIconsRegular.creditCard,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Align your ID card inside the frame',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
        const Spacer(),
        AntButton(
          label: 'Scan Student ID',
          onPressed: _captureAndVerify,
          icon: PhosphorIconsBold.camera,
          expand: true,
          size: AntButtonSize.large,
        ),
        const SizedBox(height: AppSpacing.md),
        AntButton(
          label: 'Enter Manually',
          onPressed: _showManualEntry,
          variant: AntButtonVariant.outlined,
          expand: true,
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  Widget _buildProcessing(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: theme.colorScheme.primary,
            ),
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Verifying your ID...',
            style: theme.textTheme.titleMedium,
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Running OCR and classification',
            style: theme.textTheme.bodySmall,
          ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
        ],
      ),
    );
  }

  Widget _buildSuccess(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: AppColors.tertiaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              PhosphorIconsBold.checkCircle,
              size: 48,
              color: AppColors.tertiary,
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1)),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Welcome to University Antonine',
            style: theme.textTheme.headlineSmall,
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          if (_result?.studentName != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              _result!.studentName!,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Confidence: ${(_result!.combinedScore * 100).round()}%',
            style: theme.textTheme.labelSmall,
          ).animate().fadeIn(delay: 400.ms, duration: 300.ms),
          const SizedBox(height: AppSpacing.xxl),
          AntButton(
            label: 'Continue',
            onPressed: _onSuccess,
            expand: true,
            size: AntButtonSize.large,
          ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
        ],
      ),
    );
  }

  Widget _buildFailed(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: AppColors.errorContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              PhosphorIconsBold.warningCircle,
              size: 48,
              color: AppColors.error,
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Verification Failed',
            style: theme.textTheme.headlineSmall,
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _errorMessage ?? 'Could not verify your student ID.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: AppSpacing.xxl),
          AntButton(
            label: 'Try Again',
            onPressed: () {
              setState(() => _stage = _VerifyStage.intro);
            },
            expand: true,
            size: AntButtonSize.large,
          ),
          const SizedBox(height: AppSpacing.md),
          AntButton(
            label: 'Enter Manually Instead',
            onPressed: _showManualEntry,
            variant: AntButtonVariant.text,
            expand: true,
          ),
        ],
      ),
    );
  }
}
