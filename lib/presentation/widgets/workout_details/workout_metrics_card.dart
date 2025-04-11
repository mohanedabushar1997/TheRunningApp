import 'package:flutter/material.dart';

class WorkoutMetricsCard extends StatelessWidget {
  final String distance;
  final String duration;
  final String avgPace;
  final String calories;
  final String? elevationGain; // Optional
  final String? elevationLoss; // Optional
  final String? avgHeartRate; // Optional

  const WorkoutMetricsCard({
    required this.distance,
    required this.duration,
    required this.avgPace,
    required this.calories,
    this.elevationGain,
    this.elevationLoss,
    this.avgHeartRate,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> metrics = [
      _buildMetricItem(context, Icons.straighten_outlined, 'Distance', distance),
      _buildMetricItem(context, Icons.timer_outlined, 'Duration', duration),
      _buildMetricItem(context, Icons.speed_outlined, 'Avg Pace', avgPace),
      _buildMetricItem(context, Icons.local_fire_department_outlined, 'Calories', calories),
      if (avgHeartRate != null && avgHeartRate != '--')
         _buildMetricItem(context, Icons.favorite_border_outlined, 'Avg HR', '$avgHeartRate bpm'),
      if (elevationGain != null && elevationGain != '-- m' && elevationGain != '0 m')
        _buildMetricItem(context, Icons.trending_up_outlined, 'Elevation Gain', elevationGain!),
      if (elevationLoss != null && elevationLoss != '-- m' && elevationLoss != '0 m')
        _buildMetricItem(context, Icons.trending_down_outlined, 'Elevation Loss', elevationLoss!),

    ];

    // Use GridView for better layout adaptability
    return Card(
       elevation: 2,
       child: Padding(
          padding: const EdgeInsets.all(16.0),
          // Adjust crossAxisCount based on available metrics or screen size
          child: GridView.builder(
             shrinkWrap: true, // Important inside ListView
             physics: const NeverScrollableScrollPhysics(), // Disable grid scrolling
             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Display 2 metrics per row
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 2.5, // Adjust aspect ratio (width/height)
             ),
             itemCount: metrics.length,
             itemBuilder: (context, index) {
                return metrics[index];
             },
          ),
       ),
    );
  }

  // Helper widget for each metric display item
  Widget _buildMetricItem(BuildContext context, IconData icon, String label, String value) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
      children: [
        Row(
           children: [
             Icon(icon, size: 16, color: colorScheme.primary),
             const SizedBox(width: 4),
             Text(
               label,
               style: textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                overflow: TextOverflow.ellipsis,
             ),
           ],
        ),
        const SizedBox(height: 4),
        FittedBox( // Ensure value fits if it's long
           fit: BoxFit.scaleDown,
           child: Text(
             value,
             style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.5),
             maxLines: 1,
             overflow: TextOverflow.ellipsis,
           ),
        ),
      ],
    );
  }
}