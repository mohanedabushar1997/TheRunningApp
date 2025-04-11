import 'dart:math'; // For substring calculation

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:running_app/data/models/running_tip.dart'; // Import model
import 'package:running_app/presentation/providers/tips_provider.dart';
import 'package:running_app/presentation/screens/tips/tip_detail_screen.dart'; // Import detail screen
import 'package:running_app/presentation/widgets/common/loading_indicator.dart';
import 'package:running_app/utils/logger.dart'; // Use custom logger

class TipOfTheDayWidget extends StatelessWidget {
  const TipOfTheDayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Consumer for automatic rebuilds when tipOfTheDay changes
    return Consumer<TipsProvider>(
      builder: (context, tipsProvider, child) {
        final tip = tipsProvider.tipOfTheDay;
        final isLoading = tipsProvider.isLoading; // Check loading state

        // Fetch tip if needed (e.g., on initial load)
        // This check prevents continuous fetching during rebuilds
        if (tip == null && !isLoading && tipsProvider.errorMessage == null) {
           WidgetsBinding.instance.addPostFrameCallback((_) {
              // Check again inside callback to ensure provider state hasn't changed
              if (context.read<TipsProvider>().tipOfTheDay == null && !context.read<TipsProvider>().isLoading) {
                 Log.d("TipOfTheDayWidget: Fetching initial tip.");
                 context.read<TipsProvider>().fetchTipOfTheDay();
              }
           });
        }

        // --- Loading State ---
        if (isLoading && tip == null) {
          return const Card(
             elevation: 2,
             child: SizedBox(
                height: 100, // Placeholder height
                child: Center(child: LoadingIndicator(size: 24)),
             ),
          );
        }

        // --- Error State ---
        if (tip == null && tipsProvider.errorMessage != null) {
          return Card(
             elevation: 2,
             color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
             child: ListTile(
               leading: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
               title: const Text('Could not load tip'),
                subtitle: Text(tipsProvider.errorMessage!, style: TextStyle(fontSize: 12)),
                trailing: IconButton(
                   icon: const Icon(Icons.refresh, size: 20),
                   tooltip: 'Retry',
                   onPressed: () => context.read<TipsProvider>().fetchTipOfTheDay(forceRefresh: true),
                ),
             ),
          );
        }

        // --- No Tip State ---
        // This shouldn't happen if fetch works or error is shown, but handle defensively
        if (tip == null) {
            return const Card(
               child: ListTile(title: Text('No tip available today.'))
            );
        }

        // --- Display Tip ---
        return Card(
          elevation: 2,
          clipBehavior: Clip.antiAlias, // Improves InkWell clipping
          child: InkWell( // Make card tappable
             onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TipDetailScreen(tip: tip),
                     settings: const RouteSettings(name: TipDetailScreen.routeName), // Optional
                  ),
                );
             },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    tip.category.icon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 30,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tip.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          // Show a summary of the content
                           tip.content.length > 100
                              ? '${tip.content.substring(0, 100)}...'
                              : tip.content,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                         const SizedBox(height: 8),
                         Text(
                            'Tap to read more...',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
                         ),
                      ],
                    ),
                  ),
                   // Optional: Add favorite toggle directly? (Less common here)
                   // IconButton(...)
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}