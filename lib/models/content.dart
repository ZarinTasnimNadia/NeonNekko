class Content {
  final int id;
  final String title;
  final String imageUrl;
  final String mediaType;
  final List<String> genres;
  final int? priority;
  final String? status;
  final int? currentProgress;
  final int? totalProgress;
  final double? rating;

  Content({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.mediaType,
    required this.genres,
    this.priority,
    this.status,
    this.currentProgress,
    this.totalProgress,
    this.rating,
  });

  factory Content.fromTmdbJson(Map<String, dynamic> json) {
    const String imageBaseUrl = 'https://image.tmdb.org/t/p/w500';
    final String title = json['title'] ?? json['name'] ?? 'No Title';
    final String posterPath = json['poster_path'] ?? '';
    
    final Map<int, String> tmdbGenreMap = {
      28: 'Action', 12: 'Adventure', 16: 'Animation', 35: 'Comedy', 80: 'Crime',
      99: 'Documentary', 18: 'Drama', 10751: 'Family', 14: 'Fantasy', 36: 'History',
      27: 'Horror', 10402: 'Music', 9648: 'Mystery', 10749: 'Romance', 878: 'Sci-Fi',
      10770: 'TV Movie', 53: 'Thriller', 10752: 'War', 37: 'Western'
    };

    final List<int> genreIds = List<int>.from(json['genre_ids'] ?? []);
    final List<String> genreNames = genreIds
        .where((id) => tmdbGenreMap.containsKey(id))
        .map((id) => tmdbGenreMap[id]!)
        .toList();

    return Content(
      id: json['id'],
      title: title,
      imageUrl: posterPath.isNotEmpty ? '$imageBaseUrl$posterPath' : '',
      mediaType: json['media_type'] ?? (json['title'] != null ? 'movie' : 'tv'),
      genres: genreNames,
      rating: (json['vote_average'] as num?)?.toDouble(),
    );
  }

  factory Content.fromJikanJson(Map<String, dynamic> json) {
    final List<dynamic> genreList = json['genres'] ?? [];
    final List<String> genreNames = genreList.map((g) => g['name'].toString()).toList();

    return Content(
      id: json['mal_id'] ?? 0,
      title: json['title'] ?? 'No Title',
      imageUrl: json['images']?['jpg']?['large_image_url'] ?? '',
      mediaType: 'anime',
      genres: genreNames,
      rating: (json['score'] as num?)?.toDouble(),
    );
  }
}