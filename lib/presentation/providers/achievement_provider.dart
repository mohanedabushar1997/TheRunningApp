import 'package:flutter/foundation.dart';
import 'package:running_app/data/models/achievement.dart';
import 'package:running_app/data/models/workout.dart';
import 'package:running_app/utils/logger.dart';
// TODO: Import AchievementRepository and WorkoutRepository/Stats source
// TODO: Import NotificationService

class AchievementProvider with ChangeNotifier {
   // TODO: Inject repositories
   // final AchievementRepository _achievementRepo;
   // final WorkoutRepository _workoutRepo;

   List<Achievement> _earned = [];
   List<Achievement> _locked = [];
   bool _isLoading = false;
   String? _errorMessage;

   List<Achievement> get earnedAchievements => _earned;
   List<Achievement> get lockedAchievements => _locked;
   bool get isLoading => _isLoading;
   String? get errorMessage => _errorMessage;

   AchievementProvider() {
      Log.d("AchievementProvider Initialized (placeholder data)");
      loadAchievements();
   }

   void _setLoading(bool loading) { if (_isLoading == loading) return; _isLoading = loading; notifyListeners(); }
   void _setError(String? msg) { _errorMessage = msg; }

   Future<void> loadAchievements({bool forceRefresh = false}) async {
      if (_isLoading && !forceRefresh) return;
      _setLoading(true); _setError(null);
      try {
         Log.d("Loading achievements...");
         // TODO: Replace with actual loading logic
         List<Achievement> allPossibleAchievements = predefinedAchievements;
         Map<String, DateTime> earnedData = { // Placeholder
            'total_dist_10k': DateTime.now().subtract(const Duration(days: 20)),
            'count_workouts_10': DateTime.now().subtract(const Duration(days: 5)),
            'single_dist_10k': DateTime.now().subtract(const Duration(days: 2)),
         };
         // earnedData = await _achievementRepo.getEarnedAchievements(deviceId);

         _earned = []; _locked = [];
         for (var ach in allPossibleAchievements) {
            if (earnedData.containsKey(ach.id)) { _earned.add(ach.copyWith(dateEarned: earnedData[ach.id])); }
            else { _locked.add(ach); }
         }
         _earned.sort((a, b) => a.name.compareTo(b.name));
         _locked.sort((a, b) => a.name.compareTo(b.name));

         Log.i("Loaded ${_earned.length} earned, ${_locked.length} locked achievements.");

      } catch (e, s) { Log.e("Failed to load achievements", error: e, stackTrace: s); _setError("Could not load achievements."); _earned = []; _locked = [];
      } finally { _setLoading(false); }
   }

   Future<List<Achievement>> checkWorkoutAchievements(Workout workout, String deviceId) async {
      if (_isLoading || workout.status != WorkoutStatus.completed) return [];
      Log.i("Checking achievements for workout ${workout.id}...");
      List<Achievement> newlyEarned = [];

       try {
          // TODO: Get current total stats and PBs (needs WorkoutRepository)
           final totalStats = {'totalDistance': 95000.0, 'totalDuration': 3600 * 10, 'workoutCount': 9}; // Placeholder
           final currentPBs = <double, Duration>{pbDistance5k: const Duration(minutes: 28)}; // Placeholder

           List<Achievement> stillLocked = [];
           DateTime now = DateTime.now();

           for (var achievement in List<Achievement>.from(_locked)) { // Iterate over copy
              bool earnedNow = false;
              // --- Check conditions ---
               switch (achievement.type) {
                 case AchievementType.distanceTotal: earnedNow = totalStats['totalDistance']! >= achievement.threshold; break;
                 case AchievementType.distanceSingle: earnedNow = workout.distance >= achievement.threshold; break;
                 case AchievementType.countWorkouts: earnedNow = (totalStats['workoutCount']! + 1) >= achievement.threshold; break; // +1 for the current workout
                 // ... Add checks for other types ...
                 default: earnedNow = false;
              }
              // --- End Check ---

              if (earnedNow) {
                 Log.i("ACHIEVEMENT UNLOCKED: ${achievement.name}");
                  final earnedAchievement = achievement.copyWith(dateEarned: now, workoutId: workout.id);
                 newlyEarned.add(earnedAchievement);
                  // TODO: Persist earned achievement
                  // await _achievementRepo.markAchievementEarned(deviceId, earnedAchievement);
              } else {
                  stillLocked.add(achievement);
              }
           }

           if (newlyEarned.isNotEmpty) {
              _locked = stillLocked;
              _earned.addAll(newlyEarned);
              _earned.sort((a, b) => a.name.compareTo(b.name));
              notifyListeners();
              // TODO: Trigger notifications for newlyEarned list
              // for (var ach in newlyEarned) { NotificationService.showAchievementUnlocked(ach); }
           }
       } catch (e, s) { Log.e("Error checking achievements", error: e, stackTrace: s); }
       return newlyEarned;
   }
}

// Helper copyWith for Achievement (Add to achievement.dart model file)
extension AchievementCopyWith on Achievement {
   Achievement copyWith({
      String? id, String? name, String? description, IconData? icon,
      AchievementType? type, double? threshold, DateTime? dateEarned,
      String? workoutId, bool setDateEarnedToNull = false, bool setWorkoutIdToNull = false,
   }) {
      return Achievement(
         id: id ?? this.id, name: name ?? this.name, description: description ?? this.description,
         icon: icon ?? this.icon, type: type ?? this.type, threshold: threshold ?? this.threshold,
         dateEarned: setDateEarnedToNull ? null : (dateEarned ?? this.dateEarned),
         workoutId: setWorkoutIdToNull ? null : (workoutId ?? this.workoutId),
      );
   }
}
(Code continues in the next response due to length)





(Code continues in the next response due to length)



Show thinking
Okay, here is the final batch containing the remaining core files for your project.

This batch includes placeholders for several settings screens, home/workout widgets, and supporting components. Remember, features marked with TODO require further implementation, testing, and refinement based on your specific needs.

Final Batch (Remaining Core Files)