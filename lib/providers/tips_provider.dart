import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/running_tip.dart';
import '../data/repositories/tips_repository.dart';
import '../utils/logger.dart';

/// Provider for running and fitness tips
///
/// This provider manages a collection of running and fitness tips
/// that can be shown to the user for motivation and education.
class TipsProvider extends ChangeNotifier {
  // SharedPreferences keys
  static const String _keyLastTipDate = 'last_tip_date';
  static const String _keySeenTips = 'seen_tips';
  static const String _keyDisabledCategories = 'disabled_tip_categories';
  static const String _keyCustomTips = 'custom_tips';

  // Tip categories
  static const List<String> categories = [
    'nutrition',
    'motivation',
    'technique',
    'recovery',
    'training',
    'safety',
    'equipment',
    'health',
  ];

  // Lists to store tips
  List<RunningTip> _allTips = [];
  List<String> _seenTipIds = [];
  List<String> _disabledCategories = [];
  DateTime? _lastTipDate;

  // Random number generator
  final Random _random = Random();

  // Loading state
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  // Getters
  List<RunningTip> get allTips => _allTips;
  List<String> get seenTipIds => _seenTipIds;
  List<String> get disabledCategories => _disabledCategories;
  DateTime? get lastTipDate => _lastTipDate;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;

  // Repository for loading and saving tips
  final TipsRepository? _tipsRepository;

  // Constructor
  TipsProvider({TipsRepository? tipsRepository})
      : _tipsRepository = tipsRepository {
    _initializeDefaultTips();
    // Don't auto-load if constructed with a repository
    // wait for explicit initialize call
    if (tipsRepository == null) {
      _loadPreferences();
    }
  }

  /// Initialize the provider
  Future<void> initialize() async {
    if (!_isLoading && _tipsRepository != null) {
      _isLoading = true;
      notifyListeners();

      try {
        // Load tips from repository
        final tips = await _tipsRepository!.getAllTips();
        if (tips.isNotEmpty) {
          _allTips.addAll(tips);
        }

        // Load preferences
        await _loadPreferences();

        _isLoading = false;
        _hasError = false;
        notifyListeners();
      } catch (e, stackTrace) {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
        AppLogger.error('Failed to initialize tips provider', e, stackTrace);
        notifyListeners();
      }
    }
    return;
  }

  /// Initialize with default tips
  Future<void> _initializeDefaultTips() async {
    _allTips = [
      RunningTip(
        id: 'tip_001',
        title: 'Hydration Matters',
        content:
            'Drink water before, during, and after your run. Proper hydration improves performance and speeds recovery.',
        category: 'health',
        difficulty: 'beginner',
      ),
      RunningTip(
        id: 'tip_002',
        title: 'Warm Up Properly',
        content:
            'Always start with a 5-10 minute warm-up to prepare your muscles and reduce injury risk.',
        category: 'technique',
        difficulty: 'beginner',
      ),
      RunningTip(
        id: 'tip_003',
        title: 'Recovery Nutrition',
        content:
            'Consume protein and carbs within 30 minutes after a run to maximize recovery and muscle repair.',
        category: 'nutrition',
        difficulty: 'intermediate',
      ),
      RunningTip(
        id: 'tip_004',
        title: 'Breathing Technique',
        content:
            'Focus on rhythmic breathing that corresponds with your steps. Try a 2:2 pattern (inhale for 2 steps, exhale for 2) for moderate runs.',
        category: 'technique',
        difficulty: 'intermediate',
      ),
      RunningTip(
        id: 'tip_005',
        title: 'Progressive Overload',
        content:
            'Increase your weekly mileage by no more than 10% to avoid overtraining and injuries.',
        category: 'training',
        difficulty: 'intermediate',
      ),
      RunningTip(
        id: 'tip_006',
        title: 'Rest Days Matter',
        content:
            'Schedule at least 1-2 rest days per week. Recovery is when your body adapts and gets stronger.',
        category: 'recovery',
        difficulty: 'beginner',
      ),
      RunningTip(
        id: 'tip_007',
        title: 'Proper Footwear',
        content:
            'Replace running shoes every 300-500 miles. Worn-out shoes can lead to injuries and reduced performance.',
        category: 'equipment',
        difficulty: 'beginner',
      ),
      RunningTip(
        id: 'tip_008',
        title: 'Mental Training',
        content:
            'Visualize success before your runs. Mental preparation can be as important as physical training.',
        category: 'motivation',
        difficulty: 'advanced',
      ),
      RunningTip(
        id: 'tip_009',
        title: 'Night Running Safety',
        content:
            'Wear reflective gear and carry a light when running at night. Safety should always be your priority.',
        category: 'safety',
        difficulty: 'beginner',
      ),
      RunningTip(
        id: 'tip_010',
        title: 'Strength for Runners',
        content:
            'Include lower body and core strength training in your routine to prevent injuries and improve running economy.',
        category: 'training',
        difficulty: 'intermediate',
      ),
    ];
  }

  /// Load tip preferences from SharedPreferences
  Future<void> _loadPreferences() async {
    try {
      _isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();

      // Load last tip date
      final lastTipDateStr = prefs.getString(_keyLastTipDate);
      if (lastTipDateStr != null) {
        _lastTipDate = DateTime.parse(lastTipDateStr);
      }

      // Load seen tips
      final seenTips = prefs.getStringList(_keySeenTips);
      if (seenTips != null) {
        _seenTipIds = seenTips;
      }

      // Load disabled categories
      final disabledCategories = prefs.getStringList(_keyDisabledCategories);
      if (disabledCategories != null) {
        _disabledCategories = disabledCategories;
      }

      // Load custom tips
      final customTipsJson = prefs.getStringList(_keyCustomTips);
      if (customTipsJson != null && customTipsJson.isNotEmpty) {
        final customTips = customTipsJson
            .map((json) => RunningTip.fromJson(jsonDecode(json)))
            .toList();
        _allTips.addAll(customTips);
      }

      _isLoading = false;
      _hasError = false;
      notifyListeners();
    } catch (e, stackTrace) {
      _isLoading = false;
      _hasError = true;
      _errorMessage = e.toString();
      AppLogger.error('Failed to load tip preferences', e, stackTrace);
      notifyListeners();
    }
  }

  /// Save preferences to SharedPreferences
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save last tip date
      if (_lastTipDate != null) {
        await prefs.setString(_keyLastTipDate, _lastTipDate!.toIso8601String());
      }

      // Save seen tips
      await prefs.setStringList(_keySeenTips, _seenTipIds);

      // Save disabled categories
      await prefs.setStringList(_keyDisabledCategories, _disabledCategories);

      // Save custom tips
      final customTips = _allTips.where((tip) => tip.isCustom).toList();
      if (customTips.isNotEmpty) {
        final customTipsJson =
            customTips.map((tip) => jsonEncode(tip.toJson())).toList();
        await prefs.setStringList(_keyCustomTips, customTipsJson);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save tip preferences', e, stackTrace);
    }
  }

  /// Get tip of the day
  RunningTip? getTipOfTheDay() {
    if (_isLoading || _allTips.isEmpty) return null;

    // Check if we've already shown a tip today
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_lastTipDate != null) {
      final lastDate =
          DateTime(_lastTipDate!.year, _lastTipDate!.month, _lastTipDate!.day);

      if (lastDate.isAtSameMomentAs(today)) {
        // Return the most recent tip we've seen
        if (_seenTipIds.isNotEmpty) {
          final lastTipId = _seenTipIds.last;
          return _allTips.firstWhere(
            (tip) => tip.id == lastTipId,
            orElse: () => _getRandomTip(),
          );
        }
      }
    }

    // Update the last tip date
    _lastTipDate = now;
    _savePreferences();

    return _getRandomTip();
  }

  /// Get a random tip, avoiding recently seen tips and disabled categories
  RunningTip _getRandomTip() {
    // Filter out disabled categories and recently seen tips
    final availableTips = _allTips
        .where((tip) =>
            !_disabledCategories.contains(tip.category) &&
            !_seenTipIds.contains(tip.id))
        .toList();

    // If no eligible tips, reset seen tips and try again
    if (availableTips.isEmpty) {
      // Reset seen tips but keep the most recent one
      final lastTip = _seenTipIds.isNotEmpty ? _seenTipIds.last : null;
      _seenTipIds.clear();
      if (lastTip != null) {
        _seenTipIds.add(lastTip);
      }
      _savePreferences();

      // Try again with reset seen tips
      return _getRandomTip();
    }

    // Get a random tip
    final index = _random.nextInt(availableTips.length);
    final tip = availableTips[index];

    // Add to seen tips
    _seenTipIds.add(tip.id);
    _savePreferences();

    return tip;
  }

  /// Get a tip by ID
  RunningTip? getTipById(String id) {
    try {
      return _allTips.firstWhere((tip) => tip.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Toggle a category enabled/disabled
  Future<void> toggleCategory(String category) async {
    if (_disabledCategories.contains(category)) {
      _disabledCategories.remove(category);
    } else {
      _disabledCategories.add(category);
    }

    await _savePreferences();
    notifyListeners();
  }

  /// Enable all categories
  Future<void> enableAllCategories() async {
    _disabledCategories.clear();
    await _savePreferences();
    notifyListeners();
  }

  /// Add a custom tip
  Future<void> addCustomTip(RunningTip tip) async {
    // Generate a unique ID if not provided
    final newTip = tip.id.startsWith('custom_')
        ? tip
        : RunningTip(
            id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
            title: tip.title,
            content: tip.content,
            category: tip.category,
            difficulty: tip.difficulty,
            isCustom: true,
          );

    _allTips.add(newTip);
    await _savePreferences();
    notifyListeners();
  }

  /// Delete a tip
  Future<void> deleteTip(String id) async {
    // Only allow deleting custom tips
    final index = _allTips.indexWhere((tip) => tip.id == id && tip.isCustom);
    if (index >= 0) {
      _allTips.removeAt(index);

      // Also remove from seen tips if present
      _seenTipIds.remove(id);

      await _savePreferences();
      notifyListeners();
    }
  }

  /// Get tips by category
  List<RunningTip> getTipsByCategory(String category) {
    return _allTips.where((tip) => tip.category == category).toList();
  }

  /// Get tips by difficulty
  List<RunningTip> getTipsByDifficulty(String difficulty) {
    return _allTips.where((tip) => tip.difficulty == difficulty).toList();
  }

  /// Mark all tips as unseen (reset)
  Future<void> resetSeenTips() async {
    _seenTipIds.clear();
    await _savePreferences();
    notifyListeners();
  }
}
