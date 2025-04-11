import 'package:flutter/material.dart';
import '../../../device/notifications/notification_service.dart';
import '../../../data/models/workout.dart';

/// A controller for managing notifications related to workouts
/// 
/// This controller integrates with the workout screens to show
/// notifications at appropriate times during and after workouts.
class WorkoutNotificationController {
  final NotificationService _notificationService = NotificationService();
  
  /// Initialize the notification controller
  Future<void> initialize() async {
    await _notificationService.initialize();
  }
  
  /// Show a notification when a workout is completed
  Future<void> notifyWorkoutComplete(Workout workout) async {
    await _notificationService.showWorkoutCompleteNotification(workout);
  }
  
  /// Show an achievement notification for reaching a distance milestone
  Future<void> notifyDistanceMilestone(double distance) async {
    // Convert to km
    final kmDistance = (distance / 1000).floor();
    
    if (kmDistance > 0 && kmDistance % 5 == 0) {
      // Milestone for every 5km
      await _notificationService.showAchievementNotification(
        '$kmDistance km Milestone',
        'You\'ve reached $kmDistance kilometers in a single workout. Great job!',
      );
    }
  }
  
  /// Show an achievement notification for reaching a duration milestone
  Future<void> notifyDurationMilestone(Duration duration) async {
    final minutes = duration.inMinutes;
    
    if (minutes > 0 && minutes % 30 == 0) {
      // Milestone for every 30 minutes
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      
      String durationText = '';
      if (hours > 0) {
        durationText = '$hours hour${hours > 1 ? 's' : ''}';
        if (remainingMinutes > 0) {
          durationText += ' and $remainingMinutes minute${remainingMinutes > 1 ? 's' : ''}';
        }
      } else {
        durationText = '$minutes minute${minutes > 1 ? 's' : ''}';
      }
      
      await _notificationService.showAchievementNotification(
        '$durationText Milestone',
        'You\'ve been working out for $durationText. Keep up the good work!',
      );
    }
  }
  
  /// Show an achievement notification for reaching a streak milestone
  Future<void> notifyStreakMilestone(int streakDays) async {
    if (streakDays > 0 && (streakDays % 7 == 0 || streakDays == 3 || streakDays == 5)) {
      // Milestone for 3, 5, 7, 14, 21, etc. days
      await _notificationService.showStreakNotification(streakDays);
    }
  }
  
  /// Show an achievement notification for reaching a weight goal
  Future<void> notifyWeightGoalReached(double currentWeight, double goalWeight) async {
    await _notificationService.showWeightGoalNotification(currentWeight, goalWeight);
  }
  
  /// Show an achievement notification for completing a training plan
  Future<void> notifyTrainingPlanCompleted(String planName) async {
    await _notificationService.showAchievementNotification(
      'Training Plan Completed',
      'Congratulations! You\'ve completed the $planName training plan.',
    );
  }
}
