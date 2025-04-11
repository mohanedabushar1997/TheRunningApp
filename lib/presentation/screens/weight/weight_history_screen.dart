import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:running_app/data/models/weight_record.dart';
import 'package:running_app/presentation/providers/weight_provider.dart';
import 'package:running_app/presentation/widgets/common/loading_indicator.dart';
import 'package:running_app/presentation/utils/format_utils.dart';
import 'package:running_app/presentation/providers/settings_provider.dart';
import 'package:running_app/presentation/widgets/weight/weight_chart.dart';
import 'package:running_app/presentation/widgets/weight/weight_entry_dialog.dart';
import 'package:running_app/presentation/widgets/common/empty_state_widget.dart';
import 'package:running_app/utils/logger.dart';
import 'package:running_app/presentation/utils/error_handling_utils.dart';

class WeightHistoryScreen extends StatelessWidget {
  const WeightHistoryScreen({super.key});
  static const routeName = '/weight-history';

  @override
  Widget build(BuildContext context) {
    final weightProvider = context.watch<WeightProvider>();
    final bool useImperial = context.watch<SettingsProvider>().useImperialUnits;

     if (weightProvider.records.isEmpty && !weightProvider.isLoading && weightProvider.errorMessage == null) {
         WidgetsBinding.instance.addPostFrameCallback((_) {
             if (context.read<WeightProvider>().records.isEmpty && !context.read<WeightProvider>().isLoading) {
                 context.read<WeightProvider>().loadRecords();
             }
         });
     }

    final weightRecords = weightProvider.records;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weight History'),
        actions: [
           // TODO: Add button to set goal weight?
           // IconButton(...)
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => weightProvider.loadRecords(forceRefresh: true),
        child: Column(
          children: [
            // --- Chart Section ---
            Padding(
               padding: const EdgeInsets.all(16.0),
               child: SizedBox(
                  height: 250,
                  child: weightProvider.isLoading && weightRecords.isEmpty
                      ? const Center(child: LoadingIndicator())
                      : weightRecords.length < 2
                          ? Card(elevation: 1, child: EmptyStateWidget(message: 'Add at least two entries\nto see your weight chart.', icon: Icons.show_chart))
                          : WeightChart(records: weightRecords, useImperial: useImperial),
               ),
            ),

            // --- History List Header ---
             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 16.0),
               child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     Text('History', style: Theme.of(context).textTheme.titleLarge),
                      if (weightRecords.isNotEmpty)
                         Text(
                            'Latest: ${FormatUtils.formatWeightForDisplay(weightRecords.first.weightKg, useImperial)} ${useImperial ? 'lbs' : 'kg'}',
                            style: Theme.of(context).textTheme.bodyMedium,
                         )
                  ],
               ),
             ),
            const Divider(indent: 16, endIndent: 16, height: 16),

            // --- History List ---
            Expanded(
              child: weightProvider.isLoading && weightRecords.isEmpty
                  ? const SizedBox.shrink()
                  : weightRecords.isEmpty
                      ? EmptyStateWidget(message: 'No weight records yet.\nTap the + button to add one.', icon: Icons.monitor_weight_outlined)
                      : ListView.separated(
                           itemCount: weightRecords.length,
                            padding: const EdgeInsets.only(bottom: 80),
                           itemBuilder: (context, index) {
                             final record = weightRecords[index];
                             final weightStr = FormatUtils.formatWeightForDisplay(record.weightKg, useImperial);
                             final unit = useImperial ? 'lbs' : 'kg';
                              String changeStr = '';
                              if (index < weightRecords.length - 1) {
                                 final prevRecord = weightRecords[index + 1];
                                  double changeKg = record.weightKg - prevRecord.weightKg;
                                   String changeValStr = FormatUtils.formatWeightForDisplay(changeKg.abs(), useImperial);
                                  if (changeKg > 0.05) { changeStr = '(+$changeValStr $unit)'; }
                                  else if (changeKg < -0.05) { changeStr = '(-$changeValStr $unit)'; }
                              }

                             return ListTile(
                               dense: true,
                               title: Row(
                                 children: [
                                   Text('$weightStr $unit', style: Theme.of(context).textTheme.titleMedium),
                                   const SizedBox(width: 8),
                                    if (changeStr.isNotEmpty) Text(changeStr, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: changeStr.startsWith('(+') ? Colors.redAccent : Colors.green)),
                                 ],
                               ),
                               subtitle: Text(FormatUtils.formatDateTime(record.date, format: 'EEE, MMM d, YYYY')), // Full date
                                trailing: IconButton(
                                   icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                                   tooltip: 'Delete Entry',
                                   onPressed: () async {
                                       bool? confirm = await ErrorHandlingUtils.showConfirmationDialog(
                                          context: context, title: 'Delete Entry?', isDestructive: true,
                                          content: 'Delete weight record from ${FormatUtils.formatDateTime(record.date, format: 'MMM d')}?', confirmText: 'Delete',
                                       );
                                       if (confirm == true) { weightProvider.deleteRecord(record); }
                                   },
                                ),
                             );
                           },
                            separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
                         ),
            ),
          ],
        ),
      ),
       floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          tooltip: 'Add Weight Entry',
          onPressed: () async {
             final WeightRecord? newRecord = await showDialog<WeightRecord>(
                context: context,
                builder: (_) => WeightEntryDialog(
                   initialWeightKg: weightRecords.isNotEmpty ? weightRecords.first.weightKg : context.read<UserProvider>().userProfile?.weight,
                   useImperial: useImperial,
                ),
             );
             if (newRecord != null && context.mounted) {
                context.read<WeightProvider>().addRecord(newRecord);
             }
          },
       ),
    );
  }
}