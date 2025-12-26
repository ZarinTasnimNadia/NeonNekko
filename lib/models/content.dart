class Content {
  final int id;
  final String title;
  final String imageUrl;
  final String mediaType; 
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
    return Content(
      id: json['id'],
      title: title,
      imageUrl: posterPath.isNotEmpty ? '$imageBaseUrl$posterPath' : '',
      mediaType: json['media_type'] ?? (json['title'] != null ? 'movie' : 'tv'),
      rating: (json['vote_average'] as num?)?.toDouble(),
    );
  }

  factory Content.fromJikanJson(Map<String, dynamic> json) {
    return Content(
      id: json['mal_id'] ?? 0,
      title: json['title'] ?? 'No Title',
      imageUrl: json['images']?['jpg']?['large_image_url'] ?? '',
      mediaType: 'anime',
      rating: (json['score'] as num?)?.toDouble(),
    );
  }
}