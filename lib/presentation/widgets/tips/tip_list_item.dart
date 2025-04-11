import 'package:flutter/material.dart';
import 'package:running_app/data/models/running_tip.dart';

class TipListItem extends StatelessWidget {
  final RunningTip tip;
  final VoidCallback? onTap;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;

  const TipListItem({
    required this.tip,
    this.onTap,
    required this.isFavorite,
    this.onToggleFavorite,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      leading: CircleAvatar(
         backgroundColor: colorScheme.secondaryContainer.withOpacity(0.6),
         foregroundColor: colorScheme.onSecondaryContainer,
         child: Icon(tip.category.icon, size: 22),
      ),
      title: Text(
         tip.title,
         style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
         maxLines: 1,
         overflow: TextOverflow.ellipsis
      ),
      subtitle: Text(
         tip.content,
         style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
         maxLines: 2,
         overflow: TextOverflow.ellipsis
      ),
      trailing: IconButton(
         icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? Colors.redAccent : colorScheme.outline,
         ),
         tooltip: isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
         onPressed: onToggleFavorite,
         padding: EdgeInsets.zero, // Reduce padding around icon button
          visualDensity: VisualDensity.compact,
      ),
      onTap: onTap,
    );
  }
}