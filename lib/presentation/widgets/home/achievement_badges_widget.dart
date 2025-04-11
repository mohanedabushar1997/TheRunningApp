import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:running_app/presentation/providers/achievement_provider.dart';
import 'package:running_app/presentation/screens/achievements/achievements_screen.dart';
import 'package:running_app/data/models/achievement.dart'; // Import model
import 'package:running_app/presentation/widgets/common/section_title.dart'; // Use SectionTitle

class AchievementBadgesWidget extends StatelessWidget {
  final int maxBadgesToShow;

  const AchievementBadgesWidget({this.maxBadgesToShow = 5, super.key}); // Default to 5 badges

  @override
  Widget build(BuildContext context) {
    final achievementProvider = context.watch<AchievementProvider>();
    // Show most recently earned first? Or highest tier? Sort by date desc.
    final recentAchievements = [...achievementProvider.earnedAchievements] // Create copy
                               ..sort((a, b) => (b.dateEarned ?? DateTime(1900)).compareTo(a.dateEarned ?? DateTime(1900)));
    final displayedAchievements = recentAchievements.take(maxBadgesToShow).toList();

     if (displayedAchievements.isEmpty && !achievementProvider.isLoading) {
       // Don't show the section at all if no achievements are earned yet and not loading
       return const SizedBox.shrink();
     }

    return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
          SectionTitle( // Use the common section title widget
             title: 'Recent Achievements',
              actionText: 'View All',
              onActionPressed: () => Navigator.pushNamed(context, AchievementsScreen.routeName),
          ),
          const SizedBox(height: 8),
           if (achievementProvider.isLoading && displayedAchievements.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2)))
           else if (displayedAchievements.isEmpty) // Handles case where loading finished but still no achievements
                const Text(" Keep running to unlock your first achievement!", style: TextStyle(color: Colors.grey))
           else
             SizedBox( // Constrain height if needed, or let Wrap handle it
                height: 70, // Example fixed height for horizontal scroll
               child: ListView.separated( // Use ListView for horizontal scrolling badges
                  scrollDirection: Axis.horizontal,
                  itemCount: displayedAchievements.length,
                   itemBuilder: (context, index) {
                      final ach = displayedAchievements[index];
                      return Tooltip(
                        message: "${ach.name}\nEarned: ${FormatUtils.formatDateTime(ach.dateEarned!, format: 'MMM d, yyyy')}", // Show earned date too
                        child: InkWell(
                           onTap: () => Navigator.pushNamed(context, AchievementsScreen.routeName),
                           child: Column( // Smaller vertical layout for horizontal list
                             mainAxisSize: MainAxisSize.min,
                             children: [
                               CircleAvatar(
                                  radius: 22, // Smaller avatar
                                  backgroundColor: Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.8),
                                  child: Icon(ach.icon, size: 24, color: Theme.of(context).colorScheme.onTertiaryContainer),
                               ),
                                const SizedBox(height: 4),
                                Text(ach.name, style: Theme.of(context).textTheme.labelSmall, maxLines: 1, overflow: TextOverflow.ellipsis)
                             ],
                           ),
                        ),
                      );
                   },
                    separatorBuilder: (context, index) => const SizedBox(width: 12), // Spacing between badges
               ),
             ),
       ],
    );
  }
}

(Code continues in the next response due to length)





(Code continues in the next response due to length)



Show thinking
Okay, here is the final batch containing the remaining prioritized files. This includes several placeholder widgets and screens that provide the basic structure for features like weight tracking dialogs, home screen cards, training repository, detailed split views, error handling, battery/music settings, and common UI elements.

Remember to implement the logic within the TODO comments to fully realize these features.

Final Batch (Last ~15 Files)