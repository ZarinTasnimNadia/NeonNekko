// lib/pages/search_page.dart

import 'package:flutter/material.dart';
import '../models/content.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart'; 
import '../pages/wishlist_page.dart'; 
import '../pages/watchlist_page.dart'; 
import '../pages/detail_page.dart';


class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  final TextEditingController _searchController = TextEditingController();
  
  // Future that holds the search results. Initialized to an empty list.
  Future<List<Content>> _searchResultsFuture = Future.value([]);

  @override
  void initState() {
    super.initState();
    // Listen for text changes to trigger search automatically
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    
    // Only search if the query is 3 characters or longer, or if cleared.
    if (query.length >= 3) {
      setState(() {
        _searchResultsFuture = _apiService.searchAll(query);
      });
    } else if (query.isEmpty) {
      setState(() {
        _searchResultsFuture = Future.value([]);
      });
    }
  }
  
  // Helper to refresh the UI when a toggle action occurs
  void _refreshStatus() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Titles'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search movies, TV, or anime...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchResultsFuture = Future.value([]);
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                contentPadding: const EdgeInsets.all(10.0),
              ),
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Content>>(
        future: _searchResultsFuture,
        builder: (context, snapshot) {
          if (_searchController.text.length < 3 && _searchController.text.isNotEmpty) {
            return const Center(child: Text('Type at least 3 characters to search.'));
          }
          if (_searchController.text.isEmpty) {
            return const Center(child: Text('Start typing to see results.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No results found.'));
          }

          final results = snapshot.data!;
          return ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final content = results[index];
              return _buildSearchResultTile(context, content);
            },
          );
        },
      ),
    );
  }

  Widget _buildSearchResultTile(BuildContext context, Content content) {
    // Futures to check the current status of the item
    final wishListFuture = _storageService.loadWishList();
    final watchListFuture = _storageService.loadWatchList();

    return ListTile(
      leading: SizedBox(
        width: 60,
        height: 80,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: content.imageUrl.isNotEmpty
              ? Image.network(
                  content.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => 
                      const Placeholder(color: Colors.grey),
                )
              : const Placeholder(color: Colors.grey),
        ),
      ),
      title: Text(content.title),
      subtitle: Text('Type: ${content.mediaType.toUpperCase()}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // WishList Toggle (Heart)
          FutureBuilder<List<Content>>(
            future: wishListFuture,
            builder: (context, snapshot) {
              bool isWished = snapshot.hasData 
                ? snapshot.data!.any((item) => item.id == content.id && item.mediaType == content.mediaType)
                : false;
              
              return IconButton(
                icon: Icon(isWished ? Icons.favorite : Icons.favorite_border),
                color: isWished ? const Color.fromARGB(255, 239, 127, 234) : Colors.grey,
                onPressed: () async {
                  await _storageService.toggleWishListItem(content);
                  _refreshStatus(); // Refresh UI to update icon
                },
              );
            },
          ),
          // WatchList Toggle (Bookmark)
          FutureBuilder<List<Content>>(
            future: watchListFuture,
            builder: (context, snapshot) {
              bool isWatched = snapshot.hasData 
                ? snapshot.data!.any((item) => item.id == content.id && item.mediaType == content.mediaType)
                : false;
              
              return IconButton(
                icon: Icon(isWatched ? Icons.bookmark : Icons.bookmark_border),
                color: isWatched ? const Color.fromARGB(255, 245, 116, 215) : Colors.grey,
                onPressed: () async {
                  await _storageService.toggleWatchListItem(content);
                  _refreshStatus(); // Refresh UI to update icon
                },
              );
            },
          ),
        ],
      ),
      onTap: () {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => DetailPage(content: content)),
      ).then((_) => _refreshStatus()); // Refresh list tile icons when returning
    },

    );
  }
}