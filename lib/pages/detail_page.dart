// lib/pages/detail_page.dart

import 'package:flutter/material.dart';
import '../models/content.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class DetailPage extends StatefulWidget {
  final Content content;

  const DetailPage({super.key, required this.content});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  late Future<Map<String, dynamic>> _detailsFuture;
  
  @override
  void initState() {
    super.initState();
    // Determine which API to call based on the media type
    if (widget.content.mediaType == 'anime') {
      _detailsFuture = _apiService.fetchJikanDetails(widget.content.id);
    } else {
      // Handles 'movie' and 'tv'
      _detailsFuture = _apiService.fetchTmdbDetails(widget.content.id, widget.content.mediaType);
    }
  }

  // Helper method to toggle WishList status and update the UI
  Future<void> _toggleWishList() async {
    await _storageService.toggleWishListItem(widget.content);
    setState(() {}); // Refresh UI to update the icon
  }
  
  // Helper method to toggle WatchList status and update the UI
  Future<void> _toggleWatchList() async {
    await _storageService.toggleWatchListItem(widget.content);
    setState(() {}); // Refresh UI to update the icon
  }
  
  // Helper to extract the primary image URL from the raw TMDb or Jikan data
  String _getDetailImageUrl(Map<String, dynamic> data, String mediaType) {
    if (mediaType == 'anime') {
      // Jikan uses the raw URL
      return data['images']?['jpg']?['large_image_url'] ?? '';
    } else {
      // TMDb uses a relative path that needs the base URL
      const String imageBaseUrl = 'https://image.tmdb.org/t/p/w500';
      final path = data['poster_path'] ?? data['backdrop_path'];
      return path != null ? '$imageBaseUrl$path' : '';
    }
  }

  // Helper to extract the main synopsis
  String _getSynopsis(Map<String, dynamic> data, String mediaType) {
    if (mediaType == 'anime') {
      return data['synopsis'] ?? 'No synopsis available.';
    } else {
      return data['overview'] ?? 'No overview available.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.content.title),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading details: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Details not found.'));
          }

          final data = snapshot.data!;
          final imageUrl = _getDetailImageUrl(data, widget.content.mediaType);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Poster/Header Image
                _buildHeaderImage(imageUrl, context),
                
                // 2. Action Buttons (WishList/WatchList)
                _buildActionButtons(),

                // 3. Synopsis
                _buildSectionTitle(context, 'Synopsis'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(_getSynopsis(data, widget.content.mediaType)),
                ),
                const SizedBox(height: 16),

                // 4. Metadata (Placeholder for specific fields)
                _buildSectionTitle(context, 'Metadata'),
                _buildMetadataRow(data, widget.content.mediaType),
                const SizedBox(height: 16),

                // 5. Cast/Staff (Placeholder for simplicity)
                _buildSectionTitle(context, 'Cast & Crew'),
                _buildCastSection(data, widget.content.mediaType),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildHeaderImage(String imageUrl, BuildContext context) {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        image: imageUrl.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
              )
            : null,
        color: Colors.grey[800],
      ),
      child: Stack(
        children: [
          // Display the content title prominently on the image
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Text(
              widget.content.title,
              style: Theme.of(context).textTheme.headlineMedium!.copyWith(color: Colors.white),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButtons() {
    // We use FutureBuilder again to dynamically check the status from local storage
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // WishList Toggle
          FutureBuilder<List<Content>>(
            future: _storageService.loadWishList(),
            builder: (context, snapshot) {
              bool isWished = snapshot.hasData 
                ? snapshot.data!.any((item) => item.id == widget.content.id && item.mediaType == widget.content.mediaType)
                : false;
              return ElevatedButton.icon(
                onPressed: _toggleWishList,
                icon: Icon(isWished ? Icons.favorite : Icons.favorite_border, color: Colors.red),
                label: Text(isWished ? 'WISH LISTED' : 'ADD TO WISH'),
              );
            },
          ),
          // WatchList Toggle
          FutureBuilder<List<Content>>(
            future: _storageService.loadWatchList(),
            builder: (context, snapshot) {
              bool isWatched = snapshot.hasData 
                ? snapshot.data!.any((item) => item.id == widget.content.id && item.mediaType == widget.content.mediaType)
                : false;
              return ElevatedButton.icon(
                onPressed: _toggleWatchList,
                icon: Icon(isWatched ? Icons.bookmark : Icons.bookmark_border, color: Colors.blue),
                label: Text(isWatched ? 'IN WATCHLIST' : 'ADD TO WATCH'),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }
  
  Widget _buildMetadataRow(Map<String, dynamic> data, String mediaType) {
    String releaseDate = '';
    String runtime = '';

    if (mediaType == 'anime') {
      releaseDate = data['aired']?['string'] ?? 'N/A';
      runtime = data['duration'] ?? 'N/A';
    } else {
      releaseDate = data['release_date'] ?? data['first_air_date'] ?? 'N/A';
      runtime = mediaType == 'movie' 
          ? '${data['runtime'] ?? 'N/A'} mins' 
          : '${data['number_of_seasons'] ?? 'N/A'} seasons';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _metadataItem('Release Date', releaseDate),
          _metadataItem('Runtime/Seasons', runtime),
          _metadataItem('Rating', data['vote_average']?.toStringAsFixed(1) ?? data['score']?.toStringAsFixed(1) ?? 'N/A'),
        ],
      ),
    );
  }
  
  Widget _metadataItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
  
  Widget _buildCastSection(Map<String, dynamic> data, String mediaType) {
    List<dynamic> castList = [];
    if (mediaType == 'anime') {
      // Jikan has voice actors/staff
      castList = data['staff']?.take(5).toList() ?? [];
    } else {
      // TMDb has cast/crew
      castList = data['credits']?['cast']?.take(5).toList() ?? [];
    }

    if (castList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Text('Cast/Staff information not available.'),
      );
    }
    
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: castList.length,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemBuilder: (context, index) {
          final item = castList[index];
          final name = item['name'] ?? item['title'] ?? 'Unknown';
          final role = item['character'] ?? item['job'] ?? 'Staff';
          final profilePath = item['profile_path'];
          
          return Container(
            width: 80,
            margin: const EdgeInsets.only(right: 10),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: profilePath != null 
                    ? NetworkImage('https://image.tmdb.org/t/p/w200$profilePath') 
                    : null,
                  child: profilePath == null ? const Icon(Icons.person) : null,
                ),
                const SizedBox(height: 4),
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Text(role, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          );
        },
      ),
    );
  }
}