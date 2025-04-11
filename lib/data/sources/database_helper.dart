import 'dart:async';
import 'dart:convert'; // Needed for jsonDecode
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/workout.dart';
// import '../models/workout_point.dart'; // workout_point seems unused, commenting out
import '../models/route_point.dart'; // Added RoutePoint import
import '../models/training_plan.dart';
import '../models/training_session.dart';
import '../models/workout_interval.dart';
import '../models/user_profile.dart';
import '../models/weight_record.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode if needed, or print

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static const String _databaseName = 'fitstride.db';
  static const int _databaseVersion = 1; // Increment if schema changes

  static Database? _database;

  // --- Constants for Table and Column Names ---

  // Table Names
  static const String tableUser = 'user';
  static const String tableWorkouts = 'workouts';
  static const String tableWorkoutPoints = 'workout_points';
  static const String tableTrainingPlans = 'training_plans';
  static const String tableTrainingSessions = 'training_sessions';
  static const String tableWeightRecords = 'weight_records';
  static const String tableSettings = 'settings'; // Added settings table

  // Common Columns
  static const String columnId = 'id'; // Primary key for most tables
  static const String columnDeviceId = 'device_id';
  static const String columnTimestamp = 'timestamp'; // Common timestamp field

  // User Table Columns
  static const String columnUserName = 'name';
  static const String columnUserWeight = 'weight';
  static const String columnUserHeight = 'height';
  static const String columnUserGender = 'gender';
  static const String columnUserAge = 'age';
  static const String columnUserCreatedAt = 'created_at';
  static const String columnUserUpdatedAt = 'updated_at';
  // Added missing user profile columns based on model
  static const String columnUserTargetWeight = 'target_weight';
  static const String columnUserFitnessLevel = 'fitness_level';
  static const String columnUserWorkoutGoal = 'workout_goal';
  static const String columnUserUnitPreference =
      'unit_preference'; // e.g., 'metric' or 'imperial'
  static const String columnUserWeightUnit =
      'weight_unit'; // e.g., 'kg' or 'lbs'

  // Workouts Table Columns
  static const String columnWorkoutId = 'id'; // Re-alias for clarity
  static const String columnWorkoutDeviceId =
      'device_id'; // Added for consistency
  static const String columnWorkoutType = 'type';
  static const String columnWorkoutStartTime = 'start_time';
  static const String columnWorkoutEndTime = 'end_time';
  static const String columnDurationSeconds =
      'duration'; // Renamed from duration
  static const String columnDistance = 'distance';
  static const String columnCaloriesBurned = 'calories';
  static const String columnPace = 'pace';
  static const String columnWorkoutNotes = 'notes';
  static const String columnStatus = 'status'; // Added status column
  static const String columnElevationGain =
      'elevation_gain'; // Added elevation gain
  static const String columnElevationLoss =
      'elevation_loss'; // Added elevation loss

  // Workout Points Table Columns
  static const String columnPointId = 'id'; // Re-alias for clarity
  static const String columnPointWorkoutId = 'workout_id';
  static const String columnLatitude = 'latitude';
  static const String columnLongitude = 'longitude';
  static const String columnAltitude = 'altitude'; // Renamed from elevation
  static const String columnPointTimestamp =
      'timestamp'; // Re-alias for clarity
  static const String columnSpeed = 'speed';
  static const String columnAccuracy = 'accuracy'; // Added accuracy
  static const String columnHeading = 'heading'; // Added heading

  // Training Plans Table Columns
  static const String columnPlanId = 'id'; // Re-alias for clarity
  static const String columnPlanName = 'name';
  static const String columnPlanDescription = 'description';
  static const String columnPlanDifficulty = 'difficulty';
  static const String columnPlanDurationWeeks = 'duration_weeks';

  // Training Sessions Table Columns
  static const String columnSessionId = 'id'; // Re-alias for clarity
  static const String columnSessionPlanId = 'plan_id';
  static const String columnSessionWeek = 'week';
  static const String columnSessionDay = 'day';
  static const String columnSessionDescription = 'description';
  static const String columnSessionDuration =
      'duration_minutes'; // Renamed from duration_minutes
  static const String columnSessionIntervalsJson = 'intervals_json';
  static const String columnSessionCompleted = 'is_completed';
  static const String columnSessionType = 'type'; // Added type
  static const String columnSessionDistance = 'distance'; // Added distance

  // Weight Records Table Columns
  static const String columnWeightRecordId = 'id'; // Re-alias for clarity
  static const String columnWeightDeviceId =
      'device_id'; // Re-alias for clarity
  static const String columnWeight = 'weight';
  static const String columnDate = 'date';
  static const String columnWeightNotes = 'notes';

  // Settings Table Columns
  static const String columnSettingKey = 'key';
  static const String columnSettingValue = 'value';

  // --- Database Initialization ---

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDatabase,
      // onUpgrade: _onUpgrade, // Add if needed for future migrations
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Create user table
    await db.execute('''
    CREATE TABLE $tableUser (
      $columnDeviceId TEXT PRIMARY KEY,
      $columnUserName TEXT,
      $columnUserWeight REAL,
      $columnUserHeight REAL,
      $columnUserGender TEXT,
      $columnUserAge INTEGER,
      $columnUserTargetWeight REAL,
      $columnUserFitnessLevel TEXT,
      $columnUserWorkoutGoal TEXT,
      $columnUserUnitPreference TEXT,
      $columnUserWeightUnit TEXT,
      $columnUserCreatedAt TEXT,
      $columnUserUpdatedAt TEXT
    )
    ''');

    // Create workouts table
    await db.execute('''
    CREATE TABLE $tableWorkouts (
      $columnWorkoutId TEXT PRIMARY KEY,
      $columnWorkoutDeviceId TEXT,
      $columnWorkoutType TEXT,
      $columnWorkoutStartTime TEXT,
      $columnWorkoutEndTime TEXT,
      $columnDurationSeconds INTEGER,
      $columnDistance REAL,
      $columnCaloriesBurned INTEGER,
      $columnPace REAL,
      $columnWorkoutNotes TEXT,
      $columnStatus TEXT,
      $columnElevationGain REAL,
      $columnElevationLoss REAL,
      FOREIGN KEY ($columnWorkoutDeviceId) REFERENCES $tableUser ($columnDeviceId)
    )
    ''');

    // Create workout_points table
    await db.execute('''
    CREATE TABLE $tableWorkoutPoints (
      $columnPointId INTEGER PRIMARY KEY AUTOINCREMENT,
      $columnPointWorkoutId TEXT,
      $columnLatitude REAL,
      $columnLongitude REAL,
      $columnAltitude REAL,
      $columnPointTimestamp TEXT,
      $columnSpeed REAL,
      $columnAccuracy REAL,
      $columnHeading REAL,
      FOREIGN KEY ($columnPointWorkoutId) REFERENCES $tableWorkouts ($columnWorkoutId) ON DELETE CASCADE
    )
    '''); // Added ON DELETE CASCADE

    // Create training_plans table
    await db.execute('''
    CREATE TABLE $tableTrainingPlans (
      $columnPlanId TEXT PRIMARY KEY,
      $columnPlanName TEXT,
      $columnPlanDescription TEXT,
      $columnPlanDifficulty TEXT,
      $columnPlanDurationWeeks INTEGER
    )
    ''');

    // Create training_sessions table
    await db.execute('''
    CREATE TABLE $tableTrainingSessions (
      $columnSessionId TEXT PRIMARY KEY,
      $columnSessionPlanId TEXT,
      $columnSessionWeek INTEGER,
      $columnSessionDay INTEGER,
      $columnSessionDescription TEXT,
      $columnSessionDuration INTEGER,
      $columnSessionIntervalsJson TEXT,
      $columnSessionCompleted INTEGER,
      $columnSessionType TEXT,
      $columnSessionDistance REAL,
      FOREIGN KEY ($columnSessionPlanId) REFERENCES $tableTrainingPlans ($columnPlanId) ON DELETE CASCADE
    )
    '''); // Added ON DELETE CASCADE

    // Create weight_records table
    await db.execute('''
    CREATE TABLE $tableWeightRecords (
      $columnWeightRecordId TEXT PRIMARY KEY,
      $columnWeightDeviceId TEXT,
      $columnWeight REAL,
      $columnDate TEXT,
      $columnWeightNotes TEXT,
      FOREIGN KEY ($columnWeightDeviceId) REFERENCES $tableUser ($columnDeviceId) ON DELETE CASCADE
    )
    '''); // Added ON DELETE CASCADE

    // Create settings table
    await db.execute('''
      CREATE TABLE $tableSettings (
        $columnSettingKey TEXT PRIMARY KEY,
        $columnSettingValue TEXT
      )
      ''');

    // Create indexes for faster queries
    await db.execute(
      'CREATE INDEX idx_workouts_device_id ON $tableWorkouts($columnWorkoutDeviceId)',
    );
    await db.execute(
      'CREATE INDEX idx_workouts_start_time ON $tableWorkouts($columnWorkoutStartTime)',
    );
    await db.execute(
      'CREATE INDEX idx_workout_points_workout_id ON $tableWorkoutPoints($columnPointWorkoutId)',
    );
    await db.execute(
      'CREATE INDEX idx_training_sessions_plan_id ON $tableTrainingSessions($columnSessionPlanId)',
    );
    await db.execute(
      'CREATE INDEX idx_weight_records_device_id ON $tableWeightRecords($columnWeightDeviceId)',
    );

    // Insert default training plans
    await _insertDefaultTrainingPlans(db);
  }

  // --- Default Data Insertion ---

  Future<void> _insertDefaultTrainingPlans(Database db) async {
    // Get UUID instance
    const uuid = Uuid();

    // Insert interval walking plan
    final walkingPlanId = uuid.v4();
    await db.insert(tableTrainingPlans, {
      columnPlanId: walkingPlanId,
      columnPlanName: 'Interval Walking Plan',
      columnPlanDescription:
          'A weight loss plan designed for those who rarely exercise and can bear low-intensity workouts.',
      columnPlanDifficulty: 'beginner',
      columnPlanDurationWeeks: 4,
    });

    // Insert running beginner plan
    final beginnerPlanId = uuid.v4();
    await db.insert(tableTrainingPlans, {
      columnPlanId: beginnerPlanId,
      columnPlanName: 'Running Beginner',
      columnPlanDescription:
          'A running training plan designed for new runners with less experience.',
      columnPlanDifficulty: 'beginner',
      columnPlanDurationWeeks: 6,
    });

    // Insert 5K run plan
    final fiveKPlanId = uuid.v4();
    await db.insert(tableTrainingPlans, {
      columnPlanId: fiveKPlanId,
      columnPlanName: '5K Run',
      columnPlanDescription:
          'A beginner-friendly running plan guides your run from 0k to 5k.',
      columnPlanDifficulty: 'intermediate',
      columnPlanDurationWeeks: 8,
    });

    // Insert 10K run plan
    final tenKPlanId = uuid.v4();
    await db.insert(tableTrainingPlans, {
      columnPlanId: tenKPlanId,
      columnPlanName: '10K Run',
      columnPlanDescription:
          'A more challenging running plan designed for experienced runners.',
      columnPlanDifficulty: 'advanced',
      columnPlanDurationWeeks: 10,
    });

    // Add a few sessions for each plan
    await _insertWalkingPlanSessions(db, walkingPlanId);
    await _insertBeginnerRunningSessions(db, beginnerPlanId);
    await _insert5KRunningSessions(db, fiveKPlanId);
    await _insert10KRunningSessions(db, tenKPlanId);
  }

  Future<void> _insertWalkingPlanSessions(Database db, String planId) async {
    const uuid = Uuid();

    // Week 1, Day 1
    await db.insert(tableTrainingSessions, {
      columnSessionId: uuid.v4(),
      columnSessionPlanId: planId,
      columnSessionWeek: 1,
      columnSessionDay: 1,
      columnSessionDescription: 'Warm-up walk',
      columnSessionDuration: 30,
      columnSessionIntervalsJson:
          '[{"type":"walk","duration":300,"intensity":"low","coachingCue":"Start with a gentle warm-up walk"},{"type":"walk","duration":600,"intensity":"medium","coachingCue":"Increase your pace slightly"},{"type":"walk","duration":600,"intensity":"medium","coachingCue":"Maintain this comfortable pace"},{"type":"walk","duration":300,"intensity":"low","coachingCue":"Cool down with an easy walk"}]',
      columnSessionCompleted: 0,
    });

    // Week 1, Day 3
    await db.insert(tableTrainingSessions, {
      columnSessionId: uuid.v4(),
      columnSessionPlanId: planId,
      columnSessionWeek: 1,
      columnSessionDay: 3,
      columnSessionDescription: 'Interval Walking',
      columnSessionDuration: 30,
      columnSessionIntervalsJson:
          '[{"type":"walk","duration":300,"intensity":"low","coachingCue":"Start with a gentle warm-up walk"},{"type":"walk","duration":180,"intensity":"high","coachingCue":"Speed up to a brisk walk"},{"type":"walk","duration":120,"intensity":"low","coachingCue":"Slow down for recovery"},{"type":"walk","duration":180,"intensity":"high","coachingCue":"Speed up again"},{"type":"walk","duration":120,"intensity":"low","coachingCue":"Another recovery interval"},{"type":"walk","duration":180,"intensity":"high","coachingCue":"Final brisk walking interval"},{"type":"walk","duration":300,"intensity":"low","coachingCue":"Cool down walk"}]',
      columnSessionCompleted: 0,
    });
  }

  Future<void> _insertBeginnerRunningSessions(
    Database db,
    String planId,
  ) async {
    const uuid = Uuid();

    // Week 1, Day 1
    await db.insert(tableTrainingSessions, {
      columnSessionId: uuid.v4(),
      columnSessionPlanId: planId,
      columnSessionWeek: 1,
      columnSessionDay: 1,
      columnSessionDescription: 'Walk/Run Intervals',
      columnSessionDuration: 25,
      columnSessionIntervalsJson:
          '[{"type":"walk","duration":300,"intensity":"low","coachingCue":"Start with a gentle warm-up walk"},{"type":"run","duration":60,"intensity":"medium","coachingCue":"Your first run interval, keep it easy"},{"type":"walk","duration":90,"intensity":"low","coachingCue":"Recovery walk"},{"type":"run","duration":60,"intensity":"medium","coachingCue":"Second run interval"},{"type":"walk","duration":90,"intensity":"low","coachingCue":"Recovery walk"},{"type":"run","duration":60,"intensity":"medium","coachingCue":"Third run interval"},{"type":"walk","duration":90,"intensity":"low","coachingCue":"Recovery walk"},{"type":"run","duration":60,"intensity":"medium","coachingCue":"Fourth run interval"},{"type":"walk","duration":90,"intensity":"low","coachingCue":"Recovery walk"},{"type":"run","duration":60,"intensity":"medium","coachingCue":"Fifth run interval"},{"type":"walk","duration":300,"intensity":"low","coachingCue":"Cool down walk"}]',
      columnSessionCompleted: 0,
    });

    // Week 1, Day 3
    await db.insert(tableTrainingSessions, {
      columnSessionId: uuid.v4(),
      columnSessionPlanId: planId,
      columnSessionWeek: 1,
      columnSessionDay: 3,
      columnSessionDescription: 'Walk/Run Intervals',
      columnSessionDuration: 25,
      columnSessionIntervalsJson:
          '[{"type":"walk","duration":300,"intensity":"low","coachingCue":"Start with a gentle warm-up walk"},{"type":"run","duration":60,"intensity":"medium","coachingCue":"First run interval"},{"type":"walk","duration":90,"intensity":"low","coachingCue":"Recovery walk"},{"type":"run","duration":60,"intensity":"medium","coachingCue":"Second run interval"},{"type":"walk","duration":90,"intensity":"low","coachingCue":"Recovery walk"},{"type":"run","duration":60,"intensity":"medium","coachingCue":"Third run interval"},{"type":"walk","duration":90,"intensity":"low","coachingCue":"Recovery walk"},{"type":"run","duration":60,"intensity":"medium","coachingCue":"Fourth run interval"},{"type":"walk","duration":90,"intensity":"low","coachingCue":"Recovery walk"},{"type":"run","duration":60,"intensity":"medium","coachingCue":"Fifth run interval"},{"type":"walk","duration":300,"intensity":"low","coachingCue":"Cool down walk"}]',
      columnSessionCompleted: 0,
    });
  }

  Future<void> _insert5KRunningSessions(Database db, String planId) async {
    const uuid = Uuid();

    // Week 1, Day 1
    await db.insert(tableTrainingSessions, {
      columnSessionId: uuid.v4(),
      columnSessionPlanId: planId,
      columnSessionWeek: 1,
      columnSessionDay: 1,
      columnSessionDescription: 'Base Building',
      columnSessionDuration: 30,
      columnSessionIntervalsJson:
          '[{"type":"walk","duration":300,"intensity":"low","coachingCue":"Warm up with a brisk walk"},{"type":"run","duration":180,"intensity":"medium","coachingCue":"First run interval, find your rhythm"},{"type":"walk","duration":120,"intensity":"low","coachingCue":"Recovery walk"},{"type":"run","duration":180,"intensity":"medium","coachingCue":"Second run interval"},{"type":"walk","duration":120,"intensity":"low","coachingCue":"Recovery walk"},{"type":"run","duration":180,"intensity":"medium","coachingCue":"Third run interval"},{"type":"walk","duration":120,"intensity":"low","coachingCue":"Recovery walk"},{"type":"run","duration":180,"intensity":"medium","coachingCue":"Fourth run interval"},{"type":"walk","duration":300,"intensity":"low","coachingCue":"Cool down walk"}]',
      columnSessionCompleted: 0,
    });

    // Week 1, Day 3
    await db.insert(tableTrainingSessions, {
      columnSessionId: uuid.v4(),
      columnSessionPlanId: planId,
      columnSessionWeek: 1,
      columnSessionDay: 3,
      columnSessionDescription: 'Extended Intervals',
      columnSessionDuration: 32,
      columnSessionIntervalsJson:
          '[{"type":"walk","duration":300,"intensity":"low","coachingCue":"Warm up with a brisk walk"},{"type":"run","duration":200,"intensity":"medium","coachingCue":"First run interval, steady pace"},{"type":"walk","duration":100,"intensity":"low","coachingCue":"Quick recovery"},{"type":"run","duration":200,"intensity":"medium","coachingCue":"Second run interval"},{"type":"walk","duration":100,"intensity":"low","coachingCue":"Another quick recovery"},{"type":"run","duration":200,"intensity":"medium","coachingCue":"Third run interval"},{"type":"walk","duration":100,"intensity":"low","coachingCue":"Last recovery"},{"type":"run","duration":200,"intensity":"medium","coachingCue":"Final push"},{"type":"walk","duration":300,"intensity":"low","coachingCue":"Cool down walk"}]',
      columnSessionCompleted: 0,
    });
  }

  Future<void> _insert10KRunningSessions(Database db, String planId) async {
    const uuid = Uuid();

    // Week 1, Day 1
    await db.insert(tableTrainingSessions, {
      columnSessionId: uuid.v4(),
      columnSessionPlanId: planId,
      columnSessionWeek: 1,
      columnSessionDay: 1,
      columnSessionDescription: 'Endurance Building',
      columnSessionDuration: 40,
      columnSessionIntervalsJson:
          '[{"type":"walk","duration":300,"intensity":"low","coachingCue":"Warm up with a brisk walk"},{"type":"run","duration":600,"intensity":"medium","coachingCue":"First 10-minute run, steady pace"},{"type":"walk","duration":120,"intensity":"low","coachingCue":"Brief recovery walk"},{"type":"run","duration":600,"intensity":"medium","coachingCue":"Second 10-minute run, maintain form"},{"type":"walk","duration":120,"intensity":"low","coachingCue":"Brief recovery walk"},{"type":"run","duration":600,"intensity":"medium","coachingCue":"Final 10-minute run, finish strong"},{"type":"walk","duration":300,"intensity":"low","coachingCue":"Cool down walk"}]',
      columnSessionCompleted: 0,
    });

    // Week 1, Day 3
    await db.insert(tableTrainingSessions, {
      columnSessionId: uuid.v4(),
      columnSessionPlanId: planId,
      columnSessionWeek: 1,
      columnSessionDay: 3,
      columnSessionDescription: 'Speed Intervals',
      columnSessionDuration: 45,
      columnSessionIntervalsJson:
          '[{"type":"walk","duration":300,"intensity":"low","coachingCue":"Warm up with a brisk walk"},{"type":"run","duration":300,"intensity":"medium","coachingCue":"Easy warm-up run"},{"type":"run","duration":120,"intensity":"high","coachingCue":"First sprint interval"},{"type":"walk","duration":60,"intensity":"low","coachingCue":"Quick recovery"},{"type":"run","duration":120,"intensity":"high","coachingCue":"Second sprint interval"},{"type":"walk","duration":60,"intensity":"low","coachingCue":"Quick recovery"},{"type":"run","duration":120,"intensity":"high","coachingCue":"Third sprint interval"},{"type":"walk","duration":60,"intensity":"low","coachingCue":"Quick recovery"},{"type":"run","duration":120,"intensity":"high","coachingCue":"Fourth sprint interval"},{"type":"walk","duration":60,"intensity":"low","coachingCue":"Quick recovery"},{"type":"run","duration":120,"intensity":"high","coachingCue":"Final sprint interval"},{"type":"run","duration":300,"intensity":"medium","coachingCue":"Easy cool-down run"},{"type":"walk","duration":300,"intensity":"low","coachingCue":"Final cool down walk"}]',
      columnSessionCompleted: 0,
    });
  }

  // --- User CRUD operations ---
  Future<void> insertOrUpdateUserProfile(UserProfile user) async {
    final db = await database;
    await db.insert(
      tableUser,
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserProfile?> getUserProfile(String deviceId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableUser,
      where: '$columnDeviceId = ?',
      whereArgs: [deviceId],
    );

    if (maps.isEmpty) return null;

    return UserProfile.fromMap(maps.first);
  }

  // --- Workout CRUD operations ---
  Future<String> insertWorkout(Workout workout) async {
    final db = await database;
    String id = workout.id;

    if (id.isEmpty) {
      id = const Uuid().v4();
    }

    final Map<String, dynamic> workoutMap = workout.toMap();
    workoutMap[columnWorkoutId] = id; // Ensure ID is in the map

    await db.insert(tableWorkouts, workoutMap,
        conflictAlgorithm: ConflictAlgorithm.replace);

    // Save route points
    if (workout.routePoints.isNotEmpty) {
      final batch = db.batch();

      for (var point in workout.routePoints) {
        final pointMap = {
          columnPointWorkoutId: id,
          columnLatitude: point.latitude,
          columnLongitude: point.longitude,
          columnAltitude: point.altitude, // Use correct constant
          columnPointTimestamp: point.timestamp.toIso8601String(),
          columnSpeed: point.speed,
          columnAccuracy: point.accuracy, // Added
          columnHeading: point.heading, // Added
        };

        batch.insert(tableWorkoutPoints, pointMap);
      }

      await batch.commit(noResult: true);
    }

    return id;
  }

  Future<void> updateWorkout(Workout workout) async {
    final db = await database;
    await db.update(
      tableWorkouts,
      workout.toMap(),
      where: '$columnWorkoutId = ?',
      whereArgs: [workout.id],
    );
    // Consider updating route points if they can change after initial insertion
  }

  Future<List<Workout>> getAllWorkouts({
    String? deviceId,
    int? limit,
    int? offset,
  }) async {
    final db = await database;

    final List<Map<String, dynamic>> maps;

    if (deviceId != null) {
      maps = await db.query(
        tableWorkouts,
        where: '$columnWorkoutDeviceId = ?', // Use correct column name
        whereArgs: [deviceId],
        orderBy: '$columnWorkoutStartTime DESC',
        limit: limit,
        offset: offset,
      );
    } else {
      maps = await db.query(
        tableWorkouts,
        orderBy: '$columnWorkoutStartTime DESC',
        limit: limit,
        offset: offset,
      );
    }

    final List<Workout> workouts = [];

    for (var map in maps) {
      // Get route points for this workout
      final pointMaps = await db.query(
        tableWorkoutPoints,
        where: '$columnPointWorkoutId = ?',
        whereArgs: [map[columnWorkoutId]],
        orderBy: '$columnPointTimestamp ASC',
      );

      final List<RoutePoint> points = pointMaps.map((pointMap) {
        return RoutePoint.fromMap(pointMap); // Use factory constructor
      }).toList();

      // Create workout with route points
      final workout = Workout.fromMap(map);
      workouts.add(workout.copyWith(routePoints: points));
    }

    return workouts;
  }

  Future<Workout?> getWorkoutById(String id) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      tableWorkouts,
      where: '$columnWorkoutId = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    // Get route points for this workout
    final pointMaps = await db.query(
      tableWorkoutPoints,
      where: '$columnPointWorkoutId = ?',
      whereArgs: [id],
      orderBy: '$columnPointTimestamp ASC',
    );

    final List<RoutePoint> points = pointMaps.map((pointMap) {
      return RoutePoint.fromMap(pointMap); // Use factory constructor
    }).toList();

    // Create workout with route points
    final workout = Workout.fromMap(maps.first);
    return workout.copyWith(routePoints: points);
  }

  Future<int> deleteWorkoutById(String id) async {
    final db = await database;

    // Delete route points first (foreign key constraint with ON DELETE CASCADE handles this)
    // await db.delete(tableWorkoutPoints, where: '$columnPointWorkoutId = ?', whereArgs: [id]);

    // Delete workout
    return await db
        .delete(tableWorkouts, where: '$columnWorkoutId = ?', whereArgs: [id]);
  }

  // --- Training plan operations ---
  Future<List<TrainingPlan>> getAllTrainingPlans() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableTrainingPlans);

    List<TrainingPlan> plans = [];
    for (var map in maps) {
      final plan =
          await getTrainingPlanWithSessions(map[columnPlanId] as String);
      if (plan != null) {
        plans.add(plan);
      }
    }
    return plans;
  }

  Future<TrainingPlan?> getTrainingPlanById(String id) async {
    return await getTrainingPlanWithSessions(id); // Re-use existing logic
  }

  Future<List<TrainingSession>> getSessionsForWeek(
      String planId, int week) async {
    final db = await database;
    final sessionMaps = await db.query(
      tableTrainingSessions,
      where: '$columnSessionPlanId = ? AND $columnSessionWeek = ?',
      whereArgs: [planId, week],
      orderBy: '$columnSessionDay ASC',
    );
    return sessionMaps.map((map) => TrainingSession.fromMap(map)).toList();
  }

  Future<void> markSessionCompleted(String sessionId, bool isCompleted) async {
    final db = await database;
    await db.update(
      tableTrainingSessions,
      {columnSessionCompleted: isCompleted ? 1 : 0},
      where: '$columnSessionId = ?',
      whereArgs: [sessionId],
    );
  }

  Future<TrainingPlan?> getTrainingPlanWithSessions(String id) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      tableTrainingPlans,
      where: '$columnPlanId = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    // Get sessions for this plan
    final sessionMaps = await db.query(
      tableTrainingSessions,
      where: '$columnSessionPlanId = ?',
      whereArgs: [id],
      orderBy: '$columnSessionWeek ASC, $columnSessionDay ASC',
    );

    final List<TrainingSession> sessions = sessionMaps.map((sessionMap) {
      return TrainingSession.fromMap(sessionMap); // Use factory constructor
    }).toList();

    return TrainingPlan.fromMap(maps.first).copyWith(sessions: sessions);
  }

  // --- Weight records operations ---
  Future<String> insertWeightRecord(WeightRecord record) async {
    final db = await database;
    String id = record.id;

    if (id.isEmpty) {
      id = const Uuid().v4();
    }

    final Map<String, dynamic> recordMap = record.toMap();
    recordMap[columnWeightRecordId] = id; // Ensure ID is in the map

    await db.insert(tableWeightRecords, recordMap,
        conflictAlgorithm: ConflictAlgorithm.replace);
    return id;
  }

  Future<List<WeightRecord>> getWeightRecords(String deviceId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableWeightRecords,
      where: '$columnWeightDeviceId = ?',
      whereArgs: [deviceId],
      orderBy: '$columnDate DESC',
    );

    return List.generate(maps.length, (i) {
      return WeightRecord.fromMap(maps[i]); // Use factory constructor
    });
  }

  Future<int> deleteWeightRecord(String id) async {
    final db = await database;
    return await db.delete(tableWeightRecords,
        where: '$columnWeightRecordId = ?', whereArgs: [id]);
  }

  Future<int> updateWeightRecord(WeightRecord record) async {
    final db = await database;
    return await db.update(
      tableWeightRecords,
      record.toMap(),
      where: '$columnWeightRecordId = ?',
      whereArgs: [record.id],
    );
  }

  // --- Settings Operations ---
  Future<void> saveSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      tableSettings,
      {columnSettingKey: key, columnSettingValue: value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableSettings,
      where: '$columnSettingKey = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return maps.first[columnSettingValue] as String?;
    }
    return null;
  }

  // --- Statistics ---
  Future<Map<String, double>> getTotalStats(String deviceId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT
        SUM($columnDistance) as totalDistance,
        SUM($columnDurationSeconds) as totalDuration,
        COUNT(*) as totalWorkouts
      FROM $tableWorkouts
      WHERE $columnWorkoutDeviceId = ?
    ''', [deviceId]);

    if (result.isNotEmpty &&
        result.first['totalWorkouts'] != null &&
        (result.first['totalWorkouts'] as int) > 0) {
      return {
        'totalDistance':
            (result.first['totalDistance'] as num?)?.toDouble() ?? 0.0,
        'totalDuration':
            (result.first['totalDuration'] as num?)?.toDouble() ?? 0.0,
        'totalWorkouts':
            (result.first['totalWorkouts'] as num?)?.toDouble() ?? 0.0,
      };
    }
    return {'totalDistance': 0.0, 'totalDuration': 0.0, 'totalWorkouts': 0.0};
  }

  Future<Map<String, double>> getStatsForPeriod(
      String deviceId, DateTime startDate, DateTime endDate) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT
        SUM($columnDistance) as totalDistance,
        SUM($columnDurationSeconds) as totalDuration,
        COUNT(*) as totalWorkouts
      FROM $tableWorkouts
      WHERE $columnWorkoutDeviceId = ? AND $columnWorkoutStartTime >= ? AND $columnWorkoutStartTime <= ?
    ''', [deviceId, startDate.toIso8601String(), endDate.toIso8601String()]);

    if (result.isNotEmpty &&
        result.first['totalWorkouts'] != null &&
        (result.first['totalWorkouts'] as int) > 0) {
      return {
        'totalDistance':
            (result.first['totalDistance'] as num?)?.toDouble() ?? 0.0,
        'totalDuration':
            (result.first['totalDuration'] as num?)?.toDouble() ?? 0.0,
        'totalWorkouts':
            (result.first['totalWorkouts'] as num?)?.toDouble() ?? 0.0,
      };
    }
    return {'totalDistance': 0.0, 'totalDuration': 0.0, 'totalWorkouts': 0.0};
  }

  // --- Backup and Restore (Placeholder - Requires more robust implementation) ---
  Future<String?> backupDatabaseToZip() async {
    // Placeholder: Actual implementation would involve:
    // 1. Getting the database path.
    // 2. Copying the database file to a temporary location.
    // 3. Using the 'archive' package to create a zip file containing the DB.
    // 4. Returning the path to the zip file.
    if (kDebugMode) {
      print("Database backup requested (not fully implemented).");
    }
    return null; // Indicate not implemented or return path
  }

  Future<bool> restoreDatabaseFromZip(String zipFilePath) async {
    // Placeholder: Actual implementation would involve:
    // 1. Closing the current database connection.
    // 2. Using the 'archive' package to extract the DB file from the zip.
    // 3. Getting the application's database path.
    // 4. Replacing the existing database file with the extracted one.
    // 5. Re-initializing the database connection (_initDatabase).
    // 6. Handling errors during the process.
    if (kDebugMode) {
      print(
          "Database restore requested from $zipFilePath (not fully implemented).");
    }
    return false; // Indicate not implemented or success/failure
  }

  // --- Close Database ---
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null; // Reset the static instance
  }

  // --- Get Database Path (for debugging/export) ---
  Future<String> get databasePath async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, _databaseName);
  }
}
