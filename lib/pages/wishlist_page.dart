import 'package:flutter/material.dart';
import '../models/content.dart';
import '../services/storage_service.dart';
import 'detail_page.dart';

class WishListPage extends StatefulWidget {
  const WishListPage({super.key});

  @override
  State<WishListPage> createState() => _WishListPageState();
}

class _WishListPageState extends State<WishListPage> {
  final StorageService _storageService = StorageService();
  late Future<List<Content>> _wishListFuture;

  @override
  void initState() {
    super.initState();
    _wishListFuture = _storageService.loadWishList();
  }

  void _loadData() {
    setState(() {
      _wishListFuture = _storageService.loadWishList();
    });
  }

  Future<void> _onReorder(int oldIndex, int newIndex, List<Content> currentList) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = currentList.removeAt(oldIndex);
    currentList.insert(newIndex, item);

    for (int i = 0; i < currentList.length; i++) {
      await _storageService.setPriority(currentList[i], i);
    }
    
    _loadData();
  }

  Future<void> _deleteItem(Content item) async {
    await _storageService.toggleWishListItem(item);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist Priority'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: FutureBuilder<List<Content>>(
        future: _wishListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final wishList = snapshot.data ?? [];

          return RefreshIndicator(
            onRefresh: () async {
              _loadData();
              await _wishListFuture;
            },
            child: wishList.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 200),
                      Center(child: Text('Your wishlist is empty')),
                    ],
                  )
                : ReorderableListView.builder(
                    itemCount: wishList.length,
                    onReorder: (oldIndex, newIndex) => _onReorder(oldIndex, newIndex, List.from(wishList)),
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final item = wishList[index];
                      final String uniqueKey = '${item.id}_${item.mediaType}';

                      return Dismissible(
                        key: ValueKey('dismiss_$uniqueKey'),
                        direction: DismissDirection.startToEnd,
                        onDismissed: (_) => _deleteItem(item),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: Card(
                          key: ValueKey(uniqueKey),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: item.imageUrl.isNotEmpty
                                ? Image.network(
                                    item.imageUrl,
                                    width: 50,
                                    height: 75,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.broken_image, size: 50),
                                  )
                                : const Icon(Icons.movie, size: 50),
                            title: Text(item.title, maxLines: 1),
                            subtitle: Text('Priority Rank: ${index + 1}'),
                            trailing: const Icon(Icons.drag_handle),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailPage(content: item),
                                ),
                              );
                              _loadData();
                            },
                          ),
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}
