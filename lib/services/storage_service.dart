// lib/services/storage_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/content.dart';

class StorageService {
  static const String _wishListKey = 'user_wish_list';
  static const String _watchListKey = 'user_watch_list';

  static const List<String> availableStatuses = [
    'Planning', 'Watching', 'Completed', 'Dropped'
  ];

  // --- WISH LIST METHODS ---
  
  Future<void> saveWishList(List<Content> wishList) async {
    final prefs = await SharedPreferences.getInstance();
    
    final List<String> jsonList = wishList.map((content) {
      return jsonEncode({
        'id': content.id,
        'title': content.title,
        'imageUrl': content.imageUrl,
        'mediaType': content.mediaType,
        'priority': content.priority,
      });
    }).toList();
    
    await prefs.setStringList(_wishListKey, jsonList);
  }

  Future<List<Content>> loadWishList() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> jsonList = prefs.getStringList(_wishListKey) ?? [];
    
    List<Content> list = jsonList.map((jsonString) {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      
      return Content(
        id: json['id'] as int,
        title: json['title'] as String,
        imageUrl: json['imageUrl'] as String,
        mediaType: json['mediaType'] as String,
        priority: json['priority'] as int?,
      );
    }).toList();
    
    list.sort((a, b) {
      if (a.priority == null) return (b.priority == null) ? 0 : 1;
      if (b.priority == null) return -1;
      return a.priority!.compareTo(b.priority!);
    });

    return list;
  }

  Future<List<Content>> toggleWishListItem(Content content) async {
    List<Content> currentList = await loadWishList();
    
    final isPresent = currentList.any(
      (item) => item.id == content.id && item.mediaType == content.mediaType
    );

    if (isPresent) {
      currentList.removeWhere(
        (item) => item.id == content.id && item.mediaType == content.mediaType
      );
    } else {
      currentList.add(content);
    }

    await saveWishList(currentList);
    return currentList;
  }
  
  Future<void> setPriority(Content content, int newPriority) async {
    List<Content> currentList = await loadWishList();
    
    final index = currentList.indexWhere(
      (item) => item.id == content.id && item.mediaType == content.mediaType
    );

    if (index != -1) {
      currentList[index] = Content(
        id: content.id,
        title: content.title,
        imageUrl: content.imageUrl,
        mediaType: content.mediaType,
        priority: newPriority,
      );
    }
    
    await saveWishList(currentList);
  }
  
  // --- WATCH LIST METHODS ---

  Future<void> saveWatchList(List<Content> watchList) async {
    final prefs = await SharedPreferences.getInstance();
    
    final List<String> jsonList = watchList.map((content) {
      return jsonEncode({
        'id': content.id,
        'title': content.title,
        'imageUrl': content.imageUrl,
        'mediaType': content.mediaType,
        'status': content.status,
        'currentProgress': content.currentProgress,
        'totalProgress': content.totalProgress,
      });
    }).toList();
    
    await prefs.setStringList(_watchListKey, jsonList);
  }

  Future<List<Content>> loadWatchList() async {
    final prefs = await SharedPreferences.getInstance();
    
    final List<String> jsonList = prefs.getStringList(_watchListKey) ?? [];
    
    return jsonList.map((jsonString) {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      
      return Content(
        id: json['id'] as int,
        title: json['title'] as String,
        imageUrl: json['imageUrl'] as String,
        mediaType: json['mediaType'] as String,
        status: json['status'] as String?,
        currentProgress: json['currentProgress'] as int?,
        totalProgress: json['totalProgress'] as int?,
      );
    }).toList();
  }

  Future<List<Content>> toggleWatchListItem(Content content) async {
    List<Content> currentList = await loadWatchList();
    
    final isPresent = currentList.any(
      (item) => item.id == content.id && item.mediaType == content.mediaType
    );

    if (isPresent) {
      currentList.removeWhere(
        (item) => item.id == content.id && item.mediaType == content.mediaType
      );
    } else {
      currentList.add(Content(
        id: content.id,
        title: content.title,
        imageUrl: content.imageUrl,
        mediaType: content.mediaType,
        status: 'Planning',
        currentProgress: 0,
        totalProgress: null,
      ));
    }

    await saveWatchList(currentList);
    return currentList;
  }
  
  Future<void> updateWatchListItem(Content content, {
    String? newStatus,
    int? newCurrentProgress,
    int? newTotalProgress,
  }) async {
    List<Content> currentList = await loadWatchList();
    
    final index = currentList.indexWhere(
      (item) => item.id == content.id && item.mediaType == content.mediaType
    );

    if (index != -1) {
      currentList[index] = Content(
        id: content.id,
        title: content.title,
        imageUrl: content.imageUrl,
        mediaType: content.mediaType,
        priority: currentList[index].priority,
        status: newStatus ?? content.status,
        currentProgress: newCurrentProgress ?? content.currentProgress,
        totalProgress: newTotalProgress ?? content.totalProgress,
      );
    }
    
    await saveWatchList(currentList);
  }
}