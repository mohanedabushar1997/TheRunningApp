import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:running_app/data/models/training_plan.dart';
import 'package:running_app/presentation/providers/training_plan_provider.dart';
import 'package:running_app/presentation/widgets/training/session_card.dart';
import 'package:running_app/presentation/screens/workout/workout_preparation_screen.dart'; // To start workout
import 'package:running_app/utils/logger.dart';

class TrainingPlanDetailScreen extends StatefulWidget {
  final TrainingPlan plan;

  const TrainingPlanDetailScreen({required this.plan, super.key});
  static const routeName = '/training-plan-detail';

  @override
  State<TrainingPlanDetailScreen> createState() => _TrainingPlanDetailScreenState();
}

class _TrainingPlanDetailScreenState extends State<TrainingPlanDetailScreen> {

  Map<int, List<TrainingSession>> _groupSessionsByWeek(List<TrainingSession> sessions) {
     Map<int, List<TrainingSession>> grouped = {};
     for (var session in sessions) { grouped.putIfAbsent(session.week, () => []).add(session); }
     grouped.forEach((week, sessionList) { sessionList.sort((a, b) => a.day.compareTo(b.day)); });
     return grouped;
  }

   // Action to start a planned workout
   void _startPlannedWorkout(BuildContext context, TrainingSession session) {
      Log.i("Starting planned workout: ${session.description}");
       // TODO: Determine WorkoutType based on session.type or description? Default to Run?
       WorkoutType type = WorkoutType.run; // Default assumption
       if (session.type.toLowerCase().contains('cycle') || session.type.toLowerCase().contains('bike')) {
          type = WorkoutType.cycle;
       } else if (session.type.toLowerCase().contains('walk')) {
           type = WorkoutType.walk;
       }
       // TODO: Pass goal (duration/distance) from session to WorkoutPreparationScreen or WorkoutProvider
        Navigator.pushNamed(context, WorkoutPreparationScreen.routeName /*, arguments: {'goal': session}*/);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Starting: ${session.description} (Goal passing TODO)')));
   }

  @override
  Widget build(BuildContext context) {
    final planProvider = context.watch<TrainingPlanProvider>();
    // Get latest plan details from provider if it's the active one
    final currentPlanDetails = planProvider.activePlan?.id == widget.plan.id
                              ? planProvider.activePlan!
                              : widget.plan;

    final groupedSessions = _groupSessionsByWeek(currentPlanDetails.sessions);
    final bool isActivePlan = planProvider.activePlan?.id == currentPlanDetails.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentPlanDetails.name),
        actions: [
           // Toggle Active Plan Status
           TextButton(
              onPressed: () {
                 if (isActivePlan) {
                    planProvider.clearActivePlan();
                 } else {
                    planProvider.setActivePlan(currentPlanDetails.id);
                 }
              },
              child: Text(isActivePlan ? "STOP PLAN" : "START PLAN", style: TextStyle(color: isActivePlan ? Colors.red.shade300 : null)),
            )
        ],
      ),
      body: ListView.builder(
         padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
         itemCount: currentPlanDetails.durationWeeks,
         itemBuilder: (context, weekIndex) {
           final weekNumber = weekIndex + 1;
           final sessionsForWeek = groupedSessions[weekNumber] ?? [];
            // Calculate week progress (optional)
            final completedInWeek = sessionsForWeek.where((s) => s.completed).length;
            final totalInWeek = sessionsForWeek.length;

           return Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Padding(
                 padding: EdgeInsets.only(top: weekIndex > 0 ? 24.0 : 8.0, bottom: 8.0, left: 4.0),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Text( 'Week $weekNumber', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold), ),
                      if (totalInWeek > 0) // Show progress chip
                         Chip(
                           label: Text('$completedInWeek / $totalInWeek Done'),
                            labelStyle: Theme.of(context).textTheme.labelSmall,
                            backgroundColor: completedInWeek == totalInWeek ? Colors.green.shade100 : Colors.orange.shade50,
                            side: BorderSide.none,
                            visualDensity: VisualDensity.compact,
                         ),
                   ],
                 ),
               ),
               if (sessionsForWeek.isEmpty)
                  const Padding(padding: EdgeInsets.only(left: 4.0), child: Text('Rest week.'))
               else
                  ...sessionsForWeek.map((session) => SessionCard(
                     session: session,
                     onToggleComplete: (completed) => planProvider.markSessionComplete(session.id, completed),
                     onTap: session.type.toLowerCase() == 'rest' ? null : () => _startPlannedWorkout(context, session), // Allow starting non-rest workouts
                  )).toList(),
             ],
           );
         },
      ),
    );
  }
}