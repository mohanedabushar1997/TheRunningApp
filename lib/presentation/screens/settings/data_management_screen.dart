import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:running_app/data/sources/database_helper.dart';
import 'package:running_app/presentation/providers/user_provider.dart';
import 'package:running_app/presentation/providers/workout_provider.dart';
import 'package:running_app/presentation/widgets/common/loading_indicator.dart';
import 'package:running_app/utils/logger.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart'; // To clear prefs on delete all

class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({super.key});
  static const routeName = '/settings/data';

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  bool _isBusy = false;
  String _statusMessage = '';

  void _setBusy(bool busy, {String message = ''}) {
    if (mounted) {
      setState(() {
        _isBusy = busy;
        _statusMessage = message;
      });
    }
  }

  void _setStatusMessage(String msg, {required bool isError}) {
     if (mounted) {
        // Clear previous snackbars before showing a new one
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
           content: Text(msg),
           backgroundColor: isError ? Colors.redAccent : Colors.green,
           duration: Duration(seconds: isError ? 5 : 3), // Show errors longer
        ));
     }
  }

  // --- Backup ---
  Future<void> _performBackup() async {
    _setBusy(true, message: 'Creating backup...');
    File? backupFile;
    try {
      final dbHelper = context.read<DatabaseHelper>();
      backupFile = await dbHelper.backupDatabaseToZip();
      if (backupFile == null) throw Exception('Backup file creation failed.');

       if (mounted) {
          _setStatusMessage('Backup created. Preparing to share...', isError: false);
          await _shareBackupFile(backupFile);
       }

    } catch (e, s) {
      Log.e("Backup failed", error: e, stackTrace: s);
       if (mounted) _setStatusMessage('Backup failed: $e', isError: true);
    } finally {
       // Don't set busy false here, let share handle it or timeout
       // _setBusy(false); // Handled after share attempt
    }
  }

  Future<void> _shareBackupFile(File backupFile) async {
     try {
        final xFile = XFile(
           backupFile.path,
           mimeType: 'application/zip',
           name: 'FitStride_Backup_${DateTime.now().toIso8601String().split('T').first}.zip' // Date in filename
        );
        final result = await Share.shareXFiles([xFile], subject: 'FitStride Data Backup');

        if (result.status == ShareResultStatus.success) {
            Log.i('Backup file shared successfully.');
             if (mounted) _setStatusMessage('Backup created and share initiated.', isError: false);
        } else {
             Log.w('Backup file sharing dismissed or failed: ${result.status}');
             if (mounted) _setStatusMessage('Backup created. Sharing cancelled or failed.', isError: false);
        }
     } catch (e, s) {
        Log.e("Error sharing backup file", error: e, stackTrace: s);
         if (mounted) _setStatusMessage('Error sharing backup file: $e', isError: true);
     } finally {
          _setBusy(false); // Set busy false after share attempt completes or fails
          // Optional: Delete the temp zip file after sharing attempt
          // try { await backupFile.delete(); } catch (_) {}
     }
  }

  // --- Restore ---
  Future<void> _performRestore() async {
     bool? confirmRestore = await _showConfirmationDialog(
        title: 'Restore Data?',
        content: 'Restoring data will OVERWRITE all current app data. This cannot be undone. Continue?',
        confirmText: 'Restore Data',
        isDestructive: true,
     );
     if (confirmRestore != true) return;

    _setBusy(true, message: 'Restoring data...');
    String? resultMessage;
    bool success = false;

    try {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
           type: FileType.custom, allowedExtensions: ['zip'],
        );

        if (result?.files.single.path != null) {
           File pickedFile = File(result!.files.single.path!);
           Log.i("User selected restore file: ${pickedFile.path}");

           final dbHelper = context.read<DatabaseHelper>();
           success = await dbHelper.restoreDatabaseFromZip(pickedFile);

           if (success) {
               resultMessage = 'Data restored! Please restart the app.';
                _showRestartDialog(); // Prompt user to restart
           } else {
               resultMessage = 'Restore failed. Data was not overwritten.';
           }
        } else {
           resultMessage = 'Restore cancelled.';
        }
    } catch (e, s) {
       Log.e("Restore failed", error: e, stackTrace: s);
       resultMessage = 'Error during restore: $e';
       success = false;
    } finally {
       _setBusy(false);
       if (resultMessage != null && mounted) {
          _setStatusMessage(resultMessage, isError: !success);
       }
    }
  }

  // --- Export ---
  Future<void> _performExport() async {
    _setBusy(true, message: 'Exporting data...');
     // TODO: Implement actual data export to CSV/JSON
     // Fetch data -> Format -> Save to temp file -> Share file
     await Future.delayed(const Duration(seconds: 1));
     Log.w("Data Export functionality not fully implemented.");
     _setBusy(false);
      if (mounted) _setStatusMessage('Data Export feature coming soon!', isError: false);
  }

  // --- Delete All ---
  Future<void> _performDeleteAll() async {
      bool? confirmDelete = await _showConfirmationDialog(
         title: 'DELETE ALL DATA?',
         content: 'WARNING: This permanently deletes ALL workouts, profile, and settings! Cannot be undone! Proceed?',
         confirmText: 'DELETE EVERYTHING',
         isDestructive: true,
      );
      if (confirmDelete != true) return;

     _setBusy(true, message: 'Deleting all data...');
     String? resultMessage;
     bool success = false;

     try {
        // 1. Clear SharedPreferences
         final prefs = await SharedPreferences.getInstance();
         await prefs.clear();
         Log.i("SharedPreferences cleared.");

        // 2. Delete database file
         final dbHelper = context.read<DatabaseHelper>();
         await dbHelper.close(); // Close connection first
         String dbPath = await dbHelper.databasePath;
         File dbFile = File(dbPath);
         if (await dbFile.exists()) { await dbFile.delete(); }
         Log.i("Database file deleted.");

        // 3. Reset Provider states (or rely on app restart)
         // Force reload which should now create defaults or be empty
         if (context.mounted) {
            await context.read<UserProvider>().loadUserProfile();
            await context.read<WorkoutProvider>().fetchWorkouts();
            await context.read<SettingsProvider>().loadSettings();
             // Reset other providers...
         }

        resultMessage = 'All app data deleted. Please restart the app.';
        success = true;
        _showRestartDialog(); // Prompt restart

     } catch (e, s) {
       Log.e("Delete All Data failed", error: e, stackTrace: s);
       resultMessage = 'Error during deletion: $e';
       success = false;
     } finally {
        _setBusy(false);
        if (resultMessage != null && mounted) {
           _setStatusMessage(resultMessage, isError: !success);
        }
     }
  }

   // --- Dialog Helpers ---
   Future<bool?> _showConfirmationDialog({required String title, required String content, String confirmText = 'Confirm', bool isDestructive = false}) {
      return showDialog<bool>(
         context: context,
         builder: (ctx) => AlertDialog(
           title: Text(title),
           content: Text(content),
           actions: [
             TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx, false)),
             TextButton(
                style: TextButton.styleFrom(foregroundColor: isDestructive ? Colors.red.shade800 : null),
                child: Text(confirmText),
                onPressed: () => Navigator.pop(ctx, true),
             ),
           ],
         ),
       );
   }

   void _showRestartDialog() {
       if (!mounted) return;
      showDialog(
         context: context, barrierDismissible: false,
         builder: (ctx) => AlertDialog( /* ... (same as before) ... */ ),
      );
   }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    // Use Theme for consistent styling
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar( title: const Text('Data Management') ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(8.0), // Reduced padding
            children: [
              _buildSectionHeader(context, 'Backup & Restore'),
              Card( // Wrap actions in Cards for better visual grouping
                 elevation: 1,
                 child: Column(
                   children: [
                      ListTile(
                        leading: const Icon(Icons.backup_outlined),
                        title: const Text('Backup Data'),
                        subtitle: const Text('Save a copy of app data to a shareable file.'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _isBusy ? null : _performBackup,
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: const Icon(Icons.restore_outlined),
                        title: const Text('Restore Data'),
                        subtitle: const Text('Restore from a backup file (overwrites current data).'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _isBusy ? null : _performRestore,
                      ),
                   ],
                 ),
              ),
              const SizedBox(height: 16),

              _buildSectionHeader(context, 'Export'),
               Card(
                  elevation: 1,
                  child: ListTile(
                    leading: const Icon(Icons.ios_share_outlined),
                    title: const Text('Export Workouts (CSV)'),
                    subtitle: const Text('Export workout history to a CSV file (Coming Soon).'),
                     trailing: const Icon(Icons.chevron_right),
                     onTap: _isBusy ? null : _performExport, // Disabled for now
                  ),
               ),
              const SizedBox(height: 16),

               _buildSectionHeader(context, 'Danger Zone'),
                Card(
                   elevation: 1,
                   color: colorScheme.errorContainer.withOpacity(0.3), // Subtle error background
                   child: ListTile(
                     leading: Icon(Icons.delete_forever_outlined, color: colorScheme.error),
                     title: Text('Delete All App Data', style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold)),
                     subtitle: const Text('Permanently remove all local data.'),
                     onTap: _isBusy ? null : _performDeleteAll,
                   ),
                ),
            ],
          ),

           // Loading Overlay
           if (_isBusy)
              Container(
                 color: Colors.black.withOpacity(0.6),
                 child: Center( /* ... (same as before) ... */ ),
              ),
        ],
      ),
    );
  }

   Widget _buildSectionHeader(BuildContext context, String title) {
       // ... (same implementation as before) ...
       return Padding( padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 8.0), child: Text( title.toUpperCase(), style: TextStyle( color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8, ), ), );
   }
}