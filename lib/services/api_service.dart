import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/content.dart';

class ApiService {

  // **REPLACE THIS WITH YOUR ACTUAL KEY**
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
        throw Exception('Failed to load data from API. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('API Fetch Error: $e');
      return [];
    }
  }


  
  Future<List<Content>> fetchTrendingMovies() async {

    final url = '$_tmdbBaseUrl/trending/all/week?api_key=$_tmdbApiKey';
    return _fetchData(url, Content.fromTmdbJson);
  }


  
  Future<List<Content>> fetchTopAnime() async {

    final url = '$_jikanBaseUrl/top/anime?filter=bypopularity&type=tv&limit=15';
    return _fetchData(url, Content.fromJikanJson);
  }


  Future<List<Content>> searchTmdb(String query) async {

    final url = '$_tmdbBaseUrl/search/multi?api_key=$_tmdbApiKey&query=${Uri.encodeQueryComponent(query)}';
    
    List<Content> results = await _fetchData(url, Content.fromTmdbJson);
    

    return results.where((item) => item.mediaType != 'person').toList();
  }


  Future<List<Content>> searchJikan(String query) async {

    final url = '$_jikanBaseUrl/anime?q=${Uri.encodeQueryComponent(query)}';
    
    return _fetchData(url, Content.fromJikanJson);
  }


  Future<List<Content>> searchAll(String query) async {
    if (query.isEmpty) return [];


    final List<Future<List<Content>>> futures = [
      searchTmdb(query),
      searchJikan(query),
    ];


    final List<List<Content>> allResults = await Future.wait(futures);
    

    List<Content> combined = [];
    for (var list in allResults) {
      combined.addAll(list);
    }
    
    return combined;
  }


  Future<Map<String, dynamic>> fetchTmdbDetails(int id, String mediaType) async {

    final url = '$_tmdbBaseUrl/$mediaType/$id?api_key=$_tmdbApiKey&append_to_response=credits,videos,recommendations';
    
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load TMDb details for $mediaType/$id. Status: ${response.statusCode}');
    }
  }


  Future<Map<String, dynamic>> fetchJikanDetails(int id) async {
    final url = '$_jikanBaseUrl/anime/$id/full';
    
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      // Jikan wraps the main object inside a 'data' key for details
      return data['data'] ?? {};
    } else {
      throw Exception('Failed to load Jikan details for anime/$id. Status: ${response.statusCode}');
    }
  }

}