import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/training_plan.dart';
import '../data/models/training_session.dart';
import '../data/utils/state_persistence_manager.dart';

class TrainingPlanProvider extends ChangeNotifier {
  List<TrainingPlan> _plans = [];
  TrainingPlan? _selectedPlan;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  List<TrainingPlan> get plans => _plans;
  TrainingPlan? get selectedPlan => _selectedPlan;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  /// Initialize the provider by loading saved state
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Load selected plan if exists
    final savedPlan = await StatePersistenceManager.loadSelectedPlan();
    if (savedPlan != null) {
      _selectedPlan = savedPlan;
    }
    
    // Load training plans if not already loaded
    if (_plans.isEmpty) {
      await loadTrainingPlans();
    }
    
    _isInitialized = true;
    notifyListeners();
  }

  /// Sets the list of available training plans
  void setPlans(List<TrainingPlan> plans) {
    _plans = plans;
    notifyListeners();
  }

  /// Selects a training plan
  void selectPlan(TrainingPlan plan) {
    _selectedPlan = plan;
    
    // Persist selected plan
    StatePersistenceManager.saveSelectedPlan(plan);
    
    notifyListeners();
  }

  /// Clears the selected plan
  void clearSelectedPlan() {
    _selectedPlan = null;
    
    // Remove persisted plan
    StatePersistenceManager.saveSelectedPlan(null);
    
    notifyListeners();
  }

  /// Marks a session as completed or not completed
  void completeSession(TrainingSession session, {bool completed = true}) {
    if (_selectedPlan == null) return;
    
    final sessionIndex = _selectedPlan!.sessions.indexWhere((s) => s.id == session.id);
    if (sessionIndex != -1) {
      _selectedPlan!.sessions[sessionIndex].completed = completed;
      
      // Persist updated plan
      StatePersistenceManager.saveSelectedPlan(_selectedPlan);
      
      notifyListeners();
    }
  }

  /// Gets the next uncompleted session in the selected plan
  TrainingSession? get nextSession {
    if (_selectedPlan == null) return null;
    
    try {
      return _selectedPlan!.sessions.firstWhere((session) => !session.completed);
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
    
    final completedSessions = _selectedPlan!.sessions.where((s) => s.completed).length;
    return completedSessions / totalSessions;
  }

  /// Loads training plans from the repository
  Future<void> loadTrainingPlans() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // In a real app, this would load from a repository
      // For now, we'll just simulate a delay
      await Future.delayed(Duration(milliseconds: 500));
      
      // Mock data
      _plans = [
        TrainingPlan(
          id: 'beginner-5k',
          name: '5K Beginner Plan',
          description: 'Perfect for first-time runners looking to complete a 5K race',
          difficulty: 'Beginner',
          durationWeeks: 8,
          sessions: _generateBeginnerSessions(),
        ),
        TrainingPlan(
          id: 'intermediate-10k',
          name: '10K Intermediate Plan',
          description: 'For runners who have completed a 5K and want to step up to 10K',
          difficulty: 'Intermediate',
          durationWeeks: 10,
          sessions: _generateIntermediateSessions(),
        ),
        TrainingPlan(
          id: 'advanced-half-marathon',
          name: 'Half Marathon Advanced Plan',
          description: 'Challenging plan for experienced runners targeting a half marathon',
          difficulty: 'Advanced',
          durationWeeks: 12,
          sessions: _generateAdvancedSessions(),
        ),
      ];
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load training plans: $e';
      notifyListeners();
    }
  }

  /// Gets plans filtered by difficulty
  List<TrainingPlan> getPlansByDifficulty(String difficulty) {
    return _plans.where((plan) => plan.difficulty == difficulty).toList();
  }

  /// Helper method to generate beginner training sessions
  List<TrainingSession> _generateBeginnerSessions() {
    return [
      TrainingSession(
        id: 'beginner-w1d1',
        sessionNumber: 1,
        week: 1,
        day: 1,
        description: 'Easy Run',
        duration: 20,
        completed: false,
        intervals: [
          Interval(type: 'warmup', duration: 5, intensity: 'low'),
          Interval(type: 'run', duration: 10, intensity: 'medium'),
          Interval(type: 'cooldown', duration: 5, intensity: 'low'),
        ],
      ),
      TrainingSession(
        id: 'beginner-w1d3',
        sessionNumber: 2,
        week: 1,
        day: 3,
        description: 'Interval Training',
        duration: 25,
        completed: false,
        intervals: [
          Interval(type: 'warmup', duration: 5, intensity: 'low'),
          Interval(type: 'run', duration: 1, intensity: 'high'),
          Interval(type: 'walk', duration: 1, intensity: 'low'),
          Interval(type: 'run', duration: 1, intensity: 'high'),
          Interval(type: 'walk', duration: 1, intensity: 'low'),
          Interval(type: 'run', duration: 1, intensity: 'high'),
          Interval(type: 'walk', duration: 1, intensity: 'low'),
          Interval(type: 'cooldown', duration: 5, intensity: 'low'),
        ],
      ),
      TrainingSession(
        id: 'beginner-w1d5',
        sessionNumber: 3,
        week: 1,
        day: 5,
        description: 'Long Run',
        duration: 30,
        completed: false,
        intervals: [
          Interval(type: 'warmup', duration: 5, intensity: 'low'),
          Interval(type: 'run', duration: 20, intensity: 'medium'),
          Interval(type: 'cooldown', duration: 5, intensity: 'low'),
        ],
      ),
    ];
  }

  /// Helper method to generate intermediate training sessions
  List<TrainingSession> _generateIntermediateSessions() {
    return [
      TrainingSession(
        id: 'intermediate-w1d1',
        sessionNumber: 1,
        week: 1,
        day: 1,
        description: 'Tempo Run',
        duration: 35,
        completed: false,
        intervals: [
          Interval(type: 'warmup', duration: 10, intensity: 'low'),
          Interval(type: 'tempo', duration: 15, intensity: 'high'),
          Interval(type: 'cooldown', duration: 10, intensity: 'low'),
        ],
      ),
      TrainingSession(
        id: 'intermediate-w1d3',
        sessionNumber: 2,
        week: 1,
        day: 3,
        description: 'Hill Repeats',
        duration: 40,
        completed: false,
        intervals: [
          Interval(type: 'warmup', duration: 10, intensity: 'low'),
          Interval(type: 'hill', duration: 2, intensity: 'high'),
          Interval(type: 'recovery', duration: 2, intensity: 'low'),
          Interval(type: 'hill', duration: 2, intensity: 'high'),
          Interval(type: 'recovery', duration: 2, intensity: 'low'),
          Interval(type: 'hill', duration: 2, intensity: 'high'),
          Interval(type: 'recovery', duration: 2, intensity: 'low'),
          Interval(type: 'cooldown', duration: 10, intensity: 'low'),
        ],
      ),
    ];
  }

  /// Helper method to generate advanced training sessions
  List<TrainingSession> _generateAdvancedSessions() {
    return [
      TrainingSession(
        id: 'advanced-w1d1',
        sessionNumber: 1,
        week: 1,
        day: 1,
        description: 'Speed Intervals',
        duration: 50,
        completed: false,
        intervals: [
          Interval(type: 'warmup', duration: 15, intensity: 'low'),
          Interval(type: 'sprint', duration: 1, intensity: 'very high'),
          Interval(type: 'recovery', duration: 1, intensity: 'low'),
          Interval(type: 'sprint', duration: 1, intensity: 'very high'),
          Interval(type: 'recovery', duration: 1, intensity: 'low'),
          Interval(type: 'sprint', duration: 1, intensity: 'very high'),
          Interval(type: 'recovery', duration: 1, intensity: 'low'),
          Interval(type: 'cooldown', duration: 15, intensity: 'low'),
        ],
      ),
    ];
  }
}
