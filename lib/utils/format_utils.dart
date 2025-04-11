import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Utility class for formatting various workout metrics
///
/// Provides consistent formatting for distance, pace, duration, elevation,
/// and other workout-related metrics with support for metric/imperial units.
class FormatUtils {
  /// Format distance in kilometers or miles
  static String formatDistance(double meters, bool isMetric) {
    if (meters <= 0) return '0.00';
    
    final distance = isMetric ? meters / 1000 : meters / 1609.34;
    return distance.toStringAsFixed(2);
  }
  
  /// Format pace in minutes per kilometer or mile
  static String formatPace(double paceSeconds, bool isMetric) {
    if (paceSeconds <= 0) return '--:--';
    
    final minutes = (paceSeconds / 60).floor();
    final seconds = (paceSeconds % 60).floor();
    
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  /// Format duration in HH:MM:SS format
  static String formatDuration(int seconds) {
    if (seconds <= 0) return '00:00:00';
    
    final hours = (seconds / 3600).floor();
    final minutes = ((seconds % 3600) / 60).floor();
    final remainingSeconds = seconds % 60;
    
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  /// Format duration in a more readable format (e.g., 1h 23m 45s)
  static String formatDurationReadable(int seconds) {
    if (seconds <= 0) return '0s';
    
    final hours = (seconds / 3600).floor();
    final minutes = ((seconds % 3600) / 60).floor();
    final remainingSeconds = seconds % 60;
    
    String result = '';
    
    if (hours > 0) {
      result += '${hours}h ';
    }
    
    if (minutes > 0 || hours > 0) {
      result += '${minutes}m ';
    }
    
    result += '${remainingSeconds}s';
    
    return result;
  }
  
  /// Format elevation in meters or feet
  static String formatElevation(double meters, bool isMetric) {
    if (meters <= 0) return '0';
    
    final elevation = isMetric ? meters : meters * 3.28084;
    return elevation.round().toString();
  }
  
  /// Format calories
  static String formatCalories(int calories) {
    if (calories <= 0) return '0';
    
    return calories.toString();
  }
  
  /// Format heart rate
  static String formatHeartRate(int heartRate) {
    if (heartRate <= 0) return '--';
    
    return heartRate.toString();
  }
  
  /// Format cadence (steps per minute)
  static String formatCadence(int cadence) {
    if (cadence <= 0) return '--';
    
    return cadence.toString();
  }
  
  /// Format date in a readable format
  static String formatDate(DateTime date) {
    return DateFormat('EEEE, MMMM d, y').format(date);
  }
  
  /// Format time in a readable format
  static String formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }
  
  /// Format date and time in a readable format
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d, y • h:mm a').format(dateTime);
  }
  
  /// Format weight in kilograms or pounds
  static String formatWeight(double kilograms, bool isMetric) {
    if (kilograms <= 0) return '0.0';
    
    final weight = isMetric ? kilograms : kilograms * 2.20462;
    return weight.toStringAsFixed(1);
  }
  
  /// Get the appropriate weight unit (kg or lb)
  static String getWeightUnit(bool isMetric) {
    return isMetric ? 'kg' : 'lb';
  }
  
  /// Get the appropriate distance unit (km or mi)
  static String getDistanceUnit(bool isMetric) {
    return isMetric ? 'km' : 'mi';
  }
  
  /// Get the appropriate elevation unit (m or ft)
  static String getElevationUnit(bool isMetric) {
    return isMetric ? 'm' : 'ft';
  }
  
  /// Get the appropriate pace unit (min/km or min/mi)
  static String getPaceUnit(bool isMetric) {
    return isMetric ? 'min/km' : 'min/mi';
  }
  
  /// Format a percentage value
  static String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }
  
  /// Format a decimal value with specified precision
  static String formatDecimal(double value, int precision) {
    return value.toStringAsFixed(precision);
  }
}
