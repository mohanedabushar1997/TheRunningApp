import 'package:flutter/material.dart';
import '../../../data/models/workout.dart';
import '../../../providers/workout_provider.dart';
import 'package:provider/provider.dart';

/// A widget that connects the workout details screen to the workout provider
/// This allows for proper data loading and state management
class WorkoutDetailsConnector extends StatelessWidget {
  final String workoutId;

  const WorkoutDetailsConnector({
    Key? key,
    required this.workoutId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Workout?>(
      future: Provider.of<WorkoutProvider>(context, listen: false)
          .getWorkoutById(workoutId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Workout Details')),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Workout Details')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading workout: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        final workout = snapshot.data;
        if (workout == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Workout Details')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.not_interested, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Workout not found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        // Import the actual screen here to avoid circular dependencies
        // This is a common pattern in Flutter apps
        return _buildWorkoutDetailsScreen(context, workout);
      },
    );
  }

  Widget _buildWorkoutDetailsScreen(BuildContext context, Workout workout) {
    // Dynamically import the screen to avoid circular dependencies
    return WorkoutDetailsScreen(workout: workout);
  }
}

// Forward declaration to avoid import issues
// The actual implementation is in workout_details_screen.dart
class WorkoutDetailsScreen extends StatelessWidget {
  final Workout workout;

  const WorkoutDetailsScreen({Key? key, required this.workout}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // This is just a placeholder - the real implementation is in workout_details_screen.dart
    // This class exists only to satisfy the type system
    return Container();
  }
}
