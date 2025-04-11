import 'dart:math';
import '../data/models/workout.dart';
import '../data/models/user_profile.dart';
import '../data/models/location_data.dart';
import 'logger.dart';

/// A utility class that provides improved calculations for workout metrics.
///
/// This includes more accurate calorie calculations based on user attributes (weight, age, gender),
/// improved pace calculations with smoothing algorithms, and elevation gain/loss calculations.
class WorkoutCalculations {
  /// Calculate calories burned based on user profile, workout type, and metrics.
  ///
  /// Uses the MET (Metabolic Equivalent of Task) formula which provides more accurate
  /// results than simple distance-based calculations.
  static int calculateCaloriesBurned({
    required WorkoutType workoutType,
    required int durationMinutes,
    required double distanceKm,
    required double avgSpeedKmh,
    required UserProfile? userProfile,
    double? avgHeartRate,
    double? elevationGainMeters,
  }) {
    try {
      // Default weight if no profile available (70kg - average adult)
      final double weightKg = userProfile?.weight ?? 70.0;
      final bool isMale = userProfile?.gender == Gender.male;
      final int age = userProfile?.age ?? 30;

      // Base MET values for different activities
      double met;

      // Assign MET values based on workout type and speed
      // Values derived from the Compendium of Physical Activities
      switch (workoutType) {
        case WorkoutType.walking:
          if (avgSpeedKmh < 3.2) {
            met = 2.0; // Very slow walking
          } else if (avgSpeedKmh < 4.0) {
            met = 2.5; // Slow walking
          } else if (avgSpeedKmh < 4.8) {
            met = 3.0; // Moderate walking
          } else if (avgSpeedKmh < 5.6) {
            met = 3.8; // Brisk walking
          } else if (avgSpeedKmh < 6.4) {
            met = 5.0; // Very brisk walking
          } else {
            met = 6.3; // Speed walking
          }
          break;

        case WorkoutType.jogging:
          if (avgSpeedKmh < 6.4) {
            met = 6.0;
          } else if (avgSpeedKmh < 8.0) {
            met = 8.3;
          } else if (avgSpeedKmh < 9.7) {
            met = 9.8;
          } else {
            met = 11.0;
          }
          break;

        case WorkoutType.running:
          if (avgSpeedKmh < 8.0) {
            met = 8.3; // Light running
          } else if (avgSpeedKmh < 9.7) {
            met = 9.8; // Moderate running
          } else if (avgSpeedKmh < 11.3) {
            met = 11.0; // Fast running
          } else if (avgSpeedKmh < 12.9) {
            met = 11.8; // Faster running
          } else if (avgSpeedKmh < 14.5) {
            met = 12.8; // Very fast running
          } else {
            met = 14.5; // Extremely fast running
          }
          break;

        case WorkoutType.interval:
          // For interval training, we use the average of jogging and running
          met = 10.0;
          break;
      }

      // Adjust MET for elevation gain if available
      if (elevationGainMeters != null && elevationGainMeters > 50) {
        // Add 0.2 MET for every 50m of elevation gain
        final double elevationAdjustment = (elevationGainMeters / 50) * 0.2;
        // Cap the adjustment at 2.0 additional METs
        met += min(elevationAdjustment, 2.0);
      }

      // Calculate BMR (Basal Metabolic Rate) using Mifflin-St Jeor Equation
      double bmr;
      if (isMale) {
        bmr = 10 * weightKg +
            6.25 * (userProfile?.height ?? 175) -
            5 * age.toDouble() +
            5;
      } else {
        bmr = 10 * weightKg +
            6.25 * (userProfile?.height ?? 163) -
            5 * age.toDouble() -
            161;
      }

      // Calculate calories per minute at rest
      final double caloriesPerMinuteAtRest =
          bmr / 1440; // 1440 minutes in a day

      // Calculate calories burned during activity
      final double caloriesBurned =
          met * caloriesPerMinuteAtRest * durationMinutes;

      // Heart rate adjustment if available (bonus accuracy)
      if (avgHeartRate != null && avgHeartRate > 0) {
        // Calculate percentage of max heart rate
        final double maxHeartRate = 220.0 - age.toDouble();
        final double percentMaxHR = avgHeartRate / maxHeartRate;

        // If heart rate is high relative to activity, adjust calories upward slightly
        if (percentMaxHR > 0.7) {
          return (caloriesBurned * 1.1)
              .round(); // 10% increase for high intensity
        }
      }

      return caloriesBurned.round();
    } catch (e, stackTrace) {
      AppLogger.error('Error calculating calories burned', e, stackTrace);

      // Fallback to simple calculation based on MET if detailed calculation fails
      final double weightKg = userProfile?.weight ?? 70.0;
      double basicMet = workoutType == WorkoutType.walking
          ? 3.5
          : workoutType == WorkoutType.jogging
              ? 7.0
              : 10.0;

      return ((basicMet * 3.5 * weightKg * durationMinutes) / 200).round();
    }
  }

  /// Calculate average pace with outlier filtering
  ///
  /// Uses a windowed average with outlier removal for smoother pace data
  static double calculateSmoothedPace(List<double> rawPaces) {
    try {
      if (rawPaces.isEmpty) return 0;
      if (rawPaces.length == 1) return rawPaces.first;

      // Sort paces to find quartiles for outlier detection
      final sortedPaces = List<double>.from(rawPaces)..sort();
      final q1Index = (sortedPaces.length * 0.25).floor();
      final q3Index = (sortedPaces.length * 0.75).floor();
      final q1 = sortedPaces[q1Index];
      final q3 = sortedPaces[q3Index];

      // Calculate interquartile range (IQR)
      final iqr = q3 - q1;

      // Define outlier bounds (1.5 * IQR)
      final lowerBound = q1 - (1.5 * iqr);
      final upperBound = q3 + (1.5 * iqr);

      // Filter out outliers
      final filteredPaces = rawPaces
          .where((pace) => pace >= lowerBound && pace <= upperBound && pace > 0)
          .toList();

      // Calculate average of filtered paces
      if (filteredPaces.isEmpty) {
        // Fall back to median if all values were outliers
        return sortedPaces[sortedPaces.length ~/ 2];
      }

      return filteredPaces.reduce((a, b) => a + b) / filteredPaces.length;
    } catch (e, stackTrace) {
      AppLogger.error('Error calculating smoothed pace', e, stackTrace);

      // Fallback to simple average
      return rawPaces.isEmpty
          ? 0
          : rawPaces.reduce((a, b) => a + b) / rawPaces.length;
    }
  }

  /// Calculate elevation changes from a list of location points
  ///
  /// Returns a map with 'gain' and 'loss' keys containing elevation changes in meters
  static Map<String, double> calculateElevationChanges(
      List<LocationData> locations,
      {double noiseThreshold = 1.5}) {
    double gain = 0;
    double loss = 0;

    try {
      if (locations.length < 2) return {'gain': 0, 'loss': 0};

      // Apply a simple noise filter to eliminate GPS altitude noise
      for (int i = 1; i < locations.length; i++) {
        final prevAlt = locations[i - 1].altitude ?? 0;
        final currentAlt = locations[i].altitude ?? 0;
        final diff = currentAlt - prevAlt;

        // Only count elevation changes above the noise threshold
        if (diff.abs() >= noiseThreshold) {
          if (diff > 0) {
            gain += diff;
          } else {
            loss += diff.abs();
          }
        }
      }

      return {'gain': gain, 'loss': loss};
    } catch (e, stackTrace) {
      AppLogger.error('Error calculating elevation changes', e, stackTrace);
      return {'gain': gain, 'loss': loss};
    }
  }

  /// Calculate grade-adjusted pace (GAP)
  ///
  /// Adjusts pace based on elevation grade to provide a more accurate effort measure
  static double calculateGradeAdjustedPace({
    required double paceSecondsPerKm,
    required double elevationChangeMeters,
    required double distanceKm,
  }) {
    try {
      if (distanceKm <= 0) return paceSecondsPerKm;

      // Calculate the average grade (as a percentage)
      final double grade = (elevationChangeMeters / (distanceKm * 1000)) * 100;

      // Apply grade adjustment factor
      // Research shows roughly 2% pace increase per 1% uphill grade
      // And roughly 1% pace decrease per 1% downhill grade (to a point)
      double adjustmentFactor = 1.0;

      if (grade > 0) {
        // Uphill: Harder effort needed
        adjustmentFactor = 1.0 -
            (grade *
                0.02); // Subtract from 1.0 because lower pace value = faster
        adjustmentFactor = max(adjustmentFactor, 0.5); // Cap adjustment at 50%
      } else {
        // Downhill: Easier effort, but extremely steep downhills aren't proportionally easier
        final absGrade = grade.abs();
        if (absGrade <= 10) {
          adjustmentFactor = 1.0 +
              (absGrade *
                  0.01); // Add to 1.0 because higher pace value = slower
        } else {
          // Beyond -10% grade, additional steepness doesn't make running proportionally easier
          adjustmentFactor = 1.0 + (10 * 0.01) + ((absGrade - 10) * 0.005);
        }
      }

      return paceSecondsPerKm * adjustmentFactor;
    } catch (e, stackTrace) {
      AppLogger.error('Error calculating grade-adjusted pace', e, stackTrace);
      return paceSecondsPerKm;
    }
  }

  /// Calculate workout intensity score
  ///
  /// Provides a 0-100 score based on workout metrics to help users gauge workout intensity
  static int calculateIntensityScore({
    required WorkoutType workoutType,
    required double distanceKm,
    required int durationMinutes,
    required double paceSecondsPerKm,
    double? elevationGainMeters,
    double? heartRateAvg,
    int? userAge,
  }) {
    try {
      // Base intensity factors
      int baseIntensity;
      switch (workoutType) {
        case WorkoutType.walking:
          baseIntensity = 30;
          break;
        case WorkoutType.jogging:
          baseIntensity = 50;
          break;
        case WorkoutType.running:
          baseIntensity = 70;
          break;
        case WorkoutType.interval:
          baseIntensity = 80;
          break;
      }

      // Distance factor: Longer distances increase intensity
      final distanceFactor =
          min(distanceKm / 5, 1.0) * 20; // Max 20 points for distance

      // Pace factor: Faster paces increase intensity
      double paceFactor = 0;
      switch (workoutType) {
        case WorkoutType.walking:
          // For walking, 600 sec/km (10:00 min/km) is slow, 360 sec/km (6:00 min/km) is fast
          paceFactor = max(0, min(20, (600 - paceSecondsPerKm) / 12));
          break;
        case WorkoutType.jogging:
          // For jogging, 420 sec/km (7:00 min/km) is slow, 270 sec/km (4:30 min/km) is fast
          paceFactor = max(0, min(20, (420 - paceSecondsPerKm) / 7.5));
          break;
        case WorkoutType.running:
        case WorkoutType.interval:
          // For running, 360 sec/km (6:00 min/km) is slow, 210 sec/km (3:30 min/km) is fast
          paceFactor = max(0, min(20, (360 - paceSecondsPerKm) / 7.5));
          break;
      }

      // Elevation factor: More elevation gain increases intensity
      final elevationFactor =
          min((elevationGainMeters ?? 0) / 100, 1.0) * 15; // Max 15 points

      // Heart rate factor if available
      double hrFactor = 0;
      if (heartRateAvg != null && userAge != null) {
        final maxHR = 220.0 - userAge.toDouble();
        final hrPercentage = heartRateAvg / maxHR;
        hrFactor = min(hrPercentage * 100, 1.0) * 15; // Max 15 points
      }

      // Calculate final score
      int intensityScore = (baseIntensity +
              distanceFactor +
              paceFactor +
              elevationFactor +
              hrFactor)
          .round();

      // Cap at 0-100
      return max(0, min(intensityScore, 100));
    } catch (e, stackTrace) {
      AppLogger.error('Error calculating intensity score', e, stackTrace);

      // Fallback simple calculation
      int baseScore = workoutType == WorkoutType.walking
          ? 30
          : workoutType == WorkoutType.jogging
              ? 50
              : workoutType == WorkoutType.running
                  ? 70
                  : 80;

      return min(baseScore + (distanceKm * 2).round(), 100);
    }
  }

  /// Calculate training effect from workout
  ///
  /// Returns a score from 1.0-5.0 based on workout metrics to indicate cardio training effect
  static double calculateTrainingEffect({
    required WorkoutType workoutType,
    required int durationMinutes,
    required double avgSpeedKmh,
    double? heartRateAvg,
    int? userAge,
    double? vo2Max,
  }) {
    try {
      // Simple algorithm if we don't have heart rate data
      if (heartRateAvg == null || userAge == null) {
        // Base training effect by workout type
        double baseEffect = workoutType == WorkoutType.walking
            ? 1.5
            : workoutType == WorkoutType.jogging
                ? 2.5
                : workoutType == WorkoutType.running
                    ? 3.0
                    : 3.5;

        // Adjust by duration - longer workouts have more training effect
        double durationFactor =
            min(durationMinutes / 60, 1.0); // Max 1.0 for 60+ minutes

        // Adjust by speed
        double speedFactor = min(avgSpeedKmh / 12, 1.0); // Max 1.0 for 12+ km/h

        // Calculate final effect
        return min(baseEffect + durationFactor + speedFactor, 5.0);
      }

      // More accurate algorithm with heart rate data
      final maxHR = 220.0 - userAge.toDouble();
      final hrPercentage = heartRateAvg / maxHR;

      // Base effect from heart rate percentage
      double trainingEffect;
      if (hrPercentage < 0.6) {
        trainingEffect = 1.0; // Very light
      } else if (hrPercentage < 0.7) {
        trainingEffect = 2.0; // Light
      } else if (hrPercentage < 0.8) {
        trainingEffect = 3.0; // Moderate
      } else if (hrPercentage < 0.9) {
        trainingEffect = 4.0; // Hard
      } else {
        trainingEffect = 5.0; // Very hard
      }

      // Adjust by duration
      if (durationMinutes < 20) {
        trainingEffect *= 0.8; // Short workouts have less effect
      } else if (durationMinutes > 60) {
        trainingEffect =
            min(trainingEffect * 1.2, 5.0); // Longer workouts have more effect
      }

      return trainingEffect;
    } catch (e, stackTrace) {
      AppLogger.error('Error calculating training effect', e, stackTrace);

      // Simple fallback
      return min(1.0 + durationMinutes / 30, 5.0);
    }
  }
}
