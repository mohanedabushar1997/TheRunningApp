import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:running_app/presentation/providers/settings_provider.dart';
import 'package:running_app/presentation/screens/home/home_screen.dart';
import 'package:running_app/presentation/widgets/onboarding/onboarding_page.dart';
import 'package:running_app/utils/logger.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  static const routeName = '/onboarding';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Define onboarding pages content
  // TODO: Replace placeholder image paths with actual assets
  final List<Map<String, String>> _pages = [
    {
      'title': 'Welcome to FitStride!',
      'description': 'Your personal running companion. Track runs, monitor progress, and achieve fitness goals.',
      'image': 'assets/images/onboarding_welcome.png', // Placeholder
    },
    {
      'title': 'Precise Tracking',
      'description': 'Record distance, pace, duration, calories, and map your route accurately with GPS.',
      'image': 'assets/images/onboarding_track.png', // Placeholder
    },
     {
      'title': 'Stay Motivated',
      'description': 'Set personal goals, follow training plans (coming soon!), and earn achievements.',
       'image': 'assets/images/onboarding_goals.png', // Placeholder
    },
    {
       'title': 'Analyze & Improve',
       'description': 'Review detailed summaries, charts, and personal bests to see how you\'re improving.',
       'image': 'assets/images/onboarding_analyze.png', // Placeholder
    },
     {
       'title': 'Permissions Required',
       'description': 'Please grant Location (Always or While Using) and Notification permissions for the best experience.',
       'image': 'assets/images/onboarding_permissions.png', // Placeholder
    },
  ];

  void _onPageChanged(int page) {
    setState(() { _currentPage = page; });
  }

  void _completeOnboarding() {
     Log.i("Onboarding completed.");
     context.read<SettingsProvider>().setOnboardingComplete(true);
     // Replace current route with home screen
     Navigator.pushReplacementNamed(context, HomeScreen.routeName);
  }

  void _nextPage() {
     if (_currentPage < _pages.length - 1) {
        _pageController.nextPage( duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic, );
     } else {
        _completeOnboarding();
     }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // backgroundColor: colorScheme.surface, // Match theme background
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 3, // Give more space to page content
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  return OnboardingPage(
                    title: _pages[index]['title']!,
                    description: _pages[index]['description']!,
                    imagePath: _pages[index]['image']!,
                  );
                },
              ),
            ),
            // --- Bottom Controls ---
            Container(
              padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0), // Adjust padding
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // --- Skip Button ---
                  Opacity( // Fade out skip button on last page
                     opacity: _currentPage == _pages.length - 1 ? 0.0 : 1.0,
                     child: TextButton(
                       onPressed: _currentPage == _pages.length - 1 ? null : _completeOnboarding,
                       child: const Text('SKIP'),
                     ),
                  ),

                  // --- Page Indicator ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (index) => _buildIndicator(index == _currentPage, colorScheme)),
                  ),

                  // --- Next / Done Button ---
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), // Rounded button
                    ),
                    child: Row( // Add icon for visual cue
                       mainAxisSize: MainAxisSize.min,
                       children: [
                          Text(_currentPage == _pages.length - 1 ? 'GET STARTED' : 'NEXT', style: const TextStyle(fontWeight: FontWeight.bold)),
                           if (_currentPage != _pages.length - 1)
                              const Icon(Icons.arrow_forward_ios, size: 16)
                           else
                              const Icon(Icons.check, size: 16),
                       ],
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

  // Helper for page indicator dot
  Widget _buildIndicator(bool isActive, ColorScheme colorScheme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: isActive ? 24.0 : 8.0, // Active indicator is wider
      decoration: BoxDecoration(
        color: isActive ? colorScheme.primary : colorScheme.outline.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12), // Rounded indicator
      ),
    );
  }
}