import 'package:flutter/foundation.dart';
import '../data/models/weight_record.dart';

class WeightProvider with ChangeNotifier {
  List<WeightRecord> _records = [];
  double? _targetWeight;
  bool _isLoading = false;
  String? _error;

  WeightProvider() {
    // Initialize with mock data for development purposes
    _loadMockData();
  }

  // Getters
  List<WeightRecord> get records => _records;
  double? get targetWeight => _targetWeight;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get the most recent weight record
  WeightRecord? get currentWeight {
    if (_records.isEmpty) return null;

    // Sort by date descending and get the most recent
    final sortedRecords = List<WeightRecord>.from(_records)
      ..sort((a, b) => b.date.compareTo(a.date));

    return sortedRecords.first;
  }

  // Get the first (oldest) weight record
  WeightRecord? get initialWeight {
    if (_records.isEmpty) return null;

    // Sort by date ascending and get the oldest
    final sortedRecords = List<WeightRecord>.from(_records)
      ..sort((a, b) => a.date.compareTo(b.date));

    return sortedRecords.first;
  }

  // Calculate weight change since the beginning
  double get totalWeightChange {
    if (currentWeight == null || initialWeight == null) return 0;
    return currentWeight!.weight - initialWeight!.weight;
  }

  // Calculate weight progress percentage toward target
  double get progressPercentage {
    if (currentWeight == null || initialWeight == null || _targetWeight == null)
      return 0;

    final totalChange = initialWeight!.weight - _targetWeight!;
    if (totalChange == 0) return 100; // Already at target

    final currentChange = initialWeight!.weight - currentWeight!.weight;
    final percentage = (currentChange / totalChange) * 100;

    return percentage.clamp(0, 100); // Ensure result is between 0 and 100
  }

  // Add a new weight record
  Future<void> addWeightRecord(
    double weight, {
    DateTime? date,
    String? note,
  }) async {
    final newRecord = WeightRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      weight: weight,
      date: date ?? DateTime.now(),
      note: note,
    );

    _records.add(newRecord);
    _records.sort((a, b) => b.date.compareTo(a.date)); // Sort by most recent
    notifyListeners();

    // In a real app, save to database
  }

  // Update a weight record
  Future<void> updateWeightRecord(
    String id, {
    double? weight,
    DateTime? date,
    String? note,
  }) async {
    final index = _records.indexWhere((record) => record.id == id);
    if (index != -1) {
      _records[index] = _records[index].copyWith(
        weight: weight,
        date: date,
        note: note,
      );
      notifyListeners();

      // In a real app, update in database
    }
  }

  // Delete a weight record
  Future<void> deleteWeightRecord(String id) async {
    _records.removeWhere((record) => record.id == id);
    notifyListeners();

    // In a real app, delete from database
  }

  // Set target weight
  Future<void> setTargetWeight(double target) async {
    _targetWeight = target;
    notifyListeners();

    // In a real app, save to user preferences/settings
  }

  // Load mock data for development purposes
  void _loadMockData() {
    _targetWeight = 70.0; // Target weight in kg

    _records = [
      WeightRecord(
        id: '1',
        weight: 75.2,
        date: DateTime.now().subtract(const Duration(days: 30)),
      ),
      WeightRecord(
        id: '2',
        weight: 74.5,
        date: DateTime.now().subtract(const Duration(days: 23)),
      ),
      WeightRecord(
        id: '3',
        weight: 74.1,
        date: DateTime.now().subtract(const Duration(days: 16)),
      ),
      WeightRecord(
        id: '4',
        weight: 73.8,
        date: DateTime.now().subtract(const Duration(days: 9)),
      ),
      WeightRecord(
        id: '5',
        weight: 73.2,
        date: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];

    notifyListeners();
  }
}
