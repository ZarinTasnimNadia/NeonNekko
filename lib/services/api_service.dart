import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/content.dart';

class ApiService {
  static const String _tmdbApiKey = '6e80bf4b41e695a7ba21fb88611d8e38';
  static const String _tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String _jikanBaseUrl = 'https://api.jikan.moe/v4';

  Future<List<Content>> _fetchData(String url, Content Function(Map<String, dynamic>) fromJson) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> results = data['results'] ?? data['data'] ?? [];
        return results.map((item) => fromJson(item as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      return [];
    }
  }

  Future<List<Content>> fetchTrendingMovies() async => _fetchData('$_tmdbBaseUrl/trending/all/week?api_key=$_tmdbApiKey', Content.fromTmdbJson);
  Future<List<Content>> fetchTopAnime() async => _fetchData('$_jikanBaseUrl/top/anime?filter=bypopularity&type=tv&limit=15', Content.fromJikanJson);

  Future<List<Content>> searchTmdb(String query) async {
    List<Content> results = await _fetchData('$_tmdbBaseUrl/search/multi?api_key=$_tmdbApiKey&query=${Uri.encodeQueryComponent(query)}', Content.fromTmdbJson);
    return results.where((item) => item.mediaType != 'person').toList();
  }

  Future<List<Content>> searchJikan(String query) async => _fetchData('$_jikanBaseUrl/anime?q=${Uri.encodeQueryComponent(query)}', Content.fromJikanJson);

  Future<List<Content>> searchAll(String query) async {
    if (query.isEmpty) return [];
    final results = await Future.wait([searchTmdb(query), searchJikan(query)]);
    return results.expand((x) => x).toList();
  }

  Future<Map<String, dynamic>> fetchTmdbDetails(int id, String mediaType) async {
    final response = await http.get(Uri.parse('$_tmdbBaseUrl/$mediaType/$id?api_key=$_tmdbApiKey&append_to_response=credits,videos,recommendations'));
    return response.statusCode == 200 ? jsonDecode(response.body) : throw Exception('Error');
  }

  Future<Map<String, dynamic>> fetchJikanDetails(int id) async {
    final response = await http.get(Uri.parse('$_jikanBaseUrl/anime/$id/full'));
    return response.statusCode == 200 ? (jsonDecode(response.body))['data'] : throw Exception('Error');
  }

  Future<List<Content>> fetchMoviesByGenre(int genreId) async => 
    _fetchData('$_tmdbBaseUrl/discover/movie?api_key=$_tmdbApiKey&with_genres=$genreId', Content.fromTmdbJson);

  Future<List<Content>> fetchTvByGenre(int genreId) async => 
      _fetchData('$_tmdbBaseUrl/discover/tv?api_key=$_tmdbApiKey&with_genres=$genreId', Content.fromTmdbJson);

  Future<List<Content>> fetchAnimeByGenre(int genreId) async => 
      _fetchData('$_jikanBaseUrl/anime?genres=$genreId&order_by=popularity', Content.fromJikanJson);

  Future<Map<String, dynamic>> fetchAnimeFranchiseStats(int malId) async {
    Set<int> visitedIds = {};
    Map<int, Map<String, dynamic>> franchiseMap = {};
    int totalEpisodes = 0;

    Future<void> crawl(int id) async {
      if (visitedIds.contains(id)) return;
      visitedIds.add(id);

      final response = await http.get(Uri.parse('$_jikanBaseUrl/anime/$id/full'));
      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body)['data'];
      franchiseMap[id] = {
        'name': data['title'],
        'mal_id': id,
        'episodes': data['episodes'] ?? 0,
        'type': data['type'] ?? 'TV'
      };
      
      totalEpisodes += (data['episodes'] as int? ?? 0);

      final List relations = data['relations'] ?? [];
      for (var rel in relations) {
        String relationType = rel['relation'] ?? '';
        if (relationType == 'Sequel' || relationType == 'Prequel' || relationType == 'Parent story' || relationType == 'Full story') {
          final List entries = rel['entry'] ?? [];
          for (var entry in entries) {
            if (entry['type'] == 'anime') {
              await crawl(entry['mal_id']);
            }
          }
        }
      }
    }

    try {
      await crawl(malId);
      List<Map<String, dynamic>> finalSeasonList = franchiseMap.values.toList();
      
      return {
        'total_episodes': totalEpisodes,
        'seasons_count': finalSeasonList.where((e) => e['type'] == 'TV').length,
        'season_list': finalSeasonList,
      };
    } catch (e) {
      return {'total_episodes': 0, 'seasons_count': 1, 'season_list': []};
    }
  }
}