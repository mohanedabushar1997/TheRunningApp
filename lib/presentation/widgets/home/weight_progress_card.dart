import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:running_app/presentation/providers/weight_provider.dart';
import 'package:running_app/presentation/providers/settings_provider.dart';
import 'package:running_app/presentation/screens/weight/weight_history_screen.dart';
import 'package:running_app/presentation/utils/format_utils.dart';
// TODO: Import a simple chart widget if desired (e.g., sparkline)

class WeightProgressCard extends StatelessWidget {
  const WeightProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    final weightProvider = context.watch<WeightProvider>();
    final bool useImperial = context.watch<SettingsProvider>().useImperialUnits;
    final records = weightProvider.records;
    final goalWeightKg = weightProvider.goalWeightKg;

    final currentWeightKg = records.isNotEmpty ? records.first.weightKg : null;
    final startingWeightKg = records.length > 1 ? records.last.weightKg : currentWeightKg;

    String displayWeight = '--';
    String changeStr = '';
    String goalStr = '';

    if (currentWeightKg != null) {
       displayWeight = FormatUtils.formatWeightForDisplay(currentWeightKg, useImperial);
       final unit = useImperial ? 'lbs' : 'kg';
       displayWeight += ' $unit';

       if (startingWeightKg != null && (currentWeightKg - startingWeightKg).abs() > 0.1) {
          double changeKg = currentWeightKg - startingWeightKg;
          String changeValStr = FormatUtils.formatWeightForDisplay(changeKg.abs(), useImperial);
          changeStr = changeKg >= 0 ? '+ $changeValStr $unit' : '- $changeValStr $unit';
       }
    }

    if (goalWeightKg != null) {
        final goalWeightDisplay = FormatUtils.formatWeightForDisplay(goalWeightKg, useImperial);
         final unit = useImperial ? 'lbs' : 'kg';
         goalStr = 'Goal: $goalWeightDisplay $unit';
    }

    return Card(
      elevation: 1,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, WeightHistoryScreen.routeName),
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Weight', style: Theme.of(context).textTheme.titleMedium),
                   if (goalStr.isNotEmpty)
                     Flexible(
                       child: Chip(
                          label: Text(goalStr, style: Theme.of(context).textTheme.labelSmall),
                           padding: const EdgeInsets.symmetric(horizontal: 4),
                           visualDensity: VisualDensity.compact, side: BorderSide.none,
                           backgroundColor: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
                           labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                     ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                   Text(displayWeight, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                    if (changeStr.isNotEmpty) ...[
                       const SizedBox(width: 8),
                       Text(changeStr, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: changeStr.startsWith('+') ? Colors.redAccent.shade100 : Colors.green.shade700)),
                    ]
                ],
              ),
              const SizedBox(height: 8),
               // TODO: Add simple sparkline chart
               // SizedBox(height: 50, child: Placeholder()),
               Align(
                  alignment: Alignment.centerRight,
                  child: Text('View History', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey)),
               ),
            ],
          ),
        ),
      ),
    );
  }
}