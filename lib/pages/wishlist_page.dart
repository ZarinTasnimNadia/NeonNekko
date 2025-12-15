// lib/pages/wishlist_page.dart

import 'package:flutter/material.dart';
import '../models/content.dart';
import '../services/storage_service.dart';

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

  void _refreshWishList() {
    setState(() {
      _wishListFuture = _storageService.loadWishList();
    });
  }
  
  void _showPriorityDialog(BuildContext context, Content content) {
    int tempPriority = content.priority ?? 5; 

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Set Priority for ${content.title}'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Priority Level: $tempPriority (1=High, 10=Low)'),
                  Slider(
                    value: tempPriority.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: tempPriority.round().toString(),
                    onChanged: (double value) {
                      setDialogState(() {
                        tempPriority = value.round();
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _storageService.setPriority(content, tempPriority);
                if (mounted) Navigator.pop(context);
                _refreshWishList();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My WishList'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Content>>(
        future: _wishListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading list: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Your WishList is empty! Tap the heart icon on the home screen to add titles.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          } else {
            final wishList = snapshot.data!;
            
            return ListView.builder(
              itemCount: wishList.length,
              itemBuilder: (context, index) {
                final content = wishList[index];
                
                return ListTile(
                  leading: SizedBox(
                    width: 50,
                    height: 80,
                    child: content.imageUrl.isNotEmpty
                        ? Image.network(
                            content.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => 
                                const Icon(Icons.broken_image, size: 40),
                          )
                        : const Icon(Icons.image_not_supported, size: 40),
                  ),
                  title: Text(content.title),
                  subtitle: Text(
                    content.priority != null 
                      ? 'Priority: ${content.priority} (${content.mediaType})' 
                      : 'Unprioritized (${content.mediaType})',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.sort),
                        onPressed: () => _showPriorityDialog(context, content),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                        onPressed: () async {
                          await _storageService.toggleWishListItem(content);
                          _refreshWishList();
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    // Navigate to the detail screen (future implementation)
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}