// lib/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:neonnekko/auth/auth_service.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/content.dart';
import 'wishlist_page.dart';
import 'watchlist_page.dart';
import 'search_page.dart'; 
import 'detail_page.dart'; 

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  late Future<List<Content>> _trendingMoviesFuture;
  late Future<List<Content>> _topAnimeFuture;
  late Future<List<Content>> _wishListFuture;
  late Future<List<Content>> _watchListFuture;

  @override
  void initState() {
    super.initState();
   
    _trendingMoviesFuture = _apiService.fetchTrendingMovies();
    _topAnimeFuture = _apiService.fetchTopAnime();
    _wishListFuture = _storageService.loadWishList();
    _watchListFuture = _storageService.loadWatchList();
  }
  

  void _refreshLocalLists() {
    setState(() {
      _wishListFuture = _storageService.loadWishList();
      _watchListFuture = _storageService.loadWatchList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NeonNeko'),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.filter_list),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Navigation'),
            ),
            ListTile(title: const Text('Home'), onTap: () => Navigator.pop(context)),
            ListTile(title: const Text('Profile'), onTap: () => { /* Navigate to Profile */ }),
            
          
            ListTile(
              title: const Text('WishList'), 
              onTap: () {
                Navigator.pop(context); 
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const WishListPage()),
                ).then((_) => _refreshLocalLists()); 
              },
            ),
            
           
            ListTile(
              title: const Text('WatchList'), 
              onTap: () {
                Navigator.pop(context); 
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const WatchListPage()),
                ).then((_) => _refreshLocalLists());
              },
            ),
            
          
            ListTile(
              title: const Text('Search'), 
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SearchPage()),
                ).then((_) => _refreshLocalLists());
              },
            ),

            const Divider(),
            ListTile(
              title: const Text('Sign Out'),
              onTap: () async {
                await _authService.signOut();
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, 'Trending Movies/TV'),
            _buildContentRow(context, _trendingMoviesFuture),
            const SizedBox(height: 32),
            
            _buildSectionHeader(context, 'Top Anime'),
            _buildContentRow(context, _topAnimeFuture),
            const SizedBox(height: 32),

            _buildSectionHeader(context, 'WishList: Priority Order'),
            _buildContentRow(context, _wishListFuture),
            const SizedBox(height: 32),
            
            _buildSectionHeader(context, 'Currently Watching'),
            _buildContentRow(context, _watchListFuture),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
    );
  }


  Widget _buildContentRow(BuildContext context, Future<List<Content>> contentFuture) {
    return FutureBuilder<List<Content>>(
      future: contentFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ));
        } else if (snapshot.hasError) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error loading content: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
          ));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No content found.'),
          ));
        } else {
          final contentList = snapshot.data!;
      
          final displayList = contentList.take(10).toList();
          
          return SizedBox(
            height: 250,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              scrollDirection: Axis.horizontal,
              itemCount: displayList.length,
              itemBuilder: (context, index) {
                return _buildPosterCard(displayList[index]);
              },
            ),
          );
        }
      },
    );
  }


  Widget _buildPosterCard(Content content) {

    final wishListFuture = _storageService.loadWishList();
    final watchListFuture = _storageService.loadWatchList();

    return GestureDetector(
      onTap: () {
   
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => DetailPage(content: content)),
        ).then((_) => _refreshLocalLists()); 
      },
      child: Container(
        width: 120, 
        margin: const EdgeInsets.only(right: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: content.imageUrl.isNotEmpty
                        ? Image.network(
                            content.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => 
                                const Placeholder(color: Colors.red), 
                          )
                        : const Placeholder(color: Colors.grey),
                  ),
                  
                 
                  Positioned(
                    top: 5,
                    right: 5,
                    child: FutureBuilder<List<Content>>(
                      future: wishListFuture,
                      builder: (context, snapshot) {
                        bool isWished = snapshot.hasData 
                          ? snapshot.data!.any((item) => item.id == content.id && item.mediaType == content.mediaType)
                          : false;
                        
                        return IconButton(
                          icon: Icon(
                            isWished ? Icons.favorite : Icons.favorite_border,
                            color: isWished ? const Color.fromARGB(255, 212, 128, 222) : Colors.white,
                            size: 24,
                          ),
                          onPressed: () async {
                            await _storageService.toggleWishListItem(content);
                            _refreshLocalLists(); // Refresh UI
                          },
                        );
                      },
                    ),
                  ),
                  
                 
                  Positioned(
                    top: 5,
                    left: 5,
                    child: FutureBuilder<List<Content>>(
                      future: watchListFuture,
                      builder: (context, snapshot) {
                        bool isWatched = snapshot.hasData 
                          ? snapshot.data!.any((item) => item.id == content.id && item.mediaType == content.mediaType)
                          : false;
                        
                        return IconButton(
                          icon: Icon(
                            isWatched ? Icons.bookmark : Icons.bookmark_border,
                            color: isWatched ? const Color.fromARGB(255, 232, 109, 226) : Colors.white,
                            size: 24,
                          ),
                          onPressed: () async {
                            await _storageService.toggleWatchListItem(content);
                            _refreshLocalLists(); 
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Title
            Text(
              content.title, 
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}