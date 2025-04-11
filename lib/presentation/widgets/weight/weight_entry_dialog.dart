import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:running_app/data/models/weight_record.dart';
import 'package:running_app/presentation/utils/format_utils.dart';
import 'package:running_app/utils/logger.dart';

class WeightEntryDialog extends StatefulWidget {
  final double? initialWeightKg;
  final bool useImperial;

  const WeightEntryDialog({ this.initialWeightKg, required this.useImperial, super.key });

  @override
  State<WeightEntryDialog> createState() => _WeightEntryDialogState();
}

class _WeightEntryDialogState extends State<WeightEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _weightController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final initialDisplayWeight = FormatUtils.formatWeightForDisplay(widget.initialWeightKg, widget.useImperial);
    _weightController = TextEditingController(text: initialDisplayWeight);
    _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  }

  @override
  void dispose() { _weightController.dispose(); super.dispose(); }

  Future<void> _selectDate(BuildContext context) async {
     final DateTime? picked = await showDatePicker( context: context, initialDate: _selectedDate,
       firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)), lastDate: DateTime.now(), );
     if (picked != null && picked != _selectedDate) {
       setState(() { _selectedDate = DateTime(picked.year, picked.month, picked.day); });
     }
  }

   double? _parseWeightInput(String weightStr, bool isImperial) {
      double? weight = double.tryParse(weightStr.trim().replaceAll(',', '.'));
      if (weight == null) return null;
      return isImperial ? (weight / 2.20462) : weight; // lbs to kg
   }

   void _saveEntry() {
      if (_formKey.currentState!.validate()) {
         double? weightKg = _parseWeightInput(_weightController.text, widget.useImperial);
          if (weightKg == null || weightKg < 10 || weightKg > 500) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a realistic weight."))); return;
          }
         final newRecord = WeightRecord(date: _selectedDate, weightKg: weightKg);
         Log.d("Saving weight entry: ${newRecord.weightKg} kg for date ${newRecord.date}");
         Navigator.of(context).pop(newRecord);
      }
   }

  @override
  Widget build(BuildContext context) {
     final String unit = widget.useImperial ? 'lbs' : 'kg';
     final String hintText = widget.useImperial ? 'e.g., 165.5' : 'e.g., 75.2';

    return AlertDialog(
      title: const Text('Add Weight Entry'), scrollable: true,
      content: Form( key: _formKey,
        child: Column( mainAxisSize: MainAxisSize.min, children: [
             ListTile( contentPadding: EdgeInsets.zero, leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Date'), subtitle: Text(FormatUtils.formatDateTime(_selectedDate, format: 'EEE, MMM d, yyyy')),
                trailing: const Icon(Icons.edit_outlined, size: 18), onTap: () => _selectDate(context),
             ),
             const SizedBox(height: 16),
             TextFormField( controller: _weightController,
                decoration: InputDecoration( labelText: 'Weight', hintText: hintText, suffixText: unit, icon: const Icon(Icons.monitor_weight_outlined), border: const OutlineInputBorder(), ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+([.,]?\d{0,1})'))],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Please enter weight';
                   if (double.tryParse(value.trim().replaceAll(',', '.')) == null) return 'Invalid number';
                   final parsedKg = _parseWeightInput(value, widget.useImperial);
                   if (parsedKg == null || parsedKg < 10 || parsedKg > 500) return 'Unrealistic weight';
                  return null;
                },
                autofocus: true,
             ),
          ],
        ),
      ),
      actions: [
         TextButton( child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop(), ),
          ElevatedButton( child: const Text('Save Entry'), onPressed: _saveEntry, ),
      ],
    );
  }
}