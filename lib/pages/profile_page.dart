import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      if (_supabase.auth.currentUser == null) {
        throw Exception('User is not logged in.');
      }

      final currentUserId = _supabase.auth.currentUser!.id;

      // FIX: Changed the type from List<Map<String, dynamic>> to Map<String, dynamic>
      // because the .single() modifier guarantees a single map response.
      final Map<String, dynamic> data = await _supabase 
          .from('users')
          .select('*, user_preferred_genres (genres (name))')
          .eq('id', currentUserId)
          .single();

      if (mounted) {
        setState(() {
          _profileData = data;
          _isLoading = false;
        });
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error fetching profile: ${e.message}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'An unexpected error occurred: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error.isNotEmpty || _profileData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile Error')),
        body: Center(child: Text(_error.isNotEmpty ? _error : 'Profile not found.', style: TextStyle(color: Theme.of(context).primaryColor))),
      );
    }
    
    // Process the nested genre data from the query result
    // The cast is necessary because the nested structure remains List<Map<String, dynamic>>
    final List<Map<String, dynamic>> genreLinks = (_profileData!['user_preferred_genres'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final String preferredGenres = genreLinks.map((link) => link['genres']['name']).join(', ');
    
    // Extract and display profile fields
    final currentUserId = _supabase.auth.currentUser!.id;
    final username = _profileData!['username'] ?? 'N/A';
    final email = _profileData!['email'] ?? 'N/A';
    final fullName = _profileData!['full_name'] ?? 'N/A';
    final dob = _profileData!['date_of_birth'] ?? 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Implement profile editing navigation
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar Placeholder
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).primaryColor, width: 3),
              ),
              child: const Icon(Icons.person, size: 60, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            
            // Username Display
            Text(
              username,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),

            // Profile Data List
            _buildProfileRow(context, 'Name:', fullName),
            _buildProfileRow(context, 'AccountID:', currentUserId.substring(0, 8) + '...'), // Truncate UUID
            _buildProfileRow(context, 'Email:', email),
            
            // Placeholder fields from wireframe 
            _buildProfileRow(context, 'Watched Anime:', '0'),
            _buildProfileRow(context, 'Watched Movies:', '0'),

            _buildProfileRow(context, 'WishList:', 'View List'),
            _buildProfileRow(context, 'WatchList:', 'View List'),

            _buildProfileRow(context, 'Preferred Genres:', preferredGenres.isEmpty ? 'Not set' : preferredGenres),
            _buildProfileRow(context, 'Date of Birth:', dob),

            const SizedBox(height: 40),

            // Back Button
            TextButton(
              onPressed: () => Navigator.of(context).pop(), 
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}