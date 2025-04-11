import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:running_app/data/models/running_tip.dart';
import 'package:running_app/presentation/providers/tips_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:running_app/presentation/widgets/tips/category_chip.dart'; // Use CategoryChip
import 'package:running_app/utils/logger.dart';

class TipDetailScreen extends StatelessWidget {
  final RunningTip tip;

  const TipDetailScreen({required this.tip, super.key});
  static const routeName = '/tip-detail';

  // --- Share Logic ---
  void _shareTip(BuildContext context, RunningTip tipToShare) {
     final String shareText = '*FitStride Tip: ${tipToShare.title}*\n\n${tipToShare.content}';
     try {
        Share.share(shareText, subject: 'Check out this running tip!');
     } catch (e) {
         Log.e("Error sharing tip: $e");
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Could not share tip.'), backgroundColor: Colors.red),
          );
     }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final categoryEnum = tip.category;

    return Scaffold(
      appBar: AppBar(
        title: Text(tip.title),
        actions: [
          // --- Share Action ---
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Tip',
            onPressed: () => _shareTip(context, tip),
          ),
           // --- Favorite Action ---
           Consumer<TipsProvider>(
             builder: (context, tipsProvider, child) {
               // Use the provider's cached state which is updated via toggleFavorite
               final bool isFavorite = tipsProvider.isFavorite(tip.id);
               return IconButton(
                 icon: Icon(
                   isFavorite ? Icons.favorite : Icons.favorite_border,
                   color: isFavorite ? Colors.redAccent : null,
                 ),
                 tooltip: isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
                 onPressed: () async {
                    try {
                       await tipsProvider.toggleFavorite(tip.id);
                        // Show feedback immediately based on the NEW state
                        final updatedIsFavorite = tipsProvider.isFavorite(tip.id);
                        if (context.mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(
                               content: Text(updatedIsFavorite ? 'Added to favorites' : 'Removed from favorites'),
                               duration: const Duration(seconds: 1),
                             ),
                           );
                        }
                    } catch (e) {
                        Log.e("Error toggling favorite: $e");
                         if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text('Could not update favorites.'), backgroundColor: Colors.red),
                            );
                         }
                    }
                 },
               );
             },
           ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Category & Difficulty Chips ---
             Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: <Widget>[
                   CategoryChip( // Use the dedicated widget
                      label: categoryEnum.displayName,
                      icon: categoryEnum.icon,
                      isSelected: false, // Not selectable here, just display
                      onSelected: (_) {},
                      // Use smaller style for detail screen?
                      // textStyle: textTheme.labelSmall,
                      // padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                   ),
                   Chip(
                     label: Text(tip.difficulty.name[0].toUpperCase() + tip.difficulty.name.substring(1)),
                     labelStyle: textTheme.labelSmall,
                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                     visualDensity: VisualDensity.compact, // Make chip smaller
                   ),
                ],
             ),
             const SizedBox(height: 16),

            // --- Tip Content ---
            Text(
              tip.content,
              style: textTheme.bodyLarge?.copyWith(fontSize: 16.5, height: 1.45, letterSpacing: 0.1),
            ),
            const SizedBox(height: 24),

            // --- Related Tips (TODO) ---
             // _buildRelatedTips(context), // Requires implementation
          ],
        ),
      ),
    );
  }


   // TODO: Implement Related Tips Section
   // Widget _buildRelatedTips(BuildContext context) {
   //    return FutureBuilder<List<RunningTip>>(
   //       future: context.read<TipsProvider>().findRelatedTips(tip.id, tip.category),
   //       builder: (context, snapshot) {
   //          if (snapshot.connectionState == ConnectionState.waiting) {
   //             return const Padding(padding: EdgeInsets.all(8.0), child: LoadingIndicator(size: 20));
   //          }
   //          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
   //             return const SizedBox.shrink(); // Hide section if error or no related tips
   //          }
   //          final relatedTips = snapshot.data!;
   //          return Column(
   //             crossAxisAlignment: CrossAxisAlignment.start,
   //             children: [
   //                const Divider(height: 32),
   //                Text('Related Tips', style: Theme.of(context).textTheme.titleMedium),
   //                const SizedBox(height: 8),
   //                ...relatedTips.map((relatedTip) => ListTile(
   //                   contentPadding: EdgeInsets.zero,
   //                   leading: Icon(relatedTip.category.icon, size: 18),
   //                   title: Text(relatedTip.title, maxLines: 1, overflow: TextOverflow.ellipsis),
   //                   trailing: const Icon(Icons.chevron_right, size: 18),
   //                   onTap: () {
   //                      Navigator.pushReplacement( // Use replacement to avoid deep stack
   //                         context,
   //                         MaterialPageRoute(builder: (context) => TipDetailScreen(tip: relatedTip)),
   //                      );
   //                   },
   //                )).toList(),
   //             ],
   //          );
   //       },
   //    );
   // }

}