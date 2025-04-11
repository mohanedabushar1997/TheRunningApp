import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:running_app/presentation/providers/settings_provider.dart';
import 'package:running_app/presentation/screens/settings/data_management_screen.dart';
import 'package:running_app/presentation/screens/settings/gps_settings_screen.dart';
import 'package:running_app/presentation/screens/settings/notification_settings_screen.dart';
// TODO: Import other setting screens when created
// import 'package:running_app/presentation/screens/workout/voice_coach_settings_screen.dart';
import 'package:running_app/utils/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io'; // For Platform check

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});
  static const routeName = '/app-settings';

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
   String _appVersion = 'Loading...';

   @override
   void initState() {
     super.initState();
     _loadAppVersion();
   }

   Future<void> _loadAppVersion() async {
      try {
         PackageInfo packageInfo = await PackageInfo.fromPlatform();
         if (mounted) {
            setState(() {
              _appVersion = 'Version ${packageInfo.version} (${packageInfo.buildNumber})';
            });
         }
      } catch (e, s) {
         Log.e("Error loading app version", error: e, stackTrace: s);
          if (mounted) {
             setState(() { _appVersion = 'Unknown Version'; });
          }
      }
   }

   // --- Link Launchers ---
    Future<void> _launchURL(String urlString, BuildContext scaffoldContext) async {
      final Uri url = Uri.parse(urlString);
      try {
         if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
             throw 'Could not launch $urlString';
         }
      } catch (e, s) {
          Log.e('Error launching URL $urlString', error: e, stackTrace: s);
           if (mounted) {
              ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                 SnackBar(content: Text('Could not open link: $urlString'), backgroundColor: Colors.red),
              );
           }
      }
    }

   // --- Rate App ---
   void _rateApp() {
      // TODO: Replace with actual App Store ID and Play Store package name
      const String appId = 'YOUR_APP_STORE_ID'; // e.g., 123456789
      const String packageName = 'com.fitstride.running_app'; // Your package name

      final String urlString = Platform.isIOS
         ? 'https://apps.apple.com/app/id$appId?action=write-review' // Link directly to review page if possible
         : 'market://details?id=$packageName'; // Opens Play Store directly

      Log.i("Attempting to open store for rating: $urlString");
      _launchURL(urlString, context); // Pass context for snackbar on error
   }

   // --- Data Export ---
   // Placeholder - actual logic in DataManagementScreen or triggered from there
   void _navigateToDataManagement() {
      Navigator.pushNamed(context, DataManagementScreen.routeName);
   }


  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: <Widget>[
          _buildSectionHeader('General'),
          SwitchListTile(
             secondary: const Icon(Icons.swap_horiz_outlined),
             title: const Text('Units'),
             subtitle: Text(settingsProvider.useImperialUnits ? 'Imperial (miles, lbs, ft)' : 'Metric (km, kg, cm)'),
             value: settingsProvider.useImperialUnits,
             onChanged: (value) => settingsProvider.setUseImperialUnits(value),
          ),
          ListTile(
             leading: const Icon(Icons.palette_outlined),
             title: const Text('Theme'),
              // TODO: Implement Theme selection (System, Light, Dark)
             subtitle: Text('System Default'), // Placeholder
             trailing: const Icon(Icons.chevron_right),
             onTap: () { /* TODO: Show theme selection dialog */
                Log.w("Theme selection dialog not implemented.");
             },
          ),
          const Divider(),

           _buildSectionHeader('Workout'),
           ListTile(
             leading: const Icon(Icons.gps_fixed),
             title: const Text('GPS Settings'),
             trailing: const Icon(Icons.chevron_right),
             onTap: () => Navigator.pushNamed(context, GpsSettingsScreen.routeName),
           ),
           ListTile(
             leading: const Icon(Icons.volume_up_outlined),
             title: const Text('Voice Coach'),
             trailing: const Icon(Icons.chevron_right),
             onTap: () {
                Log.w("Navigate to Voice Coach Settings: Screen not implemented.");
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voice Coach settings coming soon!')));
                // Navigator.pushNamed(context, VoiceCoachSettingsScreen.routeName);
             },
           ),
           // TODO: Add Auto-Pause setting?
           // SwitchListTile(...)

           const Divider(),

           // --- Notifications ---
           ListTile(
             leading: const Icon(Icons.notifications_active_outlined),
             title: const Text('Notifications'),
             trailing: const Icon(Icons.chevron_right),
             onTap: () => Navigator.pushNamed(context, NotificationSettingsScreen.routeName),
           ),
           const Divider(),

           // --- Data ---
            _buildSectionHeader('Data & Privacy'),
           ListTile(
             leading: const Icon(Icons.storage_outlined),
             title: const Text('Data Management'),
             subtitle: const Text('Backup, Restore, Export'),
             trailing: const Icon(Icons.chevron_right),
             onTap: _navigateToDataManagement,
           ),
           ListTile(
             leading: const Icon(Icons.description_outlined),
             title: const Text('Privacy Policy'),
             trailing: const Icon(Icons.launch, size: 18),
             onTap: () => _launchURL('https://your-privacy-policy-url.com', context), // TODO: Replace URL
           ),
           ListTile(
             leading: const Icon(Icons.gavel_outlined),
             title: const Text('Terms of Service'),
             trailing: const Icon(Icons.launch, size: 18),
             onTap: () => _launchURL('https://your-terms-of-service-url.com', context), // TODO: Replace URL
           ),
           const Divider(),

           // --- About ---
            _buildSectionHeader('About'),
           ListTile(
             leading: const Icon(Icons.rate_review_outlined),
             title: const Text('Rate FitStride'),
             onTap: _rateApp,
           ),
           ListTile(
             leading: const Icon(Icons.info_outline),
             title: const Text('Version'),
             subtitle: Text(_appVersion),
           ),
            // TODO: Add 'Send Feedback' option (e.g., mailto link or feedback form URL)
            ListTile(
              leading: const Icon(Icons.feedback_outlined),
              title: const Text('Send Feedback'),
              onTap: () => _launchURL('mailto:your-feedback-email@example.com?subject=FitStride App Feedback', context), // TODO: Replace email
            ),
             // TODO: Add 'View Licenses' (Flutter's LicensePage)
             ListTile(
               leading: const Icon(Icons.policy_outlined),
               title: const Text('Open Source Licenses'),
               onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LicensePage())),
             ),
        ],
      ),
    );
  }

  // Helper for section headers
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 20.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}