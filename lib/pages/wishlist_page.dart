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
  List<Content> _wishList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  Future<void> _loadData() async {
    final list = await _storageService.loadWishList();
    if (mounted) {
      setState(() {
        _wishList = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _wishList.removeAt(oldIndex);
      _wishList.insert(newIndex, item);
    });
    
    for (int i = 0; i < _wishList.length; i++) {
      await _storageService.setPriority(_wishList[i], i);
    }
  }

  Future<void> _deleteItem(Content item) async {
    await _storageService.toggleWishListItem(item);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _wishList.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist Priority')),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _wishList.isEmpty
            ? const Center(child: Text('Your wishlist is empty'))
            : ReorderableListView.builder(
                itemCount: _wishList.length,
                onReorder: _onReorder,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final item = _wishList[index];
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
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailPage(content: item),
                          ),
                        ).then((_) => _loadData()),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}