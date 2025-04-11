import 'package:flutter/foundation.dart';
import 'package:running_app/data/models/user_profile.dart';
import 'package:running_app/data/sources/database_helper.dart';
import 'package:running_app/services/device_id_service.dart';
import 'package:running_app/utils/logger.dart';

class UserProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper;
  final DeviceIdService _deviceIdService;

  UserProfile? _userProfile;
  bool _isLoading = true; // Start as loading
  String? _deviceId;
  bool _profileLoaded = false; // Track if initial load completed

  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get deviceId => _deviceId;
  bool get isProfileLoaded => _profileLoaded; // Expose loaded status

  UserProvider({required DatabaseHelper dbHelper, required DeviceIdService deviceIdService})
      : _dbHelper = dbHelper,
        _deviceIdService = deviceIdService {
     Log.d("UserProvider Initialized");
     // loadUserProfile is now called from main.dart after DeviceIdService is ready
  }

  Future<void> _setLoading(bool loading) async {
    // Avoid unnecessary notifications if state hasn't changed
    if (_isLoading == loading) return;
    _isLoading = loading;
    // Use addPostFrameCallback to avoid issues during build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) {
        notifyListeners();
      }
    });
  }

  Future<void> loadUserProfile() async {
     // Prevent multiple concurrent loads
     if (_isLoading && _profileLoaded) return; // Already loading and finished initial load previously?

    await _setLoading(true);
    _profileLoaded = false; // Mark as not loaded during the process

    try {
       _deviceId = await _deviceIdService.getDeviceId(); // Get device ID
       Log.i("UserProvider: Loading profile for Device ID: $_deviceId");
       if (_deviceId != null && _deviceId!.isNotEmpty) {
           _userProfile = await _dbHelper.getUserProfile(_deviceId!); // Tries loading exact, then first available
           if (_userProfile == null) {
             Log.w("UserProvider: No profile found for device ID $_deviceId. Creating default profile.");
             _userProfile = UserProfile(id: _deviceId!, name: "Runner"); // Create profile with device ID and default name
             await _dbHelper.insertOrUpdateUserProfile(_userProfile!);
              Log.i("UserProvider: Default profile created and saved.");
           } else if (_userProfile!.id != _deviceId) {
              // This case handles when getUserProfile loaded the *first available* profile
              // because the exact device ID wasn't found (e.g., after ID change).
              // We already updated the DB record with the new ID inside getUserProfile.
              Log.i("UserProvider: Loaded existing profile and associated it with current Device ID: $_deviceId");
           }
           else {
              Log.i("UserProvider: Profile loaded successfully for Device ID: $_deviceId.");
           }
           _profileLoaded = true; // Mark loading as complete
       } else {
          Log.e("UserProvider: Could not get Device ID to load profile.");
           _userProfile = null;
       }
    } catch (e, s) {
       Log.e("UserProvider: Error loading user profile", error: e, stackTrace: s);
       _userProfile = null;
    } finally {
       await _setLoading(false);
       // Ensure notification happens after loading finishes
        WidgetsBinding.instance.addPostFrameCallback((_) {
           if (hasListeners) {
              notifyListeners();
           }
        });
    }
  }

  Future<void> updateUserProfile(UserProfile updatedProfile) async {
    if (_deviceId == null || updatedProfile.id != _deviceId) {
       Log.e("UserProvider: Cannot update profile - Device ID mismatch or missing. Current: $_deviceId, Update: ${updatedProfile.id}");
       throw Exception("Profile update error: Device ID mismatch.");
    }
    // Don't set loading indicator for updates? Or maybe briefly?
    // await _setLoading(true);
    try {
      await _dbHelper.insertOrUpdateUserProfile(updatedProfile);
      _userProfile = updatedProfile; // Update local cache
      Log.i("UserProvider: Profile updated successfully.");
      notifyListeners(); // Notify immediately after successful update
    } catch (e, s) {
      Log.e("UserProvider: Error updating user profile", error: e, stackTrace: s);
      // Optionally reload profile from DB on error to ensure consistency
      await loadUserProfile(); // Reload to revert potentially failed UI update
      rethrow; // Rethrow the error so UI can handle it
    } finally {
       // await _setLoading(false);
    }
  }

   // --- Specific field updates ---
   Future<void> updateUserWeight(double newWeightKg) async {
      if (_userProfile != null) {
         await updateUserProfile(_userProfile!.copyWith(weight: newWeightKg));
      } else { Log.w("UserProvider: Cannot update weight, profile not loaded."); }
   }
   Future<void> updateUserHeight(double newHeightCm) async {
       if (_userProfile != null) {
          await updateUserProfile(_userProfile!.copyWith(height: newHeightCm));
       } else { Log.w("UserProvider: Cannot update height, profile not loaded."); }
   }
   Future<void> updateUserName(String newName) async {
      if (_userProfile != null) {
         await updateUserProfile(_userProfile!.copyWith(name: newName.trim()));
      } else { Log.w("UserProvider: Cannot update name, profile not loaded."); }
   }
   Future<void> updateUserBirthDate(DateTime? newBirthDate) async {
       if (_userProfile != null) {
          await updateUserProfile(_userProfile!.copyWith(birthDate: newBirthDate));
       } else { Log.w("UserProvider: Cannot update birth date, profile not loaded."); }
   }
    Future<void> updateUseImperialUnits(bool useImperial) async {
        if (_userProfile != null) {
           await updateUserProfile(_userProfile!.copyWith(useImperialUnits: useImperial));
        } else { Log.w("UserProvider: Cannot update units, profile not loaded."); }
    }
}