// lib/pages/watchlist_page.dart

import 'package:flutter/material.dart';
import '../models/content.dart';
import '../services/storage_service.dart';

class WatchListPage extends StatefulWidget {
  const WatchListPage({super.key});

  @override
  State<WatchListPage> createState() => _WatchListPageState();
}

class _WatchListPageState extends State<WatchListPage> {
  final StorageService _storageService = StorageService();
  late Future<List<Content>> _watchListFuture;

  @override
  void initState() {
    super.initState();
    _watchListFuture = _storageService.loadWatchList();
  }

  void _refreshWatchList() {
    setState(() {
      _watchListFuture = _storageService.loadWatchList();
    });
  }

  Map<String, List<Content>> _groupListByStatus(List<Content> list) {
    Map<String, List<Content>> groups = {};
    for (var status in StorageService.availableStatuses) {
      groups[status] = list.where((c) => c.status == status).toList();
    }
    return groups;
  }
  
  void _showStatusDialog(BuildContext context, Content content) {
    String currentStatus = content.status ?? 'Planning';
    int currentProgress = content.currentProgress ?? 0;
    
    // Use a placeholder total if the content type doesn't have an episode count
    final maxProgress = (content.totalProgress ?? 100).toDouble();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Update Status for ${content.title}'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: currentStatus,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: StorageService.availableStatuses.map((status) {
                      return DropdownMenuItem(value: status, child: Text(status));
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setDialogState(() {
                          currentStatus = newValue;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Progress: $currentProgress'),
                  Slider(
                    value: currentProgress.toDouble(),
                    min: 0,
                    max: maxProgress,
                    divisions: maxProgress.toInt(),
                    label: currentProgress.round().toString(),
                    onChanged: (double value) {
                      setDialogState(() {
                        currentProgress = value.round();
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await _storageService.updateWatchListItem(
                  content, 
                  newStatus: currentStatus, 
                  newCurrentProgress: currentProgress,
                );
                if (mounted) Navigator.pop(context);
                _refreshWatchList(); 
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
        title: const Text('My WatchList'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Content>>(
        future: _watchListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading list: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Your WatchList is empty! Add content from the home screen.', textAlign: TextAlign.center),
            );
          } else {
            final groupedList = _groupListByStatus(snapshot.data!);
            
            return ListView(
              children: StorageService.availableStatuses.map((status) {
                final group = groupedList[status] ?? [];
                if (group.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Text(
                        '$status (${group.length})', 
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    ...group.map((content) => ListTile(
                      leading: SizedBox(
                        width: 50,
                        height: 80,
                        child: content.imageUrl.isNotEmpty 
                          ? Image.network(content.imageUrl, fit: BoxFit.cover) 
                          : const Icon(Icons.image_not_supported),
                      ),
                      title: Text(content.title),
                      subtitle: Text(
                          'Progress: ${content.currentProgress ?? 0}' + 
                          (content.totalProgress != null ? ' of ${content.totalProgress}' : '')
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Color.fromARGB(255, 226, 108, 230)),
                            onPressed: () => _showStatusDialog(context, content),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Color.fromARGB(255, 83, 2, 56)),
                            onPressed: () async {
                              await _storageService.toggleWatchListItem(content);
                              _refreshWatchList();
                            },
                          ),
                        ],
                      ),
                    )).toList(),
                    const Divider(indent: 16, endIndent: 16),
                  ],
                );
              }).toList(),
            );
          }
        },
      ),
    );
  }
}