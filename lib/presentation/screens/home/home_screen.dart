import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:running_app/data/models/workout.dart';
import 'package:running_app/presentation/providers/settings_provider.dart';
import 'package:running_app/presentation/providers/user_provider.dart';
import 'package:running_app/presentation/providers/workout_provider.dart';
import 'package:running_app/presentation/screens/profile/profile_screen.dart';
import 'package:running_app/presentation/screens/settings/app_settings_screen.dart';
import 'package:running_app/presentation/screens/settings/gps_settings_screen.dart';
// Import WorkoutDetailsScreen if navigating from recent activity
import 'package:running_app/presentation/screens/workout_details/workout_details_screen.dart';
import 'package:running_app/presentation/widgets/common/loading_indicator.dart';
import 'package:running_app/presentation/widgets/home/recent_activity_card.dart';
import 'package:running_app/presentation/widgets/home/quick_start_card.dart';
import 'package:running_app/presentation/widgets/tip_of_the_day_widget.dart';
import 'package:running_app/presentation/widgets/common/section_title.dart';
import 'package:running_app/utils/logger.dart'; // Use custom logger

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  static const routeName = '/home'; // Static route name

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Index for BottomNavigationBar

  // --- Navigation Logic ---
  void _onItemTapped(int index) {
     if (index == _selectedIndex) return; // Avoid reloading same tab

     // Handle specific tab navigation or actions
     // Example: Map index 3 to Profile Screen (assuming 4 tabs: Home, History, Plans, Profile)
     if (index == 3) {
        Navigator.pushNamed(context, ProfileScreen.routeName);
         // Don't change _selectedIndex for profile pushed on top
     } else {
        setState(() {
           _selectedIndex = index;
        });
     }
  }

  // Define the tabs/pages corresponding to the BottomNavigationBar indices
   static final List<Widget> _widgetOptions = <Widget>[
     const _HomeTabContent(), // Content for the Home tab (index 0)
     // TODO: Implement History Screen
     const Center(child: Text('History Screen (Placeholder)')), // Index 1
     // TODO: Implement Training Plans Screen
     const Center(child: Text('Training Plans Screen (Placeholder)')), // Index 2
     // Placeholder for Profile tab navigation logic (handled by _onItemTapped)
     // We use IndexedStack, so provide a placeholder here anyway.
      Container(), // Index 3 (Profile - handled by pushing route)
   ];

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    // Use local name if set, otherwise a default. Avoid showing Device ID.
    final displayName = userProvider.userProfile?.name?.isNotEmpty == true
        ? userProvider.userProfile!.name!
        : 'Runner';

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $displayName!'),
        actions: [
          // Settings Action
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.pushNamed(context, AppSettingsScreen.routeName);
            },
          ),
           // GPS Settings shortcut (Optional)
           // IconButton(
           //   icon: const Icon(Icons.gps_fixed),
           //   tooltip: 'GPS Settings',
           //   onPressed: () {
           //     Navigator.pushNamed(context, GpsSettingsScreen.routeName);
           //   },
           // ),
        ],
      ),
      // Use IndexedStack to preserve state of inactive tabs
      body: IndexedStack(
         index: _selectedIndex,
         children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_edu), // Changed icon
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined), // Changed icon
            label: 'Plans',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        // Use theme colors
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).unselectedWidgetColor,
        backgroundColor: Theme.of(context).colorScheme.surface, // Or surfaceContainerLowest etc.
        type: BottomNavigationBarType.fixed, // Ensures all labels are visible
        onTap: _onItemTapped,
      ),
    );
  }
}

// --- Content Widget for the Home Tab ---
class _HomeTabContent extends StatelessWidget {
  const _HomeTabContent();

  @override
  Widget build(BuildContext context) {
    final workoutProvider = context.watch<WorkoutProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final recentWorkouts = workoutProvider.workouts.take(3).toList(); // Get latest 3
    final bool useImperial = settingsProvider.useImperialUnits;

    return RefreshIndicator(
      onRefresh: () async {
         Log.d("Refreshing workout data...");
         // Ensure UserProvider is read if needed by fetchWorkouts internally
         // Or assume workoutProvider fetches for the correct device automatically
          await workoutProvider.fetchWorkouts(forceRefresh: true);
      },
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Quick Start Section ---
          const SectionTitle(title: 'Start New Workout'),
          const SizedBox(height: 8),
          const QuickStartCard(), // Dedicated widget for starting workouts
          const SizedBox(height: 24),

          // --- Recent Activity Section ---
          const SectionTitle(title: 'Recent Activity'),
          const SizedBox(height: 8),
          if (workoutProvider.isLoading && workoutProvider.workouts.isEmpty)
             const Center(child: Padding(padding: EdgeInsets.all(16.0), child: LoadingIndicator()))
          else if (recentWorkouts.isEmpty)
            const Center(child: Padding(
               padding: EdgeInsets.symmetric(vertical: 32.0),
               child: Text('No recent activities.\nGo for a run!', textAlign: TextAlign.center),
             ))
          else
            Column(
              // Build list of RecentActivityCard widgets
              children: recentWorkouts.map((workout) => Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: RecentActivityCard(
                  workout: workout,
                  useImperial: useImperial,
                  // Navigate to details screen on tap
                  onTap: () {
                     Navigator.push(
                       context,
                       MaterialPageRoute(
                         builder: (context) => WorkoutDetailsScreen(workout: workout),
                         settings: const RouteSettings(name: WorkoutDetailsScreen.routeName) // Optional: Set route name
                       ),
                     );
                  },
                ),
              )).toList(),
            ),
          const SizedBox(height: 24),

          // --- Tip of the Day Section ---
          const SectionTitle(title: 'Tip of the Day'),
          const SizedBox(height: 8),
          const TipOfTheDayWidget(),
          const SizedBox(height: 24),

          // TODO: Add other home screen sections (Weekly Goals, Challenges, etc.)
          // Example Placeholder:
           // const SectionTitle(title: 'Weekly Goals'),
           // const SizedBox(height: 8),
           // Card(
           //   child: ListTile(
           //      leading: Icon(Icons.track_changes),
           //      title: Text('Run 15 km / 10 mi'),
           //      subtitle: LinearProgressIndicator(value: 0.33), // Example progress
           //      trailing: Text('5 / 15 km'),
           //   ),
           // ),
           // const SizedBox(height: 24),
        ],
      ),
    );
  }
}