import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

/// Service for managing data persistence across app sessions
class DataPersistenceService {
  // Singleton pattern
  static final DataPersistenceService _instance = DataPersistenceService._internal();
  factory DataPersistenceService() => _instance;
  DataPersistenceService._internal();
  
  // Database instance
  Database? _database;
  
  // Shared preferences instance
  SharedPreferences? _preferences;
  
  // Status flags
  bool _isInitialized = false;
  
  // Getters
  bool get isInitialized => _isInitialized;
  
  /// Initialize the data persistence service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Initialize shared preferences
    _preferences = await SharedPreferences.getInstance();
    
    // Initialize database
    await _initializeDatabase();
    
    _isInitialized = true;
  }
  
  /// Initialize the SQLite database
  Future<void> _initializeDatabase() async {
    // Get database path
    final databasesPath = await getDatabasesPath();
    final dbPath = path.join(databasesPath, 'running_app.db');
    
    // Open database
    _database = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (Database db, int version) async {
        // Create workout table
        await db.execute('''
          CREATE TABLE workouts (
            id TEXT PRIMARY KEY,
            start_time INTEGER,
            end_time INTEGER,
            distance REAL,
            duration INTEGER,
            avg_speed REAL,
            avg_pace REAL,
            calories INTEGER,
            elevation_gain REAL,
            elevation_loss REAL,
            battery_usage INTEGER,
            route_data TEXT,
            metadata TEXT
          )
        ''');
        
        // Create achievements table
        await db.execute('''
          CREATE TABLE achievements (
            id TEXT PRIMARY KEY,
            title TEXT,
            description TEXT,
            category TEXT,
            tier TEXT,
            unlocked INTEGER,
            unlocked_date INTEGER,
            progress REAL,
            target REAL,
            metadata TEXT
          )
        ''');
        
        // Create user profile table
        await db.execute('''
          CREATE TABLE user_profile (
            id TEXT PRIMARY KEY,
            name TEXT,
            age INTEGER,
            gender TEXT,
            weight REAL,
            height REAL,
            fitness_level TEXT,
            goal TEXT,
            created_at INTEGER,
            updated_at INTEGER,
            metadata TEXT
          )
        ''');
      },
    );
  }
  
  /// Save workout data to database
  Future<bool> saveWorkout(Map<String, dynamic> workout) async {
    if (!_isInitialized || _database == null) {
      await initialize();
    }
    
    try {
      // Convert route data to JSON string
      if (workout.containsKey('route_data') && workout['route_data'] is List) {
        workout['route_data'] = jsonEncode(workout['route_data']);
      }
      
      // Convert metadata to JSON string
      if (workout.containsKey('metadata') && workout['metadata'] is Map) {
        workout['metadata'] = jsonEncode(workout['metadata']);
      }
      
      // Insert or update workout
      await _database!.insert(
        'workouts',
        workout,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      return true;
    } catch (e) {
      print('Error saving workout: $e');
      return false;
    }
  }
  
  /// Get all workouts from database
  Future<List<Map<String, dynamic>>> getWorkouts() async {
    if (!_isInitialized || _database == null) {
      await initialize();
    }
    
    try {
      // Get all workouts ordered by start time (newest first)
      final List<Map<String, dynamic>> workouts = await _database!.query(
        'workouts',
        orderBy: 'start_time DESC',
      );
      
      // Parse JSON strings back to objects
      return workouts.map((workout) {
        // Parse route data
        if (workout.containsKey('route_data') && workout['route_data'] is String) {
          try {
            workout['route_data'] = jsonDecode(workout['route_data']);
          } catch (e) {
            workout['route_data'] = [];
          }
        }
        
        // Parse metadata
        if (workout.containsKey('metadata') && workout['metadata'] is String) {
          try {
            workout['metadata'] = jsonDecode(workout['metadata']);
          } catch (e) {
            workout['metadata'] = {};
          }
        }
        
        return workout;
      }).toList();
    } catch (e) {
      print('Error getting workouts: $e');
      return [];
    }
  }
  
  /// Get workout by ID
  Future<Map<String, dynamic>?> getWorkout(String id) async {
    if (!_isInitialized || _database == null) {
      await initialize();
    }
    
    try {
      // Get workout by ID
      final List<Map<String, dynamic>> workouts = await _database!.query(
        'workouts',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (workouts.isEmpty) {
        return null;
      }
      
      final workout = workouts.first;
      
      // Parse JSON strings back to objects
      if (workout.containsKey('route_data') && workout['route_data'] is String) {
        try {
          workout['route_data'] = jsonDecode(workout['route_data']);
        } catch (e) {
          workout['route_data'] = [];
        }
      }
      
      if (workout.containsKey('metadata') && workout['metadata'] is String) {
        try {
          workout['metadata'] = jsonDecode(workout['metadata']);
        } catch (e) {
          workout['metadata'] = {};
        }
      }
      
      return workout;
    } catch (e) {
      print('Error getting workout: $e');
      return null;
    }
  }
  
  /// Delete workout by ID
  Future<bool> deleteWorkout(String id) async {
    if (!_isInitialized || _database == null) {
      await initialize();
    }
    
    try {
      // Delete workout by ID
      await _database!.delete(
        'workouts',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      return true;
    } catch (e) {
      print('Error deleting workout: $e');
      return false;
    }
  }
  
  /// Save achievement data to database
  Future<bool> saveAchievement(Map<String, dynamic> achievement) async {
    if (!_isInitialized || _database == null) {
      await initialize();
    }
    
    try {
      // Convert metadata to JSON string
      if (achievement.containsKey('metadata') && achievement['metadata'] is Map) {
        achievement['metadata'] = jsonEncode(achievement['metadata']);
      }
      
      // Insert or update achievement
      await _database!.insert(
        'achievements',
        achievement,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      return true;
    } catch (e) {
      print('Error saving achievement: $e');
      return false;
    }
  }
  
  /// Get all achievements from database
  Future<List<Map<String, dynamic>>> getAchievements() async {
    if (!_isInitialized || _database == null) {
      await initialize();
    }
    
    try {
      // Get all achievements
      final List<Map<String, dynamic>> achievements = await _database!.query(
        'achievements',
      );
      
      // Parse JSON strings back to objects
      return achievements.map((achievement) {
        // Parse metadata
        if (achievement.containsKey('metadata') && achievement['metadata'] is String) {
          try {
            achievement['metadata'] = jsonDecode(achievement['metadata']);
          } catch (e) {
            achievement['metadata'] = {};
          }
        }
        
        return achievement;
      }).toList();
    } catch (e) {
      print('Error getting achievements: $e');
      return [];
    }
  }
  
  /// Save user profile to database
  Future<bool> saveUserProfile(Map<String, dynamic> profile) async {
    if (!_isInitialized || _database == null) {
      await initialize();
    }
    
    try {
      // Convert metadata to JSON string
      if (profile.containsKey('metadata') && profile['metadata'] is Map) {
        profile['metadata'] = jsonEncode(profile['metadata']);
      }
      
      // Set updated_at timestamp
      profile['updated_at'] = DateTime.now().millisecondsSinceEpoch;
      
      // Insert or update profile
      await _database!.insert(
        'user_profile',
        profile,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      return true;
    } catch (e) {
      print('Error saving user profile: $e');
      return false;
    }
  }
  
  /// Get user profile from database
  Future<Map<String, dynamic>?> getUserProfile(String id) async {
    if (!_isInitialized || _database == null) {
      await initialize();
    }
    
    try {
      // Get profile by ID
      final List<Map<String, dynamic>> profiles = await _database!.query(
        'user_profile',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (profiles.isEmpty) {
        return null;
      }
      
      final profile = profiles.first;
      
      // Parse metadata
      if (profile.containsKey('metadata') && profile['metadata'] is String) {
        try {
          profile['metadata'] = jsonDecode(profile['metadata']);
        } catch (e) {
          profile['metadata'] = {};
        }
      }
      
      return profile;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }
  
  /// Save app settings to shared preferences
  Future<bool> saveSettings(Map<String, dynamic> settings) async {
    if (!_isInitialized || _preferences == null) {
      await initialize();
    }
    
    try {
      // Save each setting based on its type
      for (final entry in settings.entries) {
        final key = entry.key;
        final value = entry.value;
        
        if (value is String) {
          await _preferences!.setString(key, value);
        } else if (value is int) {
          await _preferences!.setInt(key, value);
        } else if (value is double) {
          await _preferences!.setDouble(key, value);
        } else if (value is bool) {
          await _preferences!.setBool(key, value);
        } else if (value is List<String>) {
          await _preferences!.setStringList(key, value);
        } else {
          // Convert other types to JSON string
          await _preferences!.setString(key, jsonEncode(value));
        }
      }
      
      return true;
    } catch (e) {
      print('Error saving settings: $e');
      return false;
    }
  }
  
  /// Get app settings from shared preferences
  Future<Map<String, dynamic>> getSettings() async {
    if (!_isInitialized || _preferences == null) {
      await initialize();
    }
    
    try {
      // Get all keys
      final keys = _preferences!.getKeys();
      
      // Create settings map
      final Map<String, dynamic> settings = {};
      
      // Get each setting
      for (final key in keys) {
        settings[key] = _preferences!.get(key);
      }
      
      return settings;
    } catch (e) {
      print('Error getting settings: $e');
      return {};
    }
  }
  
  /// Get a specific setting from shared preferences
  T? getSetting<T>(String key, {T? defaultValue}) {
    if (!_isInitialized || _preferences == null) {
      return defaultValue;
    }
    
    try {
      // Get setting based on type
      if (T == String) {
        return _preferences!.getString(key) as T? ?? defaultValue;
      } else if (T == int) {
        return _preferences!.getInt(key) as T? ?? defaultValue;
      } else if (T == double) {
        return _preferences!.getDouble(key) as T? ?? defaultValue;
      } else if (T == bool) {
        return _preferences!.getBool(key) as T? ?? defaultValue;
      } else if (T == List<String>) {
        return _preferences!.getStringList(key) as T? ?? defaultValue;
      } else {
        // Try to parse JSON string
        final value = _preferences!.getString(key);
        if (value == null) {
          return defaultValue;
        }
        
        try {
          return jsonDecode(value) as T? ?? defaultValue;
        } catch (e) {
          return defaultValue;
        }
      }
    } catch (e) {
      print('Error getting setting: $e');
      return defaultValue;
    }
  }
  
  /// Save file to app documents directory
  Future<String?> saveFile(String fileName, List<int> bytes) async {
    try {
      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final filePath = path.join(directory.path, fileName);
      
      // Write file
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      
      return filePath;
    } catch (e) {
      print('Error saving file: $e');
      return null;
    }
  }
  
  /// Read file from app documents directory
  Future<List<int>?> readFile(String fileName) async {
    try {
      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final filePath = path.join(directory.path, fileName);
      
      // Read file
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }
      
      return await file.readAsBytes();
    } catch (e) {
      print('Error reading file: $e');
      return null;
    }
  }
  
  /// Delete file from app documents directory
  Future<bool> deleteFile(String fileName) async {
    try {
      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final filePath = path.join(directory.path, fileName);
      
      // Delete file
      final file = File(filePath);
      if (!await file.exists()) {
        return true;
      }
      
      await file.delete();
      return true;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }
  
  /// Export all data to a JSON file
  Future<String?> exportData() async {
    if (!_isInitialized || _database == null || _preferences == null) {
      await initialize();
    }
    
    try {
      // Get all data
      final workouts = await getWorkouts();
      final achievements = await getAchievements();
      final settings = await getSettings();
      
      // Get user profile
      final userProfile = await getUserProfile('user');
      
      // Create export data
      final exportData = {
        'workouts': workouts,
        'achievements': achievements,
        'settings': settings,
        'user_profile': userProfile,
        'export_date': DateTime.now().toIso8601String(),
      };
      
      // Convert to JSON
      final jsonData = jsonEncode(exportData);
      
      // Save to file
      final fileName = 'running_app_export_${DateTime.now().millisecondsSinceEpoch}.json';
      final directory = await getApplicationDocumentsDirectory();
      final filePath = path.join(directory.path, fileName);
      
      final file = File(filePath);
      await file.writeAsString(jsonData);
      
      return filePath;
    } catch (e) {
      print('Error exporting data: $e');
      return null;
    }
  }
  
  /// Import data from a JSON file
  Future<bool> importData(String filePath) async {
    if (!_isInitialized || _database == null || _preferences == null) {
      await initialize();
    }
    
    try {
      // Read file
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }
      
      final jsonData = await file.readAsString();
      
      // Parse JSON
      final importData = jsonDecode(jsonData);
      
      // Import workouts
      if (importData.containsKey('workouts') && importData['workouts'] is List) {
        for (final workout in importData['workouts']) {
          await saveWorkout(Map<String, dynamic>.from(workout));
        }
      }
      
      // Import achievements
      if (importData.containsKey('achievements') && importData['achievements'] is List) {
        for (final achievement in importData['achievements']) {
          await saveAchievement(Map<String, dynamic>.from(achievement));
        }
      }
      
      // Import settings
      if (importData.containsKey('settings') && importData['settings'] is Map) {
        await saveSettings(Map<String, dynamic>.from(importData['settings']));
      }
      
      // Import user profile
      if (importData.containsKey('user_profile') && importData['user_profile'] is Map) {
        await saveUserProfile(Map<String, dynamic>.from(importData['user_profile']));
      }
      
      return true;
    } catch (e) {
      print('Error importing data: $e');
      return false;
    }
  }
  
  /// Clear all data
  Future<bool> clearAllData() async {
    if (!_isInitialized || _database == null || _preferences == null) {
      await initialize();
    }
    
    try {
      // Clear database tables
      await _database!.delete('workouts');
      await _database!.delete('achievements');
      await _database!.delete('user_profile');
      
      // Clear shared preferences
      await _preferences!.clear();
      
      return true;
    } catch (e) {
      print('Error clearing data: $e');
      return false;
    }
  }
  
  /// Close database connection
  Future<void> close() async {
    await _database?.close();
    _database = null;
    _isInitialized = false;
  }
}
