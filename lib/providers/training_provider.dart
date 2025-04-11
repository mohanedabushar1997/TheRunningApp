import 'package:flutter/foundation.dart';
import '../data/models/training_session.dart';
import '../data/repositories/training_repository.dart';

class TrainingProvider with ChangeNotifier {
  final TrainingRepository _repository;

  List<TrainingPlan> _availablePlans = [];
  TrainingPlan? _selectedPlan;
  int _currentWeek = 1;
  List<TrainingSession> _currentWeekSessions = [];
  bool _isLoading = false;
  String? _error;

  TrainingProvider({required TrainingRepository repository})
    : _repository = repository {
    _loadTrainingPlans();
  }

  // Getters
  List<TrainingPlan> get availablePlans => _availablePlans;
  TrainingPlan? get selectedPlan => _selectedPlan;
  int get currentWeek => _currentWeek;
  List<TrainingSession> get currentWeekSessions => _currentWeekSessions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Returns the next upcoming session that is not completed
  TrainingSession? get nextSession {
    final incompleteSessions =
        _currentWeekSessions.where((session) => !session.isCompleted).toList()
          ..sort((a, b) => a.day.compareTo(b.day));

    return incompleteSessions.isNotEmpty ? incompleteSessions.first : null;
  }

  // Load all available training plans
  Future<void> _loadTrainingPlans() async {
    _setLoading(true);
    try {
      _availablePlans = await _repository.getTrainingPlans();
      _error = null;
    } catch (e) {
      _error = 'Failed to load training plans: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // Select a training plan by ID
  Future<void> selectPlan(String planId) async {
    _setLoading(true);
    try {
      final plan = await _repository.getTrainingPlanById(planId);
      if (plan != null) {
        _selectedPlan = plan;
        _currentWeek = 1; // Reset to first week when selecting a new plan
        await loadWeekSessions(1);
        _error = null;
      } else {
        _error = 'Training plan not found';
      }
    } catch (e) {
      _error = 'Failed to select training plan: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // Load sessions for a specific week
  Future<void> loadWeekSessions(int week) async {
    if (_selectedPlan == null) return;

    _setLoading(true);
    try {
      _currentWeekSessions = await _repository.getSessionsForWeek(
        _selectedPlan!.id,
        week,
      );
      _currentWeek = week;
      _error = null;
    } catch (e) {
      _error = 'Failed to load week sessions: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // Mark a session as completed or not completed
  Future<bool> markSessionCompleted(
    String sessionId, {
    required bool isCompleted,
  }) async {
    try {
      final success = await _repository.markSessionCompleted(
        sessionId,
        isCompleted: isCompleted,
      );

      if (success) {
        // Update local state
        final index = _currentWeekSessions.indexWhere((s) => s.id == sessionId);
        if (index != -1) {
          _currentWeekSessions[index] = _currentWeekSessions[index].copyWith(
            isCompleted: isCompleted,
          );
          notifyListeners();
        }
      }

      return success;
    } catch (e) {
      _error = 'Failed to update session: ${e.toString()}';
      return false;
    }
  }

  // Navigate to the next week if available
  bool goToNextWeek() {
    if (_selectedPlan == null) return false;
    if (_currentWeek < _selectedPlan!.totalWeeks) {
      loadWeekSessions(_currentWeek + 1);
      return true;
    }
    return false;
  }

  // Navigate to the previous week if available
  bool goToPreviousWeek() {
    if (_currentWeek > 1) {
      loadWeekSessions(_currentWeek - 1);
      return true;
    }
    return false;
  }

  // Helper to set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
