import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum IdGateState { verified, expired, verifying }

const _storageKey = 'last_id_verified_at';
const _gateHours = 24;

final idGateControllerProvider =
    StateNotifierProvider<IdGateController, IdGateState>((ref) {
  return IdGateController();
});

class IdGateController extends StateNotifier<IdGateState> {
  IdGateController() : super(IdGateState.expired) {
    checkGate();
  }

  final _storage = const FlutterSecureStorage();
  int _failedAttempts = 0;
  DateTime? _cooldownUntil;
  DateTime? _lastVerifiedAt;

  /// Hours remaining until gate expires. Returns 0 if expired.
  int get hoursRemaining {
    if (_lastVerifiedAt == null) return 0;
    final expiry = _lastVerifiedAt!.add(const Duration(hours: _gateHours));
    final remaining = expiry.difference(DateTime.now()).inHours;
    return remaining.clamp(0, _gateHours);
  }

  /// Whether the user is in cooldown from too many failed attempts.
  bool get isInCooldown =>
      _cooldownUntil != null && DateTime.now().isBefore(_cooldownUntil!);

  /// Seconds remaining in cooldown.
  int get cooldownSecondsRemaining {
    if (_cooldownUntil == null) return 0;
    return _cooldownUntil!.difference(DateTime.now()).inSeconds.clamp(0, 300);
  }

  /// Check secure storage for last verification timestamp.
  Future<void> checkGate() async {
    final stored = await _storage.read(key: _storageKey);
    if (stored != null) {
      _lastVerifiedAt = DateTime.tryParse(stored);
      if (_lastVerifiedAt != null) {
        final elapsed = DateTime.now().difference(_lastVerifiedAt!);
        if (elapsed.inHours < _gateHours) {
          state = IdGateState.verified;
          return;
        }
      }
    }
    state = IdGateState.expired;
  }

  /// Called when ID verification succeeds.
  Future<void> markVerified() async {
    _lastVerifiedAt = DateTime.now();
    await _storage.write(
      key: _storageKey,
      value: _lastVerifiedAt!.toIso8601String(),
    );
    _failedAttempts = 0;
    _cooldownUntil = null;
    state = IdGateState.verified;
  }

  /// Called when a scan attempt fails.
  void recordFailure() {
    _failedAttempts++;
    if (_failedAttempts >= 3) {
      _cooldownUntil = DateTime.now().add(const Duration(minutes: 5));
    }
  }

  /// Force expire (for testing/re-scan).
  Future<void> forceExpire() async {
    await _storage.delete(key: _storageKey);
    _lastVerifiedAt = null;
    state = IdGateState.expired;
  }

  void setVerifying() => state = IdGateState.verifying;
}
