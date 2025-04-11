import 'package:flutter/material.dart';
import 'package:running_app/data/models/workout.dart'; // For WorkoutType enum
import 'package:running_app/presentation/screens/workout/workout_preparation_screen.dart'; // Target screen

class QuickStartCard extends StatelessWidget {
  const QuickStartCard({super.key});

  void _navigateToPrepare(BuildContext context, WorkoutType type) {
     // Navigate to the preparation screen, passing the selected type?
     // Or let preparation screen handle selection? Let's assume prep screen handles it.
     Navigator.pushNamed(context, WorkoutPreparationScreen.routeName);

     // If prep screen needed the type passed:
     // Navigator.push(
     //   context,
     //   MaterialPageRoute(
     //     builder: (context) => WorkoutPreparationScreen(initialType: type), // Modify screen constructor
     //   ),
     // );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      // margin: const EdgeInsets.symmetric(vertical: 8.0), // Add margin if needed
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround, // Space out buttons
          children: [
            _buildStartButton(
              context: context,
              icon: Icons.directions_run,
              label: 'Run',
              type: WorkoutType.run,
              color: Colors.blue.shade700,
            ),
            _buildStartButton(
              context: context,
              icon: Icons.directions_walk,
              label: 'Walk',
              type: WorkoutType.walk,
              color: Colors.green.shade700,
            ),
            _buildStartButton(
              context: context,
              icon: Icons.directions_bike,
              label: 'Cycle',
              type: WorkoutType.cycle,
              color: Colors.orange.shade800,
            ),
            // TODO: Add button for Treadmill or other types if needed
          ],
        ),
      ),
    );
  }

  // Helper widget for individual start buttons
  Widget _buildStartButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required WorkoutType type,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min, // Takes minimum vertical space
      children: [
        ElevatedButton(
          onPressed: () => _navigateToPrepare(context, type),
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16), // Adjust padding for size
            backgroundColor: color,
            foregroundColor: Colors.white, // Icon/Text color
          ),
          child: Icon(icon, size: 28), // Adjust icon size
        ),
        const SizedBox(height: 6), // Space between icon and label
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
             color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}