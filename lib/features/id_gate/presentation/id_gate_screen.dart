import 'dart:async';
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
import '../../../core/widgets/ant_button.dart';
import '../../id_verification/domain/id_validator.dart';
import '../id_gate_controller.dart';

class IdGateScreen extends ConsumerStatefulWidget {
  const IdGateScreen({super.key});

  @override
  ConsumerState<IdGateScreen> createState() => _IdGateScreenState();
}

enum _GateStage { prompt, scanning, success, failed, cooldown }

class _IdGateScreenState extends ConsumerState<IdGateScreen> {
  _GateStage _stage = _GateStage.prompt;
  final _validator = IdValidator();
  final _picker = ImagePicker();
  String? _errorMessage;
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  @override
  void dispose() {
    _validator.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _scan() async {
    final gate = ref.read(idGateControllerProvider.notifier);
    if (gate.isInCooldown) {
      _startCooldownTimer();
      setState(() => _stage = _GateStage.cooldown);
      return;
    }

    setState(() => _stage = _GateStage.scanning);
    gate.setVerifying();

    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
      );

      if (photo == null) {
        setState(() => _stage = _GateStage.prompt);
        return;
      }

      final imageFile = File(photo.path);
      const deviceSalt = 'antonine-study-device-salt';
      final result = await _validator.verify(imageFile, deviceSalt);

      if (await imageFile.exists()) await imageFile.delete();

      if (result.status == VerificationStatus.success) {
        await gate.markVerified();
        setState(() => _stage = _GateStage.success);
        await Future<void>.delayed(const Duration(milliseconds: 600));
        if (mounted) context.go(AppRoutes.home);
      } else if (result.combinedScore >= 0.55) {
        // Soft fail — auto-retry once
        setState(() => _errorMessage = 'Hold steady, trying again...');
        await Future<void>.delayed(const Duration(milliseconds: 800));
        // The user would need to scan again
        setState(() {
          _stage = _GateStage.failed;
          _errorMessage = result.errorMessage;
        });
        gate.recordFailure();
        if (gate.isInCooldown) {
          _startCooldownTimer();
          setState(() => _stage = _GateStage.cooldown);
        }
      } else {
        setState(() {
          _stage = _GateStage.failed;
          _errorMessage = result.errorMessage;
        });
        gate.recordFailure();
        if (gate.isInCooldown) {
          _startCooldownTimer();
          setState(() => _stage = _GateStage.cooldown);
        }
      }
    } catch (e) {
      setState(() {
        _stage = _GateStage.failed;
        _errorMessage = 'Camera error: $e';
      });
    }
  }

  void _startCooldownTimer() {
    final gate = ref.read(idGateControllerProvider.notifier);
    _cooldownSeconds = gate.cooldownSecondsRemaining;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _cooldownSeconds = gate.cooldownSecondsRemaining;
        if (_cooldownSeconds <= 0) {
          timer.cancel();
          _stage = _GateStage.prompt;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: switch (_stage) {
            _GateStage.prompt => _buildPrompt(theme),
            _GateStage.scanning => _buildScanning(theme),
            _GateStage.success => _buildSuccess(theme),
            _GateStage.failed => _buildFailed(theme),
            _GateStage.cooldown => _buildCooldown(theme),
          },
        ),
      ),
    );
  }

  Widget _buildPrompt(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(flex: 2),
        Icon(
          PhosphorIconsBold.shieldCheck,
          size: 72,
          color: AppColors.gold,
        )
            .animate()
            .fadeIn(duration: 500.ms)
            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Welcome back.',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Quick ID check to keep your account secure.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
        const SizedBox(height: AppSpacing.xxxl),
        // Animated card outline guide
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderRadiusLg,
            border: Border.all(color: AppColors.gold, width: 2),
            color: AppColors.gold.withValues(alpha: 0.05),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  PhosphorIconsRegular.identificationCard,
                  size: 48,
                  color: AppColors.gold,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Position your student ID here',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .shimmer(duration: 2000.ms, color: AppColors.gold.withValues(alpha: 0.1)),
        const Spacer(flex: 3),
        AntButton(
          label: 'Scan Student ID',
          onPressed: _scan,
          icon: PhosphorIconsBold.camera,
          expand: true,
          size: AntButtonSize.large,
        ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
        const SizedBox(height: AppSpacing.md),
        TextButton(
          onPressed: () {
            // TODO(user): implement help / sign-out flow
          },
          child: Text(
            'Need help?',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildScanning(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.gold,
            ),
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: AppSpacing.xl),
          Text('Verifying...', style: theme.textTheme.titleMedium),
          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _errorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.gold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              PhosphorIconsBold.checkCircle,
              size: 48,
              color: AppColors.gold,
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(
                  begin: const Offset(0.5, 0.5), end: const Offset(1, 1)),
          const SizedBox(height: AppSpacing.xl),
          Text(
            "You're in. See you tomorrow.",
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
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
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _errorMessage ?? 'Could not verify your student ID.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          AntButton(
            label: 'Try Again',
            onPressed: () => setState(() => _stage = _GateStage.prompt),
            expand: true,
            size: AntButtonSize.large,
          ),
        ],
      ),
    );
  }

  Widget _buildCooldown(ThemeData theme) {
    final minutes = _cooldownSeconds ~/ 60;
    final seconds = _cooldownSeconds % 60;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            PhosphorIconsBold.timer,
            size: 64,
            color: AppColors.warning,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Too many attempts',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Please wait before trying again.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: theme.textTheme.displaySmall?.copyWith(
              fontFamily: 'JetBrains Mono',
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}
