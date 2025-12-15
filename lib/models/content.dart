class Content {
  final int id;
  final String title;
  final String imageUrl;
  final String mediaType; 
  final int? priority;
  

  final String? status; 
  final int? currentProgress; 
  final int? totalProgress; 
  // -------------------------

  Content({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.mediaType,
    this.priority,
    

    this.status,
    this.currentProgress,
    this.totalProgress,

  });

  // Factory constructor to create a Content object from TMDb JSON
  factory Content.fromTmdbJson(Map<String, dynamic> json) {
    const String imageBaseUrl = 'https://image.tmdb.org/t/p/w500';
    
    // TMDb uses 'title' for movies and 'name' for TV
    final String title = json['title'] ?? json['name'] ?? 'No Title';
    
    final String posterPath = json['poster_path'] ?? '';

    return Content(
      id: json['id'],
      title: title,
      imageUrl: posterPath.isNotEmpty ? '$imageBaseUrl$posterPath' : '',
      mediaType: json['media_type'] ?? (json['title'] != null ? 'movie' : 'tv'),
    );
  }

  // Factory constructor to create a Content object from Jikan JSON
  factory Content.fromJikanJson(Map<String, dynamic> json) {
    final String title = json['title'] ?? 'No Title';
    // Accessing the largest available image size
    final String posterUrl = json['images']?['jpg']?['large_image_url'] ?? json['images']?['jpg']?['image_url'] ?? '';

    return Content(
      id: json['mal_id'] ?? 0, // MyAnimeList ID
      title: title,
      imageUrl: posterUrl,
      mediaType: 'anime',
    );
  }
}