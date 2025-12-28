import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'dart:async';
import '../models/content.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
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
  Future<List<Content>> _searchResultsFuture = Future.value([]);
  late Future<List<Content>> _wishListFuture;
  late Future<List<Content>> _watchListFuture;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadLists();
  }

  void _loadLists() {
    setState(() {
      _wishListFuture = _storageService.loadWishList();
      _watchListFuture = _storageService.loadWatchList();
    });
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      if (query.length >= 3) {
        setState(() {
          _searchResultsFuture = _apiService.searchAll(query);
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ShadInput(
          controller: _searchController,
          placeholder: const Text('Search instantly...'),
          // Removing the focus boundary/box shadow
          decoration: ShadDecoration(
            border: ShadBorder.none,
            secondaryBorder: ShadBorder.none,
            secondaryFocusedBorder: ShadBorder.none,
          ),
        ),
      ),
      body: FutureBuilder<List<Content>>(
        future: _searchResultsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('Type 3+ letters...'));
          
          final results = snapshot.data!;
          return ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final item = results[index];
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(item.imageUrl, width: 40, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image)),
                ),
                title: Text(item.title),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FutureBuilder<List<Content>>(
                      future: _wishListFuture,
                      builder: (context, snapshot) {
                        final isWished = snapshot.data?.any((element) => element.id == item.id) ?? false;
                        return ShadButton.ghost(
                          width: 32,
                          height: 32,
                          padding: EdgeInsets.zero,
                          child: Icon(
                            isWished ? Icons.favorite : Icons.favorite_border,
                            color: isWished ? Colors.pink : Colors.grey,
                            size: 20,
                          ),
                          onPressed: () async {
                            await _storageService.toggleWishListItem(item);
                            _loadLists();
                          },
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    FutureBuilder<List<Content>>(
                      future: _watchListFuture,
                      builder: (context, snapshot) {
                        final isWatched = snapshot.data?.any((element) => element.id == item.id) ?? false;
                        return ShadButton.ghost(
                          width: 32,
                          height: 32,
                          padding: EdgeInsets.zero,
                          child: Icon(
                            isWatched ? Icons.bookmark : Icons.bookmark_border,
                            color: isWatched ? Colors.purpleAccent : Colors.grey,
                            size: 20,
                          ),
                          onPressed: () async {
                            await _storageService.toggleWatchListItem(item);
                            _loadLists();
                          },
                        );
                      },
                    ),
                  ],
                ),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailPage(content: item))).then((_) => _loadLists()),
              );
            },
          );
        },
      ),
    );
  }
}