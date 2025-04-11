import 'package:flutter/material.dart';
import 'package:running_app/data/models/workout.dart'; // To potentially get intervals/splits
import 'package:running_app/presentation/providers/settings_provider.dart'; // For units
import 'package:running_app/presentation/utils/format_utils.dart';
import 'package:provider/provider.dart'; // To get settings
import 'package:running_app/domain/use_cases/workout_use_cases.dart'; // For WorkoutSplit type

// TODO: Display calculated splits or intervals in a table/list format

class DetailedSplitView extends StatelessWidget {
  // Option 1: Pass calculated splits
   final List<WorkoutSplit> splits;
   // Option 2: Pass the full workout and calculate splits here? Less efficient.
   // final Workout workout;

  const DetailedSplitView({ required this.splits, super.key });

  @override
  Widget build(BuildContext context) {
    if (splits.isEmpty) {
       return const Center(child: Text("No split data available for this workout."));
    }

     final bool useImperial = context.watch<SettingsProvider>().useImperialUnits;
     final textTheme = Theme.of(context).textTheme;
     final colorScheme = Theme.of(context).colorScheme;
     final String distanceUnit = useImperial ? 'Mile' : 'Km'; // Header unit


    return SingleChildScrollView( // Ensure table is scrollable if many splits
      scrollDirection: Axis.vertical,
      child: DataTable(
         columnSpacing: 16, // Adjust spacing
          horizontalMargin: 8, // Adjust margin
          headingRowHeight: 36,
          dataRowMinHeight: 40,
          dataRowMaxHeight: 48,
          headingTextStyle: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
         columns: [
            DataColumn(label: Text(distanceUnit)), // Split Number (Km/Mile)
            const DataColumn(label: Text('Time'), numeric: true),
             const DataColumn(label: Text('Avg Pace'), numeric: true),
             // TODO: Add optional columns like Elevation Gain/Loss, Avg HR per split
             const DataColumn(label: Text('Elev Gain'), numeric: true),
         ],
         rows: splits.map((split) {
            final splitPace = FormatUtils.formatPace(split.averagePace, useImperial).split(' ')[0]; // Get pace value without unit
            final elevGain = FormatUtils.formatElevation(split.elevationChange.gain); // TODO: Needs unit conversion based on useImperial

            return DataRow(cells: [
              DataCell(Text(split.splitNumber.toString())),
              DataCell(Text(FormatUtils.formatDuration(split.duration.inSeconds))),
              DataCell(Text(splitPace)),
              DataCell(Text(elevGain)),
            ]);
         }).toList(),
      ),
    );
  }
}