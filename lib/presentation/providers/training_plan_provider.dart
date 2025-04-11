import 'package:flutter/foundation.dart';
import 'package:running_app/data/models/training_plan.dart';
import 'package:running_app/data/models/training_session.dart';
// TODO: Import repository or service for training plans
// import 'package:running_app/data/repositories/training_repository.dart';
import 'package:running_app/utils/logger.dart';

class TrainingPlanProvider with ChangeNotifier {
  // TODO: Inject TrainingRepository
  // final TrainingRepository _repository;

  List<TrainingPlan> _availablePlans = [];
  TrainingPlan? _activePlan; // Currently selected/active plan
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<TrainingPlan> get availablePlans => List.unmodifiable(_availablePlans);
  TrainingPlan? get activePlan => _activePlan;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // TrainingPlanProvider({required TrainingRepository repository}) : _repository = repository {
   TrainingPlanProvider() { // Temporary constructor without repository
     Log.d("TrainingPlanProvider Initialized (No Repository)");
     // TODO: Load active plan and available plans on init
     // loadAvailablePlans();
     // loadActivePlan();
     _loadPlaceholderPlans(); // Load placeholder data for now
  }

   void _setLoading(bool loading) {
      if (_isLoading == loading) return;
      _isLoading = loading;
      notifyListeners();
   }

   void _setError(String? message) {
      _errorMessage = message;
      notifyListeners();
   }


   // --- Placeholder Data Loading ---
   void _loadPlaceholderPlans() {
      Log.w("Loading placeholder training plans.");
       _availablePlans = [
          // TODO: Create more realistic placeholder plans
           TrainingPlan(
              id: 'plan_beg_5k', name: 'Beginner 5k Plan', difficulty: 'Beginner', durationWeeks: 8, goal: TrainingGoal.distance_5k,
              sessions: _generatePlaceholderSessions(8, 3, TrainingGoal.distance_5k) // Example: 8 weeks, 3 sessions/week
           ),
            TrainingPlan(
               id: 'plan_int_10k', name: 'Intermediate 10k Plan', difficulty: 'Intermediate', durationWeeks: 10, goal: TrainingGoal.distance_10k,
               sessions: _generatePlaceholderSessions(10, 4, TrainingGoal.distance_10k)
            ),
       ];
       // Check if an active plan ID is stored in settings/prefs, load it
       // _activePlan = _availablePlans.firstWhere(...)
        notifyListeners();
   }

    List<TrainingSession> _generatePlaceholderSessions(int weeks, int sessionsPerWeek, TrainingGoal goal) {
       List<TrainingSession> sessions = [];
       String baseDesc = goal.name.split('_').last.toUpperCase(); // 5K, 10K etc.
       for (int w = 1; w <= weeks; w++) {
          for (int d = 1; d <= sessionsPerWeek; d++) {
             sessions.add(TrainingSession(
                id: 's_${w}_$d', week: w, day: d,
                 description: 'W$w D$d: ${baseDesc} Placeholder Run', type: 'Run',
                 duration: Duration(minutes: 20 + (w * 2) + (d*3)), // Vary duration
                 distance: (3 + w * 0.5 + d * 0.2) * 1000, // Vary distance (meters)
             ));
          }
       }
       return sessions;
    }
   // --- End Placeholder ---


  // TODO: Implement fetching available plans (from DB, Assets, or API)
  Future<void> loadAvailablePlans() async {
     _setLoading(true); _setError(null);
     try {
        Log.d("Fetching available training plans...");
        // _availablePlans = await _repository.getAvailablePlans();
         _loadPlaceholderPlans(); // Use placeholder for now
        Log.i("Loaded ${_availablePlans.length} available plans.");
     } catch (e, s) {
         Log.e("Error loading available plans", error: e, stackTrace: s);
         _setError("Could not load training plans.");
         _availablePlans = [];
     } finally {
        _setLoading(false);
     }
  }

   // TODO: Implement loading the user's currently active plan (e.g., from DB/Prefs)
   Future<void> loadActivePlan() async {
      // _activePlan = await _repository.getActivePlan(deviceId); // Needs deviceId
       // For now, maybe set first available plan as active? Or none.
       _activePlan = null; // Default to no active plan
      notifyListeners();
   }

   // TODO: Implement selecting/activating a plan
   Future<void> setActivePlan(String planId) async {
       Log.i("Setting active plan to: $planId");
      // _activePlan = _availablePlans.firstWhere((p) => p.id == planId, orElse: () => null);
       // await _repository.setActivePlan(deviceId, planId); // Persist selection
       // Temporarily set from available list
       _activePlan = _availablePlans.firstWhere((p) => p.id == planId, orElse: () => null);
       if (_activePlan == null) Log.w("Plan $planId not found in available plans.");
      notifyListeners();
   }

    // TODO: Implement clearing the active plan
    Future<void> clearActivePlan() async {
       Log.i("Clearing active plan.");
       _activePlan = null;
       // await _repository.clearActivePlan(deviceId); // Persist clearing
       notifyListeners();
    }

  // TODO: Implement marking a session as complete
   Future<void> markSessionComplete(String sessionId, bool completed) async {
      if (_activePlan == null) return;
      Log.i("Marking session $sessionId as ${completed ? 'complete' : 'incomplete'}");

      // Update locally first for immediate UI feedback
      final planIndex = _availablePlans.indexWhere((p) => p.id == _activePlan!.id);
       final sessionIndex = _activePlan!.sessions.indexWhere((s) => s.id == sessionId);
       if (sessionIndex != -1) {
          // Create a mutable copy or update immutable list correctly
           final updatedSession = _activePlan!.sessions[sessionIndex].copyWith(completed: completed);
           final updatedSessions = List<TrainingSession>.from(_activePlan!.sessions);
           updatedSessions[sessionIndex] = updatedSession;
           _activePlan = _activePlan!.copyWith(sessions: updatedSessions);

          // If plan is also in availablePlans, update it there too
          if (planIndex != -1) {
             _availablePlans[planIndex] = _activePlan!;
          }
           notifyListeners();

           // Persist change
            // await _repository.updateSessionCompletion(sessionId, completed);
             Log.w("Session completion persistence not implemented.");
       }
   }

   // TODO: Implement logic for generating custom plans based on user goals/level
   // Future<TrainingPlan> generateCustomPlan(...) async { ... }

   // TODO: Implement logic for importing plans (e.g., from a file/URL)
   // Future<void> importPlanFromFile(...) async { ... }
}

// Helper for copyWith on TrainingPlan (optional but useful)
extension TrainingPlanCopyWith on TrainingPlan {
    TrainingPlan copyWith({
       String? id, String? name, String? description, String? difficulty,
       int? durationWeeks, TrainingGoal? goal, List<TrainingSession>? sessions,
    }) {
       return TrainingPlan(
          id: id ?? this.id, name: name ?? this.name,
          description: description ?? this.description, difficulty: difficulty ?? this.difficulty,
          durationWeeks: durationWeeks ?? this.durationWeeks, goal: goal ?? this.goal,
          sessions: sessions ?? this.sessions, // Note: shallow copy of sessions list
       );
    }
}

// Helper for copyWith on TrainingSession
extension TrainingSessionCopyWith on TrainingSession {
    TrainingSession copyWith({
      String? id, int? week, int? day, String? description, String? type,
      Duration? duration, double? distance, bool? completed,
    }) {
      return TrainingSession(
         id: id ?? this.id, week: week ?? this.week, day: day ?? this.day,
         description: description ?? this.description, type: type ?? this.type,
         duration: duration ?? this.duration,
         distance: distance ?? this.distance, // Use provided or existing
         completed: completed ?? this.completed,
      );
    }
}
(Code continues in the next response due to length)





(Code continues in the next response due to length)



Show thinking
Okay, here is the final batch containing the ~25 prioritized remaining files.

This batch includes key screens, essential widgets, service structures, models, and utilities, incorporating the fixes for compilation errors, the device ID logic, and implementations or placeholders for the TODOs.

Remember that features marked with TODO, especially complex ones like detailed charting, full background service integration, achievement logic, etc., will require further development, testing, and refinement.

This concludes the code modification process.

Final Batch (Remaining Core Files)