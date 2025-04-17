import 'package:flutter/material.dart';

import 'dart:convert'; // Needed if TrainingPlan.fromMap/toMap are used directly here

import '../models/training_plan.dart';
import '../models/training_session.dart';
import '../repositories/training_repository.dart';
// Import the concrete implementation for static calls
import '../utils/state_persistence_manager.dart';

/// Provider class for managing training plans
class TrainingPlanProvider extends ChangeNotifier {
  final TrainingRepository _repository;

  List<TrainingPlan> _plans = [];
  TrainingPlan? _selectedPlan;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  TrainingPlanProvider({
    required TrainingRepository repository,
  }) : _repository = repository;

  List<TrainingPlan> get plans => _plans;
  TrainingPlan? get selectedPlan => _selectedPlan;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  /// Initialize the provider by loading saved state
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Load selected plan if exists using the concrete class
      final savedPlan =
          await SharedPreferencesStatePersistenceManager.loadSelectedPlan();
      if (savedPlan != null) {
        _selectedPlan = savedPlan;
      }

      // Load training plans
      await loadTrainingPlans();

      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to initialize: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads training plans from the repository
  Future<void> loadTrainingPlans() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Use the correct repository method name
      _plans = await _repository.getAvailablePlans();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load training plans: $e';
      notifyListeners();
    }
  }

  /// Selects a training plan
  void selectPlan(TrainingPlan plan) {
    _selectedPlan = plan;

    // Persist selected plan using the concrete class
    SharedPreferencesStatePersistenceManager.saveSelectedPlan(plan);

    notifyListeners();
  }

  /// Clears the selected plan
  void clearSelectedPlan() {
    _selectedPlan = null;

    // Remove persisted plan using the concrete class
    SharedPreferencesStatePersistenceManager.saveSelectedPlan(null);

    notifyListeners();
  }

  /// Marks a session as completed or not completed
  Future<void> completeSession(TrainingSession session,
      {bool completed = true}) async {
    if (_selectedPlan == null) return;

    try {
      // Use the correct repository method name and pass positional argument
      await _repository.updateSessionCompletion(session.id, completed);

      // Assume success if no exception was thrown (repository doesn't return bool)
      // Update local state
      final sessionIndex =
          _selectedPlan!.sessions.indexWhere((s) => s.id == session.id);
      if (sessionIndex != -1) {
        final updatedSessions =
            List<TrainingSession>.from(_selectedPlan!.sessions);
        updatedSessions[sessionIndex] = updatedSessions[sessionIndex].copyWith(
          completed: completed,
        );

        _selectedPlan = _selectedPlan!.copyWith(
          sessions: updatedSessions,
        );

        // Persist updated plan using the concrete class
        SharedPreferencesStatePersistenceManager.saveSelectedPlan(
            _selectedPlan);

        notifyListeners();
      }
      // Removed the extra closing brace here
    } catch (e) {
      // Now this catch correctly corresponds to the try block
      _error = 'Failed to update session: $e';
      notifyListeners();
    }
  }

  /// Gets the next uncompleted session in the selected plan
  TrainingSession? get nextSession {
    if (_selectedPlan == null) return null;

    try {
      return _selectedPlan!.sessions
          .firstWhere((session) => !session.completed);
    } catch (e) {
      // All sessions completed
      return null;
    }
  }

  /// Gets the completion percentage of the selected plan
  double get completionPercentage {
    if (_selectedPlan == null) return 0.0;

    final totalSessions = _selectedPlan!.sessions.length;
    if (totalSessions == 0) return 0.0;

    final completedSessions =
        _selectedPlan!.sessions.where((s) => s.completed).length;
    return completedSessions / totalSessions;
  }

  /// Gets plans filtered by difficulty
  List<TrainingPlan> getPlansByDifficulty(String difficulty) {
    return _plans.where((plan) => plan.difficulty == difficulty).toList();
  }
}
