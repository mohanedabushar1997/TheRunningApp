import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:running_app/data/models/training_plan.dart'; // Import model
import 'package:running_app/presentation/providers/training_plan_provider.dart';
import 'package:running_app/presentation/screens/training/training_plan_detail_screen.dart';
import 'package:running_app/presentation/widgets/common/loading_indicator.dart';
import 'package:running_app/utils/logger.dart';

class TrainingPlanSelectionScreen extends StatelessWidget {
  const TrainingPlanSelectionScreen({super.key});
  static const routeName = '/training-plans';

  @override
  Widget build(BuildContext context) {
    // Use watch to rebuild if plans list or active plan changes
    final planProvider = context.watch<TrainingPlanProvider>();

     // Fetch plans if list is empty and not loading
     if (planProvider.availablePlans.isEmpty && !planProvider.isLoading) {
         WidgetsBinding.instance.addPostFrameCallback((_) {
             if (context.read<TrainingPlanProvider>().availablePlans.isEmpty && !context.read<TrainingPlanProvider>().isLoading) {
                 context.read<TrainingPlanProvider>().loadAvailablePlans();
             }
         });
     }


    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Plans'),
        // TODO: Add filter/sort options?
      ),
      body: RefreshIndicator(
        onRefresh: () => planProvider.loadAvailablePlans(),
        child: Builder(
           builder: (context) {
             if (planProvider.isLoading && planProvider.availablePlans.isEmpty) {
               return const Center(child: LoadingIndicator());
             }
             if (planProvider.errorMessage != null) {
                return Center(child: Padding( padding: const EdgeInsets.all(16), child: Text('Error: ${planProvider.errorMessage}', textAlign: TextAlign.center), ));
             }
             if (planProvider.availablePlans.isEmpty) {
               return const Center(child: Padding( padding: EdgeInsets.all(16), child: Text('No training plans available.\nCheck back later or create your own!', textAlign: TextAlign.center), ));
             }

             return ListView.builder(
               padding: const EdgeInsets.all(8.0),
               itemCount: planProvider.availablePlans.length,
               itemBuilder: (context, index) {
                 final plan = planProvider.availablePlans[index];
                 final bool isActive = planProvider.activePlan?.id == plan.id;

                 return Card(
                   elevation: isActive ? 4 : 1,
                   shape: RoundedRectangleBorder(
                     borderRadius: BorderRadius.circular(12),
                     side: isActive ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5) : BorderSide.none,
                   ),
                   margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                   child: ListTile(
                     contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                     leading: CircleAvatar(
                         backgroundColor: isActive ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                         child: Icon(_getGoalIcon(plan.goal), color: isActive ? Colors.white : Colors.grey.shade700)
                      ),
                     title: Text(plan.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                     subtitle: Text('${plan.durationWeeks} Weeks · ${plan.difficulty}'),
                      trailing: isActive ? Chip(label: const Text('Active'), avatar: const Icon(Icons.check_circle, size: 16), padding: const EdgeInsets.symmetric(horizontal: 4), visualDensity: VisualDensity.compact, backgroundColor: Colors.green.shade100) : const Icon(Icons.chevron_right),
                     onTap: () {
                        Navigator.push(
                           context, MaterialPageRoute( builder: (_) => TrainingPlanDetailScreen(plan: plan), ),
                        );
                     },
                   ),
                 );
               },
             );
           }
        ),
      ),
       // TODO: FAB to create custom plan
       // floatingActionButton: FloatingActionButton.extended(...)
    );
  }

   IconData _getGoalIcon(TrainingGoal goal) {
      switch(goal) {
         case TrainingGoal.distance_5k: return Icons.looks_5;
         case TrainingGoal.distance_10k: return Icons.looks_one; // Needs better 10k icon
         case TrainingGoal.distance_half_marathon: return Icons.directions_run; // Needs better HM icon
         case TrainingGoal.distance_marathon: return Icons.emoji_events;
         case TrainingGoal.improve_pace: return Icons.speed;
         case TrainingGoal.general_fitness: return Icons.fitness_center;
      }
   }
}
(Code continues in the next response due to length)





(Code continues in the next response due to length)



Show thinking
Okay, here is the final batch containing the remaining prioritized files.

This batch includes placeholders for several screens, widgets, and providers related to features like achievements, weight tracking, training plans, music, battery optimization, and background settings. The core structure is provided, but features marked with TODO require significant further development.

This concludes the code modification process based on your requests. Remember to test thoroughly and iteratively develop the placeholder features.

Final Batch (Remaining Prioritized Files)