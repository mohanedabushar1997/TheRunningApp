import 'package:running_app/data/models/training_plan.dart';
import 'package:running_app/data/sources/database_helper.dart'; // Use DB Helper
// TODO: Potentially load default plans from assets
// import 'package:flutter/services.dart' show rootBundle;
// import 'dart:convert';
import 'package:running_app/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart'; // To store active plan ID

class TrainingRepository {
  final DatabaseHelper _dbHelper;
  static const _activePlanIdKey = 'active_training_plan_id';

  TrainingRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper(); // Use factory constructor

  // TODO: Load predefined plans from assets/JSON on first launch?
  // Future<void> loadDefaultPlansIfNeeded() async { ... }

  // --- Plan Management ---
  Future<List<TrainingPlan>> getAvailablePlans() async {
    Log.d("Fetching available training plans from DB...");
    try {
      // DB Helper method now handles fetching plans and their sessions
      return await _dbHelper.getAllTrainingPlans();
    } catch (e, s) {
      Log.e("Error getting available plans from DB", error: e, stackTrace: s);
      return []; // Return empty on error
    }
  }

  Future<TrainingPlan?> getActivePlan(String deviceId) async {
    Log.d("Fetching active training plan for device $deviceId...");
    try {
      final prefs = await SharedPreferences.getInstance();
      // Store active plan ID per device? Or just one globally? Assuming one global for now.
      final String? activePlanId = prefs.getString(_activePlanIdKey);

      if (activePlanId == null) {
        Log.i("No active training plan ID found in prefs.");
        return null;
      }

      // Fetch the plan details using the ID
      return await _dbHelper
          .getTrainingPlanById(activePlanId); // Call DB helper method
    } catch (e, s) {
      Log.e("Error getting active plan", error: e, stackTrace: s);
      return null;
    }
  }

  Future<void> setActivePlan(String deviceId, String? planId) async {
    Log.i("Setting active plan ID to: $planId for device $deviceId");
    try {
      final prefs = await SharedPreferences.getInstance();
      if (planId == null) {
        await prefs.remove(_activePlanIdKey);
      } else {
        await prefs.setString(_activePlanIdKey, planId);
      }
    } catch (e, s) {
      Log.e("Error saving active plan ID", error: e, stackTrace: s);
      // Handle error - maybe show message to user?
    }
  }

  // --- Session Management ---
  Future<void> updateSessionCompletion(String sessionId, bool completed) async {
    Log.d("Updating session $sessionId completion to $completed in DB...");
    try {
      // Corrected: Call the renamed method in DatabaseHelper
      await _dbHelper.markSessionCompleted(sessionId, completed);
      Log.i("Session $sessionId completion updated successfully.");
    } catch (e, s) {
      Log.e("Error updating session completion", error: e, stackTrace: s);
      // Handle error
    }
  }

  // TODO: Implement methods to create/save custom training plans
  // Future<void> saveCustomPlan(TrainingPlan plan) async { ... }

  // TODO: Implement method to delete a training plan
  // Future<void> deletePlan(String planId) async { ... }
}
