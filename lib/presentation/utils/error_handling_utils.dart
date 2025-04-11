import 'package:flutter/material.dart';
import 'package:running_app/utils/logger.dart';

class ErrorHandlingUtils {
  ErrorHandlingUtils._(); // Private constructor

  /// Shows a simple Snackbar with an error message.
  static void showErrorSnackbar(BuildContext context, String message, {Duration duration = const Duration(seconds: 4)}) {
     // Ensure context is still valid before showing snackbar
     if (!context.mounted) {
         Log.w("Attempted to show error snackbar on unmounted context: $message");
         return;
     }
     ScaffoldMessenger.of(context).hideCurrentSnackBar();
     ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
           content: Text(message),
           backgroundColor: Theme.of(context).colorScheme.error,
           duration: duration,
           behavior: SnackBarBehavior.floating,
            action: SnackBarAction(label: 'Dismiss', onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar()),
        ),
     );
     Log.e("Snackbar Error Displayed: $message");
  }

  /// Shows a simple confirmation dialog.
  static Future<bool?> showConfirmationDialog({
     required BuildContext context,
     required String title,
     required String content,
     String confirmText = 'Confirm',
     String cancelText = 'Cancel',
     bool isDestructive = false,
   }) {
      if (!context.mounted) return Future.value(null);
      return showDialog<bool>(
         context: context,
         builder: (ctx) => AlertDialog(
           title: Text(title),
           content: Text(content),
           actions: <Widget>[
             TextButton(
                child: Text(cancelText),
                onPressed: () => Navigator.of(ctx).pop(false),
             ),
             TextButton(
                style: TextButton.styleFrom(
                   foregroundColor: isDestructive ? Theme.of(ctx).colorScheme.error : null,
                ),
                child: Text(confirmText),
                onPressed: () => Navigator.of(ctx).pop(true),
             ),
           ],
         ),
       );
   }

    /// Shows a simple informational dialog.
    static Future<void> showInfoDialog({
       required BuildContext context,
       required String title,
       required String content,
       String dismissText = 'OK',
    }) {
        if (!context.mounted) return Future.value();
       return showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: <Widget>[
              TextButton(
                 child: Text(dismissText),
                 onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
    }

     // Example: Specific error dialog for permissions
      static Future<void> showPermissionErrorDialog(BuildContext context, String permissionName) async {
          await showInfoDialog(
             context: context,
             title: '$permissionName Permission Required',
             content: 'FitStride needs the $permissionName permission to function correctly. Please grant the permission in your device settings.',
             // TODO: Add button to open app settings directly
          );
      }

      // Example: Specific error dialog for GPS disabled
       static Future<void> showGpsDisabledDialog(BuildContext context) async {
          await showInfoDialog(
             context: context,
             title: 'Location Services Disabled',
             content: 'Please enable location services on your device for accurate workout tracking.',
             // TODO: Add button to open location settings directly
          );
       }

}