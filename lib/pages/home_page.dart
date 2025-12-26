import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../theme/theme_service.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/content.dart';
import 'wishlist_page.dart';
import 'watchlist_page.dart';
import 'search_page.dart';
import 'profile_page.dart';
import 'detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomeTabContent(),
      const WishListPage(),
      const WatchListPage(),
      const ProfilePage(),
    ];
  }

  void _showThemePicker(BuildContext context, ThemeService themeService) {
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Select Theme'),
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: themeService.availableThemes.keys.map((themeName) {
              final isSelected = themeService.currentThemeKey == themeName;
              return ShadButton.ghost(
                width: double.infinity,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                onPressed: () {
                  themeService.setTheme(themeName);
                  Navigator.pop(context);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(themeName),
                    if (isSelected) 
                      Icon(Icons.check, size: 16, color: Theme.of(context).primaryColor),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('NeonNeko'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.palette_outlined),
          onPressed: () => _showThemePicker(context, themeService),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SearchPage()),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: theme.primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home, color: theme.primaryColor),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite_outline),
            activeIcon: Icon(Icons.favorite, color: theme.primaryColor),
            label: 'Wishlist',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bookmark_outline),
            activeIcon: Icon(Icons.bookmark, color: theme.primaryColor),
            label: 'Watchlist',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person, color: theme.primaryColor),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomeTabContent extends StatefulWidget {
  const HomeTabContent({super.key});

  @override
  State<HomeTabContent> createState() => _HomeTabContentState();
}

class _HomeTabContentState extends State<HomeTabContent> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  late Future<List<Content>> _trendingMoviesFuture;
  late Future<List<Content>> _topAnimeFuture;
  late Future<List<Content>> _wishListFuture;
  late Future<List<Content>> _watchListFuture;

  @override
  void initState() {
    super.initState();
    _initFutures();
  }

  void _initFutures() {
    _trendingMoviesFuture = _apiService.fetchTrendingMovies();
    _topAnimeFuture = _apiService.fetchTopAnime();
    _wishListFuture = _storageService.loadWishList();
    _watchListFuture = _storageService.loadWatchList();
  }

  void _refreshLocalData() {
    setState(() {
      _wishListFuture = _storageService.loadWishList();
      _watchListFuture = _storageService.loadWatchList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Trending Movies/TV'),
          _buildContentRow(_trendingMoviesFuture),
          const SizedBox(height: 32),
          _buildSectionHeader('Top Anime'),
          _buildContentRow(_topAnimeFuture),
          const SizedBox(height: 32),
          _buildSectionHeader('My Wishlist'),
          _buildContentRow(_wishListFuture),
          const SizedBox(height: 32),
          _buildSectionHeader('Currently Watching'),
          _buildContentRow(_watchListFuture),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title, 
        style: ShadTheme.of(context).textTheme.h3.copyWith(fontWeight: FontWeight.bold)
      ),
    );
  }

  Widget _buildContentRow(Future<List<Content>> future) {
    return FutureBuilder<List<Content>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 250, child: Center(child: CircularProgressIndicator()));
        }
        final list = snapshot.data ?? [];
        if (list.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('No titles found.'));
        
        return SizedBox(
          height: 280,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: list.take(10).length,
            itemBuilder: (context, index) => _buildPosterCard(list[index]),
          ),
        );
      },
    );
  }

  Widget _buildPosterCard(Content content) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => DetailPage(content: content)),
      ).then((_) => _refreshLocalData()),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ShadCard(
                    padding: EdgeInsets.zero,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: content.imageUrl.isNotEmpty
                          ? Image.network(
                              content.imageUrl, 
                              fit: BoxFit.cover, 
                              width: double.infinity, 
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                            )
                          : const Placeholder(),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            content.rating?.toStringAsFixed(1) ?? 'N/A',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: FutureBuilder<List<Content>>(
                      future: _watchListFuture,
                      builder: (context, snapshot) {
                        final isWatched = snapshot.data?.any((item) => item.id == content.id) ?? false;
                        return ShadButton.ghost(
                          width: 32,
                          height: 32,
                          padding: EdgeInsets.zero,
                          decoration: const ShadDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: Icon(
                            isWatched ? Icons.bookmark : Icons.bookmark_border, 
                            color: isWatched ? Colors.purpleAccent : Colors.white, 
                            size: 18
                          ),
                          onPressed: () async {
                            await _storageService.toggleWatchListItem(content);
                            _refreshLocalData();
                          },
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: FutureBuilder<List<Content>>(
                      future: _wishListFuture,
                      builder: (context, snapshot) {
                        final isWished = snapshot.data?.any((item) => item.id == content.id) ?? false;
                        return ShadButton.ghost(
                          width: 32,
                          height: 32,
                          padding: EdgeInsets.zero,
                          decoration: const ShadDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: Icon(
                            isWished ? Icons.favorite : Icons.favorite_border, 
                            color: isWished ? Colors.pink : Colors.white, 
                            size: 18
                          ),
                          onPressed: () async {
                            await _storageService.toggleWishListItem(content);
                            _refreshLocalData();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              content.title, 
              maxLines: 2, 
              overflow: TextOverflow.ellipsis, 
              style: ShadTheme.of(context).textTheme.small
            ),
          ],
        ),
      ),
    );
  }
}