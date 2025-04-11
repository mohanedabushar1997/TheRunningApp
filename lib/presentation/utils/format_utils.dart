import 'package:intl/intl.dart';
import 'package:running_app/data/models/workout.dart'; // For WorkoutType

// Utility class for formatting various data types for display.
class FormatUtils {
  FormatUtils._(); // Private constructor

  // --- Duration Formatting ---
  static String formatDuration(int? totalSeconds) {
     if (totalSeconds == null || totalSeconds < 0) return '--:--';

    final duration = Duration(seconds: totalSeconds);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (hours > 0) {
      return "$hours:$minutes:$seconds"; // HH:MM:SS
    } else {
      return "$minutes:$seconds"; // MM:SS
    }
  }

  // --- Distance Formatting ---
  static String formatDistance(double? distanceInMeters, bool useImperial) {
     if (distanceInMeters == null || distanceInMeters < 0) return '--';

    double distance;
    String unit;

    if (useImperial) {
      distance = distanceInMeters * 0.000621371; // meters to miles
      unit = 'mi';
    } else {
      distance = distanceInMeters / 1000.0; // meters to km
      unit = 'km';
    }

    if (distance < 0.01 && distance > 0) return '< 0.01 $unit';
    // Show 1 decimal place for larger distances, 2 for smaller ones?
    if (distance >= 10.0) {
       return '${distance.toStringAsFixed(1)} $unit';
    } else {
        return '${distance.toStringAsFixed(2)} $unit';
    }
  }

  // --- Pace Formatting ---
  static String formatPace(double? paceInSecondsPerKilometer, bool useImperial) {
    if (paceInSecondsPerKilometer == null || paceInSecondsPerKilometer <= 0) return '--:--';

    double pace = paceInSecondsPerKilometer;
    String unitSuffix = '/km';

    if (useImperial) {
      // Convert seconds per km to seconds per mile
      pace = paceInSecondsPerKilometer * 1.60934;
      unitSuffix = '/mi';
    }

    if (pace.isInfinite || pace.isNaN) return '--:--';

    final int minutes = pace ~/ 60;
    final int seconds = (pace % 60).round();
    // Pad seconds with leading zero if needed
    return '${minutes.toString()}:${seconds.toString().padLeft(2, '0')} $unitSuffix';
  }


  // --- Speed Formatting ---
   static String formatSpeed(double? speedInMetersPerSecond, bool useImperial) {
    if (speedInMetersPerSecond == null || speedInMetersPerSecond < 0) return '--';

    double speed;
    String unit;

    if (useImperial) {
      speed = speedInMetersPerSecond * 2.23694; // m/s to mph
      unit = 'mph';
    } else {
      speed = speedInMetersPerSecond * 3.6; // m/s to km/h
      unit = 'km/h';
    }
     if (speed.isNaN || speed.isInfinite) return '--';
    return '${speed.toStringAsFixed(1)} $unit';
  }


  // --- Calorie Formatting ---
  static String formatCalories(int? calories) {
    if (calories == null || calories <= 0) return '-- kcal'; // Return 0 or '--'?
    final formatter = NumberFormat('#,##0');
    return '${formatter.format(calories)} kcal';
  }

  // --- Date/Time Formatting ---
  static String formatDateTime(DateTime dt, {String format = 'MMM d, yyyy HH:mm'}) {
    try {
      // Use locale-aware formatting if possible (requires intl setup in main.dart)
      // final locale = WidgetsBinding.instance.platformDispatcher.locale.toString();
      // return DateFormat(format, locale).format(dt);
      return DateFormat(format).format(dt); // Default non-locale-aware
    } catch (e) {
      // Fallback for invalid format string or locale issues
      return DateFormat.yMd().add_jm().format(dt);
    }
  }

  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(checkDate).inDays;

    try {
      if (difference == 0) {
        return 'Today'; // Just 'Today' without time for lists?
        // return 'Today, ${DateFormat.jm().format(date)}'; // Today, 2:30 PM
      } else if (difference == 1) {
        return 'Yesterday';
        // return 'Yesterday, ${DateFormat.jm().format(date)}'; // Yesterday, 9:00 AM
      } else if (difference > 1 && difference < 7) {
        // Within the last week
        return DateFormat.EEEE().format(date); // e.g., Tuesday
      } else {
        // Older than a week - show date without year if same year?
         if (date.year == now.year) {
            return DateFormat.MMMd().format(date); // e.g., Jan 5
         } else {
             return DateFormat.yMMMd().format(date); // e.g., Jan 5, 2023
         }
      }
    } catch (e) {
       return DateFormat.yMd().format(date); // Fallback
    }
  }

   // --- Workout Type Formatting ---
   static String formatWorkoutType(WorkoutType type) {
     // Use extension method on enum? Or keep here for consistency.
     switch (type) {
       case WorkoutType.run: return 'Run';
       case WorkoutType.cycle: return 'Cycle';
       case WorkoutType.walk: return 'Walk';
       case WorkoutType.treadmill: return 'Treadmill';
     }
   }

   // --- Elevation Formatting ---
    static String formatElevation(double? elevationInMeters) {
      if (elevationInMeters == null || elevationInMeters.isNaN || elevationInMeters.isInfinite) return '--';
      // TODO: Add imperial conversion (meters to feet) based on SettingsProvider
      // bool useImperial = ... get setting ...;
      // if (useImperial) {
      //    double feet = elevationInMeters * 3.28084;
      //    return '${feet.round()} ft';
      // }
      return '${elevationInMeters.round()} m';
    }

    // --- Heart Rate Formatting ---
    static String formatHeartRate(int? hr) {
      if (hr == null || hr <= 0) return '--';
      return '$hr bpm';
    }

}
(Code continues in the next response due to length)





(Code continues in the next response due to length)



Show thinking
Okay, here is the final batch containing the ~25 prioritized remaining files.

As mentioned before, this batch covers the most critical remaining screens, widgets, services, models, and utilities to establish the core application structure with the requested fixes and implemented TODOs (using placeholders for very complex features).

You will need to continue development on the items marked TODO, especially the detailed logic for background services, charting, achievements, training plans, etc.

Final Batch (Remaining Core Files)