import 'package:flutter/material.dart';
import 'package:running_app/data/models/training_session.dart';
import 'package:running_app/presentation/utils/format_utils.dart';

class SessionCard extends StatelessWidget {
  final TrainingSession session;
  final ValueChanged<bool>? onToggleComplete;
  final VoidCallback? onTap; // To start workout

  const SessionCard({
    required this.session,
    this.onToggleComplete,
    this.onTap,
    super.key,
  });

   IconData _getSessionIcon(String type) {
      final lowerType = type.toLowerCase();
       if (lowerType.contains('interval')) return Icons.speed_outlined;
       if (lowerType.contains('long')) return Icons.directions_run;
       if (lowerType.contains('easy')) return Icons.run_circle_outlined;
       if (lowerType.contains('tempo')) return Icons.timer_outlined;
       if (lowerType.contains('recovery')) return Icons.self_improvement;
       if (lowerType.contains('rest')) return Icons.bedtime_outlined;
       if (lowerType.contains('cross') || lowerType.contains('xt')) return Icons.pool_outlined;
       if (lowerType.contains('strength') || lowerType.contains('gym')) return Icons.fitness_center;
       return Icons.run_circle_outlined;
   }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final bool isComplete = session.completed;
     final bool isRestDay = session.type.toLowerCase() == 'rest';

    return Card(
      elevation: isComplete ? 0.5 : 1.5,
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
         onTap: (isRestDay || isComplete) ? null : onTap,
         borderRadius: BorderRadius.circular(10.0),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4.0, 8.0, 8.0, 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Checkbox or Icon
              isRestDay
                 ? Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Icon(Icons.bedtime_outlined, color: Colors.grey.shade400, size: 24),
                   )
                 : Checkbox(
                   value: isComplete,
                   onChanged: onToggleComplete != null ? (value) => onToggleComplete!(value ?? false) : null,
                   visualDensity: VisualDensity.compact,
                   activeColor: colorScheme.primary,
                   side: BorderSide(color: isComplete ? Colors.transparent : Colors.grey.shade400),
                ),
                // Session Icon
                if (!isRestDay) ...[
                   Icon(_getSessionIcon(session.type), color: isComplete ? Colors.grey : colorScheme.secondary, size: 22),
                   const SizedBox(width: 10),
                ],

               // Details
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(
                        session.description,
                        style: textTheme.titleMedium?.copyWith(
                           fontWeight: FontWeight.w500,
                           decoration: isComplete ? TextDecoration.lineThrough : null,
                           color: isComplete ? Colors.grey.shade600 : null,
                        ),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                     ),
                     if (!isRestDay) ...[
                         const SizedBox(height: 4),
                         Text(
                           _formatTargets(session),
                           style: textTheme.bodyMedium?.copyWith( color: isComplete ? Colors.grey.shade600 : colorScheme.onSurfaceVariant, ),
                           maxLines: 1, overflow: TextOverflow.ellipsis,
                         ),
                     ]
                   ],
                 ),
               ),
               const SizedBox(width: 8),
               // Action Icon
                if (onTap != null && !isComplete && !isRestDay)
                   IconButton(
                      icon: const Icon(Icons.play_circle_outline_rounded),
                      tooltip: 'Start Planned Workout',
                      iconSize: 28,
                      color: colorScheme.primary,
                      onPressed: onTap,
                   )
                else if (isComplete)
                    Icon(Icons.check_circle, color: Colors.green.shade600, size: 28)
                else if (!isRestDay)
                     Icon(Icons.chevron_right, color: Colors.grey.shade400)
            ],
          ),
        ),
      ),
    );
  }

   String _formatTargets(TrainingSession s) {
      String target = "";
      if (s.duration > Duration.zero) { target += FormatUtils.formatDuration(s.duration.inSeconds); }
      if (s.distance != null && s.distance! > 0) {
         if (target.isNotEmpty) target += " / ";
         // TODO: Get units from SettingsProvider
         target += FormatUtils.formatDistance(s.distance, false);
      }
      if (target.isEmpty && s.type.toLowerCase() != 'rest') target = s.type;
      return target.isNotEmpty ? target : 'Activity';
   }
}