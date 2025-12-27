import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/content.dart';
import 'api_service.dart';

class StorageService {
  final _supabase = Supabase.instance.client;

  String? get _userId => _supabase.auth.currentUser?.id;

  // --- ENUM MAPPING HELPERS ---

  String _mapDbStatusToUi(String? dbStatus) {
    switch (dbStatus) {
      case 'currently_watching': return 'Watching';
      case 'finished': return 'Completed';
      case 'dropped': return 'Dropped';
      case 'plan_to_watch': return 'Planning';
      default: return 'Watching';
    }
  }

  String _mapUiToDbStatus(String? uiStatus) {
    switch (uiStatus) {
      case 'Watching': return 'currently_watching';
      case 'Completed': return 'finished';
      case 'Dropped': return 'dropped';
      case 'Planning': return 'plan_to_watch';
      default: return 'currently_watching';
    }
  }

  // --- LOCAL CACHING LOGIC ---

  Future<void> _saveLocalCache(String key, List<Content> content) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(content.map((item) => {
      'id': item.id,
      'title': item.title,
      'imageUrl': item.imageUrl,
      'mediaType': item.mediaType,
      'status': item.status,
      'currentProgress': item.currentProgress,
      'totalProgress': item.totalProgress,
      'priority': item.priority,
    }).toList());
    await prefs.setString('${key}_$_userId', encodedData);
  }

  Future<List<Content>> _loadLocalCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString('${key}_$_userId');
    if (encodedData == null) return [];

    final List<dynamic> decodedData = jsonDecode(encodedData);
    return decodedData.map((json) => Content(
      id: json['id'],
      title: json['title'],
      imageUrl: json['imageUrl'],
      mediaType: json['mediaType'],
      status: json['status'],
      currentProgress: json['currentProgress'],
      totalProgress: json['totalProgress'],
      priority: json['priority'],
      genres: json['genres'] ?? [],
    )).toList();
  }


  Future<List<Content>> loadWishList() async {
    if (_userId == null) return [];
    
    // 1. Try to load from local cache first for immediate UI feedback
    List<Content> cachedList = await _loadLocalCache('wishlist');
    
    try {
      final res = await _supabase
          .from('wishlist')
          .select()
          .eq('user_id', _userId!)
          .order('priority_order', ascending: true);

      final List<Content> list = (res as List).map((json) => Content(
        id: json['title_id'],
        title: json['temp_title'] ?? 'Unknown',
        imageUrl: json['temp_image'] ?? '',
        mediaType: json['temp_media_type'] ?? 'anime',
        priority: json['priority_order'],
        genres: [],
      )).toList();

      // 2. Only overwrite cache if we successfully got data from the server
      await _saveLocalCache('wishlist', list);
      return list;
    } catch (e) {
      debugPrint('Wishlist fetch failed, using cached list: $e');
      return cachedList;
    }
  }

  Future<void> toggleWishListItem(Content content) async {
    if (_userId == null) return;
    try {
      final existing = await _supabase
          .from('wishlist')
          .select()
          .eq('user_id', _userId!)
          .eq('title_id', content.id)
          .maybeSingle();

      if (existing != null) {
        await _supabase.from('wishlist').delete().eq('user_id', _userId!).eq('title_id', content.id);
      } else {
        await _supabase.from('wishlist').insert({
          'user_id': _userId,
          'title_id': content.id,
          'priority_order': 0,
          'temp_title': content.title,
          'temp_image': content.imageUrl,
          'temp_media_type': content.mediaType,
        });
      }
    } catch (e) {
      debugPrint('Toggle Wishlist Error: $e');
      // For a full offline app, you'd queue this action for later sync
    }
  }


  Future<void> setPriority(Content content, int newPriority) async {
    if (_userId == null) return;
    try {
      await _supabase
          .from('wishlist')
          .update({'priority_order': newPriority})
          .eq('user_id', _userId!)
          .eq('title_id', content.id);
    } catch (e) {
      debugPrint('Set Priority Error: $e');
    }
  }

  // --- WATCHLIST METHODS ---

  Future<List<Content>> loadWatchList() async {
    if (_userId == null) return [];

    try {
      final res = await _supabase
          .from('watchlist')
          .select()
          .eq('user_id', _userId!);

      final List<Content> list = (res as List).map((json) => Content(
        id: json['title_id'],
        title: json['temp_title'] ?? 'Unknown',
        imageUrl: json['temp_image'] ?? '',
        mediaType: json['temp_media_type'] ?? 'anime',
        status: _mapDbStatusToUi(json['current_status']),
        currentProgress: json['episodes_watched'],
        totalProgress: json['temp_total_episodes'] ?? 12,
        genres: [],
      )).toList();

      await _saveLocalCache('watchlist', list);
      return list;
    } catch (e) {
      debugPrint('Watchlist fetch failed, loading local cache: $e');
      return await _loadLocalCache('watchlist');
    }
  }

// storage_service.dart

  Future<bool> toggleWatchListItem(Content content) async {
    if (_userId == null) return false;
    try {
      final existing = await _supabase
          .from('watchlist')
          .select()
          .eq('user_id', _userId!)
          .eq('title_id', content.id)
          .maybeSingle();

      if (existing != null) {
        await _supabase
            .from('watchlist')
            .delete()
            .eq('user_id', _userId!)
            .eq('title_id', content.id);
        debugPrint('Removed from database');
        return false; 
      } else {
        await updateWatchListItem(content, newStatus: 'Watching', newCurrentProgress: 0);
        debugPrint('Added to database');
        return true; 
      }
    } catch (e) {
      debugPrint('Toggle error: $e');
      return false;
    }
  }



  final ApiService _apiService = ApiService();



  Future<void> updateWatchListItem(Content content, {String? newStatus, int? newCurrentProgress, int? newTotalProgress}) async {
    if (_userId == null) return;

    int totalEp = newTotalProgress ?? content.totalProgress ?? 12;

    
    if (totalEp == 12) {
      try {
        if (content.mediaType == 'anime') {
          final stats = await _apiService.fetchAnimeFranchiseStats(content.id);
          if (stats['total_episodes'] > 0) totalEp = stats['total_episodes'];
        } else if (content.mediaType == 'tv') {
          // Fetch real episode count for TV shows like Stranger Things
          final details = await _apiService.fetchTmdbDetails(content.id, 'tv');
          if (details.containsKey('number_of_episodes')) {
            totalEp = details['number_of_episodes'];
          }
        } else if (content.mediaType == 'movie') {
          totalEp = 1;
        }
      } catch (e) {
        debugPrint("Error fetching metadata: $e");
      }
    }

    String dbStatus = _mapUiToDbStatus(newStatus ?? content.status);

    final updateData = {
      'user_id': _userId,
      'title_id': content.id,
      'episodes_watched': newCurrentProgress ?? content.currentProgress ?? 0,
      'current_status': dbStatus,
      'temp_title': content.title,
      'temp_image': content.imageUrl,
      'temp_media_type': content.mediaType,
      'temp_total_episodes': totalEp, // This will now save 42 for Stranger Things
      'last_updated': DateTime.now().toIso8601String(),
    };

    try {
      await _supabase.from('watchlist').upsert(updateData);
    } catch (e) {
      debugPrint('Update Watchlist Error: $e');
    }
  }
  Future<void> removeFromWishlistIfExists(Content content) async {
  if (_userId == null) return;
  try {
    
    await _supabase
        .from('wishlist')
        .delete()
        .eq('user_id', _userId!)
        .eq('title_id', content.id);
    debugPrint('Checked and removed ${content.title} from wishlist if it was present.');
  } catch (e) {
    debugPrint('Wishlist cleanup error: $e');
  }
}
}