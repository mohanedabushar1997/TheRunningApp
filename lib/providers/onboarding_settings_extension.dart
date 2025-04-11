import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/settings_provider.dart';
import '../../screens/onboarding/onboarding_screen.dart';

/// Extension for SettingsProvider to handle onboarding-related settings
extension OnboardingSettingsExtension on SettingsProvider {
  // Onboarding settings
  bool get onboardingCompleted => _preferences?.getBool('onboarding_completed') ?? false;
  
  // User profile settings
  Map<String, dynamic> get userProfileMap {
    final name = _preferences?.getString('user_name') ?? '';
    final age = _preferences?.getInt('user_age') ?? 30;
    final weight = _preferences?.getDouble('user_weight') ?? 70.0;
    final height = _preferences?.getDouble('user_height') ?? 170.0;
    final gender = _preferences?.getInt('user_gender') ?? 2;
    final fitnessLevel = _preferences?.getInt('user_fitness_level') ?? 0;
    final workoutGoal = _preferences?.getInt('user_workout_goal') ?? 3;
    
    return {
      'name': name,
      'age': age,
      'weight': weight,
      'height': height,
      'gender': gender,
      'fitnessLevel': fitnessLevel,
      'workoutGoal': workoutGoal,
    };
  }

  // Setters for onboarding settings
  Future<void> setOnboardingCompleted(bool value) async {
    await _preferences?.setBool('onboarding_completed', value);
    notifyListeners();
  }

  // Setter for user profile
  Future<void> setUserProfile(UserProfile userProfile) async {
    await _preferences?.setString('user_name', userProfile.name);
    await _preferences?.setInt('user_age', userProfile.age);
    await _preferences?.setDouble('user_weight', userProfile.weight);
    await _preferences?.setDouble('user_height', userProfile.height);
    await _preferences?.setInt('user_gender', userProfile.gender.index);
    await _preferences?.setInt('user_fitness_level', userProfile.fitnessLevel.index);
    await _preferences?.setInt('user_workout_goal', userProfile.workoutGoal.index);
    notifyListeners();
  }
  
  // Check if onboarding is needed and navigate if necessary
  void checkAndShowOnboarding(BuildContext context) {
    if (!onboardingCompleted) {
      // Navigate to onboarding screen
      Future.delayed(Duration.zero, () {
        Navigator.of(context).pushReplacementNamed(OnboardingScreen.routeName);
      });
    }
  }
}
