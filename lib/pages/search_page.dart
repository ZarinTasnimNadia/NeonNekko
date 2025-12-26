import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'dart:async';
import '../models/content.dart';
import '../services/api_service.dart';
import '../pages/detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  Future<List<Content>> _searchResultsFuture = Future.value([]);
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      if (query.length >= 3) {
        setState(() {
          _searchResultsFuture = _apiService.searchAll(query);
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ShadInput(
          controller: _searchController,
          placeholder: const Text('Search instantly...'),
          // Removing the focus boundary/box shadow
          decoration: ShadDecoration(
            border: ShadBorder.none,
            secondaryBorder: ShadBorder.none,
            secondaryFocusedBorder: ShadBorder.none,
          ),
        ),
      ),
      body: FutureBuilder<List<Content>>(
        future: _searchResultsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('Type 3+ letters...'));
          
          final results = snapshot.data!;
          return ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final item = results[index];
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(item.imageUrl, width: 40, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image)),
                ),
                title: Text(item.title),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailPage(content: item))),
              );
            },
          );
        },
      ),
    );
  }
}