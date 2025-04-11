import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:running_app/presentation/utils/format_utils.dart';
import 'package:running_app/utils/logger.dart';

class WeightGoalDialog extends StatefulWidget {
  final double? currentGoalKg;
  final bool useImperial;

  const WeightGoalDialog({ this.currentGoalKg, required this.useImperial, super.key });

  @override
  State<WeightGoalDialog> createState() => _WeightGoalDialogState();
}

class _WeightGoalDialogState extends State<WeightGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _goalWeightController;

  @override
  void initState() {
    super.initState();
    final initialDisplayWeight = FormatUtils.formatWeightForDisplay(widget.currentGoalKg, widget.useImperial);
    _goalWeightController = TextEditingController(text: initialDisplayWeight);
  }

  @override
  void dispose() { _goalWeightController.dispose(); super.dispose(); }

   double? _parseWeightInput(String weightStr, bool isImperial) {
       double? weight = double.tryParse(weightStr.trim().replaceAll(',', '.'));
       if (weight == null) return null;
       return isImperial ? (weight / 2.20462) : weight;
   }

  void _saveGoal() {
     if (_goalWeightController.text.trim().isEmpty) { Log.d("Clearing weight goal."); Navigator.of(context).pop('CLEAR'); return; }
     if (_formKey.currentState!.validate()) {
        double? goalWeightKg = _parseWeightInput(_goalWeightController.text, widget.useImperial);
        if (goalWeightKg == null || goalWeightKg < 20 || goalWeightKg > 250) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a realistic goal."))); return;
        }
        Log.d("Setting weight goal: ${goalWeightKg.toStringAsFixed(1)} kg");
        Navigator.of(context).pop(goalWeightKg);
     }
  }

  @override
  Widget build(BuildContext context) {
     final String unit = widget.useImperial ? 'lbs' : 'kg';
     final String hintText = widget.useImperial ? 'e.g., 155.0' : 'e.g., 70.0';

    return AlertDialog(
      title: const Text('Set Weight Goal'), scrollable: true,
      content: Form( key: _formKey,
        child: TextFormField(
           controller: _goalWeightController,
           decoration: InputDecoration( labelText: 'Goal Weight', hintText: hintText, suffixText: unit, icon: const Icon(Icons.flag_outlined), border: const OutlineInputBorder(), ),
           keyboardType: const TextInputType.numberWithOptions(decimal: true),
           inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+([.,]?\d{0,1})'))],
           validator: (value) {
             if (value == null || value.trim().isEmpty) return null; // Allow empty to clear
             if (double.tryParse(value.trim().replaceAll(',', '.')) == null) return 'Invalid number';
              final parsedKg = _parseWeightInput(value, widget.useImperial);
              if (parsedKg == null || parsedKg < 20 || parsedKg > 250) return 'Unrealistic goal';
             return null;
           },
           autofocus: true,
        ),
      ),
      actions: [
          TextButton( child: const Text('Clear Goal'), style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
             onPressed: () { _goalWeightController.clear(); _saveGoal(); }
           ),
         TextButton( child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop(), ),
          ElevatedButton( child: const Text('Set Goal'), onPressed: _saveGoal, ),
      ],
    );
  }
}