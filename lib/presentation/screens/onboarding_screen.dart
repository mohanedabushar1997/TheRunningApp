import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/settings_provider.dart';
import 'home_screen.dart';
import '../../data/models/user_profile.dart';
import '../../device/storage/shared_prefs_helper.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // User info form fields
  final _nameController = TextEditingController();
  String _selectedGender = 'Not specified';
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _targetWeightController = TextEditingController();
  DateTime _birthDate = DateTime.now().subtract(const Duration(days: 365 * 30));

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator and skip button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page indicator
                  Row(
                    children: List.generate(
                      4, // Total number of pages
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              index == _currentPage
                                  ? theme.colorScheme.primary
                                  : theme.disabledColor.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),

                  // Skip button
                  if (_currentPage < 3)
                    TextButton(
                      onPressed: () => _finishOnboarding(),
                      child: const Text('Skip'),
                    ),
                ],
              ),
            ),

            // Page view
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  // Welcome page
                  _buildWelcomePage(theme),

                  // Permissions page
                  _buildPermissionsPage(theme),

                  // Personal info page
                  _buildPersonalInfoPage(theme),

                  // Final page
                  _buildFinalPage(theme),
                ],
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  if (_currentPage > 0)
                    ElevatedButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.surface,
                        foregroundColor: theme.colorScheme.primary,
                      ),
                      child: const Text('Back'),
                    )
                  else
                    const SizedBox(width: 80),

                  // Next/Finish button
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < 3) {
                        if (_currentPage == 2 && !_validatePersonalInfoForm()) {
                          return;
                        }
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _finishOnboarding();
                      }
                    },
                    child: Text(_currentPage < 3 ? 'Next' : 'Get Started'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Welcome page
  Widget _buildWelcomePage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // App logo/icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_run,
              color: Colors.white,
              size: 80,
            ),
          ),
          const SizedBox(height: 40),

          // Welcome text
          Text(
            'Welcome to\nThe Running App',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Your personal running coach that helps you track your progress and achieve your fitness goals.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 40),

          // Features list
          ...[
            'Track your runs with GPS',
            'Follow training plans',
            'Monitor your weight progress',
            'Get voice coaching',
          ].map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Text(feature, style: theme.textTheme.bodyLarge),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Permissions page
  Widget _buildPermissionsPage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Permissions illustration
          Icon(Icons.location_on, size: 100, color: theme.colorScheme.primary),
          const SizedBox(height: 40),

          // Title
          Text(
            'Location Access',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Explanation
          Text(
            'The Running App needs access to your location to track your runs and map your routes.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 30),

          // Permission button
          ElevatedButton(
            onPressed: () {
              // Request location permission
              Provider.of<SettingsProvider>(
                context,
                listen: false,
              ).setHighAccuracyGps(true);
            },
            child: const Text('Grant Location Access'),
          ),
          const SizedBox(height: 40),

          // Additional permissions
          Text('We also recommend:', style: theme.textTheme.titleMedium),
          const SizedBox(height: 20),

          // Additional permissions list
          ...[
            'Storage access for music playback',
            'Physical activity for better tracking',
            'Notifications for workout reminders',
          ].map(
            (permission) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: theme.colorScheme.secondary),
                  const SizedBox(width: 10),
                  Expanded(child: Text(permission)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Personal info page
  Widget _buildPersonalInfoPage(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Personal Information',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Help us personalize your experience',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 30),

            // Name field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nickname (optional)',
                hintText: 'How should we call you?',
              ),
            ),
            const SizedBox(height: 20),

            // Gender selection
            Text('Gender (optional)', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildGenderButton(theme, 'Male', Icons.male),
                const SizedBox(width: 10),
                _buildGenderButton(theme, 'Female', Icons.female),
                const SizedBox(width: 10),
                _buildGenderButton(theme, 'Not specified', Icons.person),
              ],
            ),
            const SizedBox(height: 20),

            // Date of birth
            Text(
              'Date of Birth (optional)',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _birthDate,
                  firstDate: DateTime(1930),
                  lastDate: DateTime.now(),
                );

                if (date != null) {
                  setState(() {
                    _birthDate = date;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_birthDate.day}/${_birthDate.month}/${_birthDate.year}',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Height field
            TextFormField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Height (cm)',
                hintText: 'Enter your height',
                suffixText:
                    Provider.of<SettingsProvider>(context).units == 'metric'
                        ? 'cm'
                        : 'in',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your height';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Current weight field
            TextFormField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Current Weight',
                hintText: 'Enter your current weight',
                suffixText: Provider.of<SettingsProvider>(context).weightUnit,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your current weight';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Target weight field
            TextFormField(
              controller: _targetWeightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Target Weight (optional)',
                hintText: 'Enter your target weight',
                suffixText: Provider.of<SettingsProvider>(context).weightUnit,
              ),
            ),
            const SizedBox(height: 30),

            // Privacy note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: theme.colorScheme.secondary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Your information is stored locally on your device and is not shared with anyone.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Gender selection button
  Widget _buildGenderButton(ThemeData theme, String gender, IconData icon) {
    final isSelected = _selectedGender == gender;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedGender = gender;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
              ),
              const SizedBox(height: 8),
              Text(
                gender,
                style: TextStyle(
                  color:
                      isSelected ? Colors.white : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Final onboarding page
  Widget _buildFinalPage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Success illustration
          Icon(Icons.check_circle, size: 100, color: theme.colorScheme.primary),
          const SizedBox(height: 40),

          // Title
          Text(
            'You\'re all set!',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Message
          Text(
            'Your running journey starts now. Let\'s achieve your fitness goals together!',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 40),

          // Features list
          ...[
            'Track your first run',
            'Explore training plans',
            'Set up your profile',
            'Customize your settings',
          ].map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Icon(Icons.arrow_forward, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Text(feature, style: theme.textTheme.bodyLarge),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Validate personal info form
  bool _validatePersonalInfoForm() {
    return _formKey.currentState?.validate() ?? false;
  }

  // Finish onboarding and navigate to home screen
  void _finishOnboarding() {
    // Save user profile if form is valid
    if (_validatePersonalInfoForm()) {
      _saveUserProfile();
    } else if (_currentPage == 3) {
      // If on the final page, validate again and return if invalid
      if (!_validatePersonalInfoForm()) {
        _pageController.animateToPage(
          2,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        return;
      }
    }

    // Mark onboarding as complete
    SharedPrefsHelper.resetFirstLaunch();

    // Navigate to home screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  // Save user profile
  void _saveUserProfile() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );

    // Get values from form
    final name =
        _nameController.text.isNotEmpty ? _nameController.text : 'Runner';
    final height = double.tryParse(_heightController.text) ?? 175.0;
    final weight = double.tryParse(_weightController.text) ?? 70.0;
    final targetWeight =
        double.tryParse(_targetWeightController.text) ?? weight;

    // Convert to metric if needed
    final double heightInCm =
        settingsProvider.units == 'metric'
            ? height
            : height * 2.54; // Convert inches to cm

    final double weightInKg =
        settingsProvider.units == 'metric'
            ? weight
            : weight / 2.20462; // Convert lbs to kg

    final double targetWeightInKg =
        settingsProvider.units == 'metric'
            ? targetWeight
            : targetWeight / 2.20462; // Convert lbs to kg

    // Create user profile
    final userProfile = UserProfile(
      deviceId: 'default_device', // Generate a unique device ID in a real app
      name: name,
      gender: _selectedGender,
      birthDate: _birthDate,
      height: heightInCm,
      weight: weightInKg,
      targetWeight: targetWeightInKg,
    );

    // Save profile
    userProvider.saveUserProfile(userProfile);
  }
}
