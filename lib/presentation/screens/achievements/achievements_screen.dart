import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:running_app/data/models/achievement.dart';
import 'package:running_app/presentation/providers/achievement_provider.dart'; // Import Provider
import 'package:running_app/presentation/utils/format_utils.dart'; // For date format
import 'package:running_app/presentation/widgets/common/loading_indicator.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});
  static const routeName = '/achievements';

  @override
  Widget build(BuildContext context) {
    // Use watch for automatic updates if provider state changes
    final achievementProvider = context.watch<AchievementProvider>();

    // Trigger initial load if needed
    if (achievementProvider.earnedAchievements.isEmpty &&
        achievementProvider.lockedAchievements.isEmpty &&
        !achievementProvider.isLoading) {
       WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<AchievementProvider>().loadAchievements();
       });
    }

    final List<Achievement> earned = achievementProvider.earnedAchievements;
    final List<Achievement> locked = achievementProvider.lockedAchievements;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Achievements'),
      ),
      body: achievementProvider.isLoading && earned.isEmpty && locked.isEmpty
          ? const Center(child: LoadingIndicator())
          : RefreshIndicator( // Allow pull-to-refresh
              onRefresh: () => achievementProvider.loadAchievements(forceRefresh: true),
              child: ListView(
                 padding: const EdgeInsets.all(16.0),
                 children: [
                    // --- Earned Achievements ---
                     _buildSectionHeader(context, 'Earned (${earned.length})', Icons.emoji_events),
                    if (earned.isEmpty && !achievementProvider.isLoading)
                       const Padding( padding: EdgeInsets.symmetric(vertical: 24.0), child: Text('Keep running!', textAlign: TextAlign.center), )
                    else
                       _buildAchievementGrid(context, earned),

                    const Divider(height: 32, thickness: 1),

                     // --- Locked Achievements ---
                      _buildSectionHeader(context, 'Locked (${locked.length})', Icons.lock_outline),
                      _buildAchievementGrid(context, locked),

                 ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
     return Padding(
       padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
       child: Row(
         children: [
           Icon(icon, color: Theme.of(context).colorScheme.primary),
           const SizedBox(width: 8),
           Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
         ],
       ),
     );
  }

   // Grid to display achievement badges
   Widget _buildAchievementGrid(BuildContext context, List<Achievement> achievements) {
      if (achievements.isEmpty && !context.read<AchievementProvider>().isLoading) {
         // Don't show empty grid if still loading or no achievements exist
         return const SizedBox.shrink();
      }
      return GridView.builder(
         shrinkWrap: true,
         physics: const NeverScrollableScrollPhysics(),
         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            // Adjust based on screen width?
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 3,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
             childAspectRatio: 0.9, // Slightly taller than wide
         ),
         itemCount: achievements.length,
         itemBuilder: (context, index) {
            return _buildAchievementBadge(context, achievements[index]);
         },
      );
   }

   // Widget for a single badge
   Widget _buildAchievementBadge(BuildContext context, Achievement achievement) {
      final bool earned = achievement.isEarned;
      final colorScheme = Theme.of(context).colorScheme;
      final textTheme = Theme.of(context).textTheme;

      return InkWell(
         onTap: () => _showAchievementDetails(context, achievement),
         borderRadius: BorderRadius.circular(8),
         child: Opacity(
            opacity: earned ? 1.0 : 0.4, // Fade locked achievements
           child: Container( // Use Container for background/border
              decoration: BoxDecoration(
                 // border: Border.all(color: Colors.grey.shade300),
                 // borderRadius: BorderRadius.circular(8),
                 // color: earned ? colorScheme.surfaceVariant.withOpacity(0.3) : Colors.grey.shade100,
              ),
              padding: const EdgeInsets.all(8),
             child: Column(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                  CircleAvatar(
                     radius: 30, // Badge size
                     backgroundColor: earned ? colorScheme.tertiaryContainer : colorScheme.surfaceVariant,
                     child: Icon(achievement.icon, size: 28, color: earned ? colorScheme.onTertiaryContainer : colorScheme.outline),
                  ),
                  const SizedBox(height: 8),
                  Text(
                     achievement.name,
                     style: textTheme.labelMedium?.copyWith(fontWeight: earned ? FontWeight.bold : FontWeight.normal),
                     textAlign: TextAlign.center,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                   // Optional: Show earned date briefly
                   // if (earned)
                   //    Text(
                   //       FormatUtils.formatDateTime(achievement.dateEarned!, format: 'yyyy-MM-dd'),
                   //       style: textTheme.labelSmall?.copyWith(color: Colors.grey),
                   //    ),
               ],
             ),
           ),
         ),
      );
   }

   // Dialog to show achievement details
   void _showAchievementDetails(BuildContext context, Achievement achievement) {
       final bool earned = achievement.isEarned;
       final colorScheme = Theme.of(context).colorScheme;
       showDialog(context: context, builder: (ctx) => AlertDialog(
          titlePadding: const EdgeInsets.only(top: 20, left: 20, right: 20),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          title: Row(children: [
             Icon(achievement.icon, size: 28, color: earned ? colorScheme.primary : Colors.grey),
             const SizedBox(width: 12),
             Expanded(child: Text(achievement.name, style: Theme.of(context).textTheme.titleLarge))
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text(achievement.description, style: Theme.of(context).textTheme.bodyMedium),
                if (earned) ...[
                   const SizedBox(height: 12),
                   Text(
                      'Earned on: ${FormatUtils.formatDateTime(achievement.dateEarned!, format: 'MMMM d, yyyy')}',
                       style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: Colors.grey.shade600),
                   ),
                ]
            ],
          ),
          actions: [ TextButton(child: const Text('CLOSE'), onPressed: () => Navigator.pop(ctx)) ],
       ));
   }
}

// --- Placeholder Provider (Create presentation/providers/achievement_provider.dart) ---
/*
import 'package:flutter/foundation.dart';
import 'package:running_app/data/models/achievement.dart';
// import 'package:running_app/data/repositories/achievement_repository.dart'; // TODO

class AchievementProvider with ChangeNotifier {
   // final AchievementRepository _repository; // TODO: Inject repository

   List<Achievement> _earned = [];
   List<Achievement> _locked = [];
   bool _isLoading = false;

   List<Achievement> get earnedAchievements => _earned;
   List<Achievement> get lockedAchievements => _locked;
   bool get isLoading => _isLoading;

   AchievementProvider(/* {required AchievementRepository repository} */) /*: _repository = repository*/ {
      loadAchievements();
   }

   Future<void> loadAchievements({bool forceRefresh = false}) async {
      if (_isLoading) return;
       _isLoading = true; notifyListeners();
       try {
          Log.d("Loading achievements...");
           // TODO: Load earned achievement IDs/dates from DB/Prefs
           Set<String> earnedIds = {'total_dist_10k', 'count_workouts_10'}; // Placeholder
           DateTime earnedDate = DateTime.now().subtract(Duration(days: 5)); // Placeholder

           List<Achievement> allPredefined = predefinedAchievements; // Use predefined list
           _earned = allPredefined.where((a) => earnedIds.contains(a.id))
                                   .map((a) => a.copyWith(dateEarned: earnedDate)) // Add earned date
                                   .toList();
           _locked = allPredefined.where((a) => !earnedIds.contains(a.id)).toList();

           // Sort lists?
           _earned.sort((a, b) => a.name.compareTo(b.name));
           _locked.sort((a, b) => a.name.compareTo(b.name));

          Log.i("Loaded ${_earned.length} earned, ${_locked.length} locked achievements.");
       } catch (e, s) {
          Log.e("Failed to load achievements", error: e, stackTrace: s);
       } finally {
          _isLoading = false; notifyListeners();
       }
   }

   // TODO: Implement checkWorkoutAchievements(Workout workout)
   // This method would be called after a workout is saved.
   // It checks the workout details (distance, duration, pace, date etc.)
   // and the user's total stats against the thresholds of LOCKED achievements.
   // If an achievement is unlocked:
   // 1. Save the achievement state (ID, dateEarned) to DB/Prefs.
   // 2. Move it from the locked list to the earned list in the provider state.
   // 3. Notify listeners.
   // 4. Optionally trigger a notification (NotificationService.showAchievementUnlocked(...)).
   Future<void> checkWorkoutAchievements(Workout workout) async {
      Log.d("Checking achievements for workout ${workout.id}");
       // ... complex logic to check thresholds ...
       bool newAchievementEarned = false;
       // if (condition for achievement 'xyz') {
       //    await _repository.markAchievementEarned('xyz', DateTime.now(), workout.id);
       //    newAchievementEarned = true;
       // }
       if (newAchievementEarned) {
          await loadAchievements(forceRefresh: true); // Reload lists if something changed
           // Trigger notification?
       }
   }

}
*/