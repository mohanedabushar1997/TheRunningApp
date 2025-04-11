import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:running_app/presentation/providers/user_provider.dart';

class WelcomeWidget extends StatelessWidget {
  const WelcomeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final userName = userProvider.userProfile?.name?.isNotEmpty == true
        ? userProvider.userProfile!.name!
        : null;

    String greeting = "Hello";
    final hour = DateTime.now().hour;
    if (hour < 12) { greeting = "Good morning"; }
    else if (hour < 18) { greeting = "Good afternoon"; }
    else { greeting = "Good evening"; }


    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            Text(
               '$greeting${userName != null ? ", $userName" : ""}!',
               style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
               maxLines: 1,
               overflow: TextOverflow.ellipsis,
            ),
             const SizedBox(height: 4),
              Text(
                 "Ready for your next workout?", // TODO: Show weather summary?
                 style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
         ],
      ),
    );
  }
}