import 'dart:math';
import 'package:running_app/data/models/route_point.dart';
import 'package:running_app/data/models/user_profile.dart';
import 'package:running_app/data/models/workout.dart';
import 'package:running_app/data/models/workout_interval.dart'; // Import interval
import 'package:latlong2/latlong.dart';
import 'package:running_app/utils/logger.dart';

// Data structure for workout update calculations
class WorkoutUpdateResult {
  final double newTotalDistance;
  final double distanceDelta;
  final double? currentPace; // seconds per kilometer
  final ElevationChange elevationChange;

  WorkoutUpdateResult({
    required this.newTotalDistance,
    required this.distanceDelta,
    this.currentPace,
    required this.elevationChange,
  });
}

class ElevationChange {
   final double gain;
   final double loss;
   const ElevationChange({this.gain = 0.0, this.loss = 0.0});

   ElevationChange operator +(ElevationChange other) {
      return ElevationChange(gain: gain + other.gain, loss: loss + other.loss);
   }
}

// Data structure for splits
class WorkoutSplit {
   final int splitNumber; // e.g., 1 for first km/mile
   final double distance; // Distance of this split (e.g., 1000m or 1609m)
   final Duration duration;
   final double? averagePace; // sec/km
   final ElevationChange elevationChange;

   WorkoutSplit({
      required this.splitNumber,
      required this.distance,
      required this.duration,
      this.averagePace,
      required this.elevationChange,
   });
}


class WorkoutUseCases {
  final Distance _distanceCalculator = const Distance(roundResult: false); // More precise distance

  /// Calculates updates based on a new route point.
  WorkoutUpdateResult calculateWorkoutUpdate({
    required RoutePoint newPoint,
    RoutePoint? lastPoint,
    required double currentDistance,
    required Duration currentDuration,
  }) {
    double distanceDelta = 0;
    double? currentPace;
    ElevationChange elevationChange = const ElevationChange();

    if (lastPoint != null && newPoint.timestamp.isAfter(lastPoint.timestamp)) {
       final timeDeltaSeconds = newPoint.timestamp.difference(lastPoint.timestamp).inMilliseconds / 1000.0;

       // Calculate distance using Haversine formula via latlong2
       distanceDelta = _distanceCalculator.as(
         LengthUnit.Meter,
         lastPoint.toLatLng(),
         newPoint.toLatLng(),
       );

       // --- Filtering ---
       // 1. Accuracy Filter (Ignore very inaccurate points for distance/pace)
       bool isAccurate = (newPoint.accuracy ?? 1000.0) < 50.0; // Configurable threshold
       // 2. Time Filter (Ensure time has passed)
       bool timePassed = timeDeltaSeconds > 0.1; // Minimum time delta
       // 3. Speed Filter (Check against realistic speeds)
       double speedMps = (timePassed && isAccurate) ? (distanceDelta / timeDeltaSeconds) : 0;
       bool realisticSpeed = speedMps < 15; // Approx 3:40 min/km pace, unlikely human running speed sustained

       if (!isAccurate || !timePassed || !realisticSpeed) {
           if (!isAccurate) Log.v("WorkoutCalc: Ignoring delta due to low accuracy: ${newPoint.accuracy}");
           if (!timePassed) Log.v("WorkoutCalc: Ignoring delta due to zero/negative time delta: ${timeDeltaSeconds}s");
           if (!realisticSpeed) Log.v("WorkoutCalc: Ignoring delta due to unrealistic speed: ${speedMps.toStringAsFixed(1)} m/s");
           distanceDelta = 0; // Ignore delta if checks fail
       }

       // Calculate current pace (only if valid delta)
       if (distanceDelta > 0 && timeDeltaSeconds > 0) {
         double paceSecPerMeter = timeDeltaSeconds / distanceDelta;
         currentPace = paceSecPerMeter * 1000.0;
       } else {
          // Fallback: Use overall average pace if available
          if (currentDistance > 0 && currentDuration.inSeconds > 0) {
             currentPace = (currentDuration.inSeconds / (currentDistance / 1000.0));
          }
       }

       // Calculate elevation change (with filtering)
        if (isAccurate && newPoint.altitude != null && lastPoint.altitude != null) {
           // TODO: Consider altitude accuracy if available (position.altitudeAccuracy)
           final altitudeDelta = newPoint.altitude! - lastPoint.altitude!;
           double threshold = 0.5; // Minimum change to register (adjust based on testing)
            if (altitudeDelta > threshold) {
               elevationChange = ElevationChange(gain: altitudeDelta, loss: 0.0);
            } else if (altitudeDelta < -threshold) {
                elevationChange = ElevationChange(gain: 0.0, loss: -altitudeDelta);
            }
        }
    }

    double newTotalDistance = currentDistance + distanceDelta;

    return WorkoutUpdateResult(
      newTotalDistance: newTotalDistance,
      distanceDelta: distanceDelta,
      currentPace: currentPace,
      elevationChange: elevationChange,
    );
  }


   Workout finalizeWorkoutData(Workout workout, UserProfile? userProfile) {
      double? finalAveragePace;
      if (workout.distance > 10 && workout.duration.inSeconds > 1) { // Min distance/duration for pace
         finalAveragePace = workout.duration.inSeconds / (workout.distance / 1000.0);
      }

      // Recalculate total calories based on final duration
      int finalCalories = calculateCaloriesBurned(
         duration: workout.duration,
         userWeightKg: userProfile?.weight ?? 70.0,
         metValue: getMetValueForActivity(workout.workoutType, averagePaceSecPerKm: finalAveragePace), // Pass pace for better MET
      );

      // Calculate final elevation from points if not tracked incrementally
      final finalElevation = calculateTotalElevation(workout.routePoints);

      // Calculate splits
      // TODO: Decide split distance based on settings (km or mile)
      List<WorkoutSplit> splits = calculateSplits(workout.routePoints, 1000.0); // Calculate 1km splits

      // Convert splits to WorkoutIntervals if workout.intervals is empty
       List<WorkoutInterval> intervalsToSave = workout.intervals;
       if (intervalsToSave.isEmpty && splits.isNotEmpty) {
           intervalsToSave = splits.map((split) => WorkoutInterval(
               duration: split.duration,
               distance: split.distance,
               type: IntervalType.work, // Assuming splits are 'work' intervals
               actualPace: split.averagePace,
               actualDistance: split.distance,
               actualDuration: split.duration,
               // Note: Target info isn't available from just splits
           )).toList();
       }


      return workout.copyWith(
         pace: () => finalAveragePace,
         status: WorkoutStatus.completed,
         caloriesBurned: () => finalCalories,
         elevationGain: () => finalElevation.gain,
         elevationLoss: () => finalElevation.loss,
         intervals: () => intervalsToSave, // Save calculated splits/intervals
      );
   }


   int calculateCaloriesBurned({
       required Duration duration,
       required double userWeightKg,
       required double metValue,
   }) {
      if (duration.inSeconds <= 0 || userWeightKg <= 0 || metValue <= 0) return 0;
      final double durationHours = duration.inSeconds / 3600.0;
      final double calories = metValue * userWeightKg * durationHours;
      return calories.round();
   }

   /// Provides estimated MET value, optionally refined by average pace.
   double getMetValueForActivity(WorkoutType type, {double? averagePaceSecPerKm}) {
      double paceMinPerKm = (averagePaceSecPerKm ?? 0) / 60.0;

      switch (type) {
         case WorkoutType.run:
         case WorkoutType.treadmill:
            // More refined MET based on pace (approximate values)
             if (paceMinPerKm <= 0) return 8.0; // Default if pace unknown
             if (paceMinPerKm <= 4.0) return 14.5; // ~<6:26 min/mile
             if (paceMinPerKm <= 4.5) return 12.8; // ~<7:15 min/mile
             if (paceMinPerKm <= 5.0) return 11.0; // ~<8:00 min/mile
             if (paceMinPerKm <= 5.6) return 10.0; // ~<9:00 min/mile
             if (paceMinPerKm <= 6.2) return 9.0;  // ~<10:00 min/mile
             if (paceMinPerKm <= 7.5) return 8.0;  // ~<12:00 min/mile
             return 6.0; // Slower than 12 min/mile
         case WorkoutType.cycle:
            // TODO: Estimate MET based on average speed if available, otherwise use average
            return 8.0;
         case WorkoutType.walk:
             // TODO: Estimate MET based on walking pace
            return 4.0;
         default:
            return 5.0;
      }
   }

   /// Calculates splits for a given distance (e.g., 1000m for km, 1609.34m for mile).
   List<WorkoutSplit> calculateSplits(List<RoutePoint> points, double splitDistanceMeters) {
      if (points.length < 2 || splitDistanceMeters <= 0) return [];

      List<WorkoutSplit> splits = [];
      int splitNumber = 1;
      double currentSplitDistance = 0;
      double cumulativeDistance = 0;
      Duration currentSplitDuration = Duration.zero;
      ElevationChange currentSplitElevation = const ElevationChange();
      DateTime splitStartTime = points.first.timestamp;
      RoutePoint? lastPointForSplit = points.first;

      for (int i = 1; i < points.length; i++) {
         final p1 = points[i - 1];
         final p2 = points[i];
         final timeDelta = p2.timestamp.difference(p1.timestamp);
         final distDelta = _distanceCalculator.as(LengthUnit.Meter, p1.toLatLng(), p2.toLatLng());
         final elevationDelta = calculateTotalElevation([p1, p2]); // Elevation for this segment

         if (distDelta <= 0 || timeDelta.isNegative) continue; // Skip invalid segments

         double distanceRemainingInSplit = splitDistanceMeters - currentSplitDistance;

         if (distDelta >= distanceRemainingInSplit) {
            // This segment completes the current split (and maybe starts the next)
            double fractionOfSegment = distanceRemainingInSplit / distDelta;
            Duration timeForSplitCompletion = Duration(milliseconds: (timeDelta.inMilliseconds * fractionOfSegment).round());
            ElevationChange elevationForSplitCompletion = ElevationChange(
                gain: currentSplitElevation.gain + elevationDelta.gain * fractionOfSegment,
                loss: currentSplitElevation.loss + elevationDelta.loss * fractionOfSegment
            );

            Duration finalSplitDuration = currentSplitDuration + timeForSplitCompletion;
            double finalSplitDistance = currentSplitDistance + distanceRemainingInSplit; // Should be ~= splitDistanceMeters
            double? avgPace = finalSplitDuration.inSeconds > 0 ? (finalSplitDuration.inSeconds / (finalSplitDistance / 1000.0)) : null;

            splits.add(WorkoutSplit(
               splitNumber: splitNumber,
               distance: finalSplitDistance,
               duration: finalSplitDuration,
               averagePace: avgPace,
               elevationChange: elevationForSplitCompletion,
            ));

             // Start next split
             splitNumber++;
             currentSplitDistance = distDelta - distanceRemainingInSplit; // Carry over remaining distance
             currentSplitDuration = Duration(milliseconds: (timeDelta.inMilliseconds * (1.0 - fractionOfSegment)).round());
             currentSplitElevation = ElevationChange(
                gain: elevationDelta.gain * (1.0 - fractionOfSegment),
                loss: elevationDelta.loss * (1.0 - fractionOfSegment)
             );
             splitStartTime = p2.timestamp - currentSplitDuration; // Approx start time of new split segment
             lastPointForSplit = p2; // Not quite right, need interpolation point

              // Handle multiple splits within one segment (unlikely but possible)
               while (currentSplitDistance >= splitDistanceMeters) {
                   // TODO: Complex interpolation needed here to accurately calculate time/elevation for full splits within a single segment
                   Log.w("Multiple splits within one GPS segment detected - calculation needs refinement.");
                   // Simple approximation: Assume linear pace/elevation within segment
                   double fractionForFullSplit = splitDistanceMeters / currentSplitDistance;
                   Duration timeForFullSplit = Duration(milliseconds: (currentSplitDuration.inMilliseconds * fractionForFullSplit).round());
                   ElevationChange elevationForFullSplit = ElevationChange(
                      gain: currentSplitElevation.gain * fractionForFullSplit,
                      loss: currentSplitElevation.loss * fractionForFullSplit
                   );
                   double? avgPaceFullSplit = timeForFullSplit.inSeconds > 0 ? (timeForFullSplit.inSeconds / (splitDistanceMeters / 1000.0)) : null;

                   splits.add(WorkoutSplit(
                      splitNumber: splitNumber,
                      distance: splitDistanceMeters,
                      duration: timeForFullSplit,
                      averagePace: avgPaceFullSplit,
                      elevationChange: elevationForFullSplit,
                   ));

                   splitNumber++;
                   currentSplitDistance -= splitDistanceMeters;
                   currentSplitDuration -= timeForFullSplit; // Reduce duration
                   // Adjust elevation, start time etc...
                   currentSplitElevation = ElevationChange(
                      gain: currentSplitElevation.gain - elevationForFullSplit.gain,
                      loss: currentSplitElevation.loss - elevationForFullSplit.loss
                   );

               }


         } else {
            // Add segment to current split
            currentSplitDistance += distDelta;
            currentSplitDuration += timeDelta;
            currentSplitElevation += elevationDelta;
             lastPointForSplit = p2;
         }
         cumulativeDistance += distDelta;
      }

       // Add the last partial split if any distance was covered
       if (currentSplitDistance > 10.0) { // Minimum distance for a partial split
          double? avgPace = currentSplitDuration.inSeconds > 0 ? (currentSplitDuration.inSeconds / (currentSplitDistance / 1000.0)) : null;
           splits.add(WorkoutSplit(
             splitNumber: splitNumber,
             distance: currentSplitDistance,
             duration: currentSplitDuration,
             averagePace: avgPace,
             elevationChange: currentSplitElevation,
           ));
       }

      Log.i("Calculated ${splits.length} splits for distance $splitDistanceMeters m.");
      return splits;
   }


   ElevationChange calculateTotalElevation(List<RoutePoint> points) {
      double gain = 0;
      double loss = 0;
      double smoothingFactor = 0.3; // Simple smoothing for altitude noise
      double? smoothedAltitude;

      for (int i = 0; i < points.length; i++) {
          final p = points[i];
          if (p.altitude == null) continue;

          double currentAltitude = p.altitude!;
          // Apply simple exponential smoothing
           smoothedAltitude ??= currentAltitude; // Initialize first time
           smoothedAltitude = (smoothingFactor * currentAltitude) + ((1.0 - smoothingFactor) * smoothedAltitude!);

           if (i > 0 && points[i-1].altitude != null) {
               double? prevSmoothedAltitude; // Need smoothed altitude of previous point
               // Recalculate previous smoothed altitude (inefficient) or store it
               // For simplicity here, just use previous raw altitude for delta calc (less accurate)
               double prevAltitude = points[i-1].altitude!;

              final delta = smoothedAltitude - prevAltitude; // Delta using smoothed current and raw previous
              double threshold = 0.5; // Minimum change threshold

              if (delta > threshold) {
                 gain += delta;
              } else if (delta < -threshold) {
                  loss += -delta;
              }
           }
      }
       Log.d("Calculated Total Elevation: Gain=${gain.toStringAsFixed(1)}, Loss=${loss.toStringAsFixed(1)}");
      return ElevationChange(gain: gain, loss: loss);
   }
}