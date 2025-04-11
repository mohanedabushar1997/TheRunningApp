import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:running_app/presentation/providers/training_plan_provider.dart';
import 'package:running_app/presentation/screens/training/training_plan_detail_screen.dart'; // Detail screen
import 'package:running_app/presentation/screens/training/training_plan_selection_screen.dart'; // Selection screen
import 'package:running_app/data/models/training_plan.dart'; // Import model

class TrainingPlanCard extends StatelessWidget {
  const TrainingPlanCard({super.key});

  @override
  Widget build(BuildContext context) {
    final planProvider = context.watch<TrainingPlanProvider>();
    final activePlan = planProvider.activePlan;

    // --- If no plan is active ---
    if (activePlan == null) {
      return Card(
        elevation: 1,
        child: ListTile(
          leading: const Icon(Icons.assignment_add_outlined, color: Colors.grey),
          title: const Text('No Active Training Plan'),
          subtitle: const Text('Select a plan to get started!'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
             // Navigate to plan selection screen
              Navigator.pushNamed(context, TrainingPlanSelectionScreen.routeName);
          },
        ),
      );
    }

    // --- If a plan IS active ---
    // TODO: Calculate current week/day and next session
    final int currentWeek = 1; // Placeholder
    final int totalWeeks = activePlan.durationWeeks;
    final TrainingSession? nextSession = activePlan.sessions.firstWhere((s) => !s.completed && s.week >= currentWeek, orElse: () => null);

    return Card(
      elevation: 2,
       shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(12), side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1) ),
      child: InkWell( // Make card tappable
         onTap: () {
            // Navigate to active plan details
             Navigator.push(context, MaterialPageRoute(builder: (_) => TrainingPlanDetailScreen(plan: activePlan)));
         },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                 activePlan.name,
                 style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                 maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                 'Week $currentWeek of $totalWeeks · ${activePlan.difficulty}',
                 style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const Divider(height: 20),
               Text(
                  'Next Session:',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
               ),
               const SizedBox(height: 4),
               if (nextSession != null)
                  Row(
                     children: [
                        Icon(_getSessionIcon(nextSession.type), size: 18, color: Theme.of(context).colorScheme.secondary),
                        const SizedBox(width: 8),
                        Expanded(child: Text(nextSession.description, maxLines: 1, overflow: TextOverflow.ellipsis)),
                         // TODO: Add Button to start next session?
                         // ElevatedButton(...)
                     ],
                  )
               else
                   const Text('Plan Complete! 🎉'),

            ],
          ),
        ),
      ),
    );
  }

   IconData _getSessionIcon(String type) {
      // Consistent with SessionCard logic
       final lowerType = type.toLowerCase();
       if (lowerType.contains('interval')) return Icons.speed_outlined;
       if (lowerType.contains('long')) return Icons.directions_run;
       if (lowerType.contains('easy')) return Icons.run_circle_outlined;
       if (lowerType.contains('tempo')) return Icons.timer_outlined;
       if (lowerType.contains('recovery')) return Icons.self_improvement;
       if (lowerType.contains('rest')) return Icons.bedtime_outlined;
       if (lowerType.contains('cross')) return Icons.pool_outlined;
       if (lowerType.contains('strength')) return Icons.fitness_center;
       return Icons.run_circle_outlined;
   }
}
(Code continues in the next response due to length)





(Code continues in the next response due to length)



Show thinking
Okay, here is the next batch of 10 files, continuing with the prioritized list of remaining core files.

Final Batch (Files 90-99)