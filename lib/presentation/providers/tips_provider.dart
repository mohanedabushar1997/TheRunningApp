import 'package:flutter/foundation.dart';
import 'package:running_app/data/models/running_tip.dart';
import 'package:running_app/data/repositories/tips_repository.dart';
import 'package:running_app/utils/logger.dart';

class TipsProvider with ChangeNotifier {
  final TipsRepository _tipsRepository;

  // State
  List<RunningTip> _allTips = []; // Cache for all loaded tips
  List<RunningTip> _filteredTips = [];
  RunningTip? _tipOfTheDay;
  List<RunningTip> _favoriteTips = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<RunningTip> get filteredTips => List.unmodifiable(_filteredTips);
  RunningTip? get tipOfTheDay => _tipOfTheDay;
  List<RunningTip> get favoriteTips => List.unmodifiable(_favoriteTips); // Getter for favorites
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  TipsProvider({required TipsRepository tipsRepository}) : _tipsRepository = tipsRepository {
     // Initial fetch (optional, can be done on demand)
     // fetchTips();
     // fetchTipOfTheDay();
  }

  void _setLoading(bool loading) {
    if (_isLoading == loading) return;
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  // Fetch tips with filtering and update state
  Future<void> fetchTips({
      RunningCategory? category = RunningCategory.all,
      TipDifficulty? difficulty = TipDifficulty.any,
      bool forceRefresh = false
   }) async {
    // TODO: Implement caching to avoid refetching if filters/data haven't changed
    // if (!forceRefresh && _allTips.isNotEmpty && sameFilters) return;

    _setLoading(true);
    _setError(null); // Clear previous errors
    try {
       // Get filtered tips directly from repository (which handles favorite status internally now)
      _filteredTips = await _tipsRepository.getTips(category: category, difficulty: difficulty);
      Log.i("Fetched ${_filteredTips.length} tips. Category: ${category?.name}, Difficulty: ${difficulty?.name}");

      // Optionally update _allTips cache if filters are 'all'/'any'
       if (category == RunningCategory.all && difficulty == TipDifficulty.any) {
          _allTips = List.from(_filteredTips);
       }

    } catch (e, s) {
      Log.e("Error fetching tips", error: e, stackTrace: s);
      _setError("Failed to load tips. Please try again.");
      _filteredTips = []; // Clear list on error
    } finally {
      _setLoading(false);
    }
  }

  // Fetch a random tip for "Tip of the Day"
  Future<void> fetchTipOfTheDay({bool forceRefresh = false}) async {
     if (!forceRefresh && _tipOfTheDay != null) return; // Don't refetch if already have one

     _setLoading(true); // Consider separate loading state for tip of the day?
     _setError(null);
     try {
       _tipOfTheDay = await _tipsRepository.getRandomTip();
       Log.i("Fetched Tip of the Day: ${_tipOfTheDay?.id}");
     } catch (e, s) {
        Log.e("Error fetching tip of the day", error: e, stackTrace: s);
        _setError("Failed to load tip of the day.");
        _tipOfTheDay = null;
     } finally {
        _setLoading(false); // Use main loading state for now
     }
  }

   // Fetch only favorite tips
   Future<void> fetchFavoriteTips() async {
      _setLoading(true);
      _setError(null);
      try {
         _favoriteTips = await _tipsRepository.getFavoriteTips();
         Log.i("Fetched ${_favoriteTips.length} favorite tips.");
      } catch (e, s) {
         Log.e("Error fetching favorite tips", error: e, stackTrace: s);
         _setError("Failed to load favorite tips.");
         _favoriteTips = [];
      } finally {
         _setLoading(false);
      }
   }


   // Toggle favorite status
   Future<void> toggleFavorite(String tipId) async {
       await _tipsRepository.toggleFavorite(tipId);
       // Update the specific tip in the current lists if present
       _updateTipFavoriteStatus(tipId, _tipsRepository.isFavorite(tipId));
       // Refetch favorites list
       await fetchFavoriteTips(); // Update the dedicated favorites list
       notifyListeners(); // Notify UI about the change
   }

   // Helper to update favorite status in cached lists
   void _updateTipFavoriteStatus(String tipId, bool isFavorite) {
      int indexAll = _allTips.indexWhere((t) => t.id == tipId);
      if (indexAll != -1) {
         _allTips[indexAll] = _allTips[indexAll].copyWith(isFavorite: isFavorite);
      }
      int indexFiltered = _filteredTips.indexWhere((t) => t.id == tipId);
       if (indexFiltered != -1) {
          _filteredTips[indexFiltered] = _filteredTips[indexFiltered].copyWith(isFavorite: isFavorite);
       }
       if (_tipOfTheDay?.id == tipId) {
          _tipOfTheDay = _tipOfTheDay?.copyWith(isFavorite: isFavorite);
       }
   }

   // Check if a tip is a favorite (delegates to repository's cached state)
   bool isFavorite(String tipId) {
      return _tipsRepository.isFavorite(tipId);
   }

   // TODO: Implement findRelatedTips
   Future<List<RunningTip>> findRelatedTips(String currentTipId, RunningCategory category, {int count = 3}) async {
      _setLoading(true); // May need separate loading indicator for related tips
       try {
          return await _tipsRepository.findRelatedTips(currentTipId, category, count: count);
       } catch (e, s) {
          Log.e("Error finding related tips", error: e, stackTrace: s);
           return [];
       } finally {
           _setLoading(false);
       }
   }
}
This completes the second batch. Let me know when you're ready for Batch 3.





now give me batches of 5 instead of 10



Show thinking
Okay, switching to batches of 5 files. Here is the next batch with compilation fixes, device ID logic, and implemented TODOs (including more detailed placeholders and logic where feasible).

Batch 3 of 10 Files (First 5)