import 'dart:io';
import 'package:flutter/foundation.dart'; // For kReleaseMode
import 'package:logger/logger.dart' as pkg_logger;
import 'package:path_provider/path_provider.dart';
// TODO: Import remote logging service (e.g., Crashlytics, Sentry) if using
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';
// import 'package:sentry_flutter/sentry_flutter.dart';

// Define custom Log level enum matching logger package levels
enum Level {
  verbose(pkg_logger.Level.trace), // Renamed verbose to trace for logger pkg
  debug(pkg_logger.Level.debug),
  info(pkg_logger.Level.info),
  warning(pkg_logger.Level.warning),
  error(pkg_logger.Level.error),
  fatal(pkg_logger.Level.fatal); // Renamed wtf to fatal

  const Level(this.packageLevel);
  final pkg_logger.Level packageLevel;
}

class Log {
  static late pkg_logger.Logger _logger;
  static FileOutput? _fileOutput;
  static bool _isInitialized = false;
  static Level _currentLogLevel = Level.info; // Default level

  // Prevent instantiation
  Log._();

  static void initialize({
    Level level = kReleaseMode ? Level.info : Level.debug,
    bool logToFile = true, // Default to logging to file
    int fileLogSizeBytes = 1024 * 1024 * 5, // 5 MB max file size
    int filesToKeep = 3, // Keep last 3 log files
  }) {
    if (_isInitialized) {
      print("Logger already initialized.");
      return;
    }

    _currentLogLevel = level;
    List<pkg_logger.LogOutput> outputs = [];

    // Console Output (with colors)
    outputs.add(pkg_logger.ConsoleOutput());

    // File Output (Optional)
    if (logToFile) {
      _initializeFileOutput(fileLogSizeBytes, filesToKeep).then((output) {
        if (output != null) {
          _fileOutput = output;
          outputs.add(_fileOutput!);
           // Update logger instance once file output is ready
           _logger = pkg_logger.Logger(
             printer: pkg_logger.PrettyPrinter(
               methodCount: 1, // number of method calls to be displayed
               errorMethodCount: 8, // number of method calls if stacktrace is provided
               lineLength: 120, // width of the output
               colors: true, // Colorful log messages
               printEmojis: false, // Print an emoji for each log message
               printTime: true, // Should each log print contain a timestamp
             ),
             level: _currentLogLevel.packageLevel,
             output: pkg_logger.MultiOutput(outputs), // Use MultiOutput
           );
           Log.i("File logging initialized.");
        }
      });
    }

    // Initial logger setup (might be updated when file output is ready)
    _logger = pkg_logger.Logger(
      printer: pkg_logger.PrettyPrinter(
        methodCount: 1,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: false,
        printTime: true,
      ),
      level: _currentLogLevel.packageLevel,
      // Use MultiOutput even if file output isn't ready yet
      output: pkg_logger.MultiOutput(outputs),
    );

    _isInitialized = true;
    Log.i("Logger initialized. Level: ${level.name}. Log to file: $logToFile");
  }

  static Future<FileOutput?> _initializeFileOutput(int maxSize, int fileCount) async {
     try {
       final directory = await getApplicationDocumentsDirectory();
       final logDir = Directory('${directory.path}/logs');
       await logDir.create(recursive: true); // Ensure directory exists
       final logFile = File('${logDir.path}/app_log.txt');
       print("Log file path: ${logFile.path}"); // Print path for debugging access

       // Rotate logs: Keep only the last 'fileCount' files
       _rotateLogFiles(logDir.path, fileCount);


       return FileOutput(
         file: logFile,
         overrideExisting: false, // Append to existing file
         encoding: Encoding.getByName('utf-8') ?? Encoding.getByName('ascii')!,
         // TODO: Implement file size limit / rotation within FileOutput or manually
         // The logger package's FileOutput doesn't directly support size rotation.
         // We can check size before logging or use a dedicated file rotation package.
         // Simple check (approximate):
         // if (await logFile.exists() && await logFile.length() > maxSize) { ... rotate ... }
       );
     } catch (e, s) {
       print("Error initializing file logger: $e"); // Use print as logger might not be ready
       print(s);
       return null;
     }
  }

   // Simple log rotation (basic implementation)
   static void _rotateLogFiles(String logDirPath, int filesToKeep) {
      try {
         final dir = Directory(logDirPath);
         if (!dir.existsSync()) return;

         // Get existing log files, sort by modification time (oldest first)
         final files = dir.listSync()
            .where((entity) => entity is File && entity.path.endsWith('.txt'))
            .map((entity) => entity as File)
            .toList();

          files.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));

          // Rename current log file with timestamp if it exists
          final currentLogFile = File('$logDirPath/app_log.txt');
           if (currentLogFile.existsSync()) {
              try {
                 final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
                 currentLogFile.renameSync('$logDirPath/app_log_$timestamp.txt');
                 files.add(File('$logDirPath/app_log_$timestamp.txt')); // Add renamed file to list
              } catch (e) {
                 print("Error renaming current log file: $e");
              }
           }

          // Delete oldest files if count exceeds limit
          if (files.length >= filesToKeep) {
             int filesToDelete = files.length - filesToKeep + 1; // +1 because we added the newly renamed current one
             for (int i = 0; i < filesToDelete && i < files.length; i++) {
                 try {
                    files[i].deleteSync();
                    print("Deleted old log file: ${files[i].path}");
                 } catch (e) {
                    print("Error deleting old log file ${files[i].path}: $e");
                 }
             }
          }

      } catch (e) {
         print("Error during log rotation: $e");
      }
   }


  static void _log(Level level, String message, {dynamic error, StackTrace? stackTrace}) {
    if (!_isInitialized) {
      print("LOGGER NOT INITIALIZED: [$level] $message");
      return;
    }

    // Map our Level to the package's Level
    final pkgLevel = level.packageLevel;

    // Log using the logger package instance
    _logger.log(pkgLevel, message, error: error, stackTrace: stackTrace);

    // --- Remote Logging Integration ---
    // TODO: Configure and use remote logging services
    if (level.index >= Level.warning.index) { // Log warnings, errors, fatals
      _logToRemote(level, message, error: error, stackTrace: stackTrace);
    }
  }

  static void _logToRemote(Level level, String message, {dynamic error, StackTrace? stackTrace}) {
     // Example using Firebase Crashlytics
     // try {
     //    if (level.index >= Level.error.index && error != null) {
     //       FirebaseCrashlytics.instance.recordError(
     //          error,
     //          stackTrace,
     //          reason: message,
     //          fatal: level == Level.fatal,
     //       );
     //    } else {
     //       // Log warnings/infos as custom logs/breadcrumbs
     //       FirebaseCrashlytics.instance.log("[${level.name}] $message ${error != null ? '| Error: $error' : ''}");
     //    }
     // } catch (e) {
     //    _logger.e("Failed to report to Crashlytics", error: e);
     // }

     // Example using Sentry
     // try {
     //    Sentry.captureMessage(
     //       message,
     //       level: _mapLevelToSentryLevel(level),
     //    );
     //    if (error != null) {
     //       Sentry.captureException(
     //          error,
     //          stackTrace: stackTrace,
     //       );
     //    }
     // } catch (e) {
     //     _logger.e("Failed to report to Sentry", error: e);
     // }
  }

  // --- Public Logging Methods ---
  static void v(String message) => _log(Level.verbose, message);
  static void d(String message) => _log(Level.debug, message);
  static void i(String message) => _log(Level.info, message);
  static void w(String message, {dynamic error}) => _log(Level.warning, message, error: error);
  static void e(String message, {dynamic error, StackTrace? stackTrace}) => _log(Level.error, message, error: error, stackTrace: stackTrace);
  static void fatal(String message, {dynamic error, StackTrace? stackTrace}) => _log(Level.fatal, message, error: error, stackTrace: stackTrace);

  // --- Sentry Level Mapping (Example) ---
  // static SentryLevel _mapLevelToSentryLevel(Level level) {
  //   switch (level) {
  //     case Level.verbose: return SentryLevel.debug;
  //     case Level.debug: return SentryLevel.debug;
  //     case Level.info: return SentryLevel.info;
  //     case Level.warning: return SentryLevel.warning;
  //     case Level.error: return SentryLevel.error;
  //     case Level.fatal: return SentryLevel.fatal;
  //     default: return SentryLevel.info;
  //   }
  // }
}