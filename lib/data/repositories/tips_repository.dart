import 'dart:math'; // For Random
import 'package:flutter/material.dart'; // For Icons
import 'package:running_app/data/models/running_tip.dart';
import 'package:running_app/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For favorite persistence

// TODO: Load tips from a database or asset file instead of hardcoding.
// Could use sqflite or load from a JSON file in assets/.

class TipsRepository {

  // --- Favorite Management ---
  static const _favoriteTipsKey = 'favorite_tip_ids';
  Set<String> _favoriteTipIds = {}; // In-memory cache of favorite IDs

  // Load favorites from persistence
  Future<void> _loadFavorites() async {
     try {
        final prefs = await SharedPreferences.getInstance();
        final List<String>? storedFavorites = prefs.getStringList(_favoriteTipsKey);
        if (storedFavorites != null) {
           _favoriteTipIds = storedFavorites.toSet();
           Log.d("Loaded ${_favoriteTipIds.length} favorite tip IDs.");
        }
     } catch (e, s) {
        Log.e("Error loading favorite tips", error: e, stackTrace: s);
     }
  }

  // Save favorites to persistence
  Future<void> _saveFavorites() async {
     try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(_favoriteTipsKey, _favoriteTipIds.toList());
        Log.d("Saved ${_favoriteTipIds.length} favorite tip IDs.");
     } catch (e, s) {
         Log.e("Error saving favorite tips", error: e, stackTrace: s);
     }
  }

  Future<void> toggleFavorite(String tipId) async {
    if (_favoriteTipIds.contains(tipId)) {
      _favoriteTipIds.remove(tipId);
    } else {
      _favoriteTipIds.add(tipId);
    }
    await _saveFavorites(); // Persist change
  }

  bool isFavorite(String tipId) {
    return _favoriteTipIds.contains(tipId);
  }
  // --- End Favorite Management ---


  // In-memory list (Consider loading from assets/DB)
  final List<RunningTip> _tips = [
     RunningTip(id: 'tip_001', title: 'Warm-Up Essentials', content: 'Always start your run with a dynamic warm-up. Include exercises like leg swings, torso twists, and high knees for 5-10 minutes to prepare your muscles and reduce injury risk.', category: RunningCategory.technique, difficulty: TipDifficulty.beginner),
     RunningTip(id: 'tip_002', title: 'Hydration Strategy', content: 'Drink water throughout the day, not just before running. Sip water during longer runs (over 60 minutes) and rehydrate fully afterward. Consider electrolytes for hot weather or intense sessions.', category: RunningCategory.nutrition, difficulty: TipDifficulty.any),
     RunningTip(id: 'tip_003', title: 'Proper Running Form', content: 'Maintain an upright posture, engage your core, keep your gaze forward, and let your arms swing relaxed from the shoulders. Aim for a light, quick cadence, landing midfoot.', category: RunningCategory.technique, difficulty: TipDifficulty.intermediate),
     RunningTip(id: 'tip_004', title: 'Choosing the Right Shoes', content: 'Visit a specialized running store for a gait analysis. Choose shoes that match your foot type, running style, and planned mileage. Replace shoes every 300-500 miles (500-800 km).', category: RunningCategory.gear, difficulty: TipDifficulty.beginner),
     RunningTip(id: 'tip_005', title: 'Cool-Down Importance', content: 'Finish your run with 5-10 minutes of easy jogging or walking, followed by static stretching targeting major muscle groups (quads, hamstrings, calves, hips). This aids recovery.', category: RunningCategory.recovery, difficulty: TipDifficulty.beginner),
     RunningTip(id: 'tip_006', title: 'Listen to Your Body', content: 'Pay attention to pain signals. Distinguish between normal muscle soreness and potential injury. Don\'t push through sharp or persistent pain. Rest is crucial for recovery.', category: RunningCategory.injuryPrevention, difficulty: TipDifficulty.any),
     RunningTip(id: 'tip_007', title: 'Cross-Training Benefits', content: 'Incorporate activities like swimming, cycling, or strength training into your routine. Cross-training builds overall fitness, strengthens supporting muscles, and prevents overuse injuries.', category: RunningCategory.training, difficulty: TipDifficulty.intermediate),
     RunningTip(id: 'tip_008', title: 'Pacing Yourself', content: 'Start runs at a comfortable, conversational pace, especially for longer distances. Use a GPS watch or app to monitor your pace. Avoid starting too fast to conserve energy.', category: RunningCategory.technique, difficulty: TipDifficulty.beginner),
     RunningTip(id: 'tip_009', title: 'Nutrition for Runners', content: 'Fuel your body with a balanced diet rich in carbohydrates for energy, protein for muscle repair, and healthy fats. Eat a small, carb-focused snack 1-2 hours before running.', category: RunningCategory.nutrition, difficulty: TipDifficulty.intermediate),
     RunningTip(id: 'tip_010', title: 'Rest and Recovery', content: 'Schedule rest days into your training week. Aim for 7-9 hours of quality sleep per night. Recovery is when your body adapts and gets stronger.', category: RunningCategory.recovery, difficulty: TipDifficulty.any),
     RunningTip(id: 'tip_011', title: 'Hill Training Techniques', content: 'Lean slightly into the hill, shorten your stride, increase cadence, and use your arms. Maintain effort, not pace. Control your descent to avoid excessive impact.', category: RunningCategory.training, difficulty: TipDifficulty.advanced),
     RunningTip(id: 'tip_012', title: 'Dealing with Side Stitches', content: 'Slow down your pace and breathe deeply, focusing on exhaling fully. Gently press on the affected area or stretch your arms overhead. Ensure proper hydration and avoid eating large meals close to running.', category: RunningCategory.injuryPrevention, difficulty: TipDifficulty.beginner),
     RunningTip(id: 'tip_013', title: 'Running in Different Weather', content: 'Dress in layers for cold weather, choosing moisture-wicking fabrics. Wear light-colored, breathable clothing in the heat and run during cooler parts of the day. Always check the forecast.', category: RunningCategory.gear, difficulty: TipDifficulty.any),
     RunningTip(id: 'tip_014', title: 'Setting Realistic Goals', content: 'Set SMART (Specific, Measurable, Achievable, Relevant, Time-bound) goals. Gradually increase mileage or pace to avoid injury and stay motivated. Celebrate your progress!', category: RunningCategory.motivation, difficulty: TipDifficulty.beginner),
     RunningTip(id: 'tip_015', title: 'Strength Training for Runners', content: 'Include exercises targeting core, glutes, hips, and legs 2-3 times per week. Squats, lunges, planks, and glute bridges improve stability, power, and efficiency.', category: RunningCategory.training, difficulty: TipDifficulty.intermediate),
     RunningTip(id: 'tip_016', title: 'Finding Motivation', content: 'Run with a friend or group, listen to music or podcasts, explore new routes, sign up for a race, or simply focus on the mental and physical benefits of running.', category: RunningCategory.motivation, difficulty: TipDifficulty.any),
  ];

  // Constructor to load favorites
  TipsRepository() {
     _loadFavorites(); // Load favorites when repository is instantiated
  }

  // Get tips (apply favorite status and filters)
  Future<List<RunningTip>> getTips({RunningCategory? category, TipDifficulty? difficulty}) async {
    await _loadFavorites(); // Ensure favorites are loaded before returning tips
    await Future.delayed(const Duration(milliseconds: 50)); // Simulate loading

    List<RunningTip> filteredTips = _tips.map((tip) => tip.copyWith(isFavorite: isFavorite(tip.id))).toList(); // Apply favorite status

    if (category != null && category != RunningCategory.all) {
      filteredTips = filteredTips.where((tip) => tip.category == category).toList();
    }
    if (difficulty != null && difficulty != TipDifficulty.any) {
       filteredTips = filteredTips.where((tip) {
         if (difficulty == TipDifficulty.beginner) {
            return tip.difficulty == TipDifficulty.beginner || tip.difficulty == TipDifficulty.any;
         } else if (difficulty == TipDifficulty.intermediate) {
            return tip.difficulty == TipDifficulty.beginner || tip.difficulty == TipDifficulty.intermediate || tip.difficulty == TipDifficulty.any;
         } else if (difficulty == TipDifficulty.advanced) {
             return true;
         }
         return tip.difficulty == TipDifficulty.any; // Only show 'any' if 'any' is selected
       }).toList();
    }

    return filteredTips;
  }

  // Get a random tip
  Future<RunningTip> getRandomTip() async {
     await _loadFavorites();
    await Future.delayed(const Duration(milliseconds: 20));
    if (_tips.isEmpty) {
       // Handle case with no tips available
       return const RunningTip(id: 'none', title: 'No Tips Available', content: 'Check back later for running tips.', category: RunningCategory.all, difficulty: TipDifficulty.any);
    }
    final random = Random();
    final randomTip = _tips[random.nextInt(_tips.length)];
    return randomTip.copyWith(isFavorite: isFavorite(randomTip.id));
  }

  // Get tip by ID
  Future<RunningTip?> getTipById(String id) async {
     await _loadFavorites();
    await Future.delayed(const Duration(milliseconds: 10));
    try {
      final tip = _tips.firstWhere((tip) => tip.id == id);
      return tip.copyWith(isFavorite: isFavorite(tip.id));
    } catch (e) {
      return null; // Not found
    }
  }

  // Get only favorite tips
  Future<List<RunningTip>> getFavoriteTips() async {
     await _loadFavorites();
     await Future.delayed(const Duration(milliseconds: 30));
      return _tips
          .where((tip) => _favoriteTipIds.contains(tip.id))
          .map((tip) => tip.copyWith(isFavorite: true)) // Ensure favorite status is true
          .toList();
  }

   // TODO: Implement findRelatedTips logic
   Future<List<RunningTip>> findRelatedTips(String currentTipId, RunningCategory category, {int count = 3}) async {
      await _loadFavorites();
       await Future.delayed(const Duration(milliseconds: 30));
       // Simple related: find other tips in the same category, exclude current, limit count
        return _tips
           .where((tip) => tip.id != currentTipId && tip.category == category)
           .map((tip) => tip.copyWith(isFavorite: isFavorite(tip.id))) // Apply favorite status
           .take(count)
           .toList();
       // Could be enhanced with tag-based relations, content similarity etc.
   }
}