import 'package:flutter/material.dart'; // Added for Icons
import 'package:shared_preferences/shared_preferences.dart';
import '../models/achievement.dart';
// Use the correct path for NotificationService
import '../../device/notifications/notification_service.dart';

/// A service for managing achievements in the app
class AchievementService {
  // Singleton pattern
  static final AchievementService _instance = AchievementService._internal();
  factory AchievementService() => _instance;
  AchievementService._internal();

  // Store predefined achievements (immutable)
  final List<Achievement> _predefinedAchievements = [];
  // Store unlocked dates (achievement ID -> DateTime)
  final Map<String, DateTime> _unlockedDates = {};

  final NotificationService _notificationService = NotificationService();
  bool _initialized = false;

  /// Initialize the achievement service
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize notification service
    // Initialize notification service
    // Call the static initialize method directly on the class
    // Note: We don't have access to the navigatorKey here, so passing null.
    // This might need adjustment if notification taps require navigation.
    await NotificationService.initialize(navKey: null);

    // Create predefined achievements
    _createPredefinedAchievements();

    // Load unlocked achievements from preferences
    await _loadUnlockedAchievements();

    _initialized = true;
  }

  /// Create predefined achievements
  void _createPredefinedAchievements() {
    // Using placeholder Icons, replace with appropriate ones
    _predefinedAchievements.addAll([
      // Distance achievements (threshold in meters)
      const Achievement(
        id: 'distance_1km',
        name: 'First Steps',
        description: 'Complete a 1 km workout',
        icon: Icons.directions_run, // Placeholder
        type: AchievementType.distanceSingle,
        threshold: 1000,
      ),
      const Achievement(
        id: 'distance_5km',
        name: 'Getting Started',
        description: 'Complete a 5 km workout',
        icon: Icons.directions_run, // Placeholder
        type: AchievementType.distanceSingle,
        threshold: 5000,
      ),
      const Achievement(
        id: 'distance_10km',
        name: 'Distance Runner',
        description: 'Complete a 10 km workout',
        icon: Icons.emoji_events_outlined, // Placeholder
        type: AchievementType.distanceSingle,
        threshold: 10000,
      ),
      const Achievement(
        id: 'distance_21km',
        name: 'Half Marathon',
        description: 'Complete a 21.1 km workout',
        icon: Icons.military_tech_outlined, // Placeholder
        type: AchievementType.distanceSingle,
        threshold: 21097.5,
      ),
      const Achievement(
        id: 'distance_42km',
        name: 'Marathon',
        description: 'Complete a 42.2 km workout',
        icon: Icons.military_tech, // Placeholder
        type: AchievementType.distanceSingle,
        threshold: 42195,
      ),
      const Achievement(
        id: 'distance_total_100km', // Changed ID for clarity
        name: '100 km Club',
        description: 'Run a total of 100 km',
        icon: Icons.social_distance, // Placeholder
        type: AchievementType.distanceTotal,
        threshold: 100000,
      ),

      // Workout count achievements
      const Achievement(
        id: 'workouts_1',
        name: 'First Workout',
        description: 'Complete your first workout',
        icon: Icons.fitness_center, // Placeholder
        type: AchievementType.countWorkouts,
        threshold: 1,
      ),
      const Achievement(
        id: 'workouts_10',
        name: 'Regular Runner',
        description: 'Complete 10 workouts',
        icon: Icons.fitness_center, // Placeholder
        type: AchievementType.countWorkouts,
        threshold: 10,
      ),
      const Achievement(
        id: 'workouts_25',
        name: 'Dedicated Runner',
        description: 'Complete 25 workouts',
        icon: Icons.fitness_center, // Placeholder
        type: AchievementType.countWorkouts,
        threshold: 25,
      ),
      const Achievement(
        id: 'workouts_50',
        name: 'Fitness Enthusiast',
        description: 'Complete 50 workouts',
        icon: Icons.fitness_center, // Placeholder
        type: AchievementType.countWorkouts,
        threshold: 50,
      ),
      const Achievement(
        id: 'workouts_100',
        name: 'Century Club',
        description: 'Complete 100 workouts',
        icon: Icons.fitness_center, // Placeholder
        type: AchievementType.countWorkouts,
        threshold: 100,
      ),
      // Removed workouts_365 as it might overlap with streak

      // Streak achievements
      const Achievement(
        id: 'streak_3',
        name: 'Getting Started Streak',
        description: 'Maintain a 3-day workout streak',
        icon: Icons.local_fire_department, // Placeholder
        type: AchievementType.streakConsecutiveDays,
        threshold: 3,
      ),
      const Achievement(
        id: 'streak_7',
        name: 'Weekly Warrior',
        description: 'Maintain a 7-day workout streak',
        icon: Icons.local_fire_department, // Placeholder
        type: AchievementType.streakConsecutiveDays,
        threshold: 7,
      ),
      const Achievement(
        id: 'streak_14',
        name: 'Fortnight Fighter',
        description: 'Maintain a 14-day workout streak',
        icon: Icons.local_fire_department, // Placeholder
        type: AchievementType.streakConsecutiveDays,
        threshold: 14,
      ),
      const Achievement(
        id: 'streak_30',
        name: 'Monthly Master',
        description: 'Maintain a 30-day workout streak',
        icon: Icons.local_fire_department, // Placeholder
        type: AchievementType.streakConsecutiveDays,
        threshold: 30,
      ),
      // Removed higher streaks for brevity

      // Pace achievements (threshold in seconds per km, lower is better)
      // Note: The original service used speed (km/h), model uses pace. Adjusting.
      const Achievement(
        id: 'pace_10min_km', // e.g., 10:00 min/km
        name: 'Steady Pace',
        description: 'Achieve a pace faster than 10:00 min/km for 1km',
        icon: Icons.speed, // Placeholder
        type: AchievementType.paceBest,
        threshold: 600, // 10 * 60 seconds
      ),
      const Achievement(
        id: 'pace_8min_km', // e.g., 08:00 min/km
        name: 'Picking Up Speed',
        description: 'Achieve a pace faster than 08:00 min/km for 1km',
        icon: Icons.speed, // Placeholder
        type: AchievementType.paceBest,
        threshold: 480, // 8 * 60 seconds
      ),
      const Achievement(
        id: 'pace_6min_km', // e.g., 06:00 min/km
        name: 'Speed Demon',
        description: 'Achieve a pace faster than 06:00 min/km for 1km',
        icon: Icons.speed, // Placeholder
        type: AchievementType.paceBest,
        threshold: 360, // 6 * 60 seconds
      ),
      // Add more pace achievements for different distances (5k, 10k etc.) if needed

      // Elevation achievements (threshold in meters)
      const Achievement(
        id: 'elevation_total_1000m',
        name: 'Mountain Goat',
        description: 'Climb a total of 1000 meters',
        icon: Icons.landscape, // Placeholder
        type: AchievementType.elevationTotalGain,
        threshold: 1000,
      ),

      // Special achievements (threshold might be 1 for event completion)
      const Achievement(
        id: 'special_early_bird',
        name: 'Early Bird',
        description: 'Complete a workout before 7 AM',
        icon: Icons.wb_sunny_outlined, // Placeholder
        type: AchievementType.specialEvent,
        threshold: 1, // Represents 1 event completion
      ),
      const Achievement(
        id: 'special_night_owl',
        name: 'Night Owl',
        description: 'Complete a workout after 10 PM',
        icon: Icons.nightlight_outlined, // Placeholder
        type: AchievementType.specialEvent,
        threshold: 1, // Represents 1 event completion
      ),
      // Add more special achievements
    ]);
  }

  /// Load unlocked achievements from preferences
  Future<void> _loadUnlockedAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    _unlockedDates.clear();
    for (final achievement in _predefinedAchievements) {
      final unlockedDateString =
          prefs.getString('achievement_${achievement.id}_date');
      if (unlockedDateString != null) {
        final unlockedDate = DateTime.tryParse(unlockedDateString);
        if (unlockedDate != null) {
          _unlockedDates[achievement.id] = unlockedDate;
        }
      }
    }
  }

  /// Save unlocked achievement to preferences
  Future<void> _saveUnlockedAchievement(
      String achievementId, DateTime dateEarned) async {
    final prefs = await SharedPreferences.getInstance();
    _unlockedDates[achievementId] = dateEarned;
    await prefs.setString(
      'achievement_${achievementId}_date',
      dateEarned.toIso8601String(),
    );
  }

  // Helper to check if an achievement is unlocked
  bool isUnlocked(String achievementId) {
    return _unlockedDates.containsKey(achievementId);
  }

  // Helper to get the unlock date
  DateTime? getUnlockDate(String achievementId) {
    return _unlockedDates[achievementId];
  }

  /// Generic unlock function
  Future<Achievement?> _unlockAchievement(Achievement achievement) async {
    if (!isUnlocked(achievement.id)) {
      final now = DateTime.now();
      await _saveUnlockedAchievement(achievement.id, now);
      // Assuming NotificationService has a method like this
      // Pass the achievement object itself for more context
      // Using showMilestoneNotification as the closest match
      await _notificationService.showMilestoneNotification(
          achievement.name, // Use achievement name for title
          achievement.description // Use achievement description for body
          );
      return achievement.copyWith(dateEarned: now);
    }
    return null; // Return null if already unlocked
  }

  /// Check and update distance achievements (total distance in meters)
  Future<List<Achievement>> checkTotalDistanceAchievements(
      double totalDistanceMeters) async {
    if (!_initialized) await initialize();
    final newlyUnlocked = <Achievement>[];

    for (final achievement in _predefinedAchievements) {
      if (achievement.type == AchievementType.distanceTotal &&
          !isUnlocked(achievement.id) &&
          totalDistanceMeters >= achievement.threshold) {
        final unlocked = await _unlockAchievement(achievement);
        if (unlocked != null) newlyUnlocked.add(unlocked);
      }
    }
    return newlyUnlocked;
  }

  /// Check and update single run distance achievements (distance in meters)
  Future<List<Achievement>> checkSingleDistanceAchievements(
      double singleDistanceMeters) async {
    if (!_initialized) await initialize();
    final newlyUnlocked = <Achievement>[];

    for (final achievement in _predefinedAchievements) {
      if (achievement.type == AchievementType.distanceSingle &&
          !isUnlocked(achievement.id) &&
          singleDistanceMeters >= achievement.threshold) {
        final unlocked = await _unlockAchievement(achievement);
        if (unlocked != null) newlyUnlocked.add(unlocked);
      }
    }
    return newlyUnlocked;
  }

  /// Check and update workout count achievements
  Future<List<Achievement>> checkWorkoutCountAchievements(
      int workoutCount) async {
    if (!_initialized) await initialize();
    final newlyUnlocked = <Achievement>[];

    for (final achievement in _predefinedAchievements) {
      if (achievement.type == AchievementType.countWorkouts &&
          !isUnlocked(achievement.id) &&
          workoutCount >= achievement.threshold) {
        final unlocked = await _unlockAchievement(achievement);
        if (unlocked != null) newlyUnlocked.add(unlocked);
      }
    }
    return newlyUnlocked;
  }

  /// Check and update streak achievements
  Future<List<Achievement>> checkStreakAchievements(int streakDays) async {
    if (!_initialized) await initialize();
    final newlyUnlocked = <Achievement>[];

    for (final achievement in _predefinedAchievements) {
      if (achievement.type == AchievementType.streakConsecutiveDays &&
          !isUnlocked(achievement.id) &&
          streakDays >= achievement.threshold) {
        final unlocked = await _unlockAchievement(achievement);
        if (unlocked != null) newlyUnlocked.add(unlocked);
      }
    }
    return newlyUnlocked;
  }

  /// Check and update pace achievements (pace in seconds per km)
  Future<List<Achievement>> checkPaceAchievements(
      double paceSecondsPerKm) async {
    if (!_initialized) await initialize();
    final newlyUnlocked = <Achievement>[];

    for (final achievement in _predefinedAchievements) {
      // Lower pace value is better
      if (achievement.type == AchievementType.paceBest &&
          !isUnlocked(achievement.id) &&
          paceSecondsPerKm <= achievement.threshold) {
        // Note: <= for pace
        final unlocked = await _unlockAchievement(achievement);
        if (unlocked != null) newlyUnlocked.add(unlocked);
      }
    }
    return newlyUnlocked;
  }

  /// Check and update total elevation gain achievements (gain in meters)
  Future<List<Achievement>> checkTotalElevationAchievements(
      double totalElevationGainMeters) async {
    if (!_initialized) await initialize();
    final newlyUnlocked = <Achievement>[];

    for (final achievement in _predefinedAchievements) {
      if (achievement.type == AchievementType.elevationTotalGain &&
          !isUnlocked(achievement.id) &&
          totalElevationGainMeters >= achievement.threshold) {
        final unlocked = await _unlockAchievement(achievement);
        if (unlocked != null) newlyUnlocked.add(unlocked);
      }
    }
    return newlyUnlocked;
  }

  // --- Special Achievements ---
  // These might need specific triggers within the app logic

  Future<Achievement?> checkEarlyBirdAchievement(
      DateTime workoutStartTime) async {
    if (!_initialized) await initialize();
    final achievement = getAchievementById('special_early_bird');
    if (achievement != null &&
        !isUnlocked(achievement.id) &&
        workoutStartTime.hour < 7) {
      return await _unlockAchievement(achievement);
    }
    return null;
  }

  Future<Achievement?> checkNightOwlAchievement(
      DateTime workoutStartTime) async {
    if (!_initialized) await initialize();
    final achievement = getAchievementById('special_night_owl');
    // Assuming workout ends after 10 PM (22:00)
    if (achievement != null &&
        !isUnlocked(achievement.id) &&
        workoutStartTime.hour >= 22) {
      return await _unlockAchievement(achievement);
    }
    return null;
  }

  // Add checks for other special achievements (Weekend Warrior, All-Weather, Globetrotter, Completionist)
  // These will likely require more complex state tracking (e.g., workout history, locations)

  /// Get all achievements, adding earned date if unlocked
  List<Achievement> getAllAchievements() {
    if (!_initialized) {
      // Maybe throw an error or return empty list if not initialized
      print("Warning: AchievementService accessed before initialization.");
      return [];
    }
    return _predefinedAchievements.map((ach) {
      final unlockedDate = _unlockedDates[ach.id];
      return unlockedDate != null
          ? ach.copyWith(dateEarned: unlockedDate)
          : ach;
    }).toList();
  }

  /// Get unlocked achievements
  List<Achievement> getUnlockedAchievements() {
    return getAllAchievements().where((a) => a.isEarned).toList();
  }

  /// Get locked achievements
  List<Achievement> getLockedAchievements() {
    return getAllAchievements().where((a) => !a.isEarned).toList();
  }

  /// Get achievements by category
  List<Achievement> getAchievementsByCategory(AchievementType type) {
    return getAllAchievements().where((a) => a.type == type).toList();
  }

  // Removed getTotalAchievementPoints as points aren't defined in the model

  /// Get achievement by ID, adding earned date if unlocked
  Achievement? getAchievementById(String id) {
    if (!_initialized) return null;
    try {
      final achievement = _predefinedAchievements.firstWhere((a) => a.id == id);
      final unlockedDate = _unlockedDates[achievement.id];
      return unlockedDate != null
          ? achievement.copyWith(dateEarned: unlockedDate)
          : achievement;
    } catch (e) {
      return null; // Not found
    }
  }
}

// Removed AchievementCategory and AchievementTier enums as they are not used
// in the Achievement model. Use AchievementType instead.
