import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:running_app/data/models/route_point.dart';
import 'package:running_app/data/models/workout.dart';
import 'package:running_app/data/models/user_profile.dart'; // For user profile access
import 'package:running_app/data/models/workout_interval.dart'; // For interval tracking
import 'package:running_app/data/repositories/workout_repository.dart';
import 'package:running_app/device/gps/location_service.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart' as geo;
// import '../../data/models/enhanced_location_data.dart' as enhanced; // Only if enhanced needed
import 'package:running_app/domain/use_cases/workout_use_cases.dart';
import 'package:running_app/utils/logger.dart';
import 'package:running_app/data/utils/state_persistence_manager.dart';
import 'package:running_app/presentation/providers/user_provider.dart'; // Needed to get deviceId and profile
// TODO: Import background service communication mechanism if needed
// import 'package:running_app/device/background/background_tracking_service.dart';
// TODO: Import voice coach service if triggering updates from here
// import 'package:running_app/device/audio/voice_coaching_service.dart';
// TODO: Import notification service if updating notification from here
// import 'package:running_app/device/notifications/notification_service.dart';


// Represents the state of the workout tracking
enum WorkoutTrackingState { idle, preparing, active, paused, saving, completed, error }

class WorkoutProvider with ChangeNotifier {
  final WorkoutRepository _workoutRepository;
  final LocationService _locationService;
  final WorkoutUseCases _workoutUseCases;
  final StatePersistenceManager _persistenceManager;
  // Make UserProvider nullable initially, update via method
  UserProvider? _userProvider;

  // --- State Variables ---
  Workout? _activeWorkout;
  WorkoutTrackingState _trackingState = WorkoutTrackingState.idle;
  bool _isLoading = false; // General loading state for fetching workouts
  String? _errorMessage;
  List<Workout> _workouts = []; // List of past workouts

  // Location & Tracking Data Streams
  StreamSubscription<geo.Position>? _positionSubscription;
  // TODO: Define subscription for background state updates
  // StreamSubscription<Map<String, dynamic>>? _backgroundStateSubscription;

  Timer? _durationTimer;

  // --- Getters ---
  Workout? get activeWorkout => _activeWorkout;
  WorkoutTrackingState get trackingState => _trackingState;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Workout> get workouts => List.unmodifiable(_workouts);


  WorkoutProvider({
    required WorkoutRepository workoutRepository,
    required LocationService locationService,
    required WorkoutUseCases workoutUseCases,
    required StatePersistenceManager persistenceManager,
    required UserProvider? userProvider, // Allow initial null
  })  : _workoutRepository = workoutRepository,
        _locationService = locationService,
        _workoutUseCases = workoutUseCases,
        _persistenceManager = persistenceManager,
        _userProvider = userProvider
        {
     Log.d("WorkoutProvider Initialized");
     _initialize();
   }

   // Separate async initialization
   Future<void> _initialize() async {
      await _loadPersistedState();
      // Subscribe to background updates if necessary after loading state
      // _subscribeToBackgroundUpdates();
      await fetchWorkouts(); // Fetch past workouts
   }

   // Method to update UserProvider reference (used by ProxyProvider)
   void updateUserProvider(UserProvider userProvider) {
      _userProvider = userProvider;
      // If workout fetch depends on deviceId, trigger fetch again if ID becomes available
      if (_workouts.isEmpty && !_isLoading && _userProvider?.deviceId != null) {
         fetchWorkouts();
      }
   }


   // --- State Persistence ---

   Future<void> _loadPersistedState() async {
      try {
         final loaded = await _persistenceManager.loadWorkoutState();
         if (loaded != null && loaded.workout != null && loaded.trackingState != null) {
             // Only restore if state is active or paused
             if (loaded.trackingState == WorkoutTrackingState.active || loaded.trackingState == WorkoutTrackingState.paused) {
                 _activeWorkout = loaded.workout;
                 _trackingState = loaded.trackingState!; // Use loaded state
                 Log.i("Workout state restored from persistence (State: ${_trackingState.name}).");

                 // If state was active, restart tracking components
                 if (_trackingState == WorkoutTrackingState.active) {
                    _startDurationTimer(); // Resumes timer based on loaded duration
                    _startLocationUpdates();
                    // TODO: Resume sensors, voice coach, notification based on loaded state
                 }
                 notifyListeners(); // Update UI with loaded state
             } else {
                Log.w("Loaded workout state is not resumable (${loaded.trackingState?.name}). Clearing.");
                await _persistenceManager.clearWorkoutState();
             }
         } else {
             Log.d("No resumable workout state found in persistence.");
             _trackingState = WorkoutTrackingState.idle; // Ensure idle state if nothing loaded
         }
      } catch (e, s) {
         Log.e("Error loading persisted workout state", error: e, stackTrace: s);
         _trackingState = WorkoutTrackingState.idle;
         _activeWorkout = null;
          await _persistenceManager.clearWorkoutState(); // Clear potentially corrupted state
      }
   }

   // Persists current state if active/paused, clears otherwise
    Future<void> _persistState() async {
       await _persistenceManager.saveWorkoutState(_activeWorkout, _trackingState);
    }

  // --- Workout Lifecycle ---

  Future<bool> prepareWorkout() async {
    _setTrackingState(WorkoutTrackingState.preparing);
    _setError(null); // Clear previous errors
    try {
      bool gpsReady = await _locationService.isReady();
      if (!gpsReady) {
         if (!await _locationService.isLocationServiceEnabled()) {
             _setError("Please enable location services on your device.");
         } else if (!await _locationService.hasPermission()) {
              // Attempt to request permission
              if (!await _locationService.requestPermission()) {
                  _setError("Location permission is required to track workouts.");
              } else {
                  // Permission granted, re-check readiness
                  if (!await _locationService.isReady()) {
                      _setError("Could not prepare location services."); // Generic error if still not ready
                  } else {
                      Log.i("Location permission granted after request.");
                      _setTrackingState(WorkoutTrackingState.idle); // Ready
                      return true;
                  }
              }
         } else {
            _setError("Could not prepare location services."); // Unknown reason
         }
         _setTrackingState(WorkoutTrackingState.error);
         return false;
      }

      // TODO: Perform other pre-workout checks (e.g., battery level?)

      _setTrackingState(WorkoutTrackingState.idle); // Ready to start
      Log.i("Workout preparation complete. Ready to start.");
      return true;
    } catch (e, s) {
       Log.e("Error during workout preparation", error: e, stackTrace: s);
       _setError("Could not prepare workout.");
       _setTrackingState(WorkoutTrackingState.error);
       return false;
    }
  }

  Future<void> startWorkout({required WorkoutType type}) async {
    if (_trackingState != WorkoutTrackingState.idle) {
      Log.w("Cannot start workout, not in idle state: $_trackingState");
      if (_trackingState == WorkoutTrackingState.preparing) {
          Log.w("Attempting to start while still preparing. Waiting...");
          await Future.delayed(const Duration(milliseconds: 500)); // Short delay
           if (_trackingState != WorkoutTrackingState.idle) {
               _setError("Workout preparation did not complete.");
               _setTrackingState(WorkoutTrackingState.error);
               return;
           }
           // If state became idle, proceed
      } else {
           _setError("Workout already in progress or finished.");
           return;
      }
    }
     // Get deviceId and profile from UserProvider
     final deviceId = _userProvider?.deviceId;
     final userProfile = _userProvider?.userProfile;

     if (deviceId == null || deviceId.isEmpty) {
         _setError("Cannot start workout: Device ID is missing.");
          _setTrackingState(WorkoutTrackingState.error); // Set error state
         return;
     }

    _setTrackingState(WorkoutTrackingState.active);
    _setError(null);
    _activeWorkout = Workout(
      id: const Uuid().v4(), // Generate UUID for workout ID
      deviceId: deviceId,
      date: DateTime.now(),
      distance: 0.0,
      duration: Duration.zero,
      workoutType: type,
      status: WorkoutStatus.active,
      pace: null, caloriesBurned: 0, routePoints: [], intervals: [],
      elevationGain: 0.0, elevationLoss: 0.0,
    );

    _startDurationTimer();
    _startLocationUpdates();
    // TODO: Start background service if configured/enabled
    // BackgroundTrackingService.start(_activeWorkout);

    // TODO: Trigger start actions for voice coach, notifications etc.
    // context.read<VoiceCoachingService>().announceWorkoutStart();
    // context.read<NotificationService>().showWorkoutProgressNotification(...);

    Log.i("Workout started: Type=$type, ID=${_activeWorkout!.id}, DeviceID=$deviceId");
    await _persistState(); // Persist initial state
    notifyListeners();
  }

   Future<void> pauseWorkout() async {
      if (_trackingState != WorkoutTrackingState.active) return;
      _setTrackingState(WorkoutTrackingState.paused);
      _durationTimer?.cancel();
      await _positionSubscription?.cancel();
      _positionSubscription = null; // Clear subscription

      // TODO: Update background service state if used
      // TODO: Update notification (show paused state, update actions)
      // TODO: Trigger pause announcement
      // context.read<VoiceCoachingService>().announceWorkoutPaused();

      Log.i("Workout paused: ID=${_activeWorkout?.id}");
       _activeWorkout = _activeWorkout?.copyWith(status: WorkoutStatus.paused);
       await _persistState();
      notifyListeners();
   }

   Future<void> resumeWorkout() async {
      if (_trackingState != WorkoutTrackingState.paused) return;
      _setTrackingState(WorkoutTrackingState.active);
      _startDurationTimer(); // Restart timer
      _startLocationUpdates(); // Resume location updates

      // TODO: Update background service state if used
      // TODO: Update notification (show active state)
      // TODO: Trigger resume announcement
      // context.read<VoiceCoachingService>().announceWorkoutResumed();

      Log.i("Workout resumed: ID=${_activeWorkout?.id}");
       _activeWorkout = _activeWorkout?.copyWith(status: WorkoutStatus.active);
       await _persistState();
      notifyListeners();
   }

  Future<void> stopWorkout() async {
    if (_trackingState != WorkoutTrackingState.active && _trackingState != WorkoutTrackingState.paused) return;
    if (_activeWorkout == null) {
       _setError("Cannot stop workout: No active workout data.");
       _setTrackingState(WorkoutTrackingState.error);
        return;
    }

    final workoutToStop = _activeWorkout!; // Capture current workout
    _setTrackingState(WorkoutTrackingState.saving);
    _durationTimer?.cancel();
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    // TODO: Stop background service if used
    // BackgroundTrackingService.stop();
    // TODO: Cancel persistent notification
    // context.read<NotificationService>().cancelWorkoutProgressNotification();

    // Final calculations
    final userProfile = _userProvider?.userProfile;
    final finalizedWorkout = _workoutUseCases.finalizeWorkoutData(workoutToStop, userProfile);
    _activeWorkout = finalizedWorkout.copyWith(status: WorkoutStatus.completed); // Update state before saving

    try {
      await _workoutRepository.saveWorkout(_activeWorkout!);
      Log.i("Workout stopped and saved successfully: ID=${_activeWorkout!.id}");

      // TODO: Trigger completion announcement & notification AFTER saving successfully
      // context.read<VoiceCoachingService>().announceWorkoutCompleted(_activeWorkout!);
      // context.read<NotificationService>().showWorkoutCompleteNotification(_activeWorkout!);

      _setTrackingState(WorkoutTrackingState.completed);
      await _persistenceManager.clearWorkoutState();
      await fetchWorkouts(); // Refresh workout list

      // TODO: Check for achievements / personal bests
      // await context.read<AchievementProvider>().checkWorkoutAchievements(_activeWorkout!);
      // await _workoutRepository.checkAndSavePersonalBests(_activeWorkout!);


    } catch (e, s) {
       Log.e("Failed to save workout", error: e, stackTrace: s);
       _setError("Failed to save workout. Please try again later.");
       // Revert state? Or keep as completed but unsaved? Needs strategy.
       _setTrackingState(WorkoutTrackingState.error); // Set error state
       // Do NOT clear persisted state if saving failed, allow retry?
    } finally {
        // Don't clear _activeWorkout immediately, summary screen needs it.
        // It will be cleared by clearActiveWorkout() or on next start.
       notifyListeners();
    }
  }

   Future<void> discardWorkout() async {
      if (_activeWorkout == null) return;
      Log.w("Discarding active workout: ID=${_activeWorkout!.id}");

      _durationTimer?.cancel();
      await _positionSubscription?.cancel();
      _positionSubscription = null;

      // TODO: Stop background service, cancel notification

      final discardedWorkoutId = _activeWorkout!.id; // Keep ID for potential deletion?
      _activeWorkout = null; // Clear active workout data
      _setTrackingState(WorkoutTrackingState.idle); // Or a 'discarded' state?
      await _persistenceManager.clearWorkoutState();

      // Optionally delete the workout record if it was partially saved or persisted
      // try {
      //    await _workoutRepository.deleteWorkout(discardedWorkoutId, _userProvider?.deviceId ?? '');
      // } catch (e) { Log.w("Failed to delete discarded workout record: $e"); }

      notifyListeners();
   }

  // --- Data Fetching ---

  Future<void> fetchWorkouts({bool forceRefresh = false}) async {
    // TODO: Implement caching/conditional fetching
     final deviceId = _userProvider?.deviceId;
     if (deviceId == null) {
        Log.w("Cannot fetch workouts yet: Device ID not available.");
        return; // Wait until device ID is loaded
     }

    _setLoading(true);
    try {
      _workouts = await _workoutRepository.getAllWorkouts(deviceId: deviceId);
      _errorMessage = null;
      Log.i("Fetched ${_workouts.length} past workouts for device $deviceId.");
    } catch (e, s) {
      Log.e("Failed to fetch workouts", error: e, stackTrace: s);
      _setError("Failed to fetch workouts. Please check your connection.");
      _workouts = [];
    } finally {
      _setLoading(false);
    }
  }

  // --- Other Methods ---

   void clearActiveWorkout() {
      if (_trackingState == WorkoutTrackingState.completed || _trackingState == WorkoutTrackingState.error) {
         if (_activeWorkout != null) {
             _activeWorkout = null;
             _setTrackingState(WorkoutTrackingState.idle); // Reset state after summary
             Log.i("Cleared active workout data from provider.");
             notifyListeners();
         }
      } else {
          Log.w("Attempted to clear active workout while in state: $_trackingState");
      }
   }

   void clearError() {
      if (_errorMessage != null || _trackingState == WorkoutTrackingState.error) {
         _errorMessage = null;
         // If in error state, revert to a sensible previous state (e.g., idle)
         if (_trackingState == WorkoutTrackingState.error) {
            _setTrackingState(WorkoutTrackingState.idle);
         } else {
             notifyListeners(); // Just clear error message
         }
         Log.d("WorkoutProvider error cleared.");
      }
   }


  // --- Internal Helper Methods ---

  void _setTrackingState(WorkoutTrackingState newState) {
    if (_trackingState != newState) {
      _trackingState = newState;
      Log.d("Workout tracking state changed to: $newState");
      // Avoid notifying during build phase
      WidgetsBinding.instance.addPostFrameCallback((_) {
         if (hasListeners) notifyListeners();
      });
    }
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      WidgetsBinding.instance.addPostFrameCallback((_) {
          if (hasListeners) notifyListeners();
      });
    }
  }

  void _setError(String? message) {
    _errorMessage = message;
    if (message != null) {
       Log.e("WorkoutProvider Error: $message");
        // Automatically set error state when error message is set
        _setTrackingState(WorkoutTrackingState.error);
    } else if (_trackingState == WorkoutTrackingState.error) {
        // If message is cleared but state is still error, revert state
        _setTrackingState(WorkoutTrackingState.idle); // Or previous non-error state?
    } else {
        // Just clearing message, no state change needed
         WidgetsBinding.instance.addPostFrameCallback((_) {
            if (hasListeners) notifyListeners();
         });
    }
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    // Start timer based on potentially restored duration
    final initialSeconds = _activeWorkout?.duration.inSeconds ?? 0;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_trackingState == WorkoutTrackingState.active && _activeWorkout != null) {
        _activeWorkout = _activeWorkout!.copyWith(
          duration: Duration(seconds: initialSeconds + timer.tick),
        );
         // Persist state periodically
         if (timer.tick % 30 == 0) { // Persist every 30 seconds
             _persistState();
         }
        notifyListeners();
      } else {
        timer.cancel();
      }
    });
  }

  void _startLocationUpdates() {
     if (_positionSubscription != null) {
        Log.w("Attempted to start location updates when already subscribed.");
        return; // Already listening
     }
     Log.i("Subscribing to location updates...");
     _positionSubscription = _locationService.getPositionStream().handleError((error, stackTrace) {
        // Centralized error handling for the stream
        Log.e("Error in location stream", error: error, stackTrace: stackTrace);
        String errorMsg = "GPS Error";
        if (error is LocationServiceDisabledException) {
           errorMsg = "Location services disabled.";
           // TODO: Maybe trigger UI prompt to enable services
        } else if (error is PermissionDeniedException) {
           errorMsg = "Location permission denied.";
           // TODO: Prompt user or guide to settings
        } else {
            errorMsg = "GPS signal lost or unavailable."; // Generic error
        }
         _setError(errorMsg);
         // Optionally pause workout on GPS error?
         // if (_trackingState == WorkoutTrackingState.active) { pauseWorkout(); }

     }).listen(
        (geo.Position position) {
           if (_trackingState == WorkoutTrackingState.active && _activeWorkout != null) {
               _processNewPosition(position);
           }
        },
        // onError handled by handleError above
        onDone: () {
            Log.w("Location stream closed.");
             // If workout is still active, this is an issue
             if (_trackingState == WorkoutTrackingState.active) {
                _setError("GPS signal lost.");
                // pauseWorkout(); // Pause if GPS stops unexpectedly
             }
             _positionSubscription = null; // Clear subscription on done
        },
        cancelOnError: false, // Let handleError decide whether to continue/stop
     );
  }

   void _processNewPosition(geo.Position position) {
      if (_activeWorkout == null) return;

       final newPoint = RoutePoint(
           latitude: position.latitude, longitude: position.longitude, altitude: position.altitude,
           speed: position.speed, accuracy: position.accuracy, heading: position.heading,
           timestamp: position.timestamp ?? DateTime.now(),
       );

      // Basic filtering (already done in LocationService, but can add more here)
      // if (newPoint.accuracy != null && newPoint.accuracy! > 50) return;

       final currentPoints = _activeWorkout!.routePoints;
       final updates = _workoutUseCases.calculateWorkoutUpdate(
         newPoint: newPoint,
         lastPoint: currentPoints.isNotEmpty ? currentPoints.last : null,
         currentDistance: _activeWorkout!.distance,
         currentDuration: _activeWorkout!.duration,
       );

       // Update the active workout state
        final userWeight = _userProvider?.userProfile?.weight ?? 70.0; // Get current weight
       _activeWorkout = _activeWorkout!.copyWith(
         distance: updates.newTotalDistance,
         pace: () => updates.currentPace,
         caloriesBurned: () => _workoutUseCases.calculateCaloriesBurned(
             duration: _activeWorkout!.duration, // Use current duration
             userWeightKg: userWeight,
             metValue: _workoutUseCases.getMetValueForActivity(_activeWorkout!.workoutType)
         ),
         routePoints: [...currentPoints, newPoint],
         elevationGain: () => (_activeWorkout!.elevationGain ?? 0.0) + updates.elevationChange.gain,
         elevationLoss: () => (_activeWorkout!.elevationLoss ?? 0.0) + updates.elevationChange.loss,
          // TODO: Update interval tracking if applicable
          // intervals: () => _updateIntervalProgress(newPoint, updates),
       );

       // TODO: Trigger voice coaching updates
       // context.read<VoiceCoachingService>().update(_activeWorkout!);

       // TODO: Update notification content
       // _updateNotification();

       // TODO: Check for milestones (distance, pace PBs) - Maybe less frequent?
       // if (_activeWorkout!.distance % 1000 < updates.distanceDelta) { // Approx check every km
       //    _checkAndNotifyMilestones();
       // }

      notifyListeners();
   }

    // TODO: Placeholder for updating interval progress
    /*
    List<WorkoutInterval> _updateIntervalProgress(RoutePoint newPoint, WorkoutUpdateResult updates) {
        // Find current interval, update its actualDistance/Duration/Pace
        // Check if interval completed, move to next
        return _activeWorkout!.intervals; // Return updated list
    }
    */

    // TODO: Placeholder for updating notification content
    /*
    void _updateNotification() {
        if (_activeWorkout != null) {
            // Format relevant data
            String status = ...;
            String details = ...;
            context.read<NotificationService>().showWorkoutProgressNotification(status, details);
        }
    }
    */


   // --- Cleanup ---
   @override
   void dispose() {
      Log.d("Disposing WorkoutProvider");
      _durationTimer?.cancel();
      _positionSubscription?.cancel();
      _backgroundStateSubscription?.cancel();
      // Persist state one last time if needed? Depends on app lifecycle.
      // if (_trackingState == WorkoutTrackingState.active || _trackingState == WorkoutTrackingState.paused) {
      //    _persistState();
      // }
      super.dispose();
   }
}