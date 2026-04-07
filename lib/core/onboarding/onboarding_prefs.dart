import 'package:shared_preferences/shared_preferences.dart';

const String kOnboardingCompletedKey = 'onboarding_completed_v1';

Future<bool> isOnboardingCompleted() async {
  final p = await SharedPreferences.getInstance();
  return p.getBool(kOnboardingCompletedKey) ?? false;
}

Future<void> setOnboardingCompleted() async {
  final p = await SharedPreferences.getInstance();
  await p.setBool(kOnboardingCompletedKey, true);
}
