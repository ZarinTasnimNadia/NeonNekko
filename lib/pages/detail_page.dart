import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import '../models/content.dart';
import '../services/api_service.dart';

class DetailPage extends StatefulWidget {
  final Content content;
  const DetailPage({super.key, required this.content});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final _supabase = Supabase.instance.client;
  final ApiService _apiService = ApiService();
  final TextEditingController _commentController = TextEditingController();

  late Future<Map<String, dynamic>> _detailsFuture;
  List<dynamic> _comments = [];
  double _userRating = 0;
  double _averageRating = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _detailsFuture = _fetchData();
    _fetchComments();
  }

  Future<Map<String, dynamic>> _fetchData() async {
    if (widget.content.mediaType == 'anime') {
      final results = await Future.wait([
        _apiService.fetchJikanDetails(widget.content.id),
        _apiService.fetchAnimeFranchiseStats(widget.content.id),
      ]);
      return {
        ...results[0],
        'franchise_info': results[1],
      };
    } else {
      return await _apiService.fetchTmdbDetails(widget.content.id, widget.content.mediaType);
    }
  }

  Future<void> _fetchComments() async {
    try {
      final res = await _supabase
          .from('reviews')
          .select('''
            *,
            users (
              username,
              avatar_url
            )
          ''')
          .eq('content_id', widget.content.id)
          .eq('media_type', widget.content.mediaType)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _comments = (res is List) ? List<dynamic>.from(res) : [];
          
          if (_comments.isNotEmpty) {
            final total = _comments.fold<double>(0, (sum, item) => sum + ((item['rating'] as num?)?.toDouble() ?? 0.0));
            _averageRating = total / _comments.length;
          } else {
            _averageRating = 0.0;
          }

          final currentUserId = _supabase.auth.currentUser?.id;
          if (currentUserId != null) {
            try {
              final userReview = _comments.firstWhere(
                (r) => r['user_id'] == currentUserId,
              );
              _userRating = ((userReview['rating'] as num?)?.toDouble()) ?? 0.0;
              _commentController.text = userReview['comment'] ?? '';
            } catch (e) {
              _userRating = 0.0;
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching comments: $e');
      if (mounted) {
        setState(() {
          _comments = [];
          _averageRating = 0.0;
        });
      }
    }
  }

  Future<void> _submitReview() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);
    try {
      await _supabase.from('reviews').upsert({
        'user_id': user.id,
        'content_id': widget.content.id,
        'media_type': widget.content.mediaType,
        'rating': _userRating,
        'comment': _commentController.text,
        'updated_at': DateTime.now().toIso8601String(),
      });

      await _fetchComments();
      if (mounted) {
        ShadToaster.of(context).show(const ShadToast(description: Text('Review saved successfully!')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.content.title)),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) return const Center(child: Text('Error loading details'));

          final data = snapshot.data!;
          String episodeInfo = "N/A";
          List<Map<String, dynamic>> animeSeasons = [];
          String globalRating = "N/A";

          if (widget.content.mediaType == 'anime') {
            final franchise = data['franchise_info'];
            final totalEpisodes = franchise['total_episodes'] ?? 0;
            final tvSeasonCount = franchise['seasons_count'] ?? 1;
            animeSeasons = List<Map<String, dynamic>>.from(franchise['season_list'] ?? []);
            episodeInfo = "$tvSeasonCount TV Seasons • $totalEpisodes Total Episodes";
            globalRating = data['score']?.toString() ?? "N/A";
          } else {
            if (data.containsKey('number_of_episodes')) {
              episodeInfo = "${data['number_of_seasons']} Seasons • ${data['number_of_episodes']} Episodes";
            } else if (data.containsKey('runtime')) {
              episodeInfo = "${data['runtime']} Minutes";
            }
            globalRating = data['vote_average']?.toStringAsFixed(1) ?? "N/A";
          }

          final List genres = data['genres'] ?? [];
          final genreNames = genres.map((g) => g['name']).join(', ');

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(widget.content.imageUrl, height: 350, width: double.infinity, fit: BoxFit.cover),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(widget.content.title, style: theme.textTheme.h2)),
                          _buildRatingBadge(theme),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.public, size: 16, color: theme.colorScheme.mutedForeground),
                          const SizedBox(width: 4),
                          Text(
                            'Global Rating: $globalRating',
                            style: theme.textTheme.muted.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (genreNames.isNotEmpty) ShadBadge(child: Text(genreNames)),
                      const SizedBox(height: 12),
                      Text(episodeInfo, style: theme.textTheme.large.copyWith(color: theme.colorScheme.primary)),
                      const Divider(height: 32),
                      Text(data['overview'] ?? data['synopsis'] ?? 'No synopsis available', style: theme.textTheme.p),
                      
                      if (animeSeasons.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text('Full Franchise History', style: theme.textTheme.h3),
                        const SizedBox(height: 8),
                        ...animeSeasons.map((s) {
                          final bool isCurrent = s['mal_id'] == widget.content.id;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(s['name'], 
                              style: theme.textTheme.muted.copyWith(
                                color: isCurrent ? theme.colorScheme.primary : null,
                                fontWeight: isCurrent ? FontWeight.bold : null
                              )
                            ),
                            subtitle: Text("${s['episodes']} Episodes (${s['type']})"),
                            trailing: isCurrent ? const ShadBadge(child: Text('Viewing')) : const Icon(Icons.chevron_right),
                            onTap: isCurrent ? null : () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetailPage(
                                    content: Content(
                                      id: s['mal_id'],
                                      title: s['name'],
                                      imageUrl: widget.content.imageUrl, 
                                      mediaType: 'anime',
                                      genres: widget.content.genres
                                    )
                                  )
                                )
                              );
                            },
                          );
                        }),
                      ],
                    ],
                  ),
                ),
                _buildReviewInput(theme),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Community Reviews', style: theme.textTheme.h3),
                ),
                _comments.isEmpty
                    ? const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('No reviews yet.')))
                    : _buildCommentList(theme),
                const SizedBox(height: 60),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRatingBadge(ShadThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 24),
          Text(_averageRating.toStringAsFixed(1), style: theme.textTheme.h4),
        ],
      ),
    );
  }

  Widget _buildReviewInput(ShadThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ShadCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Review', style: theme.textTheme.h4),
            const SizedBox(height: 12),
            RatingBar.builder(
              initialRating: _userRating,
              itemSize: 30,
              allowHalfRating: true,
              itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (r) => setState(() => _userRating = r),
            ),
            const SizedBox(height: 12),
            ShadInput(
              controller: _commentController,
              placeholder: const Text('Share your thoughts...'),
            ),
            const SizedBox(height: 12),
            ShadButton(
              width: double.infinity,
              onPressed: _isSubmitting ? null : _submitReview,
              child: _isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Post Review'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentList(ShadThemeData theme) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _comments.length,
      itemBuilder: (context, index) {
        final r = _comments[index];
        final username = r['users']?['username'] ?? 'Anonymous User';
        return ListTile(
          leading: CircleAvatar(child: Text(username[0].toUpperCase())),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(username, style: theme.textTheme.large),
              Text('⭐ ${r['rating']}', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r['comment'] ?? '', style: theme.textTheme.muted),
              const SizedBox(height: 4),
              Text(DateFormat('MMM d, yyyy').format(DateTime.parse(r['created_at'])), style: const TextStyle(fontSize: 10)),
            ],
          ),
        );
      },
    );
  }
}