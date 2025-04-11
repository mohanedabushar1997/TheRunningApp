import 'package:shared_preferences/shared_preferences.dart';
import '../models/achievement.dart';
import '../../device/notifications/notification_service.dart';

/// A service for managing achievements in the app
class AchievementService {
  // Singleton pattern
  static final AchievementService _instance = AchievementService._internal();
  factory AchievementService() => _instance;
  AchievementService._internal();

  final List<Achievement> _achievements = [];
  final NotificationService _notificationService = NotificationService();
  bool _initialized = false;
  
  /// Initialize the achievement service
  Future<void> initialize() async {
    if (_initialized) return;
    
    // Initialize notification service
    await _notificationService.initialize();
    
    // Create predefined achievements
    _createPredefinedAchievements();
    
    // Load unlocked achievements from preferences
    await _loadUnlockedAchievements();
    
    _initialized = true;
  }
  
  /// Create predefined achievements
  void _createPredefinedAchievements() {
    // Distance achievements
    _achievements.addAll([
      Achievement(
        id: 'distance_1km',
        title: 'First Steps',
        description: 'Complete a 1 km workout',
        iconPath: 'assets/icons/achievements/distance_bronze.png',
        category: AchievementCategory.distance,
        tier: AchievementTier.bronze,
        requiredValue: 1,
      ),
      Achievement(
        id: 'distance_5km',
        title: 'Getting Started',
        description: 'Complete a 5 km workout',
        iconPath: 'assets/icons/achievements/distance_bronze.png',
        category: AchievementCategory.distance,
        tier: AchievementTier.bronze,
        requiredValue: 5,
      ),
      Achievement(
        id: 'distance_10km',
        title: 'Distance Runner',
        description: 'Complete a 10 km workout',
        iconPath: 'assets/icons/achievements/distance_silver.png',
        category: AchievementCategory.distance,
        tier: AchievementTier.silver,
        requiredValue: 10,
      ),
      Achievement(
        id: 'distance_21km',
        title: 'Half Marathon',
        description: 'Complete a 21.1 km workout',
        iconPath: 'assets/icons/achievements/distance_gold.png',
        category: AchievementCategory.distance,
        tier: AchievementTier.gold,
        requiredValue: 21,
      ),
      Achievement(
        id: 'distance_42km',
        title: 'Marathon',
        description: 'Complete a 42.2 km workout',
        iconPath: 'assets/icons/achievements/distance_platinum.png',
        category: AchievementCategory.distance,
        tier: AchievementTier.platinum,
        requiredValue: 42,
      ),
      Achievement(
        id: 'distance_100km',
        title: 'Ultra Runner',
        description: 'Run a total of 100 km',
        iconPath: 'assets/icons/achievements/distance_diamond.png',
        category: AchievementCategory.distance,
        tier: AchievementTier.diamond,
        requiredValue: 100,
      ),
    ]);
    
    // Workout count achievements
    _achievements.addAll([
      Achievement(
        id: 'workouts_1',
        title: 'First Workout',
        description: 'Complete your first workout',
        iconPath: 'assets/icons/achievements/workouts_bronze.png',
        category: AchievementCategory.workouts,
        tier: AchievementTier.bronze,
        requiredValue: 1,
      ),
      Achievement(
        id: 'workouts_10',
        title: 'Regular Runner',
        description: 'Complete 10 workouts',
        iconPath: 'assets/icons/achievements/workouts_bronze.png',
        category: AchievementCategory.workouts,
        tier: AchievementTier.bronze,
        requiredValue: 10,
      ),
      Achievement(
        id: 'workouts_25',
        title: 'Dedicated Runner',
        description: 'Complete 25 workouts',
        iconPath: 'assets/icons/achievements/workouts_silver.png',
        category: AchievementCategory.workouts,
        tier: AchievementTier.silver,
        requiredValue: 25,
      ),
      Achievement(
        id: 'workouts_50',
        title: 'Fitness Enthusiast',
        description: 'Complete 50 workouts',
        iconPath: 'assets/icons/achievements/workouts_gold.png',
        category: AchievementCategory.workouts,
        tier: AchievementTier.gold,
        requiredValue: 50,
      ),
      Achievement(
        id: 'workouts_100',
        title: 'Century Club',
        description: 'Complete 100 workouts',
        iconPath: 'assets/icons/achievements/workouts_platinum.png',
        category: AchievementCategory.workouts,
        tier: AchievementTier.platinum,
        requiredValue: 100,
      ),
      Achievement(
        id: 'workouts_365',
        title: 'Yearly Dedication',
        description: 'Complete 365 workouts',
        iconPath: 'assets/icons/achievements/workouts_diamond.png',
        category: AchievementCategory.workouts,
        tier: AchievementTier.diamond,
        requiredValue: 365,
      ),
    ]);
    
    // Streak achievements
    _achievements.addAll([
      Achievement(
        id: 'streak_3',
        title: 'Getting Started',
        description: 'Maintain a 3-day workout streak',
        iconPath: 'assets/icons/achievements/streak_bronze.png',
        category: AchievementCategory.streak,
        tier: AchievementTier.bronze,
        requiredValue: 3,
      ),
      Achievement(
        id: 'streak_7',
        title: 'Weekly Warrior',
        description: 'Maintain a 7-day workout streak',
        iconPath: 'assets/icons/achievements/streak_bronze.png',
        category: AchievementCategory.streak,
        tier: AchievementTier.bronze,
        requiredValue: 7,
      ),
      Achievement(
        id: 'streak_14',
        title: 'Fortnight Fighter',
        description: 'Maintain a 14-day workout streak',
        iconPath: 'assets/icons/achievements/streak_silver.png',
        category: AchievementCategory.streak,
        tier: AchievementTier.silver,
        requiredValue: 14,
      ),
      Achievement(
        id: 'streak_30',
        title: 'Monthly Master',
        description: 'Maintain a 30-day workout streak',
        iconPath: 'assets/icons/achievements/streak_gold.png',
        category: AchievementCategory.streak,
        tier: AchievementTier.gold,
        requiredValue: 30,
      ),
      Achievement(
        id: 'streak_90',
        title: 'Quarterly Champion',
        description: 'Maintain a 90-day workout streak',
        iconPath: 'assets/icons/achievements/streak_platinum.png',
        category: AchievementCategory.streak,
        tier: AchievementTier.platinum,
        requiredValue: 90,
      ),
      Achievement(
        id: 'streak_365',
        title: 'Iron Will',
        description: 'Maintain a 365-day workout streak',
        iconPath: 'assets/icons/achievements/streak_diamond.png',
        category: AchievementCategory.streak,
        tier: AchievementTier.diamond,
        requiredValue: 365,
      ),
    ]);
    
    // Speed achievements
    _achievements.addAll([
      Achievement(
        id: 'speed_5kmh',
        title: 'First Pace',
        description: 'Achieve a pace of 5 km/h',
        iconPath: 'assets/icons/achievements/speed_bronze.png',
        category: AchievementCategory.speed,
        tier: AchievementTier.bronze,
        requiredValue: 5,
      ),
      Achievement(
        id: 'speed_8kmh',
        title: 'Picking Up Speed',
        description: 'Achieve a pace of 8 km/h',
        iconPath: 'assets/icons/achievements/speed_bronze.png',
        category: AchievementCategory.speed,
        tier: AchievementTier.bronze,
        requiredValue: 8,
      ),
      Achievement(
        id: 'speed_10kmh',
        title: 'Steady Runner',
        description: 'Achieve a pace of 10 km/h',
        iconPath: 'assets/icons/achievements/speed_silver.png',
        category: AchievementCategory.speed,
        tier: AchievementTier.silver,
        requiredValue: 10,
      ),
      Achievement(
        id: 'speed_12kmh',
        title: 'Speed Demon',
        description: 'Achieve a pace of 12 km/h',
        iconPath: 'assets/icons/achievements/speed_gold.png',
        category: AchievementCategory.speed,
        tier: AchievementTier.gold,
        requiredValue: 12,
      ),
      Achievement(
        id: 'speed_15kmh',
        title: 'Lightning Fast',
        description: 'Achieve a pace of 15 km/h',
        iconPath: 'assets/icons/achievements/speed_platinum.png',
        category: AchievementCategory.speed,
        tier: AchievementTier.platinum,
        requiredValue: 15,
      ),
      Achievement(
        id: 'speed_20kmh',
        title: 'Olympic Sprinter',
        description: 'Achieve a pace of 20 km/h',
        iconPath: 'assets/icons/achievements/speed_diamond.png',
        category: AchievementCategory.speed,
        tier: AchievementTier.diamond,
        requiredValue: 20,
      ),
    ]);
    
    // Calories achievements
    _achievements.addAll([
      Achievement(
        id: 'calories_100',
        title: 'Calorie Counter',
        description: 'Burn 100 calories in a workout',
        iconPath: 'assets/icons/achievements/calories_bronze.png',
        category: AchievementCategory.calories,
        tier: AchievementTier.bronze,
        requiredValue: 100,
      ),
      Achievement(
        id: 'calories_300',
        title: 'Calorie Crusher',
        description: 'Burn 300 calories in a workout',
        iconPath: 'assets/icons/achievements/calories_bronze.png',
        category: AchievementCategory.calories,
        tier: AchievementTier.bronze,
        requiredValue: 300,
      ),
      Achievement(
        id: 'calories_500',
        title: 'Fat Burner',
        description: 'Burn 500 calories in a workout',
        iconPath: 'assets/icons/achievements/calories_silver.png',
        category: AchievementCategory.calories,
        tier: AchievementTier.silver,
        requiredValue: 500,
      ),
      Achievement(
        id: 'calories_1000',
        title: 'Calorie King',
        description: 'Burn 1000 calories in a workout',
        iconPath: 'assets/icons/achievements/calories_gold.png',
        category: AchievementCategory.calories,
        tier: AchievementTier.gold,
        requiredValue: 1000,
      ),
      Achievement(
        id: 'calories_10000',
        title: 'Mega Burner',
        description: 'Burn a total of 10,000 calories',
        iconPath: 'assets/icons/achievements/calories_platinum.png',
        category: AchievementCategory.calories,
        tier: AchievementTier.platinum,
        requiredValue: 10000,
      ),
      Achievement(
        id: 'calories_100000',
        title: 'Calorie Millionaire',
        description: 'Burn a total of 100,000 calories',
        iconPath: 'assets/icons/achievements/calories_diamond.png',
        category: AchievementCategory.calories,
        tier: AchievementTier.diamond,
        requiredValue: 100000,
      ),
    ]);
    
    // Special achievements
    _achievements.addAll([
      Achievement(
        id: 'special_early_bird',
        title: 'Early Bird',
        description: 'Complete a workout before 7 AM',
        iconPath: 'assets/icons/achievements/special_bronze.png',
        category: AchievementCategory.special,
        tier: AchievementTier.bronze,
        requiredValue: 1,
      ),
      Achievement(
        id: 'special_night_owl',
        title: 'Night Owl',
        description: 'Complete a workout after 10 PM',
        iconPath: 'assets/icons/achievements/special_bronze.png',
        category: AchievementCategory.special,
        tier: AchievementTier.bronze,
        requiredValue: 1,
      ),
      Achievement(
        id: 'special_weekend_warrior',
        title: 'Weekend Warrior',
        description: 'Complete workouts on 5 consecutive weekends',
        iconPath: 'assets/icons/achievements/special_silver.png',
        category: AchievementCategory.special,
        tier: AchievementTier.silver,
        requiredValue: 5,
      ),
      Achievement(
        id: 'special_all_weather',
        title: 'All-Weather Runner',
        description: 'Complete workouts in all four seasons',
        iconPath: 'assets/icons/achievements/special_gold.png',
        category: AchievementCategory.special,
        tier: AchievementTier.gold,
        requiredValue: 4,
      ),
      Achievement(
        id: 'special_globetrotter',
        title: 'Globetrotter',
        description: 'Complete workouts in 5 different locations',
        iconPath: 'assets/icons/achievements/special_platinum.png',
        category: AchievementCategory.special,
        tier: AchievementTier.platinum,
        requiredValue: 5,
      ),
      Achievement(
        id: 'special_completionist',
        title: 'Completionist',
        description: 'Unlock 25 other achievements',
        iconPath: 'assets/icons/achievements/special_diamond.png',
        category: AchievementCategory.special,
        tier: AchievementTier.diamond,
        requiredValue: 25,
      ),
    ]);
  }
  
  /// Load unlocked achievements from preferences
  Future<void> _loadUnlockedAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    
    for (final achievement in _achievements) {
      final isUnlocked = prefs.getBool('achievement_${achievement.id}_unlocked') ?? false;
      final unlockedDateString = prefs.getString('achievement_${achievement.id}_date');
      
      if (isUnlocked) {
        achievement.isUnlocked = true;
        if (unlockedDateString != null) {
          achievement.unlockedDate = DateTime.parse(unlockedDateString);
        }
      }
    }
  }
  
  /// Save unlocked achievement to preferences
  Future<void> _saveUnlockedAchievement(Achievement achievement) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setBool('achievement_${achievement.id}_unlocked', true);
    if (achievement.unlockedDate != null) {
      await prefs.setString(
        'achievement_${achievement.id}_date', 
        achievement.unlockedDate!.toIso8601String(),
      );
    }
  }
  
  /// Check and update distance achievements
  Future<List<Achievement>> checkDistanceAchievements(double distanceKm) async {
    if (!_initialized) await initialize();
    
    final unlockedAchievements = <Achievement>[];
    
    for (final achievement in _achievements) {
      if (achievement.category == AchievementCategory.distance && 
          !achievement.isUnlocked &&
          distanceKm >= achievement.requiredValue) {
        achievement.unlock();
        await _saveUnlockedAchievement(achievement);
        unlockedAchievements.add(achievement);
        
        // Show notification
        await _notificationService.showAchievementNotification(
          achievement.title,
          achievement.description,
        );
      }
    }
    
    return unlockedAchievements;
  }
  
  /// Check and update workout count achievements
  Future<List<Achievement>> checkWorkoutCountAchievements(int workoutCount) async {
    if (!_initialized) await initialize();
    
    final unlockedAchievements = <Achievement>[];
    
    for (final achievement in _achievements) {
      if (achievement.category == AchievementCategory.workouts && 
          !achievement.isUnlocked &&
          workoutCount >= achievement.requiredValue) {
        achievement.unlock();
        await _saveUnlockedAchievement(achievement);
        unlockedAchievements.add(achievement);
        
        // Show notification
        await _notificationService.showAchievementNotification(
          achievement.title,
          achievement.description,
        );
      }
    }
    
    return unlockedAchievements;
  }
  
  /// Check and update streak achievements
  Future<List<Achievement>> checkStreakAchievements(int streakDays) async {
    if (!_initialized) await initialize();
    
    final unlockedAchievements = <Achievement>[];
    
    for (final achievement in _achievements) {
      if (achievement.category == AchievementCategory.streak && 
          !achievement.isUnlocked &&
          streakDays >= achievement.requiredValue) {
        achievement.unlock();
        await _saveUnlockedAchievement(achievement);
        unlockedAchievements.add(achievement);
        
        // Show notification
        await _notificationService.showAchievementNotification(
          achievement.title,
          achievement.description,
        );
      }
    }
    
    return unlockedAchievements;
  }
  
  /// Check and update speed achievements
  Future<List<Achievement>> checkSpeedAchievements(double speedKmh) async {
    if (!_initialized) await initialize();
    
    final unlockedAchievements = <Achievement>[];
    
    for (final achievement in _achievements) {
      if (achievement.category == AchievementCategory.speed && 
          !achievement.isUnlocked &&
          speedKmh >= achievement.requiredValue) {
        achievement.unlock();
        await _saveUnlockedAchievement(achievement);
        unlockedAchievements.add(achievement);
        
        // Show notification
        await _notificationService.showAchievementNotification(
          achievement.title,
          achievement.description,
        );
      }
    }
    
    return unlockedAchievements;
  }
  
  /// Check and update calories achievements
  Future<List<Achievement>> checkCaloriesAchievements(double calories, bool isSingleWorkout) async {
    if (!_initialized) await initialize();
    
    final unlockedAchievements = <Achievement>[];
    
    for (final achievement in _achievements) {
      if (achievement.category == AchievementCategory.calories && 
          !achievement.isUnlocked) {
        
        // Check if this is a single workout achievement or total calories achievement
        final isTotalCaloriesAchievement = achievement.requiredValue >= 10000;
        
        if ((isSingleWorkout && !isTotalCaloriesAchievement) || 
            (!isSingleWorkout && isTotalCaloriesAchievement)) {
          if (calories >= achievement.requiredValue) {
            achievement.unlock();
            await _saveUnlockedAchievement(achievement);
            unlockedAchievements.add(achievement);
            
            // Show notification
            await _notificationService.showAchievementNotification(
              achievement.title,
              achievement.description,
            );
          }
        }
      }
    }
    
    return unlockedAchievements;
  }
  
  /// Check and update special achievements
  Future<List<Achievement>> checkSpecialAchievements(Map<String, dynamic> criteria) async {
    if (!_initialized) await initialize();
    
    final unlockedAchievements = <Achievement>[];
    
    // Early Bird achievement
    if (criteria.containsKey('timeOfDay') && criteria['timeOfDay'] == 'morning') {
      final earlyBird = _achievements.firstWhere(
        (a) => a.id == 'special_early_bird',
        orElse: () => Achievement(
          id: '',
          title: '',
          description: '',
          iconPath: '',
          category: AchievementCategory.special,
          tier: AchievementTier.bronze,
          requiredValue: 0,
        ),
      );
      
      if (!earlyBird.isUnlocked) {
        earlyBird.unlock();
        await _saveUnlockedAchievement(earlyBird);
        unlockedAchievements.add(earlyBird);
        
        // Show notification
        await _notificationService.showAchievementNotification(
          earlyBird.title,
          earlyBird.description,
        );
      }
    }
    
    // Night Owl achievement
    if (criteria.containsKey('timeOfDay') && criteria['timeOfDay'] == 'night') {
      final nightOwl = _achievements.firstWhere(
        (a) => a.id == 'special_night_owl',
        orElse: () => Achievement(
          id: '',
          title: '',
          description: '',
          iconPath: '',
          category: AchievementCategory.special,
          tier: AchievementTier.bronze,
          requiredValue: 0,
        ),
      );
      
      if (!nightOwl.isUnlocked) {
        nightOwl.unlock();
        await _saveUnlockedAchievement(nightOwl);
        unlockedAchievements.add(nightOwl);
        
        // Show notification
        await _notificationService.showAchievementNotification(
          nightOwl.title,
          nightOwl.description,
        );
      }
    }
    
    // Weekend Warrior achievement
    if (criteria.containsKey('consecutiveWeekends')) {
      final consecutiveWeekends = criteria['consecutiveWeekends'] as int;
      final weekendWarrior = _achievements.firstWhere(
        (a) => a.id == 'special_weekend_warrior',
        orElse: () => Achievement(
          id: '',
          title: '',
          description: '',
          iconPath: '',
          category: AchievementCategory.special,
          tier: AchievementTier.silver,
          requiredValue: 0,
        ),
      );
      
      if (!weekendWarrior.isUnlocked && consecutiveWeekends >= weekendWarrior.requiredValue) {
        weekendWarrior.unlock();
        await _saveUnlockedAchievement(weekendWarrior);
        unlockedAchievements.add(weekendWarrior);
        
        // Show notification
        await _notificationService.showAchievementNotification(
          weekendWarrior.title,
          weekendWarrior.description,
        );
      }
    }
    
    // All-Weather Runner achievement
    if (criteria.containsKey('seasons')) {
      final seasons = criteria['seasons'] as Set<String>;
      final allWeatherRunner = _achievements.firstWhere(
        (a) => a.id == 'special_all_weather',
        orElse: () => Achievement(
          id: '',
          title: '',
          description: '',
          iconPath: '',
          category: AchievementCategory.special,
          tier: AchievementTier.gold,
          requiredValue: 0,
        ),
      );
      
      if (!allWeatherRunner.isUnlocked && seasons.length >= allWeatherRunner.requiredValue) {
        allWeatherRunner.unlock();
        await _saveUnlockedAchievement(allWeatherRunner);
        unlockedAchievements.add(allWeatherRunner);
        
        // Show notification
        await _notificationService.showAchievementNotification(
          allWeatherRunner.title,
          allWeatherRunner.description,
        );
      }
    }
    
    // Globetrotter achievement
    if (criteria.containsKey('locations')) {
      final locations = criteria['locations'] as Set<String>;
      final globetrotter = _achievements.firstWhere(
        (a) => a.id == 'special_globetrotter',
        orElse: () => Achievement(
          id: '',
          title: '',
          description: '',
          iconPath: '',
          category: AchievementCategory.special,
          tier: AchievementTier.platinum,
          requiredValue: 0,
        ),
      );
      
      if (!globetrotter.isUnlocked && locations.length >= globetrotter.requiredValue) {
        globetrotter.unlock();
        await _saveUnlockedAchievement(globetrotter);
        unlockedAchievements.add(globetrotter);
        
        // Show notification
        await _notificationService.showAchievementNotification(
          globetrotter.title,
          globetrotter.description,
        );
      }
    }
    
    // Completionist achievement
    final unlockedCount = _achievements.where((a) => a.isUnlocked).length;
    final completionist = _achievements.firstWhere(
      (a) => a.id == 'special_completionist',
      orElse: () => Achievement(
        id: '',
        title: '',
        description: '',
        iconPath: '',
        category: AchievementCategory.special,
        tier: AchievementTier.diamond,
        requiredValue: 0,
      ),
    );
    
    if (!completionist.isUnlocked && unlockedCount >= completionist.requiredValue) {
      completionist.unlock();
      await _saveUnlockedAchievement(completionist);
      unlockedAchievements.add(completionist);
      
      // Show notification
      await _notificationService.showAchievementNotification(
        completionist.title,
        completionist.description,
      );
    }
    
    return unlockedAchievements;
  }
  
  /// Get all achievements
  List<Achievement> getAllAchievements() {
    return List.unmodifiable(_achievements);
  }
  
  /// Get unlocked achievements
  List<Achievement> getUnlockedAchievements() {
    return _achievements.where((a) => a.isUnlocked).toList();
  }
  
  /// Get locked achievements
  List<Achievement> getLockedAchievements() {
    return _achievements.where((a) => !a.isUnlocked).toList();
  }
  
  /// Get achievements by category
  List<Achievement> getAchievementsByCategory(AchievementCategory category) {
    return _achievements.where((a) => a.category == category).toList();
  }
  
  /// Get total achievement points
  int getTotalAchievementPoints() {
    return _achievements
        .where((a) => a.isUnlocked)
        .fold(0, (sum, a) => sum + a.getPointsValue());
  }
  
  /// Get achievement by ID
  Achievement? getAchievementById(String id) {
    try {
      return _achievements.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }
}
