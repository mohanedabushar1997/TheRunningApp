import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatters
import 'package:provider/provider.dart';
import 'package:running_app/data/models/user_profile.dart';
import 'package:running_app/presentation/providers/settings_provider.dart'; // For units
import 'package:running_app/presentation/providers/user_provider.dart';
import 'package:running_app/presentation/utils/format_utils.dart';
import 'package:running_app/utils/logger.dart';
import 'package:running_app/presentation/widgets/common/loading_indicator.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  static const routeName = '/profile';

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
   final _formKey = GlobalKey<FormState>();
   bool _isEditing = false; // Start in read-only mode

   // Controllers for editable fields
   late TextEditingController _nameController;
   late TextEditingController _weightController;
   late TextEditingController _heightController;
   DateTime? _selectedBirthDate;
   bool _unitsAreImperial = false; // Store initial unit setting

   @override
   void initState() {
     super.initState();
     _initializeControllers();
   }

   @override
   void didChangeDependencies() {
     super.didChangeDependencies();
      // Update if settings change while screen is active
      final newUnits = context.watch<SettingsProvider>().useImperialUnits;
      if (newUnits != _unitsAreImperial) {
         _unitsAreImperial = newUnits;
         // Optionally update controller values if needed based on unit change,
         // but typically we just change the labels/suffixes.
         // If conversion is needed, handle it carefully during save/load.
      }
   }


   void _initializeControllers() {
     final userProfile = context.read<UserProvider>().userProfile;
      final settings = context.read<SettingsProvider>();
      _unitsAreImperial = settings.useImperialUnits;

     _nameController = TextEditingController(text: userProfile?.name ?? '');
     // TODO: Handle unit conversion for display if needed
     _weightController = TextEditingController(text: _formatWeightForDisplay(userProfile?.weight, _unitsAreImperial));
     _heightController = TextEditingController(text: _formatHeightForDisplay(userProfile?.height, _unitsAreImperial));
     _selectedBirthDate = userProfile?.birthDate;
   }

   @override
   void dispose() {
     _nameController.dispose();
     _weightController.dispose();
     _heightController.dispose();
     super.dispose();
   }

   // --- Input Formatting & Conversion Helpers ---
   String _formatWeightForDisplay(double? weightKg, bool isImperial) {
      if (weightKg == null) return '';
      if (isImperial) {
         // Convert kg to lbs
         return (weightKg * 2.20462).toStringAsFixed(1);
      } else {
         return weightKg.toStringAsFixed(1);
      }
   }
    String _formatHeightForDisplay(double? heightCm, bool isImperial) {
      if (heightCm == null) return '';
      if (isImperial) {
          // Convert cm to ft/in (approximate)
          double totalInches = heightCm / 2.54;
          int feet = totalInches ~/ 12;
          int inches = (totalInches % 12).round();
          return "$feet' $inches\""; // e.g., 5' 10"
      } else {
          return heightCm.toStringAsFixed(0); // Show cm without decimal
      }
   }

   double? _parseWeight(String weightStr, bool isImperial) {
       double? weight = double.tryParse(weightStr);
       if (weight == null) return null;
       if (isImperial) {
          // Convert lbs to kg
           return weight / 2.20462;
       } else {
           return weight; // Already in kg
       }
   }
    double? _parseHeight(String heightStr, bool isImperial) {
      if (isImperial) {
          // Parse format like "5' 10\"" or just "70" (inches)
           final parts = heightStr.replaceAll('"', '').split("'");
           try {
               if (parts.length == 2) { // Format "F' I"
                   int feet = int.parse(parts[0].trim());
                   int inches = int.parse(parts[1].trim());
                   return ((feet * 12) + inches) * 2.54; // Convert total inches to cm
               } else if (parts.length == 1) { // Assume total inches "I"
                   int inches = int.parse(parts[0].trim());
                    return inches * 2.54; // Convert inches to cm
               }
           } catch (e) { Log.w("Could not parse imperial height: $heightStr"); return null; }
           return null; // Invalid format
      } else {
         // Assume cm
         return double.tryParse(heightStr);
      }
    }


   // --- Actions ---
   Future<void> _selectDate(BuildContext context) async {
      final initialDate = _selectedBirthDate ?? DateTime.now().subtract(const Duration(days: 365 * 30));
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(1920),
        lastDate: DateTime.now().subtract(const Duration(days: 365 * 10)), // Min age 10
      );
      if (picked != null && picked != _selectedBirthDate) {
        setState(() { _selectedBirthDate = picked; });
      }
   }

   void _toggleEdit() {
      setState(() {
         _isEditing = !_isEditing;
         if (!_isEditing) {
            // If cancelling edit, reset controllers to original profile values
            _initializeControllers();
         }
      });
   }

   Future<void> _saveProfile() async {
      if (!_formKey.currentState!.validate()) {
          return; // Don't save if form is invalid
      }

      final userProvider = context.read<UserProvider>();
      final currentProfile = userProvider.userProfile;
      if (currentProfile == null) {
         Log.e("Cannot save profile, current profile is null.");
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Could not load profile.')));
         return;
      }

      // Parse values, converting units if necessary
      final newWeightKg = _parseWeight(_weightController.text.trim(), _unitsAreImperial);
      final newHeightCm = _parseHeight(_heightController.text.trim(), _unitsAreImperial);

      final updatedProfile = currentProfile.copyWith(
        name: _nameController.text.trim(),
        weight: newWeightKg,
        height: newHeightCm,
        birthDate: _selectedBirthDate,
         // Ensure ID and imperial setting aren't lost
         id: currentProfile.id,
         useImperialUnits: currentProfile.useImperialUnits,
      );

      Log.d("Saving Profile: Name=${updatedProfile.name}, WeightKg=$newWeightKg, HeightCm=$newHeightCm, BirthDate=$_selectedBirthDate");

      try {
          await userProvider.updateUserProfile(updatedProfile);
           if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green)
              );
              setState(() { _isEditing = false; }); // Exit edit mode on success
           }
      } catch (e, s) {
          Log.e("Error saving profile", error: e, stackTrace: s);
           if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text('Error saving profile: $e'), backgroundColor: Colors.red)
              );
           }
      }
   }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final profile = userProvider.userProfile;
    final bool useImperial = context.watch<SettingsProvider>().useImperialUnits; // Watch for unit changes

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Profile' : 'My Profile'),
         actions: [
             IconButton(
                icon: Icon(_isEditing ? Icons.save_outlined : Icons.edit_outlined),
                tooltip: _isEditing ? 'Save Changes' : 'Edit Profile',
                onPressed: _isEditing ? _saveProfile : _toggleEdit,
              ),
              if (_isEditing) // Show cancel button only when editing
                 IconButton(
                    icon: const Icon(Icons.cancel_outlined),
                    tooltip: 'Cancel Edit',
                    onPressed: _toggleEdit,
                 ),
         ],
      ),
      body: userProvider.isLoading && profile == null // Show loading only if profile is initially null
          ? const Center(child: LoadingIndicator())
          : profile == null
              ? const Center(child: Text('Could not load profile data.'))
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      // --- Editable Fields (enabled based on _isEditing) ---
                      TextFormField(
                         controller: _nameController,
                         decoration: const InputDecoration(labelText: 'Display Name', icon: Icon(Icons.person_outline)),
                         enabled: _isEditing,
                         textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                       TextFormField(
                         controller: _weightController,
                         decoration: InputDecoration(labelText: 'Weight', suffixText: useImperial ? 'lbs' : 'kg', icon: const Icon(Icons.monitor_weight_outlined)),
                         enabled: _isEditing,
                         keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}'))], // Allow one decimal place
                         validator: (value) {
                           if (value == null || value.trim().isEmpty) return null; // Allow empty
                            if (double.tryParse(value.trim()) == null) return 'Invalid number';
                            return null;
                         },
                       ),
                       const SizedBox(height: 16),
                       TextFormField(
                         controller: _heightController,
                         decoration: InputDecoration(labelText: 'Height', suffixText: useImperial ? 'ft\' in"' : 'cm', icon: const Icon(Icons.height_outlined)),
                         enabled: _isEditing,
                         keyboardType: useImperial ? TextInputType.text : TextInputType.number, // Allow ' and " for imperial
                          inputFormatters: useImperial ? null : [FilteringTextInputFormatter.digitsOnly],
                         validator: (value) {
                           if (value == null || value.trim().isEmpty) return null; // Allow empty
                           // Basic validation - more complex parsing needed for ft/in
                            if (useImperial) {
                               // Very basic check for imperial format
                                if (!RegExp(r'^\d+(\'\s?\d{1,2}"?)?$').hasMatch(value.trim()) && !RegExp(r'^\d+$').hasMatch(value.trim())) {
                                   return 'Use format like 5\' 10" or total inches';
                                }
                            } else {
                               if (int.tryParse(value.trim()) == null) return 'Invalid number (cm)';
                            }
                            return null;
                         },
                       ),
                        const SizedBox(height: 16),
                         ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.cake_outlined),
                            title: const Text('Birth Date'),
                            subtitle: Text(_selectedBirthDate == null ? 'Not Set' : FormatUtils.formatDateTime(_selectedBirthDate!, format: 'yMMMd')),
                            trailing: _isEditing ? const Icon(Icons.calendar_today_outlined) : null,
                            onTap: _isEditing ? () => _selectDate(context) : null,
                         ),

                         // --- Read-only Info ---
                         const Divider(height: 32),
                         ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.info_outline),
                            title: const Text('Device ID (for support)'),
                            subtitle: Text(profile.id, style: Theme.of(context).textTheme.bodySmall),
                             trailing: IconButton(
                                icon: const Icon(Icons.copy, size: 18),
                                tooltip: 'Copy ID',
                                onPressed: () {
                                   Clipboard.setData(ClipboardData(text: profile.id));
                                   ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Device ID copied to clipboard.'), duration: Duration(seconds: 1)),
                                   );
                                },
                              ),
                         ),
                    ],
                  ),
                ),
    );
  }
}