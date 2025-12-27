import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/content.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import 'detail_page.dart';

class WatchListPage extends StatefulWidget {
  const WatchListPage({super.key});

  @override
  State<WatchListPage> createState() => _WatchListPageState();
}

class _WatchListPageState extends State<WatchListPage> {
  final StorageService _storageService = StorageService();
  final ApiService _apiService = ApiService();
  late Future<List<Content>> _watchListFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _watchListFuture = _storageService.loadWatchList();
    });
  }

  Future<void> _updateProgress(Content content, int delta) async {
    int current = content.currentProgress ?? 0;
    int maxVal = content.totalProgress ?? 12;

    if (maxVal == 12) {
      if (content.mediaType == 'anime') {
        final stats = await _apiService.fetchAnimeFranchiseStats(content.id);
        if (stats['total_episodes'] > 0) maxVal = stats['total_episodes'];
      } else if (content.mediaType == 'tv') {
        final details = await _apiService.fetchTmdbDetails(content.id, 'tv');
        if (details.containsKey('number_of_episodes')) {
          maxVal = details['number_of_episodes'];
        }
      } else if (content.mediaType == 'movie') {
        maxVal = 1;
      }
    }

    int next = (current + delta).clamp(0, maxVal);
    String status = (next >= maxVal && maxVal > 0) ? 'Completed' : 'Watching'; 

    await _storageService.updateWatchListItem(
      content,
      newCurrentProgress: next,
      newStatus: status,
      newTotalProgress: maxVal,
    );

    if (status == 'Completed') {
      await _storageService.removeFromWishlistIfExists(content);
    }
    
    if (mounted) {
      _refresh();
    }
  }

  void _showEditDialog(Content content) {
    String currentStatus = content.status ?? 'Watching';
    int currentProgress = content.currentProgress ?? 0;
    int totalEp = content.totalProgress ?? 12;

    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: Text('Edit ${content.title}'),
        child: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShadSelect<String>(
                placeholder: Text(currentStatus),
                options: ['Watching', 'Completed', 'Dropped', 'Planning']
                    .map((s) => ShadOption(value: s, child: Text(s)))
                    .toList(),
                selectedOptionBuilder: (context, value) => Text(value),
                onChanged: (v) => setDialogState(() => currentStatus = v!),
              ),
              const SizedBox(height: 16),
              Text('Progress: $currentProgress / $totalEp'),
              ShadSlider(
                initialValue: currentProgress.toDouble(),
                max: totalEp.toDouble(),
                onChanged: (v) => setDialogState(() => currentProgress = v.toInt()),
              ),
            ],
          ),
        ),
        actions: [
          ShadButton.ghost(
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              await _storageService.toggleWatchListItem(content);
              Navigator.pop(context);
              _refresh();
            },
          ),
          ShadButton(
            child: const Text('Save'),
            onPressed: () async {
              int finalProgress = (currentStatus == 'Completed') ? totalEp : currentProgress;
              await _storageService.updateWatchListItem(
                content,
                newStatus: currentStatus,
                newCurrentProgress: finalProgress,
              );
              if (currentStatus == 'Completed') {
                await _storageService.removeFromWishlistIfExists(content);
              }
              Navigator.pop(context);
              _refresh();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Watchlist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<Content>>(
        future: _watchListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final list = snapshot.data ?? [];
          if (list.isEmpty) return const Center(child: Text('Watchlist is empty'));
          final ongoing = list.where((c) => c.status != 'Completed').toList();
          final completed = list.where((c) => c.status == 'Completed').toList();
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ongoing.isNotEmpty) ...[_buildHeader('Ongoing'), _buildGrid(ongoing)],
                if (completed.isNotEmpty) ...[_buildHeader('Completed'), _buildGrid(completed)],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(String title) => Padding(
    padding: const EdgeInsets.all(16),
    child: Text(title, style: ShadTheme.of(context).textTheme.h4),
  );

  Widget _buildGrid(List<Content> items) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.symmetric(horizontal: 12),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3, 
      childAspectRatio: 0.52,
      crossAxisSpacing: 8, 
      mainAxisSpacing: 12
    ),
    itemCount: items.length,
    itemBuilder: (context, index) => _buildWatchCard(items[index]),
  );

  Widget _buildWatchCard(Content content) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              GestureDetector(
                onTap: () => _showEditDialog(content),
                child: ShadCard(
                  padding: EdgeInsets.zero,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      content.imageUrl, 
                      fit: BoxFit.cover, 
                      width: double.infinity, 
                      height: double.infinity,
                      errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.movie)),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 4, left: 4, right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          icon: const Icon(Icons.remove, size: 14, color: Colors.white), 
                          onPressed: () => _updateProgress(content, -1)
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Text(
                            '${content.currentProgress}/${content.totalProgress}', 
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          icon: const Icon(Icons.add, size: 14, color: Colors.white), 
                          onPressed: () => _updateProgress(content, 1)
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content.title,
          maxLines: 1, 
          overflow: TextOverflow.ellipsis, 
          style: const TextStyle(fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}