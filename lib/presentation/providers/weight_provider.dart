import 'package:flutter/foundation.dart';
import 'package:running_app/data/models/weight_record.dart';
import 'package:running_app/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
// TODO: Import WeightRepository or DatabaseHelper

class WeightProvider with ChangeNotifier {
    // TODO: Inject dependencies
    // final WeightRepository _repository;
    // final DeviceIdService _deviceIdService;

    List<WeightRecord> _records = [];
    bool _isLoading = false;
    String? _errorMessage;
    double? _goalWeightKg;

    List<WeightRecord> get records => _records; // Sorted descending by date
    bool get isLoading => _isLoading;
    String? get errorMessage => _errorMessage;
    double? get goalWeightKg => _goalWeightKg;

    WeightProvider() {
       Log.d("WeightProvider Initialized (placeholder data)");
       // TODO: Remove placeholder load when repository integrated
       loadRecords();
       _loadGoalWeight();
    }

    void _setLoading(bool loading) { if (_isLoading == loading) return; _isLoading = loading; notifyListeners(); }
    void _setError(String? msg) { _errorMessage = msg; }

    Future<void> loadRecords({bool forceRefresh = false}) async {
       // TODO: Implement actual data loading from DB, filter by deviceId
       if (_isLoading && !forceRefresh) return;
       _setLoading(true); _setError(null);
       try {
          Log.d("Loading weight records...");
           await Future.delayed(const Duration(milliseconds: 100)); // Simulate load
           // --- Placeholder Data ---
           _records = [
              WeightRecord(id: '3', date: DateTime.now(), weightKg: 74.8),
              WeightRecord(id: '2', date: DateTime.now().subtract(const Duration(days: 5)), weightKg: 75.1),
              WeightRecord(id: '1', date: DateTime.now().subtract(const Duration(days: 10)), weightKg: 75.5),
               WeightRecord(id: '0', date: DateTime.now().subtract(const Duration(days: 20)), weightKg: 76.0),
           ];
           // --- End Placeholder ---
            _records.sort((a, b) => b.date.compareTo(a.date));
          Log.i("Loaded ${_records.length} weight records (placeholder).");
       } catch (e, s) { Log.e("Failed to load weight data", error: e, stackTrace: s); _setError("Failed to load weight data."); _records = [];
       } finally { _setLoading(false); }
    }

     Future<void> addRecord(WeightRecord record) async {
         Log.i("Adding weight record: ${record.weightKg} kg on ${record.date}");
         _setLoading(true);
         try {
           // TODO: Save to repository/DB
           final savedRecord = record.copyWith(id: DateTime.now().millisecondsSinceEpoch.toString()); // Placeholder ID
           _records.removeWhere((r) => r.date.year == savedRecord.date.year && r.date.month == savedRecord.date.month && r.date.day == savedRecord.date.day);
           _records.add(savedRecord);
           _records.sort((a, b) => b.date.compareTo(a.date));
           _setError(null); notifyListeners();
         } catch (e, s) { Log.e("Failed to add weight record", error: e, stackTrace: s); _setError("Failed to save entry."); notifyListeners();
         } finally { _setLoading(false); }
     }

      Future<void> deleteRecord(WeightRecord record) async {
         Log.i("Deleting weight record from ${record.date}");
         final originalRecords = List<WeightRecord>.from(_records);
         _records.removeWhere((r) => r.id == record.id || r.date == record.date);
         notifyListeners();
         try {
            // TODO: Delete from repository/DB
             await Future.delayed(const Duration(milliseconds: 100));
         } catch (e, s) { Log.e("Failed to delete weight record", error: e, stackTrace: s); _setError("Could not delete entry."); _records = originalRecords; notifyListeners(); }
      }

      // --- Goal Weight ---
       Future<void> _loadGoalWeight() async {
           try { final prefs = await SharedPreferences.getInstance(); _goalWeightKg = prefs.getDouble('weight_goal_kg');
              Log.d("Loaded goal weight: $_goalWeightKg kg");
           } catch (e) { Log.e("Failed to load goal weight: $e"); }
           notifyListeners();
       }
       Future<void> setGoalWeight(double? goalKg) async {
          _goalWeightKg = goalKg; notifyListeners(); Log.i("Setting goal weight to: $goalKg kg");
          try { final prefs = await SharedPreferences.getInstance();
             if (goalKg == null) await prefs.remove('weight_goal_kg'); else await prefs.setDouble('weight_goal_kg', goalKg);
          } catch (e) { Log.e("Failed to save goal weight: $e"); }
       }
}