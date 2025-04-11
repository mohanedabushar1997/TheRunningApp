import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:running_app/data/models/running_tip.dart';
import 'package:running_app/presentation/providers/tips_provider.dart';
import 'package:running_app/presentation/screens/tips/tip_detail_screen.dart';
import 'package:running_app/presentation/widgets/common/loading_indicator.dart';
import 'package:running_app/presentation/widgets/tips/category_chip.dart';
import 'package:running_app/presentation/widgets/tips/tip_list_item.dart';
import 'package:running_app/utils/logger.dart';

class TipsListScreen extends StatefulWidget {
  const TipsListScreen({super.key});
  static const routeName = '/tips';

  @override
  State<TipsListScreen> createState() => _TipsListScreenState();
}

// Added TickerProviderStateMixin for TabController
class _TipsListScreenState extends State<TipsListScreen> with TickerProviderStateMixin {
  RunningCategory _selectedCategory = RunningCategory.all;
  TipDifficulty _selectedDifficulty = TipDifficulty.any;
  late TabController _tabController;

  // Tabs: All Tips, Favorite Tips
  final List<Tab> _tabs = const <Tab>[
     Tab(text: 'All Tips'),
     Tab(text: 'Favorites'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    // Add listener to fetch favorites when tab changes
    _tabController.addListener(() {
       if (_tabController.index == 1 && !_tabController.indexIsChanging) {
           Log.d("Switched to Favorites tab, fetching favorites.");
           context.read<TipsProvider>().fetchFavoriteTips();
       }
       // Optionally refetch all tips when switching back to index 0? Only if needed.
       // else if (_tabController.index == 0 && !_tabController.indexIsChanging) {
       //    context.read<TipsProvider>().fetchTips(category: _selectedCategory, difficulty: _selectedDifficulty);
       // }
    });

    // Fetch initial "All Tips"
    Future.microtask(() =>
        context.read<TipsProvider>().fetchTips(
            category: _selectedCategory,
            difficulty: _selectedDifficulty,
         ));
  }

  @override
  void dispose() {
     _tabController.dispose();
     super.dispose();
  }


  void _updateFilters(RunningCategory? category, TipDifficulty? difficulty) {
     bool categoryChanged = category != null && category != _selectedCategory;
     bool difficultyChanged = difficulty != null && difficulty != _selectedDifficulty;

     if (categoryChanged || difficultyChanged) {
        // Ensure we are on the 'All Tips' tab before applying filters
        if (_tabController.index != 0) {
           _tabController.animateTo(0);
        }
        setState(() {
           if (categoryChanged) _selectedCategory = category!;
           if (difficultyChanged) _selectedDifficulty = difficulty!;
        });
        context.read<TipsProvider>().fetchTips(
            category: _selectedCategory,
            difficulty: _selectedDifficulty,
        );
     }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Running Tips'),
        actions: [
           // Difficulty Filter (only applies to 'All Tips' tab)
           if (_tabController.index == 0)
              PopupMenuButton<TipDifficulty>(
                 icon: const Icon(Icons.filter_list_outlined),
                 tooltip: "Filter by Difficulty",
                 onSelected: (TipDifficulty difficulty) => _updateFilters(null, difficulty),
                 itemBuilder: (BuildContext context) => TipDifficulty.values
                     .map((difficulty) => PopupMenuItem<TipDifficulty>(
                           value: difficulty,
                           child: Text(difficulty.name[0].toUpperCase() + difficulty.name.substring(1)),
                         ))
                     .toList(),
               ),
        ],
         bottom: TabBar(
           controller: _tabController,
           tabs: _tabs,
         ),
      ),
      body: TabBarView(
         controller: _tabController,
         children: [
            // --- All Tips Tab ---
            _buildAllTipsTab(),
            // --- Favorites Tab ---
            _buildFavoritesTab(),
         ],
      ),
    );
  }

  // Builder for the "All Tips" tab content
  Widget _buildAllTipsTab() {
     return Column(
        children: [
          // Category Filter Chips
          _buildCategoryFilter(),
          const Divider(height: 1),
          // Tips List
          Expanded(
             child: Consumer<TipsProvider>( // Use consumer for list updates
               builder: (context, tipsProvider, child) {
                  final tips = tipsProvider.filteredTips; // Use filtered tips list
                  if (tipsProvider.isLoading) {
                     return const LoadingIndicator();
                  }
                   if (tips.isEmpty) {
                     return _buildEmptyState('No tips found for the selected filters.');
                   }
                   return RefreshIndicator(
                      onRefresh: () => tipsProvider.fetchTips(
                          category: _selectedCategory,
                          difficulty: _selectedDifficulty,
                          forceRefresh: true
                       ),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        itemCount: tips.length,
                        itemBuilder: (context, index) {
                          final tip = tips[index];
                          return TipListItem(
                            tip: tip,
                            onTap: () => _navigateToDetail(context, tip),
                             // Add favorite toggle directly on the list item
                             isFavorite: tipsProvider.isFavorite(tip.id), // Pass current status
                             onToggleFavorite: () => tipsProvider.toggleFavorite(tip.id),
                          );
                        },
                        separatorBuilder: (context, index) => const Divider(indent: 16, endIndent: 16, height: 1),
                      ),
                    );
               },
             ),
          ),
        ],
     );
  }

  // Builder for the "Favorites" tab content
   Widget _buildFavoritesTab() {
      return Consumer<TipsProvider>(
         builder: (context, tipsProvider, child) {
            final tips = tipsProvider.favoriteTips; // Use dedicated favorites list
            // Fetch if needed (e.g., if navigated directly to this tab)
            // This check might be redundant due to TabController listener, but safe to keep
            // if (tips.isEmpty && !tipsProvider.isLoading && tipsProvider.errorMessage == null) {
            //    WidgetsBinding.instance.addPostFrameCallback((_) {
            //        if (context.read<TipsProvider>().favoriteTips.isEmpty && !context.read<TipsProvider>().isLoading) {
            //            context.read<TipsProvider>().fetchFavoriteTips();
            //        }
            //    });
            // }

            if (tipsProvider.isLoading) {
               return const LoadingIndicator();
            }
            if (tips.isEmpty) {
               return _buildEmptyState('You haven\'t favorited any tips yet.');
            }
            // Use RefreshIndicator for consistency, although favorites update instantly on toggle
            return RefreshIndicator(
               onRefresh: () => tipsProvider.fetchFavoriteTips(), // Refetch favorites
               child: ListView.separated(
                 padding: const EdgeInsets.symmetric(vertical: 8.0),
                 itemCount: tips.length,
                 itemBuilder: (context, index) {
                   final tip = tips[index];
                   return TipListItem(
                     tip: tip,
                     onTap: () => _navigateToDetail(context, tip),
                      isFavorite: true, // All tips here are favorites
                      onToggleFavorite: () => tipsProvider.toggleFavorite(tip.id), // Allow unfavoriting
                   );
                 },
                 separatorBuilder: (context, index) => const Divider(indent: 16, endIndent: 16, height: 1),
               ),
             );
         },
      );
   }


  // Helper for category filter chips
  Widget _buildCategoryFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: RunningCategory.values.map((categoryEnum) {
             final isSelected = categoryEnum == _selectedCategory;
             return Padding(
               padding: const EdgeInsets.symmetric(horizontal: 4.0),
               child: CategoryChip( // Use the dedicated widget
                 label: categoryEnum.displayName,
                 icon: categoryEnum.icon,
                 isSelected: isSelected,
                 onSelected: (selected) => _updateFilters(categoryEnum, null),
               ),
             );
          }).toList(),
        ),
      ),
    );
  }

   // Helper for empty state display
   Widget _buildEmptyState(String message) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
             message,
             textAlign: TextAlign.center,
             style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          ),
        ),
      );
   }

   // Helper for navigation
   void _navigateToDetail(BuildContext context, RunningTip tip) {
     Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TipDetailScreen(tip: tip),
           settings: const RouteSettings(name: TipDetailScreen.routeName),
        ),
      );
   }
}