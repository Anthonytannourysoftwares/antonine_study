import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

enum AppState {
  splash,
  onboarding,
  idVerification,
  profileSetup,
  home,
}

final appStateProvider =
    StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier();
});

class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(AppState.splash);

  Future<AppState> determineInitialRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final onboarded = prefs.getBool(AppConstants.keyOnboardingComplete) ?? false;
    final verified = prefs.getBool(AppConstants.keyIdVerified) ?? false;
    final profiled = prefs.getBool(AppConstants.keyProfileComplete) ?? false;

    if (!onboarded) return AppState.onboarding;
    if (!verified) return AppState.idVerification;
    if (!profiled) return AppState.profileSetup;
    return AppState.home;
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyOnboardingComplete, true);
    state = AppState.idVerification;
  }

  Future<void> completeIdVerification(String firstName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyIdVerified, true);
    await prefs.setString(AppConstants.keyStudentFirstName, firstName);
    state = AppState.profileSetup;
  }

  Future<void> completeProfileSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyProfileComplete, true);
    state = AppState.home;
  }
}
